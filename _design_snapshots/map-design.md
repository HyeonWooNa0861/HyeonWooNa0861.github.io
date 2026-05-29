---
title: Visual Map Modal Design
snapshot_commit: 3d988ee
date: 2026-05-29
category: map-design
---

# Visual Map Modal Design

This snapshot records the current map direction: the navigable main directory remains the default structure, while the organic map is kept as a visual-only modal.

Rollback reference:

```bash
git checkout 3d988ee -- pages/main/index.md _layouts/default.html
```

Current map structure:

- `Visual Map` opens a modal from the main page.
- The modal uses `home-orbit`, `orbit-map`, `orbit-core`, `orbit-branch`, and `orbit-chip` elements.
- Map elements are visual objects only, so they do not need to track page links.
- Organic motion, pan/zoom behavior, irregular trim, and branch clustering remain part of the visual design.

Reason for keeping this version:

- The original directory layout stays stable for navigation.
- The map can be more fluid and experimental because it no longer carries linking responsibility.
- The design direction preserves the non-linear, deconstructive visual language without hurting basic site usability.
