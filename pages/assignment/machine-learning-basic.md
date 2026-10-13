---
layout: default
title: Machine Learning Basic Assignment
permalink: /assignment/machine-learning-basic/
---

<h1 class="branch-logo page-branch-logo" data-label="Machine Learning Basic">Machine Learning Basic</h1>

<p>This legacy assignment directory remains available for existing links. <a href="/study/machine-learning-basic/">Open the unified Machine Learning Basic Study catalog</a> for lecture notes and assignments.</p>

<ul class="post-list">
  {% assign assignments = site.assignment | where: "course", "Machine Learning Basic" | sort: "title" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ assignment.title | escape }}" href="{{ assignment.url | relative_url | escape }}">{{ assignment.title | escape }}</a>
      <p>{{ assignment.course | escape }} · {{ assignment.topic | escape }}</p>
    </li>
  {% endfor %}
</ul>
