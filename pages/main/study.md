---
layout: default
title: Study
permalink: /study/
---

# Study

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Study" %}
      {% for child in item.children %}
        <li class="post-card">
          <a href="{{ child.url | relative_url }}">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
