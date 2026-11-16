#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "date"
require "pathname"
require "yaml"

class SeminarNavigationTest < Minitest::Test
  ROOT = Pathname.new(File.expand_path("..", __dir__))

  SEMINAR_POSTS = {
    "_posts/2026-11-07-aise-lab-seminar-2026.md" => "/posts/aise-lab-seminar-2026/",
    "_posts/2026-10-15-discrete-diffusion-language-models.md" => "/posts/discrete-diffusion-language-models/",
    "_posts/2026-09-14-loss-landscape-analysis.md" => "/posts/loss-landscape-analysis/",
    "_posts/2026-09-14-neural-thickets.md" => "/posts/neural-thickets/",
    "_posts/2026-05-19-kiit-summer-conference-qeco-adapt.md" => "/posts/2026-kiit-summer-conference-qeco-adapt/"
  }.freeze

  def test_post_navigation_has_one_unified_seminar_child
    post_children = navigation.fetch("children")
    seminar_children = post_children.select { |child| child["title"] == "Seminar" }

    assert_equal 1, seminar_children.size
    assert_equal 1, post_children.count { |child| child["section"] == "seminar" }
    assert_equal "/post/seminar/", seminar_children.first["url"]
    assert_equal "seminar", seminar_children.first["section"]

    refute post_children.any? { |child| child["title"] == "26-2 Research Paper Seminar" }
    refute post_children.any? { |child| child["title"] == "2026 KIIT Summer Conference" }
  end

  def test_other_post_navigation_children_remain
    expected_children = {
      "KOSSCCHTHON 2026" => ["/posts/kosscchthon-2026/", "kosscchthon"],
      "Industry Lectures" => ["/post/industry-lectures/", "industry-lectures"]
    }

    expected_children.each do |title, (url, section)|
      child = navigation.fetch("children").find { |candidate| candidate["title"] == title }

      refute_nil child, "expected Post navigation to retain #{title}"
      assert_equal url, child["url"]
      assert_equal section, child["section"]
    end
  end

  def test_five_seminar_posts_share_section_without_changing_permalinks
    SEMINAR_POSTS.each do |path, permalink|
      metadata, = document(path)

      assert_equal "seminar", metadata["section"], "expected #{path} to use the seminar section"
      assert_equal permalink, metadata["permalink"], "expected #{path} to preserve its permalink"
    end
  end

  def test_seminar_index_uses_dynamic_post_filter_and_keeps_rlt_link
    metadata, body = document("post/seminar/index.md")

    assert_equal "Seminar", metadata["title"]
    assert_equal "/post/seminar/", metadata["permalink"]
    assert_includes body, 'site.posts | where: "section", "seminar"'
    filtered_posts = body[/\{%\s*assign\s+(\w+)\s*=\s*site\.posts\s*\|\s*where:\s*"section",\s*"seminar"/, 1]
    refute_nil filtered_posts
    assert_match(/\{%\s*for post in #{Regexp.escape(filtered_posts)}\s*%\}/, body)
    assert_includes body, "/research/rlt-recurrent-looped-transformer/"
    assert_includes body, '{% include branch-search.html collection="posts" section="seminar" %}'
  end

  def test_legacy_seminar_page_keeps_route_and_links_to_unified_catalog
    metadata, body = document("post/26-2-paper-research-seminar/index.md")

    assert_equal "/post/26-2-paper-research-seminar/", metadata["permalink"]
    assert_equal "default", metadata["layout"]
    refute metadata.key?("redirect_to")
    assert_includes body, "/post/seminar/"
    refute_includes body, 'class="post-card"'
  end

  def test_post_pager_and_search_remain_scoped_by_section
    pager = read("_includes/section-pager.html")
    search = read("_includes/branch-search.html")
    layout = read("_layouts/default.html")

    assert_includes pager, 'site.posts | where: "section", page.section'
    assert_match(/nav_child\.section == page\.section.*pager_parent_url = nav_child\.url/m, pager)
    assert_includes search, 'branch_search_items | where: "section", branch_search_section'
    assert_includes layout, '{% include branch-search.html collection="posts" section=page.section %}'
  end

  private

  def navigation
    @navigation ||= begin
      items = YAML.safe_load_file(ROOT.join("_data/navigation.yml"), aliases: true)
      items.find { |item| item["title"] == "Post" } || flunk("Post navigation is missing")
    end
  end

  def document(relative_path)
    content = read(relative_path)
    match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
    refute_nil match, "expected #{relative_path} to contain YAML front matter"

    [YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true), match[2]]
  end

  def read(relative_path)
    ROOT.join(relative_path).read(encoding: "UTF-8")
  end
end
