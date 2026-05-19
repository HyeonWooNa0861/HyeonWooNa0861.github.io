---
layout: default
title: C++ Study
permalink: /study/cpp/
---

# C++

<ul class="post-list">
  {% assign studies = site.study | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
