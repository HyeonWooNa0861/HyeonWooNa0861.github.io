---
layout: default
title: Project
permalink: /project/
---

<h1 class="branch-logo page-branch-logo" data-label="Project">Project</h1>

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Project" %}
      {% for child in item.children %}
        <li class="post-card">
          <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url }}" target="_blank" rel="noopener">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
