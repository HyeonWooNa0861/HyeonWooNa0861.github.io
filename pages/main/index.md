---
layout: default
title: GitBlog
permalink: /
---

<section class="home-hero">
  <div class="home-logo" role="img" aria-label="NaHW">
    <span class="logo-fragment" data-fragment="Na">Na</span>
    <span class="logo-fragment" data-fragment="H">H</span>
    <span class="logo-fragment" data-fragment="W">W</span>
  </div>
</section>

<div class="home-directory">
{% for item in site.data.navigation %}
  {% assign child_count = item.children | size %}
  {% if child_count > 0 %}
    {% assign child_group_count = child_count | minus: 1 | divided_by: 10 | plus: 1 %}
  {% else %}
    {% assign child_group_count = 1 %}
  {% endif %}
  <section class="directory-section" data-child-count="{{ child_count }}" data-child-groups="{{ child_group_count }}" style="--branch-grid-count: {{ child_group_count }}; --branch-grid-span: {{ child_group_count }};">
    <h2>
      <span class="branch-heading">
        <span class="branch-logo" data-label="{{ item.title }}">{{ item.title }}</span>
        <span class="branch-meta">{{ child_count }} item{% if child_count != 1 %}s{% endif %}</span>
      </span>
      <a class="directory-link" data-branch-modal-trigger href="{{ item.url | relative_url }}" aria-label="Open {{ item.title }} tabs only">
        <svg class="directory-plus" viewBox="0 0 32 32" aria-hidden="true" focusable="false">
          <path class="plus-axis plus-axis-horizontal" d="M7 16H25" />
          <path class="plus-axis plus-axis-vertical" d="M16 7V25" />
        </svg>
      </a>
    </h2>

    <div class="branch-grid-stack">
      {% for child in item.children %}
        {% assign group_mod = forloop.index0 | modulo: 10 %}
        {% if group_mod == 0 %}
          {% assign group_number = forloop.index0 | divided_by: 10 | plus: 1 %}
          <ul class="post-list branch-grid" data-branch-grid="{{ group_number }}">
        {% endif %}
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
        {% if group_mod == 9 or forloop.last %}
          </ul>
        {% endif %}
      {% endfor %}
    </div>
  </section>
{% endfor %}
</div>

<section class="visual-map-section" aria-label="Visual map">
  <div class="home-orbit visual-map-fit" aria-label="Visual map">
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
        {% assign child_count = item.children | size %}
        <section class="directory-section orbit-node" data-child-count="{{ child_count }}">
          <h2>
            <span class="branch-logo" data-label="{{ item.title }}">{{ item.title }}</span>
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
</section>
