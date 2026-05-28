---
layout: default
title: Machine Learning Basic Study
permalink: /study/machine-learning-basic/
---

<h1 class="branch-logo page-branch-logo" data-label="Machine Learning Basic">Machine Learning Basic</h1>

<ul class="post-list">
  {% assign studies = site.study | where: "course", "Machine Learning Basic" | sort: "order" %}
  {% for study in studies %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ study.title | escape }}" href="{{ study.url | relative_url }}">{{ study.title }}</a>
      <p>{{ study.course }} · {{ study.topic }}</p>
    </li>
  {% endfor %}
</ul>
