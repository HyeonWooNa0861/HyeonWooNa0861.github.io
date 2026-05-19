---
layout: default
title: Industry Lectures
permalink: /post/industry-lectures/
---

# Industry Lectures

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "industry-lectures" %}
  {% for post in posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
