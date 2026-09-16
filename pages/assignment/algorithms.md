---
layout: default
title: Algorithms Assignment
permalink: /assignment/algorithms/
---

<h1 class="branch-logo page-branch-logo" data-label="Algorithms">Algorithms</h1>

<ul class="post-list">
  {% assign assignments = site.assignment | where: "course", "Algorithms" | sort: "order" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ assignment.title | escape }}" href="{{ assignment.url | relative_url | escape }}">{{ assignment.title | escape }}</a>
      <p>{{ assignment.course | escape }} · {{ assignment.topic | escape }}</p>
    </li>
  {% endfor %}
</ul>
