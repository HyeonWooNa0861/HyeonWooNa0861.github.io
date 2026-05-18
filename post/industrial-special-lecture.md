---
layout: default
title: 산업체 특강
permalink: /post/industrial-special-lecture/
---

# 산업체 특강

<ul class="post-list">
  {% for post in site.posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
