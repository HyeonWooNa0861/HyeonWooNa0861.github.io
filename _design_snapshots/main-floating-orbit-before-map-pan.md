---
snapshot: main-floating-orbit-before-map-pan
source_commit: 2b3354f
created: 2026-05-29
---

# Main Floating Orbit Snapshot

This snapshot marks the state before converting the main page into a larger pannable map viewport.

The active page used a centered `home-orbit` layout where each top-level navigation group floated around the `NaHW` logo inside the visible page area.

Rollback reference:

```sh
git show 2b3354f:pages/main/index.md > pages/main/index.md
git show 2b3354f:_layouts/default.html > _layouts/default.html
```
