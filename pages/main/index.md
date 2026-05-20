---
layout: default
title: GitBlog
permalink: /
---

{% for item in site.data.navigation %}
## {{ item.title }}

<ul class="post-list">
  {% for child in item.children %}
    <li class="post-card">
      <a href="{{ child.url | relative_url }}">{{ child.title }}</a>
      <p>{{ child.description }}</p>
    </li>
  {% endfor %}
</ul>
{% endfor %}
