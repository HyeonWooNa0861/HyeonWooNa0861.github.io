#!/usr/bin/env ruby
# frozen_string_literal: true
require "minitest/autorun"
require "jekyll"
require "nokogiri"

class StudyPeriodsTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  def self.site
    @site ||= begin
      site = Jekyll::Site.new(Jekyll.configuration(
        "source" => ROOT, "disable_disk_cache" => true, "safe" => true,
        "strict_front_matter" => true, "quiet" => true
      ))
      site.reset
      site.read
      site.generate
      site.render
      site
    end
  end

  def catalog(course)
    page = self.class.site.pages.find { |p| p.url == "/study/#{course}/" }
    refute_nil page
    Nokogiri::HTML(page.output)
  end

  def assert_period(doc, slug, expected)
    anchor = doc.css(".content-catalog-list .branch-card-link").find { |a| a["href"].end_with?("/#{slug}/") }
    refute_nil anchor, slug
    assert_equal expected, anchor.parent["data-study-period"], slug
    assert_includes anchor.parent.text, expected == "midterm" ? "Midterm period" : "Final period"
  end

  def test_confirmed_course_boundaries_and_special_notes
    {
      "algorithms" => {
        "lecture-11-greedy-algorithm" => "midterm", "lecture-12-graph-basics" => "final",
        "midterm-review-through-greedy" => "midterm", "assignment-02-sorting-and-dynamic-programming" => "midterm"
      },
      "autonomous-driving" => {
        "lecture-11-3d-perception-03" => "midterm", "lecture-12-object-tracking-01" => "final",
        "adc-lab-01-two-stage-vs-one-stage" => "midterm", "assignment-03-lidar-3d-object-detection" => "midterm"
      },
      "speech-and-audio-recognition" => {
        "lecture-05-self-supervised-learning" => "midterm", "lecture-06-source-separation" => "final",
        "lecture-09-mvdr-lab" => "final", "asr-tokenization-and-decoding-lab" => "midterm",
        "lecture-02-spectral-analysis-lab" => "midterm", "midterm-review" => "midterm"
      }
    }.each do |course, examples|
      doc = catalog(course)
      examples.each { |slug, expected| assert_period(doc, slug, expected) }
      assert_equal 2, doc.css(".study-period-legend .study-period-badge").size
      assert_equal ["midterm-period", "final-period"], doc.css(".study-period-group > h3").map { |h| h["id"] }
      doc.css(".study-period-group").each do |group|
        kinds = group.css("[data-note-kind]").map { |card| card["data-note-kind"] }
        assert_equal kinds.sort_by { |kind| kind == "review" ? 0 : 1 }, kinds
        period = group.at_css("h3")["id"].delete_suffix("-period")
        assert group.css("li[data-study-period]").all? { |li| li["data-study-period"] == period }
      end
      expected_count = self.class.site.collections.values_at("study", "assignment").compact.flat_map(&:docs).count do |d|
        d.data["course"] == {"algorithms"=>"Algorithms","autonomous-driving"=>"Autonomous Driving","speech-and-audio-recognition"=>"Speech and Audio Recognition"}[course]
      end
      assert_equal expected_count, doc.css(".content-catalog-list > li").size
    end
  end

  def test_unclassified_courses_are_not_assigned_an_exam_period
    doc = catalog("cs231n")
    assert_empty doc.css('[data-study-period="midterm"], [data-study-period="final"], .study-period-legend')
    refute_empty doc.css(".content-catalog-list > li")
  end

  def test_additional_courses_use_evidence_and_preserve_unknowns
    aix = catalog("aix")
    assert_period(aix, "aix-midterm-review", "midterm")
    assert_period(aix, "aix-final-review", "final")
    assert_period(aix, "robotics-1", "final")
    assert_period(aix, "aix-quiz-review-after-midterm", "final")
    ds = catalog("data-structures")
    assert_period(ds, "ls13-sorting", "final")
    assert_period(ds, "data-structures-final-review", "final")
    assert ds.at_css("#unclassified-period")
    assert_equal "review", ds.at_css('[aria-labelledby="final-period"] [data-note-kind]')["data-note-kind"]
    cpp = catalog("cpp")
    assert_period(cpp, "final-exam-review", "final")
    assert cpp.at_css("#unclassified-period")
    %w[algorithms autonomous-driving speech-and-audio-recognition aix cpp data-structures cs231n].each do |course|
      doc = catalog(course)
      assert_empty doc.css("pre code").select { |code| code.text.include?('class="study-period-group"') }
      links = doc.css(".content-catalog-list .branch-card-link").map { |a| a["href"] }
      assert_equal links.uniq, links
    end
  end
end
