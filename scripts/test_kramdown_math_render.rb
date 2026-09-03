#!/usr/bin/env ruby
# frozen_string_literal: true

gem "kramdown", "= 2.4.0"
require "kramdown"
require "pathname"

EXPECTED_KRAMDOWN_VERSION = "2.4.0"
abort "FAIL: expected Kramdown #{EXPECTED_KRAMDOWN_VERSION}, loaded #{Kramdown::VERSION}" unless Kramdown::VERSION == EXPECTED_KRAMDOWN_VERSION

ROOT = Pathname.new(File.expand_path("..", __dir__))
PUBLIC_MARKDOWN_PATTERNS = %w[
  _posts/**/*.md
  _research/**/*.md
  _study/**/*.md
  _assignment/**/*.md
  pages/**/*.md
  post/**/*.md
].freeze
DETAILS_PATTERN = %r{<details\b[^>]*>.*?</details\s*>}im
SUMMARY_PATTERN = %r{<summary\b[^>]*>.*?</summary\s*>}im
UNRENDERED_MARKDOWN_PATTERNS = {
  "strong emphasis" => /(?<!\*)\*\*\S(?:[^\n]*?\S)?\*\*(?!\*)|(?<!_)__\S(?:[^\n]*?\S)?__(?!_)/,
  "inline code" => /(?<!`)`[^`\n]+`(?!`)/,
  "Markdown link" => /\[[^\]\n]+\]\([^\n)]+\)/,
  "heading" => /^\s{0,3}\#{1,6}[ \t]+\S/m,
  "list" => /^\s{0,3}(?:[-+*]|\d+\.)[ \t]+\S/m,
  "block quote" => /^\s{0,3}>[ \t]+\S/m,
  "fenced code" => /^\s{0,3}(?:```|~~~)/m,
  "table separator" => /^\s*\|?(?:\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?\s*$/m
}.freeze

def document_body(source)
  return [source, 0] unless source.start_with?("---\n")

  closing = source.index("\n---\n", 4)
  return [source, 0] unless closing

  body_start = closing + 5
  [source[body_start..].to_s, source[0...body_start].count("\n")]
end

def answer_html(rendered_details)
  rendered_details
    .sub(SUMMARY_PATTERN, "")
    .sub(/\A<details\b[^>]*>/im, "")
    .sub(%r{</details\s*>\z}im, "")
end

def mask_rendered_code(html)
  html
    .gsub(%r{<pre\b[^>]*>.*?</pre\s*>}im, "")
    .gsub(%r{<code\b[^>]*>.*?</code\s*>}im, "")
end

failures = []
summary_count = 0
files_with_math_summaries = 0
details_count = 0
files_with_details = 0

PUBLIC_MARKDOWN_PATTERNS.flat_map { |pattern| ROOT.glob(pattern) }.uniq.sort.each do |path|
  source = path.read(encoding: "UTF-8")
  body, body_line_offset = document_body(source)
  relative = path.relative_path_from(ROOT)
  matched_summary_file = false

  source.to_enum(:scan, SUMMARY_PATTERN).each do
    match = Regexp.last_match
    delimiter_count = match[0].scan(/(?<!\\)\$\$/).length
    next if delimiter_count.zero?

    matched_summary_file = true
    summary_count += 1
    line = source[0...match.begin(0)].count("\n") + 1
    rendered = Kramdown::Document.new(match[0], math_engine: :mathjax).to_html
    inline_openings = rendered.scan(/(?<!\\)\\\(/).length
    inline_closings = rendered.scan(/(?<!\\)\\\)/).length
    expected_inline_math = delimiter_count / 2

    if delimiter_count.odd?
      failures << "#{relative}:#{line}: unbalanced $$ delimiters in <summary>"
    elsif rendered.include?("$$")
      failures << "#{relative}:#{line}: Kramdown left literal $$ delimiters in <summary>"
    elsif rendered.match?(/(?<!\\)\\[\[\]]/) || rendered.include?("mode=display")
      failures << "#{relative}:#{line}: Kramdown rendered display math inside <summary>"
    elsif inline_openings != expected_inline_math || inline_closings != expected_inline_math
      failures << "#{relative}:#{line}: Kramdown did not preserve every <summary> formula as inline math"
    end
  end

  files_with_math_summaries += 1 if matched_summary_file

  source_details = body.to_enum(:scan, DETAILS_PATTERN).map { Regexp.last_match }
  next if source_details.empty?

  files_with_details += 1
  details_count += source_details.length
  rendered_body = Kramdown::Document.new(body, math_engine: :mathjax).to_html
  rendered_details = rendered_body.scan(DETAILS_PATTERN)

  if rendered_details.length != source_details.length
    failures << "#{relative}: Kramdown rendered #{rendered_details.length} of #{source_details.length} <details> blocks"
    next
  end

  source_details.zip(rendered_details).each do |source_match, rendered_details_block|
    line = body_line_offset + body[0...source_match.begin(0)].count("\n") + 1
    searchable_answer = mask_rendered_code(answer_html(rendered_details_block))

    if searchable_answer.include?("$$")
      failures << "#{relative}:#{line}: Kramdown left literal $$ delimiters in <details> answer"
    end

    UNRENDERED_MARKDOWN_PATTERNS.each do |name, pattern|
      next unless searchable_answer.match?(pattern)

      failures << "#{relative}:#{line}: Kramdown left unrendered #{name} syntax in <details> answer"
    end
  end
end

if failures.empty?
  puts "PASS: Kramdown #{Kramdown::VERSION} renderer active"
  puts "PASS: Kramdown rendered #{details_count} <details> answers across #{files_with_details} files"
  puts "PASS: Kramdown rendered #{summary_count} math <summary> elements inline across #{files_with_math_summaries} files"
  exit 0
end

failures.each { |failure| warn "ERROR: #{failure}" }
warn "FAIL: #{failures.length} Kramdown <details>/<summary> rendering issue(s)"
exit 1
