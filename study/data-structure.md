---
layout: default
title: Data Structures Study
permalink: /study/data-structure/
---

# Data Structures

<ul class="post-list">
  {% assign studies = site.study | where: "course", "Data Structures" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
