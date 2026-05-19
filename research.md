---
layout: default
title: Research
permalink: /research/
---

# Research

<ul class="post-list">
  {% assign research_items = site.research | sort: "order" %}
  {% for item in research_items %}
    <li class="post-card">
      <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
      <p>{{ item.topic }}</p>
    </li>
  {% endfor %}
</ul>
