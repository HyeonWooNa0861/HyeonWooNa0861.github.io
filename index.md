---
layout: default
title: HyeonWooNa0861 GitBlog
---

# HyeonWooNa0861 GitBlog

## Posts

<ul class="post-list">
  {% for post in site.posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
