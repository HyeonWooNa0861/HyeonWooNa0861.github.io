---
layout: default
title: GitBlog
permalink: /
---

<section class="home-hero">
  <a class="home-logo" href="{{ '/' | relative_url }}" aria-label="NaHW home">
    <span class="logo-fragment" data-fragment="Na">Na</span>
    <span class="logo-fragment" data-fragment="H">H</span>
    <span class="logo-fragment" data-fragment="W">W</span>
  </a>
</section>

<div class="home-directory">
{% for item in site.data.navigation %}
  <section class="directory-section">
    <h2>
      <span class="branch-logo" data-label="{{ item.title }}">{{ item.title }}</span>
      <a class="directory-link" href="{{ item.url | relative_url }}">Index</a>
    </h2>
    {% if item.description %}
      <p class="section-description">{{ item.description }}</p>
    {% endif %}

    <ul class="post-list">
      {% for child in item.children %}
        {% assign child_href = child.url %}
        {% unless child.url contains "://" %}
          {% assign child_href = child.url | relative_url %}
        {% endunless %}
        <li class="post-card">
          <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>{{ child.title }}</a>
          {% if child.description %}
            <p>{{ child.description }}</p>
          {% endif %}
        </li>
      {% endfor %}
    </ul>
  </section>
{% endfor %}
</div>
