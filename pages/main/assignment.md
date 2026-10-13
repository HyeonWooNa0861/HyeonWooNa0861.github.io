---
layout: default
title: Assignment
permalink: /assignment/
---

<h1 class="branch-logo page-branch-logo" data-label="Assignment">Assignment</h1>

<p>This legacy directory remains available for existing links. Assignments now appear with lecture notes in each Study course.</p>

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Study" %}
      {% for child in item.children %}
        {% assign course_assignments = site.assignment | where: "course", child.title %}
        {% assign course_assignment_count = course_assignments | size %}
        {% if course_assignments != empty %}
          <li class="post-card">
            <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url | relative_url | escape }}">{{ child.title | escape }}</a>
            <p>{{ course_assignment_count | escape }} assignment{% unless course_assignment_count == 1 %}s{% endunless %} · Open the unified Study course catalog</p>
          </li>
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
