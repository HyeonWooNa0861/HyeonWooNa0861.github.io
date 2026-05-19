---
layout: default
title: 산업체 특강
permalink: /post/industrial-special-lecture/
---

# 산업체 특강

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "industrial-special-lecture" %}
  {% for post in posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
