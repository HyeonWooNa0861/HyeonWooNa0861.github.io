---
layout: default
title: nxtcloud Boot Camp
permalink: /post/nxtcloud-boot-camp/
---

<h1 class="branch-logo page-branch-logo" data-label="nxtcloud Boot Camp">nxtcloud Boot Camp</h1>

<ul class="post-list">
  {% assign posts = site.posts | where: "section", "nxtcloud-boot-camp" | sort: "date" | reverse %}
  {% for post in posts %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ post.nav_title | default: post.title | escape }}" href="{{ post.url | relative_url }}">{{ post.nav_title | default: post.title }}</a>
      <p>{{ post.title }}</p>
    </li>
  {% endfor %}
</ul>
