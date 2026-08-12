---
layout: default
title: GitBlog
permalink: /
---

{% assign recent_posts = site.posts | sort: "date" | reverse %}
{% assign study_groups = site.study | group_by: "course" | sort: "name" %}
{% assign research_count = site.research | size %}
{% assign study_count = site.study | size %}
{% assign assignment_count = site.assignment | size %}
{% assign post_count = site.posts | size %}

<section class="index-board" data-index-board aria-labelledby="index-title">
  <header class="index-masthead index-rule" data-index-rule>
    <div class="index-masthead__identity">
      <h1 id="index-title" class="index-title">
        <span class="index-title__mark">NaHW</span>
        <span class="index-title__name">Working Index</span>
      </h1>
    </div>

    <dl class="index-stats">
      <div>
        <dt>Posts</dt>
        <dd>{{ post_count }}</dd>
      </div>
      <div>
        <dt>Research</dt>
        <dd>{{ research_count }}</dd>
      </div>
      <div>
        <dt>Study</dt>
        <dd>{{ study_count }}</dd>
      </div>
      <div>
        <dt>Assignments</dt>
        <dd>{{ assignment_count }}</dd>
      </div>
    </dl>

    <form class="library-search" role="search" data-library-search>
      <label class="library-search__label" for="library-search-input">Find a note or project</label>
      <div class="library-search__control">
        <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <circle cx="11" cy="11" r="6.5"></circle>
          <path d="m16 16 4 4"></path>
        </svg>
        <input id="library-search-input" type="search" autocomplete="off" placeholder="Press / to search titles, lectures, and research topics" data-library-search-input aria-controls="library-search-results" aria-keyshortcuts="/">
        <button class="library-search__submit" type="submit">Open</button>
      </div>
      <p class="library-search__status" data-library-search-status aria-live="polite">Search projects and the public archive.</p>
      <div class="library-search__results" id="library-search-results" data-library-search-results hidden>
        <ul>
          {% for item in site.data.navigation %}
            {% if item.title == "Project" %}
              {% for child in item.children %}
                {% assign child_href = child.url %}
                {% unless child.url contains "://" %}
                  {% assign child_href = child.url | relative_url %}
                {% endunless %}
                <li data-library-search-item data-search-text="Project {{ child.title | escape }} {{ child.description | default: '' | escape }}">
                  <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>
                    <span>{{ child.title }}</span>
                    <small>Project{% if child.description %} · {{ child.description }}{% endif %}</small>
                  </a>
                </li>
              {% endfor %}
            {% endif %}
          {% endfor %}
          {% for item in site.data.navigation %}
            {% if item.title == "Study" or item.title == "Assignment" %}
              {% for child in item.children %}
                <li data-library-search-item data-search-text="{{ item.title }} {{ child.title | escape }}">
                  <a href="{{ child.url | relative_url }}">
                    <span>{{ child.title }}</span>
                    <small>{{ item.title }} · Protected index</small>
                  </a>
                </li>
              {% endfor %}
            {% endif %}
          {% endfor %}
          {% for post in recent_posts %}
            <li data-library-search-item data-search-text="Post {{ post.title | escape }} {{ post.section | default: '' | escape }}">
              <a href="{{ post.url | relative_url }}">
                <span>{{ post.title }}</span>
                <small>Post{% if post.section %} · {{ post.section | replace: '-', ' ' }}{% endif %}</small>
              </a>
            </li>
          {% endfor %}
          {% assign searchable_research = site.research | sort: "title" %}
          {% for note in searchable_research %}
            <li data-library-search-item data-search-text="Research {{ note.title | escape }} {{ note.topic | default: '' | escape }}">
              <a href="{{ note.url | relative_url }}">
                <span>{{ note.title }}</span>
                <small>Research{% if note.topic %} · {{ note.topic }}{% endif %}</small>
              </a>
            </li>
          {% endfor %}
        </ul>
      </div>
    </form>
  </header>

  <section class="recent-work index-rule" data-index-rule aria-labelledby="recent-work-title">
    <header class="index-section-heading">
      <h2 id="recent-work-title">Latest accessions</h2>
      <a href="{{ '/log/' | relative_url }}">View accession log</a>
    </header>
    <ol class="recent-work__list">
      {% for post in recent_posts limit: 6 %}
        <li class="recent-work__item">
          <a href="{{ post.url | relative_url }}">
            <span class="recent-work__number">{{ forloop.index | prepend: '0' | slice: -2, 2 }}</span>
            <span class="recent-work__title">{{ post.title }}</span>
            <span class="recent-work__meta">
              {% if post.section %}{{ post.section | replace: '-', ' ' }} · {% endif %}
              <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%Y.%m.%d" }}</time>
            </span>
          </a>
        </li>
      {% endfor %}
    </ol>
  </section>

  <section class="workstreams index-rule" data-index-rule aria-labelledby="workstreams-title">
    <header class="index-section-heading">
      <h2 id="workstreams-title">Browse the library</h2>
      <p>Start with representative entry points from each branch.</p>
    </header>
    <div class="workstreams__grid">
      {% for item in site.data.navigation %}
        {% assign child_count = item.children | size %}
        <article class="workstream-card workstream-card--{{ item.title | downcase }}">
          <header class="workstream-card__header">
            <h3 class="workstream-card__heading"><a class="workstream-card__title" href="{{ item.url | relative_url }}">{{ item.title }}</a></h3>
            <span class="workstream-card__count">{{ child_count }}</span>
          </header>
          <ul class="workstream-card__links">
            {% for child in item.children limit: 4 %}
              {% assign child_href = child.url %}
              {% unless child.url contains "://" %}
                {% assign child_href = child.url | relative_url %}
              {% endunless %}
              <li>
                <a href="{{ child_href }}"{% if child.url contains "://" %} target="_blank" rel="noopener"{% endif %}>
                  <span>{{ child.title }}</span>
                  {% if child.description %}<small>{{ child.description }}</small>{% endif %}
                </a>
              </li>
            {% endfor %}
          </ul>
          {% if child_count > 4 %}
            <a class="workstream-card__more" href="{{ item.url | relative_url }}">Open {{ child_count | minus: 4 }} more</a>
          {% else %}
            <a class="workstream-card__more" href="{{ item.url | relative_url }}">Open full index</a>
          {% endif %}
        </article>
      {% endfor %}
    </div>
  </section>

  <section class="compact-archive index-rule" data-index-rule aria-labelledby="compact-archive-title">
    <header class="index-section-heading">
      <h2 id="compact-archive-title">Course shelves</h2>
      <a href="{{ '/study/' | relative_url }}">View study index</a>
    </header>
    <div class="archive-ledger">
      {% for group in study_groups %}
        {% assign course_items = group.items | sort: "order" %}
        {% assign course_latest = course_items | last %}
        {% assign course_url = '/study/' %}
        {% for nav_item in site.data.navigation %}
          {% if nav_item.title == "Study" %}
            {% for nav_child in nav_item.children %}
              {% if nav_child.title == group.name %}
                {% assign course_url = nav_child.url %}
              {% endif %}
            {% endfor %}
          {% endif %}
        {% endfor %}
        <div class="archive-ledger__row">
          <a class="archive-ledger__course" href="{{ course_url | relative_url }}">{{ group.name }}</a>
          <span class="archive-ledger__count">{{ group.items | size }} notes</span>
          <a class="archive-ledger__latest" href="{{ course_latest.url | relative_url }}">
            <span>Latest in sequence</span>
            <strong>{{ course_latest.title }}</strong>
          </a>
        </div>
      {% endfor %}
    </div>
  </section>
</section>
