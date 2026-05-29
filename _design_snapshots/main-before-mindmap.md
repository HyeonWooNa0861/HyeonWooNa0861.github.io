---
title: Main Design Snapshot Before Mindmap
snapshot_commit: 055fe33
date: 2026-05-29
---

# Main Design Snapshot Before Mindmap

This snapshot records the rollback point before converting the main page to a mind-map layout.

Rollback reference:

```bash
git checkout 055fe33 -- pages/main/index.md _layouts/default.html
```

Original main structure:

- `pages/main/index.md`
  - `home-hero`
  - `home-logo`
  - `home-directory`
  - `directory-section`
  - horizontal `post-list` cards

Original layout behavior:

- Main branches were arranged as responsive grid sections.
- Each branch exposed child cards through horizontal drag lists.
- Random typography, card sizing, hover motion, fractured glass trim, and hidden scrollbars were already active.
