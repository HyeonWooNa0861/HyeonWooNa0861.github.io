---
title: Main Index Board Snapshot Before Orbit
snapshot_commit: 0260830
date: 2026-05-29
---

# Main Index Board Snapshot Before Orbit

This snapshot records the asymmetric index board before converting the main page to a floating radial orbit layout.

Rollback reference:

```bash
git checkout 0260830 -- pages/main/index.md _layouts/default.html
```

Index board structure:

- `home-index-board`
- sticky `NaHW` core on the left
- stacked branch sections on the right
- horizontal child card lists inside each branch

Reason for replacement:

- The user requested a non-slide radial structure where branch cards float around the main logo.
