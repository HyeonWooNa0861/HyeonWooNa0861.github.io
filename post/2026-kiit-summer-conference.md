---
layout: default
title: 2026 KIIT Summer Conference
permalink: /post/2026-kiit-summer-conference/
---

# 2026 KIIT Summer Conference

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "kiit-summer-conference" %}
  {% for post in posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
