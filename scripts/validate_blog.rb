#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "cgi"
require "open3"
require "pathname"
require "set"
require "strscan"
require "time"
require "uri"
require "yaml"

ROOT = Pathname.new(ENV.fetch("BLOG_ROOT", File.expand_path("..", __dir__))).expand_path
NOW = Time.now.getlocal("+09:00")
TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S %z"
TIMESTAMP_VALUE = /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \+0900\z/
HANGUL = /[가-힣]/
KEBAB_COMPONENT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
POST_FILENAME = /\A\d{4}-\d{2}-\d{2}-[a-z0-9]+(?:-[a-z0-9]+)*\z/
POST_PERMALINK = %r{\A/posts/[a-z0-9]+(?:-[a-z0-9]+)*/\z}
OUTPUT_ROUTE = %r{\A/(?:[a-z0-9]+(?:-[a-z0-9]+)*/)*\z}

SECRET_PATTERNS = {
  "AWS access key" => /(?:^|[^A-Z0-9])AKIA[0-9A-Z]{16}(?:$|[^A-Z0-9])/,
  "OpenAI-style secret" => /(?:^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}/,
  "GitHub token" => /(?:^|[^A-Za-z0-9])(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})/,
  "private key" => /-----BEGIN (?:[A-Z0-9][A-Z0-9 -]* )?PRIVATE KEY(?: BLOCK)?-----/
}.freeze

COLLECTION_SCHEMAS = {
  "_posts" => {
    layout: "post",
    required: %w[layout title date categories tags permalink section]
  },
  "_research" => {
    layout: "default",
    required: %w[layout date title topic order major_topic keywords]
  },
  "_study" => {
    layout: "default",
    required: %w[layout date title course topic order major_topic keywords]
  },
  "_assignment" => {
    layout: "default",
    required: %w[layout date title course topic]
  }
}.freeze

