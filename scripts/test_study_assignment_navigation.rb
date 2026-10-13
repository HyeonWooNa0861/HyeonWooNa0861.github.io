#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "yaml"

class StudyAssignmentNavigationTest < Minitest::Test
  ROOT = Pathname.new(File.expand_path("..", __dir__))

  def test_assignment_is_integrated_into_study_navigation
    navigation = YAML.safe_load_file(ROOT.join("_data/navigation.yml"), aliases: true)
    study = navigation.find { |item| item["title"] == "Study" }

    refute navigation.any? { |item| item["title"] == "Assignment" }
    refute_nil study

    study_courses = study.fetch("children").map { |child| child.fetch("title") }
    assignment_courses.each { |course| assert_includes study_courses, course }
  end

  def test_study_catalog_lists_assignments_and_course_search_indexes_them
    catalog = read("_includes/study-catalog.html")
    search = read("_includes/branch-search.html")

    assert_includes catalog, 'site.assignment | where: "course", include.course'
    assert_includes catalog, "<h2>Lecture notes</h2>"
    assert_includes catalog, '<h2 id="assignments">Assignments</h2>'
    assert_operator search.scan("site.study | concat: site.assignment").size, :>=, 2
    assert_includes search, 'item.url contains "/assignment/"'
    assert_match(/branch_search_collection == "research".*Research note/m, search)
  end

  def test_assignment_pager_returns_to_study_course
    pager = read("_includes/section-pager.html")
    assignment_branch = pager[/\{% elsif page\.collection == "assignment".*?\{% elsif page\.collection == "research"/m]

    refute_nil assignment_branch
    assert_includes assignment_branch, 'nav_item.title == "Study"'
    refute_includes assignment_branch, 'nav_item.title == "Assignment"'
    assert_includes assignment_branch, 'sort: "order"'
  end

  def test_assignment_entries_use_study_sidebar_and_search_context
    layout = read("_layouts/default.html")

    assert_match(/item\.title == "Study".*page\.collection == "assignment"/m, layout)
    assert_match(/page\.course == child\.title/m, layout)
    assert_includes layout, "assignment_course_url"
    assert_match(/page\.url == assignment_course_url/, layout)
    assignment_layout_branch = layout[/\{% elsif page\.collection == "assignment" %\}.*?\{% elsif page\.collection == "posts" %\}/m]
    refute_nil assignment_layout_branch
    assert_includes assignment_layout_branch, '{% include branch-search.html collection="study" course=page.course %}'
  end

  def test_legacy_assignment_directories_link_to_study
    legacy_index = read("pages/main/assignment.md")

    assert_includes legacy_index, 'item.title == "Study"'
    assert_includes legacy_index, "unified Study course catalog"

    {
      "pages/assignment/aix.md" => "/study/aix/",
      "pages/assignment/algorithms.md" => "/study/algorithms/",
      "pages/assignment/cpp.md" => "/study/cpp/",
      "pages/assignment/machine-learning-basic.md" => "/study/machine-learning-basic/"
    }.each do |path, study_route|
      assert_includes read(path), %(href="#{study_route}")
    end
  end

  private

  def assignment_courses
    ROOT.glob("_assignment/**/*.md").filter_map do |path|
      front_matter = path.read(encoding: "UTF-8").split("\n---\n", 2).first.sub(/\A---\n/, "")
      YAML.safe_load(front_matter, permitted_classes: [Time], aliases: true)["course"]
    end.uniq
  end

  def read(relative_path)
    ROOT.join(relative_path).read(encoding: "UTF-8")
  end
end
