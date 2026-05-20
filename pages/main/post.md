---
layout: default
title: Post
permalink: /post/
---

# Post

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Post" %}
      {% for child in item.children %}
        <li class="post-card">
          <a href="{{ child.url | relative_url }}">{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
