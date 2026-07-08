---
layout: default
title: AI Agents
permalink: /post/ai-agents/
---

<h1 class="branch-logo page-branch-logo" data-label="AI Agents">AI Agents</h1>

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "ai-agents" | sort: "date" | reverse %}
  {% for post in posts %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ post.title | escape }}" href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" }} · {{ post.categories | join: ", " }}</p>
    </li>
  {% endfor %}
</ul>
