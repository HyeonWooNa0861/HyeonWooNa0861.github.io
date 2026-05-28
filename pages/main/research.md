---
layout: default
title: Research
permalink: /research/
---

<h1 class="branch-logo page-branch-logo" data-label="Research">Research</h1>

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Research" %}
      {% for child in item.children %}
        <li class="post-card">
          <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url | relative_url }}">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
