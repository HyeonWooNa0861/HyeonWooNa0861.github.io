---
layout: default
title: GitBlog
permalink: /
---

<div class="home-orbit" data-orbit-viewport aria-label="Visual map">
  <div class="orbit-map" data-orbit-map>
    <section class="home-hero orbit-core" aria-label="NaHW">
      <div class="home-logo" role="img" aria-label="NaHW">
        <span class="logo-fragment" data-fragment="Na">Na</span>
        <span class="logo-fragment" data-fragment="H">H</span>
        <span class="logo-fragment" data-fragment="W">W</span>
      </div>
    </section>

    <div class="home-directory orbit-field">
    {% for item in site.data.navigation %}
      <section class="directory-section orbit-node">
        <h2>
          <span class="branch-logo" data-label="{{ item.title }}">{{ item.title }}</span>
          <span class="directory-link" aria-hidden="true">
            <svg class="directory-plus" viewBox="0 0 32 32" aria-hidden="true" focusable="false">
              <path class="plus-axis plus-axis-horizontal" d="M7 16H25" />
              <path class="plus-axis plus-axis-vertical" d="M16 7V25" />
            </svg>
          </span>
        </h2>

        <ul class="post-list orbit-links">
          {% for child in item.children %}
            <li class="post-card orbit-chip">
              <span class="orbit-chip-label">{{ child.title }}</span>
              {% if child.description %}
                <p>{{ child.description }}</p>
              {% endif %}
            </li>
          {% endfor %}
        </ul>
      </section>
    {% endfor %}
    </div>
  </div>
</div>
