---
layout: default
title: GitBlog
permalink: /
---

{% for item in site.data.navigation %}
## {{ item.title }}

<ul class="post-list">
  {% for child in item.children %}
    {% assign child_href = child.url %}
    {% unless child.url contains "://" %}
      {% assign child_href = child.url | relative_url %}
    {% endunless %}
    <li class="post-card">
      <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>{{ child.title }}</a>
      <p>{{ child.description }}</p>
    </li>
  {% endfor %}
</ul>
{% endfor %}
