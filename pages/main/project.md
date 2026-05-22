---
layout: default
title: Project
permalink: /project/
---

# Project

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Project" %}
      {% for child in item.children %}
        <li class="post-card">
          <a href="{{ child.url }}" target="_blank" rel="noopener">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
