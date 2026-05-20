---
layout: default
title: Research
permalink: /research/
---

# Research

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Research" %}
      {% for child in item.children %}
        <li class="post-card">
          <a href="{{ child.url | relative_url }}">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
