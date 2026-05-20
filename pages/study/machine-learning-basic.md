---
layout: default
title: Machine Learning Basic Study
permalink: /study/machine-learning-basic/
---

# Machine Learning Basic

<ul class="post-list">
  {% assign studies = site.study | where: "course", "Machine Learning Basic" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
