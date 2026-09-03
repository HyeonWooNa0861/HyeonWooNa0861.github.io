---
layout: default
title: AI Education
permalink: /post/ai-education/
---

<h1 class="branch-logo page-branch-logo" data-label="AI Education">AI Education</h1>

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "ai-education" | sort: "date" | reverse %}
  {% for post in posts %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ post.title | escape }}" href="{{ post.url | relative_url | escape }}">{{ post.title | escape }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" | escape }} · {{ post.categories | join: ", " | escape }}</p>
    </li>
  {% endfor %}
</ul>
