---
layout: default
title: GitBlog
permalink: /
---

<section class="home-hero">
  <div>
    <p class="home-eyebrow">AI / Research / Engineering Notes</p>
    <h1>GitBlog</h1>
    <p class="home-hero-copy">A minimal index for projects, research papers, technical reports, assignments, and study notes.</p>
  </div>
</section>

<div class="home-directory">
{% for item in site.data.navigation %}
  <section class="directory-section">
    <h2>
      <span>{{ item.title }}</span>
      <a class="directory-link" href="{{ item.url | relative_url }}">View</a>
    </h2>
    <p class="directory-description">{{ item.description }}</p>

    <ul class="post-list">
      {% for child in item.children %}
        {% assign child_href = child.url %}
        {% unless child.url contains "://" %}
          {% assign child_href = child.url | relative_url %}
        {% endunless %}
        <li class="post-card">
          <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>{{ child.title }}</a>
          <p>{{ child.description }}</p>
        </li>
      {% endfor %}
    </ul>
  </section>
{% endfor %}
</div>
