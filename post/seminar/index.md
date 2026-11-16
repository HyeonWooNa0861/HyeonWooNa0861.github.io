---
layout: default
title: Seminar
permalink: /post/seminar/
---

<h1 class="branch-logo page-branch-logo" data-label="Seminar">Seminar</h1>

{% include branch-search.html collection="posts" section="seminar" %}

<ul class="post-list">
  {% assign seminar_posts = site.posts | where: "section", "seminar" | sort: "date" | reverse %}
  {% for post in seminar_posts %}
    {% assign seminar_title = post.nav_title | default: post.title %}
    <li class="post-card">
      <a class="branch-card-link" data-label="{{ seminar_title | escape }}" href="{{ post.url | relative_url | escape }}">{{ seminar_title | escape }}</a>
      <p>{{ post.date | date: "%Y-%m-%d" | escape }} · {{ post.categories | join: ", " | escape }}</p>
    </li>
  {% endfor %}
  <li class="post-card">
    <a class="branch-card-link" data-label="RLT" href="{{ '/research/rlt-recurrent-looped-transformer/' | relative_url }}">RLT</a>
    <p>Research reference · Recurrent latent computation and full-history policy replay</p>
  </li>
</ul>
