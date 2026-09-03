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
          <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url | escape }}" target="_blank" rel="noopener">{{ child.title | escape }}</a>
          <p>{{ child.description | escape }}</p>
          {% if child.source_url %}
            <p><a href="{{ child.source_url | escape }}" target="_blank" rel="noopener">{{ child.source_label | default: "Source" | escape }}</a></p>
          {% endif %}
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
