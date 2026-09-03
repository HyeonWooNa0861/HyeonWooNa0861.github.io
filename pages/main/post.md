---
layout: default
title: Post
permalink: /post/
---

<h1 class="branch-logo page-branch-logo" data-label="Post">Post</h1>

<ul class="post-list">
  {% for item in site.data.navigation %}
    {% if item.title == "Post" %}
      {% for child in item.children %}
        <li class="post-card">
          <a class="branch-card-link" data-label="{{ child.title | escape }}" href="{{ child.url | relative_url | escape }}">{{ child.title | escape }}</a>
          <p>{{ child.description | escape }}</p>
        </li>
      {% endfor %}
    {% endif %}
  {% endfor %}
</ul>
