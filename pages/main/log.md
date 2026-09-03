---
layout: default
title: Accession Log
permalink: /log/
---

{% assign accession_entries = site.posts | concat: site.research | concat: site.study | concat: site.assignment | sort: "date" | reverse %}

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
        <dd>{{ accession_entries | size | escape }}</dd>
      </div>
    </dl>
  </header>

  <section class="recent-work index-rule" data-index-rule aria-labelledby="accession-entries-title">
    <header class="index-section-heading">
      <h2 id="accession-entries-title">All accessions</h2>
      <a href="{{ '/' | relative_url }}">Back to working index</a>
    </header>
    <ol class="recent-work__list">
      {% for entry in accession_entries %}
        {% assign accession_label = entry.collection | capitalize %}
        {% if entry.collection == "posts" %}
          {% assign accession_label = entry.section | default: "Post" | replace: "-", " " %}
        {% endif %}
        <li class="recent-work__item">
          <a href="{{ entry.url | relative_url | escape }}">
            <span class="recent-work__number">{{ forloop.index | prepend: '000' | slice: -3, 3 | escape }}</span>
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
</section>
