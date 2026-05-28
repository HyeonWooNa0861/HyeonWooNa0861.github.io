---
layout: default
title: Industry Lectures
permalink: /post/industry-lectures/
---

<h1 class="branch-logo page-branch-logo" data-label="Industry Lectures">Industry Lectures</h1>

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "industry-lectures" | sort: "date" | reverse %}
  {% for post in posts %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ post.title | escape }}" href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
