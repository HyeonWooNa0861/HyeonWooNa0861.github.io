---
layout: default
title: 자료구조 Study
permalink: /study/data-structure/
---

# 자료구조

<ul class="post-list">
  {% assign studies = site.study | where: "course", "자료구조" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
