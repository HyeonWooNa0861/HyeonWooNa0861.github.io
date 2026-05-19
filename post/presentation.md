---
layout: default
title: Presentation
permalink: /post/presentation/
---

# Presentation

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "presentation" %}
  {% for post in posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
