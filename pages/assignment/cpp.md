---
layout: default
title: C++ Assignment
permalink: /assignment/cpp/
---

<h1 class="branch-logo page-branch-logo" data-label="C++">C++</h1>

<ul class="post-list">
  {% assign assignments = site.assignment | where: "course", "C++" | sort: "title" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ assignment.title | escape }}" href="{{ assignment.url | relative_url }}">{{ assignment.title }}</a>
      <p>{{ assignment.course }} · {{ assignment.topic }}</p>
    </li>
  {% endfor %}
</ul>
