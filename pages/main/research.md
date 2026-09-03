---
layout: default
title: Research
permalink: /research/
---

<h1 class="branch-logo page-branch-logo" data-label="Research">Research</h1>

{% include branch-search.html collection="research" %}

{% assign research_groups = site.research | group_by: "major_topic" | sort: "name" %}
<div class="branch-catalog">
  {% for group in research_groups %}
    <section class="branch-catalog__group" aria-labelledby="research-group-{{ forloop.index | escape }}">
      <header class="branch-catalog__heading">
        <h2 id="research-group-{{ forloop.index | escape }}">{{ group.name | escape }}</h2>
        <span>{{ group.items | size | escape }} notes</span>
      </header>
      <ul class="post-list content-catalog-list">
        {% assign research_items = group.items | sort: "title" %}
        {% for note in research_items %}
          <li class="post-card content-card">
            <a class="branch-card-link" data-label="{{ note.title | escape }}" href="{{ note.url | relative_url | escape }}">{{ note.title | escape }}</a>
            <p>{{ note.topic | escape }}</p>
            {% include content-taxonomy.html item=note mode="compact" %}
          </li>
        {% endfor %}
      </ul>
    </section>
  {% endfor %}
</div>
