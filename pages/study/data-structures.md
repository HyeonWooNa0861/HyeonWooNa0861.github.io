---
layout: default
title: Data Structures Study
permalink: /study/data-structures/
---

<h1 class="branch-logo page-branch-logo" data-label="Data Structures">Data Structures</h1>

<ul class="post-list">
  {% assign studies = site.study | where: "course", "Data Structures" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ study.title | escape }}" href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
