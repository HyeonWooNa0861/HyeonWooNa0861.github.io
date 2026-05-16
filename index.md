---
layout: default
title: GitBlog
---

## Posts

<ul class="post-list">
  {% for post in site.posts %}
    <li class="post-card">
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>

## Assignments

<ul class="post-list">
  {% assign assignments = site.assignment | sort: "title" %}
  {% for assignment in assignments %}
    <li class="post-card">
      <a href="{{ assignment.url | relative_url }}">{{ assignment.title }}</a>
      <p>{{ assignment.course }} · {{ assignment.topic }}</p>
    </li>
  {% endfor %}
</ul>
