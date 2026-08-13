---
layout: default
title: Study
permalink: /study/
---

<h1 class="branch-logo page-branch-logo" data-label="Study">Study</h1>

{% include branch-search.html collection="study" %}

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Study" %}
      {% for child in item.children %}
        {% assign course_notes = site.study | where: "course", child.title %}
        {% assign course_sample = course_notes | first %}
        <li class="post-card">
          <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url | relative_url }}">{{ child.title }}</a>
          <p>{{ child.description }} · {{ course_notes | size }} notes</p>
          {% include content-taxonomy.html item=course_sample mode="compact" %}
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