PAGE_PATTERNS = %w[pages/**/*.md post/**/*.md].freeze
PAGE_REQUIRED_FIELDS = %w[layout title permalink].freeze
ENGLISH_METADATA_FIELDS = %w[title nav_title course topic major_topic categories tags keywords].freeze
LIST_FIELDS = %w[categories tags keywords].freeze
STRING_FIELDS = %w[layout title nav_title course topic major_topic permalink section].freeze
ORDERED_COLLECTIONS = %w[_research _study _assignment].freeze
ALLOWED_URI_SCHEMES = %w[http https mailto tel].freeze
SAFE_BODY_CONTENT_SINKS = Set.new(%w[_layouts/default.html _layouts/post.html]).freeze
URI_HTML5_NAMED_REFERENCES = {
  "&colon;" => ":",
  "&sol;" => "/",
  "&bsol;" => "\\",
  "&Tab;" => "\t",
  "&NewLine;" => "\n"
}.freeze
HTML_NAMED_REFERENCE = /&[A-Za-z][A-Za-z0-9]+;/.freeze
HTML_NUMERIC_REFERENCE = /&#(?:(x)([0-9A-Fa-f]+)|(\d+));?/i.freeze
NAVIGATION_STRING_FIELDS = %w[title url match source_url description source_label section].freeze
NAVIGATION_ENGLISH_FIELDS = %w[title description source_label section].freeze
PUBLIC_TEMPLATE_PATTERNS = [
  "_layouts/**/*.html",
  "_layouts/**/*.md",
  "_layouts/**/*.liquid",
  "_includes/**/*.html",
  "_includes/**/*.md",
  "_includes/**/*.liquid"
].freeze
BANNED_PUBLIC_TEMPLATE_MARKERS = {
  "Preview unavailable?" => "persistent resource-preview fallback copy",
  "pdf-reader-fallback" => "persistent resource-preview fallback element"
}.freeze
RESOURCE_READER_CONTRACT_PATTERNS = {
  /\.pdf-reader-panel\[hidden\]\s*\{[^}]*display:\s*none\s*!important;/m => "resource reader needs CSS-enforced default hiding",
  /body\.pdf-reader-active \.pdf-reader-backdrop\s*\{[^}]*display:\s*none;/m => "desktop resource reader must not show a backdrop",
  /body\.pdf-reader-modal-active \.pdf-reader-backdrop\s*\{[^}]*display:\s*block;[^}]*pointer-events:\s*auto;/m => "mobile resource reader needs an interactive backdrop",
  /readerPanel\.setAttribute\("aria-modal", "true"\)/ => "mobile resource reader needs modal semantics",
  /readerPanel\.removeAttribute\("aria-modal"\)/ => "desktop resource reader must clear modal semantics",
  /suppressBackgroundInteraction\(\);/ => "mobile resource reader must suppress background interaction",
  /restoreBackgroundInteraction\(\);/ => "resource reader must restore background interaction",
  /trapReaderFocus\(event\);/ => "mobile resource reader must trap keyboard focus",
  /readerBackdrop\.addEventListener\("click", closeResourceReader\);/ => "resource reader backdrop must close the reader",
  /lastReaderTrigger\.focus\(\{ preventScroll: true \}\);/ => "resource reader must restore trigger focus",
  /readerPanel\.setAttribute\("aria-hidden", "true"\)/ => "resource reader initialization and close must hide it from assistive technology",
  /readerPanel\.setAttribute\("aria-hidden", "false"\)/ => "resource reader open must expose it to assistive technology",
  /readerPanel\.hidden = true;/ => "resource reader must return to a hidden state",
  /readerFrame\.removeAttribute\("src"\)/ => "resource reader close must unload the embedded resource",
  /document\.body\.classList\.remove\("pdf-reader-active", "pdf-reader-modal-active"\)/ => "resource reader close must clear reader state classes",
  />Hide<\/button>/ => "resource reader needs an English Hide control",
  /url\.protocol !== "https:" \|\| url\.port \|\| url\.username \|\| url\.password/ => "YouTube reader URLs must require credential-free HTTPS on the default port",
  /if \(!validPath\) return null;/ => "YouTube reader URLs must use a recognized official path shape",
  /function getYouTubeEmbedUrl\(url\)/ => "resource reader must recognize YouTube sources",
  %r{https://www\.youtube\.com/embed/} => "resource reader must use the official YouTube iframe endpoint",
  /allow="encrypted-media; picture-in-picture; web-share"/ => "resource reader iframe permissions must stay narrowly scoped",
  /allowfullscreen/ => "resource reader video frame must allow fullscreen",
  /sibling\.setAttribute\("aria-hidden", "true"\)/ => "mobile resource reader needs an aria-hidden fallback when inert is unavailable",
  /entry\.element\.setAttribute\("aria-hidden", entry\.previousAriaHidden\)/ => "resource reader must restore fallback aria-hidden state"
}.freeze
DYNAMIC_LINK_TARGET_ALLOWLIST = {
  "_layouts/default.html" => Set.new([
    "{{ item.url | relative_url | escape }}",
    "{{ child.url | escape }}",
    "{{ child.url | relative_url | escape }}"
  ]),
  "_includes/branch-search.html" => Set.new(["{{ item.url | relative_url | escape }}"]),
  "_includes/section-pager.html" => Set.new([
    "{{ pager_prev.url | relative_url | escape }}",
    "{{ pager_parent_url | relative_url | escape }}",
    "{{ pager_next.url | relative_url | escape }}"
  ]),
  "_includes/study-catalog.html" => Set.new(["{{ study.url | relative_url | escape }}"]),
  "pages/assignment/aix.md" => Set.new(["{{ assignment.url | relative_url | escape }}"]),
  "pages/assignment/cpp.md" => Set.new(["{{ assignment.url | relative_url | escape }}"]),
  "pages/assignment/machine-learning-basic.md" => Set.new(["{{ assignment.url | relative_url | escape }}"]),
  "pages/main/assignment.md" => Set.new(["{{ child.url | relative_url | escape }}"]),
  "pages/main/index.md" => Set.new([
    "{{ child.url | escape }}",
    "{{ child.url | relative_url | escape }}",
    "{{ course_latest.url | relative_url | escape }}",
    "{{ course_url | relative_url | escape }}",
    "{{ entry.url | relative_url | escape }}",
    "{{ item.url | relative_url | escape }}",
    "{{ note.url | relative_url | escape }}",
    "{{ post.url | relative_url | escape }}"
  ]),
  "pages/main/log.md" => Set.new(["{{ entry.url | relative_url | escape }}"]),
  "pages/main/post.md" => Set.new(["{{ child.url | relative_url | escape }}"]),
  "pages/main/project.md" => Set.new([
    "{{ child.url | escape }}",
    "{{ child.source_url | escape }}"
  ]),
  "pages/main/research.md" => Set.new(["{{ note.url | relative_url | escape }}"]),
  "pages/main/study.md" => Set.new(["{{ child.url | relative_url | escape }}"]),
  "pages/post/industry-lectures.md" => Set.new(["{{ post.url | relative_url | escape }}"]),
  "post/ai-agents/index.md" => Set.new(["{{ post.url | relative_url | escape }}"]),
  "post/ai-education/index.md" => Set.new(["{{ post.url | relative_url | escape }}"]),
  "post/knowledge-productivity/index.md" => Set.new(["{{ post.url | relative_url | escape }}"]),
  "post/nxtcloud-boot-camp/index.md" => Set.new(["{{ post.url | relative_url | escape }}"])
}.freeze
BINARY_EXTENSIONS = %w[
  .7z .avi .bin .bmp .dmg .doc .docx .eot .gif .gz .ico .jpeg .jpg .mov .mp3 .mp4 .otf .pdf .png .ppt .pptx
  .rar .tar .tif .tiff .ttf .wasm .webm .webp .woff .woff2 .xls .xlsx .zip
].freeze
MAX_SECRET_SCAN_BYTES = 5 * 1024 * 1024
HTML_TAG_NAMES = Set.new(%w[
  a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col
  colgroup data datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1
  h2 h3 h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label legend li link main map mark menu
  meta meter nav noscript object ol optgroup option output p picture pre progress q rp rt ruby s samp script search
  section select slot small source span strong style sub summary sup table tbody td template textarea tfoot th thead
  time title tr track u ul var video wbr
]).freeze
MATHJAX_TEXT_COMMANDS = %w[mbox operatorname text textbf textit textrm].freeze
MATHJAX_ROW_BREAK_ENVIRONMENTS = Set.new(%w[
  align align* aligned alignedat array bmatrix cases gather gather* gathered matrix multline multline* pmatrix
  smallmatrix split Vmatrix vmatrix
]).freeze
BARE_LATEX_GROUP_COMMAND = /(?<![\\A-Za-z])(?:begin|mathbf|mathbb|mathcal|mathrm|end|frac|operatorname|sqrt|text)\s*(?=[{\[])/.freeze
BARE_LATEX_SPACING_COMMAND = /(?<![\\A-Za-z])(?:qquad|quad)\b/.freeze

errors = []
documents = []

def relative_path(path)
  path.relative_path_from(ROOT).to_s
end

def parse_document(path, errors)
  text = path.read(encoding: "UTF-8")
  unless text.start_with?("---\n")
    errors << "#{relative_path(path)}: missing opening front matter delimiter"
    return nil
  end

  closing = text.index("\n---\n", 4)
  unless closing
    errors << "#{relative_path(path)}: missing closing front matter delimiter"
    return nil
  end

  raw = text[4...closing]
  data = YAML.safe_load(
    raw,
    permitted_classes: [Date, Time],
    permitted_symbols: [],
    aliases: true
  ) || {}
  unless data.is_a?(Hash)
    errors << "#{relative_path(path)}: front matter must be a mapping"
    return nil
  end

  [data, raw, text[(closing + 5)..-1].to_s]
rescue Psych::SyntaxError => e
  errors << "#{relative_path(path)}: invalid YAML (#{e.message.lines.first.strip})"
  nil
rescue StandardError => e
  errors << "#{relative_path(path)}: cannot read (#{e.class}: #{e.message})"
  nil
end

def parse_timestamp(raw, field, relative, errors, required:)
  lines = raw.lines.select { |line| line.start_with?("#{field}:") }
  if lines.empty?
    errors << "#{relative}: missing #{field}" if required
    return nil
  end

  if lines.length > 1
    errors << "#{relative}: duplicate #{field} fields"
    return nil
  end

  value = lines.first.sub(/\A#{Regexp.escape(field)}:\s*/, "").strip
  unless value.match?(TIMESTAMP_VALUE)
    errors << "#{relative}: #{field} must use YYYY-MM-DD HH:MM:SS +0900"
    return nil
  end

  Time.strptime(value, TIMESTAMP_FORMAT)
rescue ArgumentError
  errors << "#{relative}: #{field} is not a valid calendar timestamp"
  nil
end

def blank_value?(value)
  value.nil? || value == "" || (value.respond_to?(:empty?) && value.empty?)
end

def validate_list_field(data, field, relative, errors)
  return unless data.key?(field)

  value = data[field]
  unless value.is_a?(Array) && !value.empty? && value.all? { |item| item.is_a?(String) && !item.strip.empty? }
    errors << "#{relative}: #{field} must be a non-empty list of non-empty strings"
  end
end

def validate_english_metadata(data, relative, errors)
  ENGLISH_METADATA_FIELDS.each do |field|
    next unless data.key?(field)

    value = data[field].is_a?(Array) ? data[field].join(" ") : data[field].to_s
    errors << "#{relative}: #{field} contains Hangul public metadata" if value.match?(HANGUL)
  end
end

def validate_string_fields(data, relative, errors)
  STRING_FIELDS.each do |field|
    next unless data.key?(field)

    value = data[field]
    unless value.is_a?(String) && !value.strip.empty?
      errors << "#{relative}: #{field} must be a non-empty string"
    end
  end
end

def validate_collection_path(path, collection, relative, errors)
  local = path.relative_path_from(ROOT.join(collection))
  components = local.each_filename.to_a
  filename = components.pop.to_s.sub(/\.md\z/, "")
  expected = collection == "_posts" ? POST_FILENAME : KEBAB_COMPONENT
  errors << "#{relative}: filename must be lowercase kebab-case" unless filename.match?(expected)
  components.each do |component|
    errors << "#{relative}: directory #{component.inspect} must be lowercase kebab-case" unless component.match?(KEBAB_COMPONENT)
  end
end

def fence_marker(source)
  match = source.match(/\A {0,3}(`{3,}|~{3,})(.*)\z/)
  return nil unless match

  trailing = match[2].strip
  return nil unless trailing.empty? || trailing.match?(/\A\S+\z/)

  [match[1][0], match[1].length]
end

def indentation_width(text)
  text.each_char.reduce(0) do |width, character|
    character == "\t" ? width + (4 - (width % 4)) : width + 1
  end
end

def strip_indentation(source, required_width)
  index = 0
  width = 0
  while width < required_width && index < source.length
    character = source[index]
    break unless character == " " || character == "\t"

    width += character == "\t" ? 4 - (width % 4) : 1
    index += 1
  end
  return "" if source.strip.empty?
  return nil if width < required_width

  source[index..]
end

def definition_list_term_before?(lines, index, contexts)
  blank_seen = false
  (index - 1).downto(0) do |candidate|
    previous = fence_container_content(lines[candidate], contexts)
    return false if previous.nil?
    if previous.strip.empty?
      return false if blank_seen

      blank_seen = true
      next
    end

    stripped = previous.lstrip
    return false if previous.match?(/\A(?: {4,}|\t)/)
    return false if stripped.match?(/\A(?:\#{1,6}[ \t]|>|(?:[-+*]|\d+\.)[ \t]+|:[ \t]+|\[\^[^\]]+\]:|\[.*\]:|<|\{::)/)

    return true
  end
  false
end

def active_list_indentation(lines, index, contexts, source)
  leading = source[/\A[ \t]*/]
  leading_width = indentation_width(leading)
  return nil if leading_width.zero?

  (index - 1).downto(0) do |candidate|
    previous = fence_container_content(lines[candidate], contexts)
    break if previous.nil?
    next if previous.strip.empty?

    container = previous.match(/\A(?<prefix> {0,3}(?:[-+*]|\d+\.)[ \t]+)/)
    container ||= previous.match(/\A(?<prefix> {0,3}:[ \t]+)/) if definition_list_term_before?(lines, candidate, contexts)
    if container
      container_width = indentation_width(container[:prefix])
      return container_width if leading_width >= container_width && leading_width - container_width <= 3
    end

    if previous.match?(/\A {0,3}\[\^[^\]\n]+\]:/)
      return 4 if leading_width >= 4 && leading_width - 4 <= 3
    end

    previous_leading = previous[/\A[ \t]*/]
    break if indentation_width(previous_leading).zero?
  end
  nil
end

def fenced_code_opening(lines, index)
  source = lines[index].sub(/\r?\n\z/, "")
  return nil unless source.match?(/(?:`{3,}|~{3,})/)

  contexts = []

  loop do
    if (list_indentation = active_list_indentation(lines, index, contexts, source))
      contexts << { type: :list, indentation: list_indentation }
      source = strip_indentation(source, list_indentation)
      next
    end

    if (quote = source.match(/\A {0,3}>[ \t]?/))
      contexts << { type: :blockquote }
      source = quote.post_match
      next
    end

    list = source.match(/\A(?<prefix> {0,3}(?:[-+*]|\d+\.)[ \t]+)(?<content>.*)\z/)
    if list
      contexts << { type: :list, indentation: indentation_width(list[:prefix]) }
      source = list[:content]
      next
    end

    definition = source.match(/\A(?<prefix> {0,3}:[ \t]+)(?<content>.*)\z/)
    if definition && definition_list_term_before?(lines, index, contexts)
      contexts << { type: :list, indentation: indentation_width(definition[:prefix]) }
      source = definition[:content]
      next
    end

    footnote = source.match(/\A {0,3}\[\^[^\]\n]+\]:[ \t]*(?<content>.*)\z/)
    if footnote
      contexts << { type: :list, indentation: 4 }
      source = footnote[:content]
      next
    end

    break
  end

  marker = fence_marker(source)
  return nil unless marker

  { contexts: contexts, character: marker[0], length: marker[1] }
end

def fence_container_content(line, contexts)
  source = line.sub(/\r?\n\z/, "")
  contexts.each do |context|
    case context[:type]
    when :blockquote
      quote = source.match(/\A {0,3}>[ \t]?/)
      return nil unless quote

      source = quote.post_match
    when :list
      source = strip_indentation(source, context[:indentation])
      return nil if source.nil?
    end
  end
  source
end

def fenced_code_closing?(source, character, length)
  source.match?(Regexp.new("\\A {0,3}#{Regexp.escape(character)}{#{length},}[ \\t]*\\z"))
end

def neutralize_block_fence_marker(line)
  match = line.match(
    /\A[ \t>]*(?:(?:(?:[-+*]|\d+\.|:)|\[\^[^\]\n]+\]:)[ \t]+)?[ \t]*(?<marker>`{3,}|~{3,})/
  )
  return line unless match

  characters = line.chars
  (match.begin(:marker)...match.end(:marker)).each { |index| characters[index] = " " }
  characters.join
end

def strip_fenced_code(text, relative, errors)
  lines = text.lines
  result = lines.dup
  index = 0

  while index < lines.length
    opening = fenced_code_opening(lines, index)
    unless opening
      result[index] = neutralize_block_fence_marker(lines[index])
      index += 1
      next
    end

    character = opening[:character]
    length = opening[:length]
    contexts = opening[:contexts]
    closing = nil
    ((index + 1)...lines.length).each do |candidate|
      content = fence_container_content(lines[candidate], contexts)
      break if content.nil?

      if fenced_code_closing?(content, character, length)
        closing = candidate
        break
      end
    end
    unless closing
      errors << "#{relative}: unbalanced fenced code block"
      result[index] = neutralize_block_fence_marker(lines[index])
      index += 1
      next
    end

    (index..closing).each { |masked| result[masked] = "\n" }
    index = closing + 1
  end

  result.join
end

def mask_html_comments(text, relative = nil, errors = nil)
  characters = text.chars
  index = 0
  while (opening = text.index("<!--", index))
    if escaped_at?(text, opening)
      index = opening + 4
      next
    end
    closing = text.index("-->", opening + 4)
    errors << "#{relative}: unclosed HTML comment" if !closing && errors && relative
    finish = closing ? closing + 3 : text.length
    (opening...finish).each { |position| characters[position] = " " unless characters[position] == "\n" }
    index = finish
  end
  characters.join
end

def blockquote_remainder(line)
  source = line.sub(/\r?\n\z/, "")
  depth = 0
  while (quote = source.match(/\A {0,3}>[ \t]?/))
    depth += 1
    source = quote.post_match
  end
  [depth, source]
end

def list_container_width(lines, index, quote_depth)
  (index - 1).downto(0) do |candidate|
    depth, source = blockquote_remainder(lines[candidate])
    break if depth != quote_depth
    next if source.strip.empty?

    marker = source.match(/\A(?<prefix> {0,3}(?:[-+*]|\d+\.)[ \t]+)/)
    return indentation_width(marker[:prefix]) if marker

    break if indentation_width(source[/\A[ \t]*/]).zero?
  end
  nil
end

def mask_indented_code(text)
  lines = text.lines
  result = lines.dup
  active = {}

  lines.each_index do |index|
    quote_depth, source = blockquote_remainder(lines[index])
    blank = source.strip.empty?
    leading_width = indentation_width(source[/\A[ \t]*/])
    active_width = active[quote_depth]
    list_width = leading_width >= 4 && !active_width ? list_container_width(lines, index, quote_depth) : nil
    required_width = list_width ? list_width + 4 : 4
    list_marker = source.match(/\A(?<marker> {0,3}(?:[-+*]|\d+\.))(?<spacing>[ \t]+).*\z/)
    inline_list_code = list_marker && indentation_width(list_marker[:spacing]) >= 5
    previous_depth, previous_source = index.positive? ? blockquote_remainder(lines[index - 1]) : [quote_depth, ""]
    may_start = index.zero? || previous_depth != quote_depth || previous_source.strip.empty?

    if blank
      result[index] = "\n" if active_width
      next
    end

    if inline_list_code
      active[quote_depth] = indentation_width(list_marker[:marker]) + indentation_width(list_marker[:spacing])
      result[index] = "\n"
    elsif active_width && leading_width >= active_width
      result[index] = "\n"
    elsif leading_width >= required_width && may_start
      active[quote_depth] = required_width
      result[index] = "\n"
    else
      active.delete(quote_depth)
    end
  end

  result.join
end

def escaped_at?(text, index)
  backslashes = 0
  cursor = index - 1
  while cursor >= 0 && text[cursor] == "\\"
    backslashes += 1
    cursor -= 1
  end
  backslashes.odd?
end

def backtick_run_length(text, index)
  length = 0
  length += 1 while text[index + length] == "`"
  length
end

def kramdown_code_span_opener?(text, opening, run_length)
  return false if escaped_at?(text, opening)
  return false if opening.positive? && text[opening - 1] == "`"

  line_start = text.rindex("\n", opening - 1)
  prefix = text[(line_start ? line_start + 1 : 0)...opening]
  return false if prefix.match?(/\A(?: {4,}|\t)/)

  return true unless run_length == 1

  before = opening.zero? ? nil : text[opening - 1]
  after = text[opening + 1]
  !((before.nil? || before.match?(/\s/)) && after&.match?(/\s/))
end

def matching_backtick_run(text, opening, run_length)
  text.index("`" * run_length, opening + run_length)
end

def mask_inline_code_spans(text)
  characters = text.chars
  index = 0
  while index < text.length
    opening = text.index("`", index)
    break unless opening

    run_length = backtick_run_length(text, opening)
    unless kramdown_code_span_opener?(text, opening, run_length)
      index = opening + run_length
      next
    end

    closing = matching_backtick_run(text, opening, run_length)
    unless closing
      index = opening + run_length
      next
    end

    finish = closing + run_length
    (opening...finish).each { |position| characters[position] = " " unless characters[position] == "\n" }
    index = finish
  end
  characters.join
end

def mask_character_range(characters, opening, closing)
  (opening...closing).each do |position|
    characters[position] = " " unless characters[position] == "\n"
  end
end

def html_tag_at(text, opening)
  prefix = text[opening..].to_s.match(/\A<\s*(\/?)\s*([A-Za-z][A-Za-z0-9]*)(?=[\s\/>])/)
  return nil unless prefix && HTML_TAG_NAMES.include?(prefix[2].downcase)

  quote = nil
  cursor = opening + prefix[0].length
  while cursor < text.length
    character = text[cursor]
    if quote
      quote = nil if character == quote
    elsif character == '"' || character == "'"
      quote = character
    elsif character == ">"
      return {
        closing: cursor + 1,
        name: prefix[2].downcase,
        closing_tag: prefix[1] == "/"
      }
    end
    cursor += 1
  end
  nil
end

def mask_html_for_mathjax(text)
  characters = text.chars
  index = 0
  raw_text_elements = Set.new(%w[code pre script style textarea])

  while (opening = text.index("<", index))
    tag = html_tag_at(text, opening)
    unless tag
      index = opening + 1
      next
    end

    finish = tag[:closing]
    if !tag[:closing_tag] && raw_text_elements.include?(tag[:name])
      closing_match = text.match(%r{</\s*#{Regexp.escape(tag[:name])}\s*>}i, finish)
      finish = closing_match.end(0) if closing_match
    end
    mask_character_range(characters, opening, finish)
    index = finish
  end

  characters.join
end

def validate_raw_mathjax_delimiters(text, relative, errors)
  index = 0
  while index < text.length - 1
    token = text[index, 2]
    if ["\\(", "\\)", "\\[", "\\]"].include?(token) && !escaped_at?(text, index)
      errors << "#{relative}: unsupported raw MathJax delimiter #{token}; use $$ delimiters"
      index += 2
    else
      index += 1
    end
  end
end

def unescaped_double_dollar_offsets(line)
  offsets = []
  index = 0
  while (opening = line.index("$$", index))
    offsets << opening unless escaped_at?(line, opening)
    index = opening + 2
  end
  offsets
end

def standalone_double_dollar_line?(line, offsets)
  offsets.length == 1 && line.sub(/\r?\n\z/, "").strip == "$$"
end

def mathjax_segments(text, relative, errors)
  segments = []
  display_opening = nil
  source_offset = 0

  text.lines.each do |line|
    offsets = unescaped_double_dollar_offsets(line)
    standalone = standalone_double_dollar_line?(line, offsets)

    if display_opening
      if standalone
        delimiter_offset = source_offset + offsets.first
        segments << display_opening.merge(content_end: delimiter_offset, source_end: delimiter_offset + 2)
        display_opening = nil
      elsif offsets.any?
        errors << "#{relative}: display MathJax block contains a mixed $$ delimiter line"
      end
    elsif standalone
      delimiter_offset = source_offset + offsets.first
      display_opening = {
        kind: :display,
        token: "$$",
        source_start: delimiter_offset,
        content_start: delimiter_offset + 2
      }
    elsif offsets.length.odd?
      errors << "#{relative}: inline $$ delimiters must open and close on the same line; display delimiters must be standalone"
    else
      offsets.each_slice(2) do |opening, closing|
        segments << {
          kind: :inline,
          token: "$$",
          source_start: source_offset + opening,
          content_start: source_offset + opening + 2,
          content_end: source_offset + closing,
          source_end: source_offset + closing + 2
        }
      end
    end

    source_offset += line.length
  end

  errors << "#{relative}: unclosed display MathJax block" if display_opening
  segments
end

def mask_mathjax_segments(text, segments)
  characters = text.chars
  segments.each { |segment| mask_character_range(characters, segment[:source_start], segment[:source_end]) }
  characters.join
end

def mask_latex_text_arguments(text)
  characters = text.chars
  pattern = /\\(?:#{MATHJAX_TEXT_COMMANDS.join("|")})\s*\{/
  offset = 0

  while (match = pattern.match(text, offset))
    opening = text.index("{", match.begin(0))
    depth = 1
    cursor = opening + 1
    while cursor < text.length && depth.positive?
      unless escaped_at?(text, cursor)
        depth += 1 if text[cursor] == "{"
        depth -= 1 if text[cursor] == "}"
      end
      cursor += 1
    end
    break if depth.positive?

    mask_character_range(characters, opening + 1, cursor - 1)
    offset = cursor
  end

  characters.join
end

def unbalanced_latex_braces?(text)
  depth = 0
  text.each_char.with_index do |character, index|
    next if escaped_at?(text, index)

    depth += 1 if character == "{"
    return true if character == "}" && depth.zero?
    depth -= 1 if character == "}" && depth.positive?
  end
  depth.positive?
end

def invalid_mathjax_double_backslash?(text)
  index = 0
  while index < text.length - 1
    unless text[index, 2] == "\\\\"
      index += 1
      next
    end

    run_length = 2
    run_length += 1 while text[index + run_length] == "\\"
    environment_stack = []
    text[0...index].to_s.scan(/\\(begin|end)\s*\{([^{}]+)\}/) do |operation, environment|
      if operation == "begin"
        environment_stack << environment
      elsif environment_stack.last == environment
        environment_stack.pop
      end
    end
    valid_row_break = run_length == 2 &&
                      environment_stack.any? { |environment| MATHJAX_ROW_BREAK_ENVIRONMENTS.include?(environment) }
    return true unless valid_row_break

    index += run_length
  end
  false
end

def validate_mathjax(text, relative, errors)
  searchable = mask_html_for_mathjax(text)
  validate_raw_mathjax_delimiters(searchable, relative, errors)
  segments = mathjax_segments(searchable, relative, errors)

  segments.each do |segment|
    content = searchable[segment[:content_start]...segment[:content_end]].to_s
    errors << "#{relative}: unbalanced MathJax braces" if unbalanced_latex_braces?(content)
    if segment[:kind] == :inline && content.each_char.with_index.any? { |character, index| character == "|" && !escaped_at?(content, index) }
      errors << "#{relative}: inline MathJax contains raw |; use \\mid, \\lvert...\\rvert, or escaped \\|"
    end
    if invalid_mathjax_double_backslash?(content)
      errors << "#{relative}: possible double-escaped MathJax command or invalid row break"
    end

    bare_searchable = mask_latex_text_arguments(content)
    if (match = bare_searchable.match(BARE_LATEX_GROUP_COMMAND))
      errors << "#{relative}: possible bare LaTeX command #{match[0].strip} inside MathJax"
    end
    if (match = bare_searchable.match(BARE_LATEX_SPACING_COMMAND))
      errors << "#{relative}: possible bare LaTeX command #{match[0]} inside MathJax"
    end
  end

  outside_math = mask_mathjax_segments(searchable, segments)
  if outside_math.match?(/\\\\(?:[A-Za-z]+|[()\[\]])/)
    errors << "#{relative}: possible double-escaped MathJax command or delimiter"
  end
  if (match = outside_math.match(/(?<!\\)\\([A-Za-z]+)/))
    errors << "#{relative}: LaTeX command \\#{match[1]} is outside MathJax delimiters"
  end
end

def validate_summary_mathjax(text, relative, errors)
  text.scan(%r{<summary\b(?<attributes>[^>]*)>(?<content>.*?)</summary\s*>}im) do
    match = Regexp.last_match
    next if unescaped_double_dollar_offsets(match[:content]).empty?

    attributes = parse_attributes(match[:attributes], [])
    next if attributes["markdown"] == "span"

    errors << %(#{relative}: <summary> containing $$ must use markdown="span")
  end
end

def validate_details_kramdown(text, relative, errors)
  text.scan(/<details\b(?<attributes>[^>]*)>/im) do
    attributes = parse_attributes(Regexp.last_match[:attributes], [])
    next if attributes["markdown"] == "block"

    errors << %(#{relative}: <details> must use markdown="block")
  end
end

def markdown_table_cells(line)
  stripped = line.strip
  cells = []
  cell = +""
  stripped.each_char.with_index do |character, index|
    if character == "|" && !escaped_at?(stripped, index)
      cells << cell
      cell = +""
    else
      cell << character
    end
  end
  cells << cell

  cells.shift if stripped.start_with?("|")
  if stripped.end_with?("|") && !escaped_at?(stripped, stripped.length - 1)
    cells.pop
  end
  cells
end

def table_separator?(line)
  stripped = line.strip
  return false unless stripped.include?("|")

  cells = markdown_table_cells(stripped)
  !cells.empty? && cells.all? { |cell| cell.strip.match?(/\A:?-{3,}:?\z/) }
end

def table_column_count(line)
  markdown_table_cells(line).length
end

def validate_tables(text, relative, errors)
  lines = text.lines
  index = 0
  while index < lines.length
    unless table_separator?(lines[index])
      index += 1
      next
    end

    if index.zero? || !lines[index - 1].include?("|")
      errors << "#{relative}:#{index + 1}: table separator has no header row"
      index += 1
      next
    end

    expected = table_column_count(lines[index])
    header_columns = table_column_count(lines[index - 1])
    if header_columns != expected
      errors << "#{relative}:#{index}: table header has #{header_columns} columns; expected #{expected}"
    end

    row = index + 1
    while row < lines.length && !lines[row].strip.empty? && lines[row].include?("|")
      actual = table_column_count(lines[row])
      if actual != expected
        errors << "#{relative}:#{row + 1}: table row has #{actual} columns; expected #{expected}"
      end
      row += 1
    end
    index = row
  end
end

def scan_quoted_attribute_value(scanner, quote)
  value = +""
  liquid_closer = nil
  until scanner.eos?
    pair = scanner.peek(2)
    if liquid_closer
      value << scanner.getch
      if pair == liquid_closer
        value << scanner.getch
        liquid_closer = nil
      end
      next
    end
    if pair == "{{"
      liquid_closer = "}}"
      value << scanner.getch << scanner.getch
      next
    elsif pair == "{%"
      liquid_closer = "%}"
      value << scanner.getch << scanner.getch
      next
    end

    character = scanner.getch
    break if character == quote

    value << character
  end
  value
end

def parse_attributes(source, duplicates = [])
  scanner = StringScanner.new(source.to_s)
  attributes = {}

  until scanner.eos?
    scanner.skip(/\s+/)
    name = scanner.scan(/[A-Za-z_:][A-Za-z0-9_.:-]*/)
    unless name
      scanner.getch
      next
    end

    scanner.skip(/\s*/)
    value = ""
    if scanner.scan(/=/)
      scanner.skip(/\s*/)
      quote = scanner.scan(/["']/)
      if quote
        value = scan_quoted_attribute_value(scanner, quote)
      else
        value = scanner.scan(/[^\s>]+/).to_s
      end
    end
    normalized_name = name.downcase
    if attributes.key?(normalized_name)
      duplicates << normalized_name
    else
      attributes[normalized_name] = value
    end
  end

  attributes
end

def html_opening_tags(text)
  tags = []
  index = 0
  while index < text.length
    opening = text.index("<", index)
    break unless opening

    name_match = text[(opening + 1)..-1].to_s.match(/\A([A-Za-z][A-Za-z0-9]*)(?=[\s\/>])/)
    unless name_match && HTML_TAG_NAMES.include?(name_match[1].downcase)
      index = opening + 1
      next
    end

    cursor = opening + 1
    quote = nil
    liquid_closer = nil
    while cursor < text.length
      character = text[cursor]
      if quote
        pair = text[cursor, 2]
        if liquid_closer
          if pair == liquid_closer
            liquid_closer = nil
            cursor += 1
          end
        elsif pair == "{{"
          liquid_closer = "}}"
          cursor += 1
        elsif pair == "{%"
          liquid_closer = "%}"
          cursor += 1
        elsif character == quote
          quote = nil
        end
      elsif character == '"' || character == "'"
        quote = character
      elsif character == ">"
        tags << text[opening..cursor]
        cursor += 1
        break
      end
      cursor += 1
    end
    index = [cursor, opening + 1].max
  end
  tags
end

def liquid_outside_quoted_html_attribute?(tag)
  quote = nil
  liquid_closer = nil
  index = 0
  while index < tag.length
    pair = tag[index, 2]
    character = tag[index]
    if quote
      if liquid_closer
        if pair == liquid_closer
          liquid_closer = nil
          index += 1
        end
      elsif pair == "{{"
        liquid_closer = "}}"
        index += 1
      elsif pair == "{%"
        liquid_closer = "%}"
        index += 1
      elsif character == quote
        quote = nil
      end
    elsif character == '"' || character == "'"
      quote = character
    elsif pair == "{{" || pair == "{%"
      return true
    end
    index += 1
  end
  false
end

def html_tag_name_and_attributes(tag)
  match = tag.match(/\A<\s*([A-Za-z][A-Za-z0-9:-]*)/)
  return [nil, {}, []] unless match

  source = tag[match.end(0)...-1].to_s.sub(%r{/\s*\z}, "")
  duplicates = []
  attributes = parse_attributes(source, duplicates)
  [match[1].downcase, attributes, duplicates]
end

def kramdown_attributes(block)
  return [{}, []] unless block

  source = block.sub(/\A\{\s*:/, "").sub(/\}\z/, "")
  duplicates = []
  [parse_attributes(source, duplicates), duplicates]
end

def kramdown_attribute_blocks(text)
  blocks = []
  index = 0
  while (opening = text.index("{:", index))
    if escaped_at?(text, opening)
      index = opening + 2
      next
    end
    following = text[opening + 2]
    if following == ":" || following == "/"
      index = opening + 2
      next
    end

    cursor = opening + 2
    closing = nil
    while cursor < text.length
      if text[cursor] == "\\" && text[cursor + 1] == "}"
        cursor += 2
        next
      end
      if text[cursor] == "}"
        closing = cursor
        break
      end
      cursor += 1
    end
    break unless closing

    line_start = text.rindex("\n", opening - 1)
    line_start = line_start ? line_start + 1 : 0
    prefix = text[line_start...opening]
    inline_attached = opening.positive? && ")]".include?(text[opening - 1])
    block_attached = prefix.strip.empty? && line_start.positive? &&
                     !text[(text.rindex("\n", line_start - 2) || -1) + 1...line_start - 1].to_s.strip.empty?
    blocks << text[opening..closing] if inline_attached || block_attached
    index = closing + 1
  end
  blocks
end

def validate_kramdown_attribute_overrides(text, relative, errors)
  kramdown_attribute_blocks(text).each do |block|
    attributes, duplicates = kramdown_attributes(block)
    duplicates.each do |name|
      errors << "#{relative}: duplicate Kramdown attribute #{name}"
    end
    %w[href src].each do |name|
      if attributes.key?(name)
        errors << "#{relative}: Kramdown attributes cannot override #{name}"
      end
    end
  end
end

def safe_new_window_attributes?(attributes)
  attributes["target"].to_s.casecmp("_blank").zero? &&
    attributes["rel"].to_s.split(/\s+/).any? { |value| value.casecmp("noopener").zero? }
end

def decorative_attributes?(attributes)
  attributes["role"].to_s.casecmp("presentation").zero? ||
    attributes["aria-hidden"].to_s.casecmp("true").zero?
end

def decode_html_numeric_references(target)
  target.to_s.gsub(HTML_NUMERIC_REFERENCE) do
    match = Regexp.last_match
    codepoint = (match[2] || match[3]).to_i(match[1] ? 16 : 10)
    [codepoint].pack("U")
  rescue RangeError
    "�"
  end
end

def decode_uri_entities(target)
  decoded = CGI.unescapeHTML(decode_html_numeric_references(target))
  URI_HTML5_NAMED_REFERENCES.each { |entity, value| decoded = decoded.gsub(entity, value) }
  decoded
end

def canonical_uri_target(target)
  decoded = decode_uri_entities(target)
  decoded.strip.gsub(/[\u0000-\u0020]/, "")
end

def unsupported_named_uri_reference?(target)
  decoded = CGI.unescapeHTML(decode_html_numeric_references(target))
  URI_HTML5_NAMED_REFERENCES.each_key { |entity| decoded = decoded.gsub(entity, "") }
  decoded.match?(HTML_NAMED_REFERENCE)
end

def normalized_uri_scheme(target)
  match = canonical_uri_target(target).match(/\A([A-Za-z][A-Za-z0-9+.-]*):/)
  match && match[1].downcase
end

def validate_uri_scheme(target, relative, errors)
  if unsupported_named_uri_reference?(target)
    errors << "#{relative}: unsupported named HTML character reference in URI target"
  end

  scheme = normalized_uri_scheme(target)
  return unless scheme
  return if ALLOWED_URI_SCHEMES.include?(scheme)

  errors << "#{relative}: disallowed URI scheme #{scheme}"
end

def external_web_target?(target)
  canonical = canonical_uri_target(target)
  %w[http https].include?(normalized_uri_scheme(canonical)) || canonical.start_with?("//")
end

def normalize_reference_label(label)
  label.to_s.strip.gsub(/\s+/, " ").downcase
end

def reference_container_content(lines, index)
  content = lines[index].sub(/\r?\n\z/, "")
  contexts = []
  loop do
    if (list_indentation = active_list_indentation(lines, index, contexts, content))
      contexts << { type: :list, indentation: list_indentation }
      content = strip_indentation(content, list_indentation)
      next
    elsif (quote = content.match(/\A {0,3}>[ \t]?/))
      contexts << { type: :blockquote }
      content = quote.post_match
      next
    elsif (list = content.match(/\A(?<prefix> {0,3}(?:[-+*]|\d+\.)[ \t]+)(?<content>.*)\z/))
      contexts << { type: :list, indentation: indentation_width(list[:prefix]) }
      content = list[:content]
      next
    elsif (definition = content.match(/\A(?<prefix> {0,3}:[ \t]+)(?<content>.*)\z/)) &&
          definition_list_term_before?(lines, index, contexts)
      contexts << { type: :list, indentation: indentation_width(definition[:prefix]) }
      content = definition[:content]
      next
    elsif (footnote = content.match(/\A {0,3}\[\^[^\]\n]+\]:[ \t]*(?<content>.*)\z/))
      contexts << { type: :list, indentation: 4 }
      content = footnote[:content]
      next
    end
    break
  end
  content
end

def reference_definitions(text, relative = nil, errors = nil)
  definitions = {}
  definition_lines = Set.new
  lines = text.lines
  index = 0
  while index < lines.length
    unless lines[index].include?("]:")
      index += 1
      next
    end

    content = reference_container_content(lines, index)
    liquid = content.match(/\A {0,3}\[([^\]\n]+)\]:[ \t]*(\{\{.*\}\})[ \t]*\z/)
    match = content.match(
      /\A {0,3}\[([^\]\n]+)\]:[ \t]*(?:<(.*?)>|([^\n]*?\S[^\n]*?))(?:(?:[ \t]+?)[ \t]*?(["'])(.+?)\4)?[ \t]*\z/
    )
    match = nil if match && match[3].to_s.match?(/[ \t]+["']/)
    match ||= liquid
    unless match
      index += 1
      next
    end

    destination = liquid ? liquid[2] : (match[2] || match[3])
    label = normalize_reference_label(match[1])
    if definitions.key?(label)
      errors << "#{relative}: duplicate Markdown reference definition #{label.inspect}" if errors && relative
    end
    definitions[label] = destination
    definition_lines << index
    index += 1
  end
  [definitions, definition_lines]
end

def matching_bracket(text, opening, open_character, close_character)
  depth = 1
  index = opening + 1
  while index < text.length
    if text[index] == "\\"
      index += 2
      next
    end
    depth += 1 if text[index] == open_character
    if text[index] == close_character
      depth -= 1
      return index if depth.zero?
    end
    index += 1
  end
  nil
end

def inline_link_destination(text, opening)
  index = opening + 1
  index += 1 while text[index]&.match?(/[ \t]/)
  return nil if index >= text.length

  if ["{{", "{%"].include?(text[index, 2])
    closer = text[index, 2] == "{{" ? "}}" : "%}"
    closing_liquid = text.index(closer, index + 2)
    return nil unless closing_liquid

    destination = text[index...(closing_liquid + 2)]
    cursor = closing_liquid + 2
  elsif text[index] == "<"
    closing_angle = text.index(">", index + 1)
    return nil unless closing_angle

    destination = text[(index + 1)...closing_angle]
    cursor = closing_angle + 1
  else
    start = index
    depth = 0
    while index < text.length
      if text[index] == "\\"
        index += 2
        next
      end
      character = text[index]
      if character == "("
        depth += 1
      elsif character == ")"
        break if depth.zero?
        depth -= 1
      elsif character.match?(/\s/) && depth.zero?
        following = index
        following += 1 while text[following]&.match?(/\s/)
        break if ["\"", "'"].include?(text[following])
      end
      index += 1
    end
    destination = text[start...index].to_s.strip
    cursor = index
  end

  quote = nil
  depth = 0
  while cursor < text.length
    character = text[cursor]
    if character == "\\"
      cursor += 2
      next
    end
    if quote
      quote = nil if character == quote
    elsif character == '"' || character == "'"
      quote = character
    elsif character == "("
      depth += 1
    elsif character == ")"
      if depth.zero?
        return [destination, cursor]
      end
      depth -= 1
    end
    cursor += 1
  end
  nil
end

def classify_liquid_link_target(raw_target)
  target = raw_target.to_s.strip
  return [:static, target, nil] unless target.include?("{{") || target.include?("{%")

  literal = target.match(
    /\A\{\{\s*(?:"([^"]*)"|'([^']*)')\s*(?:\|\s*(relative_url|absolute_url))?\s*(?:\|\s*(?:escape|escape_once))?\s*\}\}\z/
  )
  return [:static, literal[1] || literal[2], literal[3]] if literal

  variable = target.match(
    /\A\{\{\s*[A-Za-z_][A-Za-z0-9_.]*(?:\s*\|\s*(relative_url|absolute_url))?\s*(?:\|\s*(?:escape|escape_once))?\s*\}\}\z/
  )
  return [:dynamic, nil, variable[1]] if variable

  [:invalid, nil, nil]
end

def safe_body_content_sink?(text, relative, opening, closing)
  return false unless SAFE_BODY_CONTENT_SINKS.include?(relative)

  line_start = text.rindex("\n", opening - 1)
  line_start = line_start ? line_start + 1 : 0
  line_end = text.index("\n", closing) || text.length
  return false unless text[line_start...line_end].strip == "{{ content }}"

  before = text[0...opening]
  %w[script style textarea title].none? do |name|
    before.scan(/<#{name}\b/i).length > before.scan(%r{</#{name}>}i).length
  end
end

def validate_liquid_output_escaping(text, relative, errors)
  text.to_enum(:scan, /\{\{(.*?)\}\}/m).each do
    match = Regexp.last_match
    expression = match[1].strip
    if expression == "content" && safe_body_content_sink?(text, relative, match.begin(0), match.end(0))
      next
    end
    next if expression.match?(/\|\s*(?:escape|escape_once)\s*\z/)
    next if expression.match?(/\A(?:"[^"]*"|'[^']*')\s*\|\s*(?:relative_url|absolute_url)\s*\z/)

    errors << "#{relative}: dynamic Liquid output must end with an HTML escape filter"
  end
end

def validate_resolved_link_target(raw_target, relative, errors, allow_dynamic:)
  kind, target, filter = classify_liquid_link_target(raw_target)
  dynamic_allowed = allow_dynamic && DYNAMIC_LINK_TARGET_ALLOWLIST.fetch(relative, Set.new).include?(raw_target.to_s.strip)
  if kind == :invalid || (kind == :dynamic && !dynamic_allowed)
    errors << "#{relative}: link target uses an unverified Liquid expression"
    return [kind, nil, filter]
  end
  return [kind, nil, filter] if kind == :dynamic

  validate_uri_scheme(target, relative, errors)
  if filter && !canonical_uri_target(target).start_with?("/")
    errors << "#{relative}: Liquid URL filter requires a site-root literal"
  end
  [kind, target, filter]
end

def srcset_targets(raw_srcset)
  raw_srcset.to_s.split(",").map do |candidate|
    value = candidate.strip
    next if value.empty?

    value.split(/\s+/, 2).first
  end.compact
end

def trailing_attribute_block(text, index)
  cursor = index
  cursor += 1 while text[cursor]&.match?(/[ \t]/)
  return [nil, index] unless text[cursor, 2] == "{:"

  opening = cursor
  cursor += 2
  closing = nil
  while cursor < text.length
    if text[cursor] == "\\" && text[cursor + 1] == "}"
      cursor += 2
      next
    end
    if text[cursor] == "}"
      closing = cursor
      break
    end
    cursor += 1
  end
  return [nil, index] unless closing

  [text[opening..closing], closing + 1]
end

def markdown_elements(text, relative = nil, errors = nil, offset: 0)
  definitions, definition_lines = reference_definitions(text, relative, errors)
  searchable = text.each_line.with_index.map do |line, index|
    if definition_lines.include?(index)
      line.gsub(/[^\r\n]/, " ")
    else
      line
    end
  end.join
  elements = []
  index = 0

  while index < searchable.length
    image = searchable[index, 2] == "![" && !escaped_at?(searchable, index)
    opening = image ? index + 1 : index
    unless searchable[opening] == "[" && !escaped_at?(searchable, opening)
      index += 1
      next
    end

    label_end = matching_bracket(searchable, opening, "[", "]")
    unless label_end
      index = opening + 1
      next
    end
    label = searchable[(opening + 1)...label_end]
    cursor = label_end + 1
    destination = nil
    element_end = cursor

    if searchable[cursor] == "("
      parsed = inline_link_destination(searchable, cursor)
      if parsed
        destination, closing = parsed
        element_end = closing + 1
      end
    elsif searchable[cursor] == "["
      reference_end = matching_bracket(searchable, cursor, "[", "]")
      if reference_end
        reference_label = searchable[(cursor + 1)...reference_end]
        reference_label = label if reference_label.empty?
        destination = definitions[normalize_reference_label(reference_label)]
        element_end = reference_end + 1
      end
    else
      destination = definitions[normalize_reference_label(label)]
      element_end = cursor if destination
    end

    unless destination
      index = label_end + 1
      next
    end

    attribute_block, final_index = trailing_attribute_block(searchable, element_end)
    attributes, duplicate_attributes = kramdown_attributes(attribute_block)
    elements.concat(markdown_elements(label, nil, nil, offset: offset + opening + 1)) unless image
    elements << {
      destination: destination,
      label: label,
      image: image,
      attributes: attributes,
      duplicate_attributes: duplicate_attributes,
      source_start: offset + (image ? index : opening),
      source_end: offset + final_index
    }
    index = [final_index, element_end, label_end + 1].max
  end

  elements
end

def validate_links_and_images(text, relative, errors)
  if text.match?(/<\s*(?:\{\{|\{%)/)
    errors << "#{relative}: HTML tag name cannot be generated by Liquid"
  end

  elements = markdown_elements(text, relative, errors)
  elements.each do |element|
    destination = element[:destination]
    attributes = element[:attributes]
    _kind, resolved_destination, _filter = validate_resolved_link_target(
      destination,
      relative,
      errors,
      allow_dynamic: false
    )
    element[:duplicate_attributes].each do |name|
      errors << "#{relative}: duplicate Markdown attribute #{name}"
    end
    %w[href src].each do |name|
      errors << "#{relative}: Kramdown attributes cannot override #{name}" if attributes.key?(name)
    end

    if element[:image]
      if element[:label].strip.empty? && !decorative_attributes?(attributes)
        errors << "#{relative}: empty alt text requires role=presentation or aria-hidden=true"
      end
    elsif resolved_destination && external_web_target?(resolved_destination) && !safe_new_window_attributes?(attributes)
      errors << "#{relative}: external Markdown link must use target=_blank and rel=noopener"
    end
  end

  text.to_enum(:scan, /<([^<>\n]+)>/).each do
    match = Regexp.last_match
    next if escaped_at?(text, match.begin(0))

    candidate = match[1]
    canonical = canonical_uri_target(candidate)
    next unless canonical.match?(/\A[A-Za-z][A-Za-z0-9+.-]*:/)
    next if canonical.match?(/\s/)

    validate_uri_scheme(canonical, relative, errors)
    if external_web_target?(canonical)
      errors << "#{relative}: external Markdown autolink cannot declare required safety attributes"
    end
  end

  html_opening_tags(text).each do |tag|
    if liquid_outside_quoted_html_attribute?(tag)
      errors << "#{relative}: Liquid cannot generate HTML attribute names or fragments"
    end

    name, attributes, duplicate_attributes = html_tag_name_and_attributes(tag)
    next unless name

    duplicate_attributes.each do |attribute_name|
      errors << "#{relative}: duplicate HTML attribute #{attribute_name}"
    end

    resolved_attributes = {}
    %w[href src].each do |field|
      next unless attributes.key?(field)

      kind, resolved, filter = validate_resolved_link_target(
        attributes[field],
        relative,
        errors,
        allow_dynamic: true
      )
      resolved_attributes[field] = [kind, resolved, filter]
    end
    if attributes.key?("srcset")
      srcset_targets(attributes["srcset"]).each do |target|
        validate_resolved_link_target(target, relative, errors, allow_dynamic: false)
      end
    end

    if name == "a"
      href = attributes["href"]
      href_kind, resolved_href, href_filter = resolved_attributes.fetch("href", [:static, href, nil])
      external_or_unfiltered_dynamic = resolved_href && external_web_target?(resolved_href)
      external_or_unfiltered_dynamic ||= href_kind == :dynamic && href_filter.nil?
      if href && external_or_unfiltered_dynamic && !safe_new_window_attributes?(attributes)
        errors << "#{relative}: external HTML link must use target=_blank and rel=noopener"
      end
    elsif name == "img"
      unless attributes.key?("alt")
        errors << "#{relative}: HTML image is missing alt"
        next
      end
      if attributes["alt"].strip.empty? && !decorative_attributes?(attributes)
        errors << "#{relative}: empty alt text requires role=presentation or aria-hidden=true"
      end
    end
  end
end

def validate_body(body, relative, errors)
  without_fences = strip_fenced_code(body, relative, errors)
  without_indented_code = mask_indented_code(without_fences)
  liquid_searchable = mask_inline_code_spans(without_indented_code)
  without_comments = mask_html_comments(without_indented_code, relative, errors)
  without_inline_code = mask_inline_code_spans(without_comments)

  validate_mathjax(without_inline_code, relative, errors)
  validate_details_kramdown(without_inline_code, relative, errors)
  validate_summary_mathjax(without_inline_code, relative, errors)

  validate_tables(without_comments, relative, errors)
  validate_liquid_output_escaping(liquid_searchable, relative, errors)
  validate_kramdown_attribute_overrides(without_inline_code, relative, errors)
  validate_links_and_images(without_inline_code, relative, errors)

  h1_titles = []
  without_comments.each_line do |line|
    match = line.match(/^#\s+(.+?)\s*$/)
    h1_titles << match[1] if match
  end
  h1_titles.group_by { |title| title }.each do |title, occurrences|
    errors << "#{relative}: duplicate body H1 #{title.inspect}" if occurrences.length > 1
  end

  details_open = without_comments.scan(/<details\b/i).length
  details_close = without_comments.scan(%r{</details>}i).length
  summary_open = without_comments.scan(/<summary\b/i).length
  summary_close = without_comments.scan(%r{</summary>}i).length
  errors << "#{relative}: unbalanced details elements" unless details_open == details_close
  errors << "#{relative}: unbalanced summary elements" unless summary_open == summary_close
end

def validate_collection_document(path, collection, schema, errors)
  parsed = parse_document(path, errors)
  return nil unless parsed

  data, raw, body = parsed
  relative = relative_path(path)
  missing = schema[:required].reject { |field| data.key?(field) && !blank_value?(data[field]) }
  errors << "#{relative}: missing front matter fields: #{missing.join(', ')}" unless missing.empty?
  if data["layout"] != schema[:layout]
    errors << "#{relative}: layout must be #{schema[:layout].inspect}"
  end

  validate_string_fields(data, relative, errors)
  LIST_FIELDS.each { |field| validate_list_field(data, field, relative, errors) }
  validate_english_metadata(data, relative, errors)
  validate_collection_path(path, collection, relative, errors)
  validate_body(body, relative, errors)

  published_at = parse_timestamp(raw, "date", relative, errors, required: true)
  modified_at = parse_timestamp(raw, "last_modified_at", relative, errors, required: false)
  errors << "#{relative}: date is in the future (#{published_at.strftime(TIMESTAMP_FORMAT)})" if published_at && published_at > NOW
  errors << "#{relative}: last_modified_at is in the future" if modified_at && modified_at > NOW
  if published_at && modified_at && modified_at < published_at
    errors << "#{relative}: last_modified_at precedes date"
  end

  if collection == "_posts"
    permalink = data["permalink"].to_s
    errors << "#{relative}: invalid posts permalink #{permalink.inspect}" unless permalink.match?(POST_PERMALINK)
    if published_at && path.basename.to_s[0, 10] != published_at.strftime("%Y-%m-%d")
      errors << "#{relative}: filename date does not match front matter date"
    end
    unless data["section"].is_a?(String) && data["section"].match?(KEBAB_COMPONENT)
      errors << "#{relative}: section must be a lowercase kebab-case string"
    end
  end

  if ORDERED_COLLECTIONS.include?(collection) && data.key?("order")
    unless data["order"].is_a?(Integer) && data["order"].positive?
      errors << "#{relative}: order must be a positive integer"
    end
  end

  { collection: collection, path: path, relative: relative, data: data, raw: raw, body: body, page: false }
end

def validate_page_document(path, errors)
  parsed = parse_document(path, errors)
  return nil unless parsed

  data, raw, body = parsed
  relative = relative_path(path)
  missing = PAGE_REQUIRED_FIELDS.reject { |field| data.key?(field) && !blank_value?(data[field]) }
  errors << "#{relative}: missing front matter fields: #{missing.join(', ')}" unless missing.empty?
  errors << "#{relative}: layout must be \"default\"" unless data["layout"] == "default"
  validate_string_fields(data, relative, errors)
  LIST_FIELDS.each { |field| validate_list_field(data, field, relative, errors) }
  validate_english_metadata(data, relative, errors)
  validate_body(body, relative, errors)
  errors << "#{relative}: public index/page UI contains Hangul" if body.match?(HANGUL)

  published_at = parse_timestamp(raw, "date", relative, errors, required: false)
  modified_at = parse_timestamp(raw, "last_modified_at", relative, errors, required: false)
  errors << "#{relative}: date is in the future (#{published_at.strftime(TIMESTAMP_FORMAT)})" if published_at && published_at > NOW
  errors << "#{relative}: last_modified_at is in the future" if modified_at && modified_at > NOW
  if published_at && modified_at && modified_at < published_at
    errors << "#{relative}: last_modified_at precedes date"
  end

  permalink = data["permalink"].to_s
  errors << "#{relative}: invalid page permalink #{permalink.inspect}" unless permalink.match?(OUTPUT_ROUTE)

  { collection: nil, path: path, relative: relative, data: data, raw: raw, body: body, page: true }
end

def output_route(document)
  explicit = document[:data]["permalink"].to_s
  return explicit unless explicit.empty?

  collection = document[:collection].delete_prefix("_")
  local = document[:path].relative_path_from(ROOT.join(document[:collection])).sub_ext("").to_s
  "/#{collection}/#{local}/"
end

def markdown_targets(text)
  searchable = strip_fenced_code(text, "link scan", [])
  searchable = mask_html_comments(searchable)
  searchable = mask_indented_code(searchable)
  searchable = mask_inline_code_spans(searchable)
  targets = markdown_elements(searchable).map { |element| element[:destination] }
  html_opening_tags(searchable).each do |tag|
    _name, attributes, _duplicate_attributes = html_tag_name_and_attributes(tag)
    %w[href src].each { |field| targets << attributes[field] if attributes.key?(field) }
    targets.concat(srcset_targets(attributes["srcset"])) if attributes.key?("srcset")
  end
  targets
end

def normalize_target(raw_target)
  target = raw_target.to_s.strip
  return nil if target.empty? || target.include?("{{") || target.include?("{%") || target.start_with?("#", "//")
  return nil if normalized_uri_scheme(target)

  if target.start_with?("<") && target.include?(">")
    target = target[1...target.index(">")]
  else
    target = target.split(/\s+(?=["'])/, 2).first
  end
  return nil unless target.start_with?("/")

  target.split(/[?#]/, 2).first
end

def configured_public_static_paths(errors)
  return @configured_public_static_paths if defined?(@configured_public_static_paths)

  paths = Set.new(["assets"])
  config = ROOT.join("_config.yml")
  if config.file?
    data = YAML.safe_load(
      config.read(encoding: "UTF-8"),
      permitted_classes: [],
      permitted_symbols: [],
      aliases: true
    ) || {}
    unless data.is_a?(Hash)
      errors << "_config.yml: root must be a mapping"
      data = {}
    end
    errors << "_config.yml: markdown must be kramdown" unless data["markdown"] == "kramdown"
    kramdown = data["kramdown"]
    unless kramdown.is_a?(Hash) && kramdown["math_engine"] == "mathjax"
      errors << "_config.yml: kramdown.math_engine must be mathjax"
    end
    site_url = data["url"]
    if site_url
      unless site_url.is_a?(String) && site_url.match?(%r{\Ahttps?://}i) &&
             !site_url.match?(/[<>"'\u0000-\u0020]/)
        errors << "_config.yml: url must be an attribute-safe absolute http or https URL"
      end
    end
    includes = data["include"]
    if !includes.nil? && !includes.is_a?(Array)
      errors << "_config.yml: include must be a list"
      includes = []
    end
    Array(includes).each do |entry|
      unless entry.is_a?(String) && !entry.strip.empty?
        errors << "_config.yml: include entries must be non-empty strings"
        next
      end
      raw_entry = entry.strip
      relative = raw_entry.sub(%r{/+\z}, "")
      if relative.empty? || Pathname.new(relative).absolute? || Pathname.new(relative).cleanpath.to_s != relative
        errors << "_config.yml: invalid include path #{entry.inspect}"
        next
      end

      paths << relative
    end
  end
  @configured_public_static_paths = paths
rescue Psych::SyntaxError => e
  errors << "_config.yml: invalid YAML (#{e.message.lines.first.strip})"
  @configured_public_static_paths = paths
rescue StandardError => e
  errors << "_config.yml: cannot read (#{e.class}: #{e.message})"
  @configured_public_static_paths = paths
end

def exact_public_asset?(decoded, errors)
  relative = decoded.sub(%r{\A/}, "")
  allowed = configured_public_static_paths(errors).any? do |path|
    relative == path || relative.start_with?("#{path}/")
  end
  return false unless allowed

  components = Pathname.new(relative).each_filename.to_a
  current = ROOT
  components.each do |component|
    return false unless current.directory?

    entry = current.children.find { |child| child.basename.to_s == component }
    return false unless entry

    current = entry
  end
  current.file?
end

def validate_local_target(raw_target, relative, routes, errors)
  candidate = raw_target.to_s.strip
  return if candidate.empty?

  liquid_kind, liquid_target, _liquid_filter = classify_liquid_link_target(candidate)
  return if liquid_kind == :invalid || liquid_kind == :dynamic
  candidate = liquid_target
  return if candidate.start_with?("#", "//") || normalized_uri_scheme(candidate)

  unless candidate.start_with?("/") || candidate.start_with?("<")
    errors << "#{relative}: local target must start with /"
    return
  end

  path = normalize_target(candidate)
  return unless path

  decoded = URI::DEFAULT_PARSER.unescape(path)
  cleaned = Pathname.new(decoded).cleanpath.to_s
  cleaned += "/" if decoded.end_with?("/") && cleaned != "/"
  unless cleaned == decoded
    errors << "#{relative}: non-canonical local target #{path}"
    return
  end

  return if routes.include?(decoded)
  return if exact_public_asset?(decoded, errors)

  errors << "#{relative}: missing local route or asset #{path}"
rescue ArgumentError
  errors << "#{relative}: malformed local target #{path}"
end

def repository_text_paths(errors)
  output, status = Open3.capture2e(
    "git", "-C", ROOT.to_s, "ls-files", "--cached", "--others", "--exclude-standard", "-z"
  )
  unless status.success?
    errors << "repository: cannot enumerate public text files"
    return []
  end

  output.split("\0").map { |relative| ROOT.join(relative) }.select do |path|
    next false unless path.file?
    if path.symlink?
      errors << "#{relative_path(path)}: symbolic link is not scanned for secrets"
      next false
    end
    next false if BINARY_EXTENSIONS.include?(path.extname.downcase)

    if path.size > MAX_SECRET_SCAN_BYTES
      errors << "#{relative_path(path)}: cannot scan oversized text candidate for secrets"
      next false
    end

    sample = path.binread([path.size, 8192].min)
    !sample.include?("\0")
  end
rescue StandardError => e
  errors << "repository: cannot classify files for secret scanning (#{e.class})"
  []
end

def scan_repository_secrets(errors)
  repository_text_paths(errors).each do |path|
    text = path.read(encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "�")
    SECRET_PATTERNS.each do |name, pattern|
      errors << "#{relative_path(path)}: possible #{name}" if text.match?(pattern)
    end
  rescue StandardError => e
    errors << "#{relative_path(path)}: cannot scan for secrets (#{e.class})"
  end
end

configured_public_static_paths(errors)

COLLECTION_SCHEMAS.each do |collection, schema|
  ROOT.join(collection).glob("**/*.md").sort.each do |path|
    document = validate_collection_document(path, collection, schema, errors)
    documents << document if document
  end
end

PAGE_PATTERNS.each do |pattern|
  ROOT.glob(pattern).sort.each do |path|
    document = validate_page_document(path, errors)
    documents << document if document
  end
end

routes_by_path = Hash.new { |hash, key| hash[key] = [] }
documents.each do |document|
  route = output_route(document)
  unless route.match?(OUTPUT_ROUTE)
    errors << "#{document[:relative]}: invalid output route #{route.inspect}"
    next
  end
  routes_by_path[route] << document[:relative]
end
routes_by_path.each do |route, sources|
  errors << "duplicate output route #{route}: #{sources.join(', ')}" if sources.length > 1
end
routes = routes_by_path.keys.to_set

research = documents.select { |document| document[:collection] == "_research" }
research.group_by { |document| document[:data]["order"] }.each do |order, grouped|
  next if order.nil? || grouped.length == 1
  errors << "_research: duplicate order #{order}: #{grouped.map { |document| document[:relative] }.join(', ')}"
end

%w[_study _assignment].each do |collection|
  grouped_documents = documents.select { |document| document[:collection] == collection }
  grouped_documents.group_by { |document| [document[:data]["course"], document[:data]["order"]] }.each do |key, grouped|
    course, order = key
    next if order.nil? || grouped.length == 1
    errors << "#{collection}: duplicate order #{order} in #{course}: #{grouped.map { |document| document[:relative] }.join(', ')}"
  end
end

documents.each do |document|
  markdown_targets(document[:body]).uniq.each do |target|
    validate_local_target(target, document[:relative], routes, errors)
  end
end

navigation = ROOT.join("_data/navigation.yml")
if navigation.exist?
  begin
    navigation_text = navigation.read(encoding: "UTF-8")
    navigation_data = YAML.safe_load(navigation_text, permitted_classes: [], permitted_symbols: [], aliases: true)
    unless navigation_data.is_a?(Array)
      errors << "_data/navigation.yml: root must be a list"
      navigation_data = []
    end
    navigation_values = Hash.new { |hash, key| hash[key] = Hash.new { |inner, value| inner[value] = [] } }
    visit_navigation = lambda do |items, scope, depth|
      unless items.is_a?(Array)
        errors << "_data/navigation.yml: #{scope} must be a list"
        next
      end

      items.each_with_index do |item, index|
        unless item.is_a?(Hash)
          errors << "_data/navigation.yml: #{scope}[#{index}] must be a mapping"
          next
        end

        label = "#{scope}[#{index}] #{item['title'].inspect}"
        %w[title url].each do |field|
          errors << "_data/navigation.yml: #{label} is missing #{field}" unless item.key?(field)
        end
        NAVIGATION_STRING_FIELDS.each do |field|
          next unless item.key?(field)

          value = item[field]
          unless value.is_a?(String) && !value.strip.empty?
            errors << "_data/navigation.yml: #{label} #{field} must be a non-empty string"
          end
        end
        NAVIGATION_ENGLISH_FIELDS.each do |field|
          value = item[field]
          next unless value.is_a?(String)

          errors << "_data/navigation.yml: #{label} #{field} contains Hangul" if value.match?(HANGUL)
        end

        %w[url match source_url].each do |field|
          value = item[field]
          next unless value.is_a?(String) && !value.strip.empty?
          if value.include?("{{") || value.include?("{%")
            errors << "_data/navigation.yml: #{label} #{field} cannot use Liquid"
            next
          end
          if value.match?(/[<>"'\u0000-\u0020]/)
            errors << "_data/navigation.yml: #{label} #{field} contains an unsafe URL delimiter"
            next
          end

          canonical = canonical_uri_target(value)
          if canonical.start_with?("//")
            errors << "_data/navigation.yml: #{label} #{field} cannot be protocol-relative"
            next
          end

          validate_uri_scheme(value, "_data/navigation.yml: #{label} #{field}", errors)
          scheme = normalized_uri_scheme(value)
          if scheme
            unless %w[http https].include?(scheme)
              errors << "_data/navigation.yml: #{label} #{field} external URL must use http or https"
            else
              unless canonical.match?(%r{\Ahttps?://}i)
                errors << "_data/navigation.yml: #{label} #{field} external URL must use http:// or https://"
              end
            end
            if field == "match" || (field == "url" && depth.zero?)
              errors << "_data/navigation.yml: #{label} #{field} must be a site-root internal route"
            end
            next
          end

          navigation_values[field][value] << label if %w[url match].include?(field)
          validate_local_target(value, "_data/navigation.yml: #{label} #{field}", routes, errors)
        end

        visit_navigation.call(item["children"], "#{label}.children", depth + 1) if item.key?("children")
      end
    end

    visit_navigation.call(navigation_data, "root", 0)
    %w[url match].each do |field|
      navigation_values[field].each do |value, labels|
        next if labels.length == 1
        errors << "_data/navigation.yml: duplicate #{field} #{value}: #{labels.join(', ')}"
      end
    end
  rescue Psych::SyntaxError => e
    errors << "_data/navigation.yml: invalid YAML (#{e.message.lines.first.strip})"
  end
else
  errors << "_data/navigation.yml: missing"
end

PUBLIC_TEMPLATE_PATTERNS.each do |pattern|
  ROOT.glob(pattern).sort.each do |path|
    text = path.read(encoding: "UTF-8")
    relative = relative_path(path)
    errors << "#{relative}: public template UI contains Hangul" if text.match?(HANGUL)
    BANNED_PUBLIC_TEMPLATE_MARKERS.each do |marker, label|
      errors << "#{relative}: #{label} is not allowed" if text.include?(marker)
    end
    if relative == "_layouts/default.html" && text.include?("data-pdf-reader-panel")
      RESOURCE_READER_CONTRACT_PATTERNS.each do |pattern, message|
        errors << "#{relative}: #{message}" unless text.match?(pattern)
      end
    end
    without_fences = strip_fenced_code(text, relative, errors)
    without_indented_code = mask_indented_code(without_fences)
    liquid_searchable = mask_inline_code_spans(without_indented_code)
    without_comments = mask_html_comments(without_indented_code, relative, errors)
    without_inline_code = mask_inline_code_spans(without_comments)
    validate_liquid_output_escaping(liquid_searchable, relative, errors)
    validate_links_and_images(without_inline_code, relative, errors)
  rescue StandardError => e
    errors << "#{relative_path(path)}: cannot validate template (#{e.class}: #{e.message})"
  end
end

scan_repository_secrets(errors)

puts "Validated #{documents.length} public Markdown documents."

unique_errors = errors.uniq
if unique_errors.empty?
  puts "PASS: front matter, timestamps, routes, links, tables, MathJax source structure, public UI, and basic secret signatures"
  exit 0
end

unique_errors.each { |error| warn "ERROR: #{error}" }
warn "FAIL: #{unique_errors.length} issue(s)"
exit 1
