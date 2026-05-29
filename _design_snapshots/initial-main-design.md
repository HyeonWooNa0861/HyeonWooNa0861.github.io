---
title: Initial Main Design
snapshot_commit: 055fe33
date: 2026-05-29
category: initial-design
---

# Initial Main Design

This snapshot records the initial main-page structure before the mind-map and orbit-map experiments.

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
