---
layout: default
title: Accession Log
permalink: /log/
---

{% assign accession_posts = site.posts | sort: "date" | reverse %}

<section class="index-board" data-index-board aria-labelledby="accession-log-title">
  <header class="index-masthead index-rule" data-index-rule>
    <div class="index-masthead__identity">
      <h1 id="accession-log-title" class="index-title">
        <span class="index-title__mark">NaHW</span>
        <span class="index-title__name">Accession Log</span>
      </h1>
    </div>

    <dl class="index-stats">
      <div>
        <dt>Entries</dt>
        <dd>{{ accession_posts | size }}</dd>
      </div>
    </dl>
  </header>

  <section class="recent-work index-rule" data-index-rule aria-labelledby="accession-entries-title">
    <header class="index-section-heading">
      <h2 id="accession-entries-title">All accessions</h2>
      <a href="{{ '/' | relative_url }}">Back to working index</a>
    </header>
    <ol class="recent-work__list">
      {% for post in accession_posts %}
        <li class="recent-work__item">
          <a href="{{ post.url | relative_url }}">
            <span class="recent-work__number">{{ forloop.index | prepend: '00' | slice: -2, 2 }}</span>
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
</section>
