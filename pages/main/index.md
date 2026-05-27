---
layout: default
title: GitBlog
permalink: /
---

<section class="home-hero">
  <p class="home-eyebrow">AI / Research / Engineering</p>
  <h1>GitBlog</h1>
</section>

<div class="home-directory">
{% for item in site.data.navigation %}
  <section class="directory-section">
    <h2>
      <span>{{ item.title }}</span>
      <a class="directory-link" href="{{ item.url | relative_url }}">Open</a>
    </h2>

    <ul class="post-list">
      {% for child in item.children %}
        {% assign child_href = child.url %}
        {% unless child.url contains "://" %}
          {% assign child_href = child.url | relative_url %}
        {% endunless %}
        <li class="post-card">
          <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>{{ child.title }}</a>
        </li>
      {% endfor %}
    </ul>
  </section>
{% endfor %}
</div>
