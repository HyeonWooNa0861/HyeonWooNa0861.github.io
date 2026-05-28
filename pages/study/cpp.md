---
layout: default
title: C++ Study
permalink: /study/cpp/
---

<h1 class="branch-logo page-branch-logo" data-label="C++">C++</h1>

<ul class="post-list">
  {% assign studies = site.study | where: "course", "C++" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ study.title | escape }}" href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
