---
layout: default
title: AIX Assignment
permalink: /assignment/aix/
---

<h1 class="branch-logo page-branch-logo" data-label="AIX">AIX</h1>

<p>This legacy assignment directory remains available for existing links. <a href="/study/aix/">Open the unified AIX Study catalog</a> for lecture notes and assignments.</p>

<ul class="post-list">
  {% assign assignments = site.assignment | where: "course", "AIX" | sort: "order" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ assignment.title | escape }}" href="{{ assignment.url | relative_url | escape }}">{{ assignment.title | escape }}</a>
      <p>{{ assignment.course | escape }} · {{ assignment.topic | escape }}</p>
    </li>
  {% endfor %}
</ul>
