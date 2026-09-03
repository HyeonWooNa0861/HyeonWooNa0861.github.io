#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "rbconfig"
require "tmpdir"

VALIDATOR = File.expand_path("validate_blog.rb", __dir__)

class ValidateBlogTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("gitblog-validator-")
    write("pages/main/index.md", page_document("/"))
    write("_posts/2020-01-01-valid-post.md", post_document)
    write("_data/navigation.yml", "- title: Home\n  url: /\n")
    git("init", "--quiet")
    git("add", ".")
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def test_valid_minimal_site_passes
    output, status = validate

    assert status.success?, output
    assert_includes output, "Validated 2 public Markdown documents."
  end

  def test_future_timestamp_fails
    write(
      "_posts/2999-01-01-future-post.md",
      post_document(date: "2999-01-01 00:00:00 +0900", permalink: "/posts/future-post/")
    )
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "date is in the future"
  end

  def test_duplicate_output_route_fails
    write("pages/main/index.md", page_document("/posts/valid-post/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "duplicate output route /posts/valid-post/"
  end

  def test_invalid_front_matter_types_fail
    write("_posts/2020-01-01-valid-post.md", post_document(layout: "default", tags: "one-tag"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "layout must be \"post\""
    assert_includes output, "tags must be a non-empty list"
  end

  def test_missing_internal_route_fails
    write("pages/main/index.md", page_document("/", body: "[Missing]({{ \"/missing/\" | relative_url }})"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "missing local route or asset /missing/"
  end

  def test_secret_signature_fails_without_printing_secret
    token = "ghp_" + ("a" * 40)
    write("notes.txt", "credential=#{token}\n")
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "possible GitHub token"
    refute_includes output, token
  end

  def test_pem_and_extensionless_private_keys_are_scanned_without_echoing_content
    encrypted_header = "-----BEGIN " + "ENCRYPTED PRIVATE KEY-----"
    dsa_header = "-----BEGIN " + "DSA PRIVATE KEY-----"
    write("credentials.pem", "#{encrypted_header}\nnot-a-real-key\n")
    write("PRIVATE_KEY", "#{dsa_header}\nnot-a-real-key\n")
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "credentials.pem: possible private key"
    assert_includes output, "PRIVATE_KEY: possible private key"
    refute_includes output, encrypted_header
    refute_includes output, dsa_header
  end

  def test_unsafe_uri_schemes_fail
    body = <<~MARKDOWN
      [Unsafe script](javascript:alert(1))

      <a href="data:text/html,unsafe">Unsafe data</a>
      <img src="vbscript:unsafe" alt="Unsafe image">
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
    assert_includes output, "disallowed URI scheme data"
    assert_includes output, "disallowed URI scheme vbscript"
  end

  def test_html_link_attributes_cannot_be_spoofed_by_data_attributes
    body = '<a href="https://example.com" data-target="_blank" data-rel="noopener">External</a>'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external HTML link must use target=_blank and rel=noopener"
  end

  def test_html5_named_references_cannot_hide_unsafe_or_external_urls
    ["javascript&colon;alert(1)", "java&Tab;script&colon;alert(1)"].each do |target|
      write("pages/main/index.md", page_document("/", body: %(<a href="#{target}">Unsafe</a>)))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end

    write("pages/main/index.md", page_document("/", body: '<a href="https&colon;&sol;&sol;example.com">External</a>'))
    git("add", ".")
    output, status = validate
    refute status.success?
    assert_includes output, "external HTML link must use target=_blank and rel=noopener"

    write("pages/main/index.md", page_document("/", body: '<a href="https://example.com/?value=&copy;">Unsupported</a>'))
    git("add", ".")
    output, status = validate
    refute status.success?
    assert_includes output, "unsupported named HTML character reference in URI target"
  end

  def test_semicolonless_numeric_references_cannot_hide_unsafe_scheme
    targets = [
      "javascript&#58 alert(1)",
      "javascript&#x3a alert(1)",
      "java&#9script&#58alert(1)",
      "java&#x0A script&#x3A alert(1)"
    ]
    targets.each do |target|
      write("pages/main/index.md", page_document("/", body: %(<a href="#{target}">Unsafe</a>)))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end
  end

  def test_http_scheme_without_slashes_still_requires_external_link_safety
    body = '[External](https:example.com)'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external Markdown link must use target=_blank and rel=noopener"
  end

  def test_page_metadata_types_and_optional_timestamps_are_checked
    write(
      "pages/main/index.md",
      <<~MARKDOWN
        ---
        layout: default
        title:
          - Home
        nav_title: 42
        permalink: /
        date: 2999-01-01 00:00:00 +0900
        last_modified_at: 2999-01-02 00:00:00 +0900
        ---

        <h1>Home</h1>
      MARKDOWN
    )
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "title must be a non-empty string"
    assert_includes output, "nav_title must be a non-empty string"
    assert_includes output, "date is in the future"
    assert_includes output, "last_modified_at is in the future"
  end

  def test_collection_scalar_metadata_fields_must_be_strings
    content = post_document
      .sub('title: "Valid Post"', "title: 42")
      .sub("section: notes", "section: true")
    write("_posts/2020-01-01-valid-post.md", content)
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "title must be a non-empty string"
    assert_includes output, "section must be a non-empty string"
  end

  def test_private_build_path_is_not_a_public_target
    write("_layouts/default.html", "<!doctype html>\n")
    write("pages/main/index.md", page_document("/", body: "[Private layout](/_layouts/default.html)"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "missing local route or asset /_layouts/default.html"
  end

  def test_persistent_resource_preview_fallback_is_rejected
    write(
      "_layouts/default.html",
      '<p class="pdf-reader-fallback">Preview unavailable?</p>'
    )
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "persistent resource-preview fallback copy is not allowed"
    assert_includes output, "persistent resource-preview fallback element is not allowed"
  end

  def test_resource_reader_requires_mobile_modal_accessibility_contract
    write("_layouts/default.html", '<div data-pdf-reader-panel></div>')
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "resource reader needs CSS-enforced default hiding"
    assert_includes output, "desktop resource reader must not show a backdrop"
    assert_includes output, "mobile resource reader needs an interactive backdrop"
    assert_includes output, "mobile resource reader needs modal semantics"
    assert_includes output, "desktop resource reader must clear modal semantics"
    assert_includes output, "mobile resource reader must suppress background interaction"
    assert_includes output, "resource reader must restore background interaction"
    assert_includes output, "mobile resource reader must trap keyboard focus"
    assert_includes output, "resource reader backdrop must close the reader"
    assert_includes output, "resource reader must restore trigger focus"
    assert_includes output, "resource reader initialization and close must hide it from assistive technology"
    assert_includes output, "resource reader open must expose it to assistive technology"
    assert_includes output, "resource reader must return to a hidden state"
    assert_includes output, "resource reader close must unload the embedded resource"
    assert_includes output, "resource reader close must clear reader state classes"
    assert_includes output, "resource reader needs an English Hide control"
    assert_includes output, "YouTube reader URLs must require credential-free HTTPS on the default port"
    assert_includes output, "YouTube reader URLs must use a recognized official path shape"
    assert_includes output, "resource reader must recognize YouTube sources"
    assert_includes output, "resource reader must use the official YouTube iframe endpoint"
    assert_includes output, "resource reader iframe permissions must stay narrowly scoped"
    assert_includes output, "resource reader video frame must allow fullscreen"
    assert_includes output, "mobile resource reader needs an aria-hidden fallback when inert is unavailable"
    assert_includes output, "resource reader must restore fallback aria-hidden state"
  end

  def test_public_asset_target_passes
    write("assets/images/decorative.svg", "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>\n")
    body = <<~MARKDOWN
      ![](/assets/images/decorative.svg){:role="presentation" aria-hidden="true"}

      <img src="/assets/images/decorative.svg" alt="" aria-hidden="true">
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_decorative_markdown_image_requires_explicit_marker
    write("assets/images/decorative.svg", "<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>\n")
    body = <<~MARKDOWN
      ![](/assets/images/decorative.svg)

      <img src="/assets/images/decorative.svg" alt="">
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "empty alt text requires role=presentation or aria-hidden=true"
  end

  def test_markdown_reference_and_autolink_are_checked
    body = <<~MARKDOWN
      [Reference][docs]

      <https://example.org/reference>

      [docs]: https://example.com/docs
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external Markdown link must use target=_blank and rel=noopener"
    assert_includes output, "external Markdown autolink cannot declare required safety attributes"
  end

  def test_markdown_link_with_balanced_parentheses_title_and_attributes_passes
    body = <<~MARKDOWN
      [Docs](https://example.com/a_(b) "Reference"){:target="_blank" rel="noopener"}

      [Reference][docs-reference]{:target="_blank" rel="noopener"}

      [docs-reference]: https://example.com/reference "Reference title"
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_duplicate_html_attributes_are_rejected
    body = '<a href="javascript:unsafe" href="https://example.com" target="_blank" rel="noopener">Unsafe</a>'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "duplicate HTML attribute href"
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_invalid_jekyll_config_is_not_masked
    write("_config.yml", "include: [assets\n")
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "_config.yml: invalid YAML"
  end

  def test_jekyll_config_requires_kramdown_mathjax
    write("_config.yml", "markdown: commonmark\nkramdown:\n  math_engine: katex\n")
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "_config.yml: markdown must be kramdown"
    assert_includes output, "_config.yml: kramdown.math_engine must be mathjax"
  end

  def test_entity_encoded_external_url_requires_safe_attributes
    body = '<a href="&#x68;ttps://example.com">External</a>'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external HTML link must use target=_blank and rel=noopener"
  end

  def test_nested_linked_image_is_validated
    body = '[![](javascript:unsafe)](https://example.com){:target="_blank" rel="noopener"}'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
    assert_includes output, "empty alt text requires role=presentation or aria-hidden=true"
  end

  def test_navigation_requires_string_fields_and_rooted_local_paths
    write(
      "_data/navigation.yml",
      <<~YAML
        - title: 42
          url: 7
        - title: Relative
          url: missing-page
      YAML
    )
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "title must be a non-empty string"
    assert_includes output, "url must be a non-empty string"
    assert_includes output, "local target must start with /"
  end

  def test_relative_internal_target_is_rejected
    write("pages/main/index.md", page_document("/", body: "[Missing](missing.pdf)"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "local target must start with /"
  end

  def test_duplicate_study_order_within_course_fails
    write("_study/example/first.md", study_document(title: "First", order: 1))
    write("_study/example/second.md", study_document(title: "Second", order: 1))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "_study: duplicate order 1 in Example Course"
  end

  def test_navigation_duplicate_and_missing_routes_fail
    write(
      "_data/navigation.yml",
      <<~YAML
        - title: First
          url: /posts/valid-post/
        - title: Duplicate
          url: /posts/valid-post/
        - title: Missing
          url: /missing/
      YAML
    )
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "duplicate url /posts/valid-post/"
    assert_includes output, "missing local route or asset /missing/"
  end

  def test_table_and_mathjax_structure_failures_are_reported
    body = <<~'MARKDOWN'
      $$x + y

      | One | Two |
      |---|---|
      | Only one |
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "inline $$ delimiters must open and close on the same line"
    assert_includes output, "table row has 1 columns; expected 2"
  end

  def test_mathjax_detects_bare_latex_commands_and_commands_outside_delimiters
    body = <<~'MARKDOWN'
      $$a,b,qquad c=frac{1}{2}$$

      The rendered command \alpha is missing math delimiters.
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "possible bare LaTeX command frac inside MathJax"
    assert_includes output, "possible bare LaTeX command qquad inside MathJax"
    assert_includes output, "LaTeX command \\alpha is outside MathJax delimiters"
  end

  def test_mathjax_detects_unbalanced_display_delimiters_and_braces
    body = <<~'MARKDOWN'
      $$x_{i}$$

      $$y_{i$$

      $$
      y = \frac{1}{2}
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unbalanced MathJax braces"
    assert_includes output, "unclosed display MathJax block"
  end

  def test_mathjax_rejects_double_escaping_but_allows_display_row_breaks
    invalid_body = <<~'MARKDOWN'
      $$x = \\frac{1}{2}$$
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: invalid_body))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, "possible double-escaped MathJax command or invalid row break"

    valid_body = <<~'MARKDOWN'
      Inline matrix: $$v=\begin{bmatrix}1\\2\end{bmatrix}$$

      $$
      \begin{aligned}
      x &= 1 \\
      y &= 2 \\[4pt]
      z &= 3
      \end{aligned}
      $$
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: valid_body))
    git("add", ".")

    output, status = validate
    assert status.success?, output
  end

  def test_mathjax_validation_ignores_code_comments_and_html_markup
    body = <<~'MARKDOWN'
      `\(\alpha\) $$ { qquad`

      ```tex
      \[\beta\] $$ { qquad
      ```

      <!-- \(\gamma\) $$ { qquad -->
      <code>\[\delta\] $$ { qquad</code>
      <pre>\(\epsilon\) $$ { qquad</pre>
      <span data-example="\[\zeta\] $$ { qquad">Rendered text</span>

      $$\text{the word qquad is prose}$$
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_mathjax_supports_kramdown_inline_dollars_and_rejects_raw_delimiters
    write("pages/main/index.md", page_document("/", body: "Inline: $$0<p<1,\\quad x = \\sqrt{2}$$.\n"))
    git("add", ".")
    output, status = validate
    assert status.success?, output

    write("pages/main/index.md", page_document("/", body: "\\(x + y\\) and \\[z\\]\n"))
    git("add", ".")
    output, status = validate
    refute status.success?
    assert_includes output, "unsupported raw MathJax delimiter \\(; use $$ delimiters"
    assert_includes output, "unsupported raw MathJax delimiter \\[; use $$ delimiters"
  end

  def test_summary_mathjax_requires_kramdown_span_parsing
    body = <<~'MARKDOWN'
      <details markdown="block">
      <summary class="worked-example">Derive $$x^2$$</summary>

      Explanation.
      </details>
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, '<summary> containing $$ must use markdown="span"'

    write(
      "pages/main/index.md",
      page_document("/", body: body.sub('class="worked-example"', 'class="worked-example" markdown="span"'))
    )
    git("add", ".")

    output, status = validate
    assert status.success?, output
  end

  def test_details_requires_kramdown_block_parsing
    body = <<~'MARKDOWN'
      <details class="worked-example">
      <summary>Show the answer</summary>

      Answer with **emphasis**.
      </details>
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, '<details> must use markdown="block"'

    write(
      "pages/main/index.md",
      page_document("/", body: body.sub('class="worked-example"', 'class="worked-example" markdown="block"'))
    )
    git("add", ".")

    output, status = validate
    assert status.success?, output
  end

  def test_mathjax_rejects_cross_line_inline_and_mixed_display_delimiters
    cross_line = <<~'MARKDOWN'
      A broken inline expression starts $$x +
      y$$ on the next line.
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: cross_line))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, "inline $$ delimiters must open and close on the same line"

    mixed_display = <<~'MARKDOWN'
      $$
      x + y$$
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: mixed_display))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, "display MathJax block contains a mixed $$ delimiter line"
    assert_includes output, "unclosed display MathJax block"
  end

  def test_even_backslashes_before_table_pipe_keep_the_pipe_as_a_delimiter
    body = <<~'MARKDOWN'
      | One | Two |
      |---|---|
      | A \\| B | C |
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "table row has 3 columns; expected 2"
  end

  def test_odd_backslash_before_table_pipe_keeps_literal_pipe_in_cell
    body = <<~'MARKDOWN'
      | One |
      |---|
      | A \| B |
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_inline_mathjax_rejects_raw_pipes_that_kramdown_parses_as_tables
    invalid_body = <<~'MARKDOWN'
      Cardinality $$O(|E|)$$ and transition $$P(s'|s,a)$$.
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: invalid_body))
    git("add", ".")

    output, status = validate
    refute status.success?
    assert_includes output, "inline MathJax contains raw |"

    valid_body = <<~'MARKDOWN'
      Cardinality $$O(\lvert E\rvert)$$, transition $$P(s'\mid s,a)$$, and norm $$\|x\|$$.
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: valid_body))
    git("add", ".")

    output, status = validate
    assert status.success?, output
  end

  def test_escaped_backticks_do_not_hide_unsafe_rendered_link
    body = '\\` [Unsafe](javascript:alert(1)) \\`'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_even_backslashes_do_not_hide_unsafe_rendered_link
    body = '\\\\[Unsafe](javascript:alert(1))'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_escaped_image_bang_leaves_a_rendered_link
    body = '\\![External](https://example.com/image.png)'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external Markdown link must use target=_blank and rel=noopener"
  end

  def test_real_inline_code_span_hides_non_rendered_link_syntax
    body = '`[Example](javascript:not-rendered)`'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_backslash_before_kramdown_code_span_closer_does_not_extend_mask
    body = '`code\\` [Unsafe](javascript:alert(1)) `'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_longer_backtick_run_can_close_kramdown_code_span
    body = '``code``` [Unsafe](javascript:alert(1)) ``'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_kramdown_whitespace_backticks_do_not_hide_rendered_link
    body = '` [Unsafe](javascript:alert(1)) `'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_indented_fence_marker_does_not_hide_following_rendered_link
    ["    ```", "\t```"].each do |opening|
      body = "#{opening}\n\n[Unsafe](javascript:alert(1))\n```\n"
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end
  end

  def test_unclosed_fence_does_not_hide_following_rendered_link
    body = "```text\ncode\n\n[Unsafe](javascript:alert(1))\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unbalanced fenced code block"
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_blockquote_fence_markers_do_not_hide_link_after_container
    body = "> ```\n> code\n\n[Unsafe](javascript:alert(1))\n> ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_blockquote_fenced_code_masks_non_rendered_link_syntax
    body = "> ```\n> [Example](javascript:not-rendered)\n> ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_nested_blockquote_fenced_code_masks_non_rendered_link_syntax
    body = "> > ~~~text\n> > [Example](javascript:not-rendered)\n> > ~~~\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_list_fenced_code_masks_non_rendered_link_syntax
    body = "- ```\n  [Example](javascript:not-rendered)\n  ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_fence_in_list_item_continuation_masks_non_rendered_link_syntax
    body = "- item\n  ```text\n  [Example](javascript:not-rendered)\n  ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_blockquote_fence_in_list_item_masks_non_rendered_link_syntax
    body = "- item\n  > ```\n  > [Example](javascript:not-rendered)\n  > ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_definition_list_fence_masks_non_rendered_link_syntax
    body = "Term\n: ~~~text\n  [Example](javascript:not-rendered)\n  ~~~\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_footnote_fence_masks_non_rendered_link_syntax
    body = "Text[^note]\n\n[^note]:\n    ~~~text\n    [Example](javascript:not-rendered)\n    ~~~\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_mixed_blockquote_list_fence_masks_non_rendered_link_syntax
    body = "> - ```ruby\n>   [Example](javascript:not-rendered)\n>   ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_list_fence_cannot_close_across_container_boundary
    body = "- ```\n  code\n\n[Unsafe](javascript:alert(1))\n  ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unbalanced fenced code block"
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_list_item_continuation_fence_cannot_close_at_root
    body = "- item\n  ```\n  code\n\n[Unsafe](javascript:alert(1))\n```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unbalanced fenced code block"
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_container_fence_requires_matching_character_and_length
    body = "> ````\n> [Unsafe](javascript:alert(1))\n> ~~~~\n> ```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unbalanced fenced code block"
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_top_level_link_after_container_fence_remains_visible
    body = "> ```\n> code\n> ```\n\n[Unsafe](javascript:alert(1))\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_parenthesized_number_is_not_an_ordered_list_fence_container
    body = "1) ~~~\n   [Unsafe](javascript:not-fenced)\n   ~~~\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_valid_gfm_fence_masks_non_rendered_link_syntax
    body = "```text\n[Example](javascript:not-rendered)\n```\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_disallowed_kramdown_autolink_scheme_fails
    write("pages/main/index.md", page_document("/", body: "<ftp://example.com/file>"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme ftp"
  end

  def test_escaped_autolink_opening_is_literal_text
    write("pages/main/index.md", page_document("/", body: '\\<https://example.com/file>'))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_even_backslashes_before_autolink_leave_it_rendered
    write("pages/main/index.md", page_document("/", body: '\\\\<ftp://example.com/file>'))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme ftp"
  end

  def test_unbracketed_inline_link_destination_can_contain_whitespace
    write("assets/docs/file name.pdf", "not-a-real-pdf")
    write("pages/main/index.md", page_document("/", body: "[Document](/assets/docs/file name.pdf)"))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_spaced_inline_link_destination_is_validated_as_one_target
    write("pages/main/index.md", page_document("/", body: "[Broken](/ existing-missing)"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "missing local route or asset / existing-missing"
  end

  def test_indented_code_is_masked_at_root_and_inside_containers
    bodies = [
      "    [Example](javascript:not-rendered)\n",
      ">     [Example](javascript:not-rendered)\n",
      "- item\n\n      [Example](javascript:not-rendered)\n"
    ]

    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")
      output, status = validate
      assert status.success?, "#{body.inspect}\n#{output}"
    end
  end

  def test_indented_code_masks_liquid_html_and_table_syntax
    body = "\n" + [
      "{{ page.unescaped }}",
      '<img src="javascript:not-rendered">',
      "| One | Two |",
      "|---|---|",
      "| only one |"
    ].map { |line| "    #{line}\n" }.join
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_indented_html_link_is_not_rendered
    body = "    <a href=\"https://example.com\">Example</a>\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_indented_code_inside_nested_blockquote_list_is_masked
    body = "> - item\n>\n>       [Example](javascript:not-rendered)\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_indented_code_on_the_first_list_line_is_masked
    bodies = [
      "-     [Example](javascript:not-rendered)\n",
      "> -     [Example](javascript:not-rendered)\n"
    ]
    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")
      output, status = validate
      assert status.success?, "#{body.inspect}\n#{output}"
    end
  end

  def test_indented_text_that_interrupts_a_paragraph_remains_rendered
    body = "Paragraph\n    [Unsafe](javascript:alert(1))\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_three_space_indent_and_list_paragraph_continuation_remain_rendered
    bodies = [
      "   [Unsafe](javascript:alert(1))\n",
      "- item\n  [Unsafe](javascript:alert(1))\n"
    ]
    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")
      output, status = validate
      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end
  end

  def test_liquid_cannot_hide_an_unsafe_markdown_link_target
    body = '[Unsafe]({{ "javascript:alert(1)" }})'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_liquid_cannot_hide_an_unsafe_html_link_target
    body = '<a href="{{ "javascript:alert(1)" }}">Unsafe</a>'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_unknown_dynamic_html_link_targets_fail_closed
    [
      "{{ page.destination | escape }}",
      "{{ page.destination | relative_url | escape }}"
    ].each do |destination|
      body = %(<a href="#{destination}" target="_blank" rel="noopener">Unsafe</a>)
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "unverified Liquid expression"
    end
  end

  def test_front_matter_strings_cannot_inject_markup_or_break_attributes
    document = <<~'MARKDOWN'
      ---
      layout: default
      title: "<img src=x onerror=alert(1)>"
      permalink: /
      payload: '" href="javascript:alert(1)'
      ---

      <a title="{{ page.payload }}">Unsafe</a>
      {{ page.title }}
    MARKDOWN
    write("pages/main/index.md", document)
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "dynamic Liquid output must end with an HTML escape filter"
  end

  def test_escaped_metadata_allows_normal_quotes_and_angle_brackets
    document = <<~'MARKDOWN'
      ---
      layout: default
      title: 'What''s "New" in C++ <=>'
      permalink: /
      ---

      {{ page.title | escape }}
    MARKDOWN
    navigation = <<~'YAML'
      - title: 'What''s New'
        description: 'A "quoted" archive'
        url: /
    YAML
    write("pages/main/index.md", document)
    write("_data/navigation.yml", navigation)
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_liquid_cannot_generate_html_link_attribute_structure
    [
      '<a {{ page.link_attributes }}>Unsafe</a>',
      '<a h{{ page.suffix }}="javascript:alert(1)">Unsafe</a>',
      '<{{ page.tag }} href="javascript:alert(1)">Unsafe</{{ page.tag }}>'
    ].each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_match(/Liquid cannot generate HTML attribute|HTML tag name cannot be generated by Liquid/, output)
    end
  end

  def test_allowlisted_template_link_target_is_accepted
    body = '<a href="{{ post.url | relative_url | escape }}">Post</a>'
    write("post/ai-agents/index.md", page_document("/post/ai-agents/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_liquid_cannot_hide_an_unsafe_reference_link_target
    body = "[Unsafe][target]\n\n[target]: {{ \"javascript:alert(1)\" }}"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_blockquote_reference_definition_is_document_scoped
    body = "[Unsafe][target]\n\n> [target]: javascript:alert(1)\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_list_continuation_reference_definitions_are_document_scoped
    definitions = [
      "- item\n  [target]: javascript:alert(1)",
      "- item\n    [target]: javascript:alert(1)",
      "- item\n\t[target]: javascript:alert(1)",
      "10. item\n    [target]: javascript:alert(1)"
    ]

    definitions.each do |definition|
      body = "[Unsafe][target]\n\n#{definition}\n"
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end
  end

  def test_recursive_container_reference_definitions_are_document_scoped
    definitions = [
      "Term\n: item\n    [target]: javascript:alert(1)",
      "[^note]:\n    [target]: javascript:alert(1)"
    ]

    definitions.each do |definition|
      body = "[Unsafe][target]\n\n#{definition}\n"
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "disallowed URI scheme javascript"
    end
  end

  def test_reference_definition_destination_can_contain_spaces
    body = "[Unsafe][target]\n\n[target]: javascript:alert(1)// comment\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_indented_code_outside_list_does_not_define_reference
    body = "    [target]: javascript:not-rendered\n\n[Unresolved][target]\n"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_last_reference_definition_wins_and_duplicates_fail
    body = <<~MARKDOWN
      [Unsafe][target]

      [target]: /
      [target]: javascript:alert(1)
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
    assert_includes output, "duplicate Markdown reference definition"
  end

  def test_kramdown_attributes_cannot_override_link_or_image_targets
    bodies = [
      '[Safe](/){:href="javascript:alert(1)"}',
      '[Safe](/){:href="https://example.com"}',
      '![Alt](/assets/image.png){:src="data:image/svg+xml,unsafe"}',
      "[target]: /\n{:href=\"javascript:alert(1)\"}\n\n[Safe][target]"
    ]

    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_match(/Kramdown attributes cannot override (?:href|src)/, output)
    end
  end

  def test_escaped_brace_and_multiline_kramdown_attributes_cannot_bypass_target_override_ban
    bodies = [
      '[Safe](/){:title="x\}" href="javascript:alert(1)"}',
      "[target]: /\n{:title=\"x\\}\" href=\"javascript:alert(1)\"}\n\n[Safe][target]",
      "[Safe](/){:\n href=\"javascript:alert(1)\"\n}"
    ]

    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")

      output, status = validate

      refute status.success?
      assert_includes output, "Kramdown attributes cannot override href"
    end
  end

  def test_escaped_and_unattached_kramdown_attribute_text_is_not_applied
    bodies = [
      '\\{:href="javascript:not-an-attribute"}',
      'Text {:href="javascript:not-an-ial"}',
      "Paragraph\n\n{:href=\"javascript:not-attached\"}\n"
    ]

    bodies.each do |body|
      write("pages/main/index.md", page_document("/", body: body))
      git("add", ".")
      output, status = validate
      assert status.success?, output
    end
  end

  def test_html_comments_mask_non_rendered_markup
    body = <<~MARKDOWN
      <!--
      [Example](javascript:not-rendered)
      {:href="javascript:not-rendered"}
      -->
    MARKDOWN
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end


  def test_unclosed_html_comment_fails_closed
    write("pages/main/index.md", page_document("/", body: "<!-- hidden"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "unclosed HTML comment"
  end

  def test_liquid_inside_html_comment_is_still_validated
    body = "<!-- {{ page.unescaped }} -->"
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "dynamic Liquid output must end with an HTML escape filter"
  end

  def test_escaped_html_comment_opening_does_not_mask_rendered_markdown
    body = '\\<!-- [Unsafe](javascript:alert(1)) -->'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_content_liquid_output_is_only_allowed_at_a_layout_body_sink
    write("pages/main/index.md", page_document("/", body: "{{ content }}"))
    write("_layouts/default.html", '<div data-content="{{ content }}"></div>')
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_operator output.scan("dynamic Liquid output must end with an HTML escape filter").length, :>=, 2
  end

  def test_content_liquid_output_is_rejected_inside_script_and_includes
    write("_layouts/default.html", "<script>\n{{ content }}\n</script>\n")
    write("_includes/unsafe.html", "{{ content }}\n")
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_operator output.scan("dynamic Liquid output must end with an HTML escape filter").length, :>=, 2
  end

  def test_content_liquid_output_is_allowed_as_the_known_layout_body_sink
    write("_layouts/default.html", "<main>\n  {{ content }}\n</main>\n")
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_srcset_targets_validate_schemes_and_local_assets
    write("assets/images/present.png", "png")
    body = <<~HTML
      <img src="/assets/images/present.png"
           srcset="data:image/svg+xml;base64,PHN2Zy8+ 1x, /assets/images/missing.png 2x"
           alt="Example">
    HTML
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme data"
    assert_includes output, "missing local route or asset /assets/images/missing.png"
  end

  def test_valid_local_srcset_targets_pass
    write("assets/images/one.png", "png")
    write("assets/images/two.png", "png")
    body = '<img src="/assets/images/one.png" srcset="/assets/images/one.png 1x, /assets/images/two.png 2x" alt="Example">'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_source_srcset_rejects_javascript
    body = '<source srcset="javascript:alert(1) 1x">'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "disallowed URI scheme javascript"
  end

  def test_external_http_srcset_targets_pass
    body = '<img src="/" srcset="https://example.com/one.png 1x, http://example.com/two.png 2x" alt="Example">'
    write("pages/main/index.md", page_document("/", body: body))
    git("add", ".")

    output, status = validate

    assert status.success?, output
  end

  def test_navigation_cannot_skip_validation_with_liquid
    write("_data/navigation.yml", "- title: Home\n  url: '{{ data.dynamic_url }}'\n")
    write("pages/main/index.md", page_document("/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "url cannot use Liquid"
  end

  def test_top_level_navigation_url_must_be_internal
    write("_data/navigation.yml", "- title: Home\n  url: https://example.com/\n")
    write("pages/main/index.md", page_document("/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "url must be a site-root internal route"
  end

  def test_navigation_rejects_protocol_relative_child_url
    navigation = <<~YAML
      - title: Home
        url: /
        children:
          - title: External
            url: //example.com/path
    YAML
    write("_data/navigation.yml", navigation)
    write("pages/main/index.md", page_document("/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "url cannot be protocol-relative"
  end

  def test_navigation_external_url_requires_double_slash_form
    navigation = <<~YAML
      - title: Home
        url: /
        children:
          - title: External
            url: https:example.com/path
    YAML
    write("_data/navigation.yml", navigation)
    write("pages/main/index.md", page_document("/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "external URL must use http:// or https://"
  end

  def test_navigation_url_rejects_html_attribute_delimiters
    navigation = <<~YAML
      - title: Home
        url: /
        children:
          - title: External
            url: 'https://example.com/" onmouseover="alert(1)'
    YAML
    write("_data/navigation.yml", navigation)
    write("pages/main/index.md", page_document("/"))
    git("add", ".")

    output, status = validate

    refute status.success?
    assert_includes output, "contains an unsafe URL delimiter"
  end

  private

  def write(relative, content)
    path = File.join(@root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def git(*arguments)
    _output, status = Open3.capture2e("git", "-C", @root, *arguments)
    assert status.success?, "git #{arguments.join(' ')} failed"
  end

  def validate
    stdout, stderr, status = Open3.capture3({ "BLOG_ROOT" => @root }, RbConfig.ruby, VALIDATOR)
    [stdout + stderr, status]
  end

  def page_document(permalink, body: "<h1>Home</h1>")
    <<~MARKDOWN
      ---
      layout: default
      title: Home
      permalink: #{permalink}
      ---

      #{body}
    MARKDOWN
  end

  def post_document(date: "2020-01-01 00:00:00 +0900", permalink: "/posts/valid-post/", layout: "post", tags: ["Validation"])
    rendered_tags = if tags.is_a?(Array)
                      "tags:\n" + tags.map { |tag| "  - #{tag}" }.join("\n")
                    else
                      "tags: #{tags}"
                    end
    <<~MARKDOWN
      ---
      layout: #{layout}
      title: "Valid Post"
      date: #{date}
      categories:
        - Notes
      #{rendered_tags}
      permalink: #{permalink}
      section: notes
      ---

      ## Core message

      A compact validation fixture.
    MARKDOWN
  end

  def study_document(title:, order:)
    <<~MARKDOWN
      ---
      layout: default
      date: 2020-01-01 00:00:00 +0900
      title: "#{title}"
      course: "Example Course"
      topic: "Validation"
      order: #{order}
      major_topic: "Validation"
      keywords:
        - "Fixture"
      ---

      ## Core message

      A compact study fixture.
    MARKDOWN
  end
end
