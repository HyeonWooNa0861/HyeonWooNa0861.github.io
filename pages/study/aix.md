---
layout: default
title: AIX Study
permalink: /study/aix/
---

# AIX

<ul class="post-list">
  {% assign studies = site.study | where: "course", "AIX" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
