---
name: post
description: "Create and publish GitHub Pages/Jekyll posts from provided URLs, preserving source links, local blog conventions, front matter, categories, tags, permalinks, and copyright-safe summaries. Use when the user invokes $post or asks to turn one or more URLs into a github.io blog post."
---

# Post

Use this skill to create a GitHub Pages/Jekyll blog post from one or more source URLs.

Default repository:

- `/Users/nahw/Documents/gitblog/HyeonWooNa0861.github.io`

Related local branches:

- Course material: `/Users/nahw/Documents/수업자료`
- Study material: `/Users/nahw/Documents/공부자료`
- GitBlog repository: `/Users/nahw/Documents/gitblog/HyeonWooNa0861.github.io`

## Workflow

1. Work in the default repository unless the user gives another path.
2. Read `BLOG_POSTING_GUIDELINES.md`, `_config.yml`, and a recent matching file under `_posts/`, `_research/`, `_study/`, or `_assignment/` before editing.
3. If URLs are provided, open or fetch the pages when network/browser access is available. If access is unavailable, ask the user for page text or continue only from the visible URL/title context.
4. Choose the destination:
   - Use `_posts/` for events, technical notes, trends, workshop notes, and project updates.
   - Use `_research/` for paper or research analysis.
   - Use `_study/` for lecture/exam study material.
   - Use `_assignment/` for assignment material.
5. Create a kebab-case slug and filename. For `_posts/`, use `YYYY-MM-DD-slug.md`.
6. Write front matter using existing local conventions. For ordinary posts:

```yaml
---
layout: post
title: "Post Title"
date: YYYY-MM-DD 00:00:00 +0900
categories: [Category]
tags: [Tag]
permalink: /posts/slug/
---
```

7. Write a Korean post by default. Use clear headings, concise paragraphs, and tables only when they improve scanning.
8. Preserve source links in a final `## 참고자료` section using HTML anchors:

```md
## 참고자료

<ul>
  <li><a href="https://example.com" target="_blank" rel="noopener">Source Title</a></li>
</ul>
```

9. Do not republish full copyrighted text. Summarize, paraphrase, analyze, and link to sources. Keep direct quotes short and necessary.
10. For research posts:
    - Keep full paper translations private unless the license explicitly permits redistribution.
    - Prefer Korean commentary or translation-style explanation plus source links.
    - Place source PDFs under `assets/pdfs/research/<slug>/` when a local PDF is part of the blog record.
11. Validate before finishing:
    - YAML front matter parses by inspection.
    - Markdown tables have matching pipe counts.
    - Links are present and use `target="_blank" rel="noopener"` for external sources.
    - Run `git diff --check` when files are changed.
    - Run `bundle exec jekyll build` or `jekyll build` only when the local environment supports it; otherwise state why it was skipped.

## Prompt Template

Use this template when the user asks for a reusable prompt instead of direct editing:

```text
Use $post to create a GitHub Pages/Jekyll post from the URLs below.

Repository:
/Users/nahw/Documents/gitblog/HyeonWooNa0861.github.io

Source URLs:
- [URL 1]
- [URL 2]

Post intent:
[event note / technical summary / research analysis / study note / assignment write-up]

Requirements:
- Write in Korean unless I specify another language.
- Use the existing repository conventions and BLOG_POSTING_GUIDELINES.md.
- Keep the original URLs as source links in a final 참고자료 section.
- Summarize and analyze the sources instead of copying full text.
- Create or update the appropriate Markdown file.
- Verify the result with git diff --check.
```

## Final Response

Report:

- created or updated file path
- source URLs used
- verification commands run
- skipped checks and why
