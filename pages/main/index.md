---
layout: default
title: HyeonWoo Na — Developer & AI Notes
permalink: /
---

{% assign recent_posts = site.posts | sort: "date" | reverse %}
{% assign accession_entries = recent_posts | concat: site.research | sort: "date" | reverse %}

<section class="index-board" data-index-board aria-labelledby="index-title">
  <header class="index-masthead index-rule" data-index-rule>
    <div class="index-masthead__identity">
      <p class="developer-eyebrow">HyeonWoo Na <span aria-hidden="true">/</span> AI &amp; Development</p>
      <h1 id="index-title" class="index-title">
        Building things.<br>Making sense of AI.
      </h1>
      <p class="developer-intro">An AI student's space for web projects, research notes, and things learned along the way.</p>
      <div class="developer-links">
        <a class="developer-primary-link" href="#selected-projects">Explore projects <span aria-hidden="true">↗</span></a>
        <a href="{{ '/about/' | relative_url }}">More about me <span aria-hidden="true">→</span></a>
      </div>
    </div>

    <form class="library-search" role="search" data-library-search>
      <label class="library-search__label" for="library-search-input">Search the archive</label>
      <div class="library-search__control">
        <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <circle cx="11" cy="11" r="6.5"></circle>
          <path d="m16 16 4 4"></path>
        </svg>
        <input id="library-search-input" type="search" role="combobox" autocomplete="off" placeholder="Search notes, topics, projects…" data-library-search-input aria-autocomplete="list" aria-haspopup="listbox" aria-controls="library-search-results" aria-describedby="library-search-status" aria-expanded="false" aria-keyshortcuts="/ ArrowUp ArrowDown Enter Escape">
        <button class="library-search__submit" type="submit">Open</button>
      </div>
      <p class="library-search__status" id="library-search-status" data-library-search-status aria-live="polite">Search projects and the public archive.</p>
      <div class="library-search__results" id="library-search-results" role="listbox" aria-label="Search results" data-library-search-results hidden>
        <ul role="presentation">
          {% for item in site.data.navigation %}
            {% if item.title == "Project" %}
              {% for child in item.children %}
                <li data-library-search-item data-search-text="Project {{ child.title | escape }} {{ child.description | default: '' | escape }}">
                  {% if child.url contains "://" %}
                  <a href="{{ child.url | escape }}" target="_blank" rel="noopener">
                  {% else %}
                  <a href="{{ child.url | relative_url | escape }}">
                  {% endif %}
                    <span data-library-search-result-title>{{ child.title | escape }}</span>
                    <small>Project{% if child.description %} · {{ child.description | escape }}{% endif %}</small>
                  </a>
                </li>
              {% endfor %}
            {% endif %}
          {% endfor %}
          {% for item in site.data.navigation %}
            {% if item.title == "Study" or item.title == "Assignment" %}
              {% for child in item.children %}
                <li data-library-search-item data-search-text="{{ item.title | escape }} {{ child.title | escape }}">
                  <a href="{{ child.url | relative_url | escape }}">
                    <span data-library-search-result-title>{{ child.title | escape }}</span>
                    <small>{{ item.title | escape }} · Protected index</small>
                  </a>
                </li>
              {% endfor %}
            {% endif %}
          {% endfor %}
          {% for post in recent_posts %}
            <li data-library-search-item data-search-text="Post {{ post.title | escape }} {{ post.section | default: '' | escape }}">
              <a href="{{ post.url | relative_url | escape }}">
                <span data-library-search-result-title>{{ post.title | escape }}</span>
                <small>Post{% if post.section %} · {{ post.section | replace: '-', ' ' | escape }}{% endif %}</small>
              </a>
            </li>
          {% endfor %}
          {% assign searchable_research = site.research | sort: "title" %}
          {% for note in searchable_research %}
            <li data-library-search-item data-search-text="Research {{ note.title | escape }} {{ note.major_topic | default: '' | escape }} {{ note.topic | default: '' | escape }} {{ note.keywords | join: ' ' | escape }}">
              <a href="{{ note.url | relative_url | escape }}">
                <span data-library-search-result-title>{{ note.title | escape }}</span>
                <small>Research{% if note.topic %} · {{ note.topic | escape }}{% endif %}</small>
              </a>
            </li>
          {% endfor %}
        </ul>
      </div>
    </form>
  </header>

  <section class="selected-projects index-rule" id="selected-projects" data-index-rule aria-labelledby="selected-projects-title">
    <header class="index-section-heading">
      <h2 id="selected-projects-title">Selected projects</h2>
      <a href="{{ '/project/' | relative_url }}">All projects <span aria-hidden="true">↗</span></a>
    </header>
    <div class="project-selection">
      {% for item in site.data.navigation %}
        {% if item.title == "Project" %}
          {% for child in item.children limit: 3 %}
            <article class="project-selection__item">
              <span class="project-selection__number" aria-hidden="true">0{{ forloop.index | escape }}</span>
              <h3><a href="{{ child.url | escape }}" target="_blank" rel="noopener noreferrer">{{ child.title | escape }} <span aria-hidden="true">↗</span><span class="developer-sr-only"> (opens in a new tab)</span></a></h3>
              <p>{{ child.description | escape }}</p>
            </article>
          {% endfor %}
        {% endif %}
      {% endfor %}
    </div>
  </section>

  <section class="recent-work index-rule" data-index-rule aria-labelledby="recent-work-title">
    <header class="index-section-heading">
      <h2 id="recent-work-title">Recent writing</h2>
      <a href="{{ '/log/' | relative_url }}">All updates <span aria-hidden="true">↗</span></a>
    </header>
    <ol class="recent-work__list">
      {% for entry in accession_entries limit: 4 %}
        {% assign accession_label = entry.collection | capitalize %}
        {% if entry.collection == "posts" %}
          {% assign accession_label = "Post" %}
        {% endif %}
        <li class="recent-work__item">
          <a href="{{ entry.url | relative_url | escape }}">
            <span class="recent-work__number">{{ forloop.index | prepend: '0' | slice: -2, 2 | escape }}</span>
            <span class="recent-work__title">{{ entry.title | escape }}</span>
            <span class="recent-work__meta">
              {{ accession_label | escape }} ·
              <time datetime="{{ entry.date | date_to_xmlschema | escape }}">{{ entry.date | date: "%Y.%m.%d" | escape }}</time>
            </span>
          </a>
        </li>
      {% endfor %}
    </ol>
  </section>

  <section class="archive-overview index-rule" data-index-rule aria-labelledby="archive-title">
    <header class="index-section-heading">
      <h2 id="archive-title">A place for everything I learn.</h2>
      <p>Explore the full archive.</p>
    </header>
    <div class="archive-overview__list">
      {% for item in site.data.navigation %}
        {% unless item.title == "Project" %}
          <a class="archive-overview__link" href="{{ item.url | relative_url | escape }}">
            <span class="archive-overview__title">{{ item.title | escape }}</span>
            <span class="archive-overview__description">
              {% case item.title %}
                {% when "Post" %}Projects, experiences, and technical notes
                {% when "Research" %}Paper readings and ideas in AI
                {% when "Study" %}Course notes and lecture reviews <small>Passcode required</small>
                {% when "Assignment" %}Worked problems and coursework <small>Passcode required</small>
              {% endcase %}
            </span>
            <span aria-hidden="true">↗</span>
          </a>
        {% endunless %}
      {% endfor %}
    </div>
  </section>

  <footer class="developer-footer">
    <span>NaHW <span aria-hidden="true">/</span> Build. Learn. Share.</span>
    <a href="https://github.com/HyeonWooNa0861" target="_blank" rel="noopener noreferrer">GitHub <span aria-hidden="true">↗</span></a>
  </footer>
</section>
