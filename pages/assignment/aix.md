---
layout: default
title: AIX Assignment
permalink: /assignment/aix/
---

<h1 class="branch-logo page-branch-logo" data-label="AIX">AIX</h1>

<ul class="post-list">
  {% assign assignments = site.assignment | where: "course", "AIX" | sort: "order" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ assignment.title | escape }}" href="{{ assignment.url | relative_url | escape }}">{{ assignment.title | escape }}</a>
      <p>{{ assignment.course | escape }} · {{ assignment.topic | escape }}</p>
    </li>
  {% endfor %}
</ul>
