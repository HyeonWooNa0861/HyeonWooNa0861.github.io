const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const layout = fs.readFileSync("_layouts/default.html", "utf8");

const mainScriptStart = layout.lastIndexOf("<script>");
const mainScriptEnd = layout.indexOf("</script>", mainScriptStart);
assert.notEqual(mainScriptStart, -1, "main layout script must exist");
assert.notEqual(mainScriptEnd, -1, "main layout script must close");
new vm.Script(layout.slice(mainScriptStart + "<script>".length, mainScriptEnd));

assert.doesNotMatch(layout, /Preview unavailable\?/);
assert.doesNotMatch(layout, /pdf-reader-fallback/);
assert.match(layout, /var readerPanel = null;/);
assert.match(layout, /\.pdf-reader-panel\[hidden\]\s*\{[^}]*display:\s*none\s*!important;/s);
assert.match(layout, /allowfullscreen/);
assert.match(layout, /referrerpolicy="strict-origin-when-cross-origin"/);
assert.match(layout, /allow="encrypted-media; picture-in-picture; web-share"/);
assert.doesNotMatch(layout, /allow="[^"]*\b(?:accelerometer|autoplay|gyroscope)\b/);

function between(startMarker, endMarker) {
  const start = layout.indexOf(startMarker);
  const end = layout.indexOf(endMarker, start);
  assert.notEqual(start, -1, `${startMarker} must exist`);
  assert.notEqual(end, -1, `${endMarker} must exist after ${startMarker}`);
  return layout.slice(start, end);
}

// The reader's later desktop grid must not override the mobile single column.
const readerStyles = between(
  ".page-shell.has-sidebar {\n        grid-template-columns: 210px",
  "@media (max-width: 760px)"
);
assert.match(readerStyles, /@media \(max-width: 980px\), \(hover: none\), \(pointer: coarse\)\s*\{\s*\.page-shell\.has-sidebar\s*\{[^}]*grid-template-columns:\s*minmax\(0, 1fr\);/s);
// Study uses .page-content directly; a .post-only selector misses its equations.
assert.match(readerStyles, /\.page-content mjx-container\[display="true"\]\s*\{[^}]*max-width:\s*100%;[^}]*overflow-x:\s*auto;[^}]*overflow-y:\s*hidden;/s);

// Anchor and native button text must stay centered in the same 44px mobile row.
const readerActionStyles = between(
  ".pdf-reader-open,\n      .pdf-reader-close {",
  "\n      .pdf-reader-close {\n        background:"
);
for (const declaration of ["display: inline-flex;", "align-items: center;", "justify-content: center;"]) {
  assert.ok(readerActionStyles.includes(declaration), `reader actions must share ${declaration}`);
}
assert.ok(/\.pdf-reader-open,\s*\.pdf-reader-close\s*\{\s*min-height:\s*44px;/.test(layout), "mobile reader actions must retain 44px touch targets");

// Keep the shared desktop canvas fluid; nested prose caps must not narrow it again.
const developerStyles = fs.readFileSync("assets/css/minimal-developer.css", "utf8");
assert.ok(/--content-width:\s*1680px;/.test(layout), "desktop canvas must allow 1680px");
assert.ok(/--layout-gutter:\s*clamp\(20px, 2\.5vw, 48px\);/.test(layout), "desktop gutters must scale with viewport width");
assert.ok(/\.wrap\s*\{\s*width:\s*min\(calc\(100% - 2 \* var\(--layout-gutter\)\), var\(--content-width\)\);/.test(layout), "wrappers must share the fluid canvas");
assert.ok(/\.posted-page \.page-content\s*\{\s*max-width:\s*none;/.test(layout), "posted cards must fill their grid track");
assert.ok(/\.posted-page \.post,\s*\.posted-page \.section-pager\s*\{\s*width:\s*100%;/.test(readerStyles), "posts and pagers must use the available card width");
assert.ok(!/(?:width|max-width):\s*(?:min\(100%,\s*)?(?:68|72)ch/.test(readerStyles), "nested prose caps must not narrow posts again");
assert.ok(!/width:\s*min\(100% - 48px, (?:960|1080)px\)/.test(developerStyles), "home and header must not reintroduce smaller desktop canvases");
assert.ok(/minimal-developer\.css' \| relative_url \}\}\?v=\{\{ site\.time/.test(layout), "deployed stylesheet updates must invalidate stale cached width rules");
// Narrow/coarse layouts, split reader, and embedded documents keep their own rules.
assert.ok(/@media \(max-width: 980px\), \(hover: none\), \(pointer: coarse\)\s*\{\s*\.wrap\s*\{\s*width:\s*min\(calc\(100% - 28px\), var\(--content-width\)\);/.test(layout), "narrow and coarse layouts must retain compact gutters and the shared canvas limit");
assert.ok(/body\.pdf-reader-active \.main-wrap\s*\{\s*width:\s*calc\(100% - 32px\);\s*max-width:\s*none;/.test(layout), "split reader must retain its independent full-width layout");
assert.ok(/html\[data-reader-embed="true"\] \.page-content\s*\{\s*width:\s*100%;\s*max-width:\s*none;/.test(layout), "embedded documents must retain their full-width layout");

const initialization = between("function ensureResourceReader()", "function supportsInert()");
assert.match(initialization, /readerPanel\.setAttribute\("aria-hidden", "true"\);/);
assert.match(initialization, /readerPanel\.hidden = true;/);
assert.match(initialization, />Hide<\/button>/);
assert.doesNotMatch(initialization, /Preview unavailable\?/);

const openReader = between("function openResourceReader(link, resource)", "function closeResourceReader()");
assert.match(openReader, /readerPanel\.setAttribute\("aria-hidden", "false"\);/);
assert.match(openReader, /readerPanel\.hidden = false;/);

const closeReader = between("function closeResourceReader()", "readerLinks\.forEach");
assert.match(closeReader, /readerFrame\.removeAttribute\("src"\);/);
assert.match(closeReader, /readerPanel\.setAttribute\("aria-hidden", "true"\);/);
assert.match(closeReader, /readerPanel\.hidden = true;/);
assert.match(closeReader, /document\.body\.classList\.remove\("pdf-reader-active", "pdf-reader-modal-active"\);/);

const modalFallback = between("function restoreBackgroundInteraction()", "function isReaderModalViewport()");
assert.match(modalFallback, /sibling\.setAttribute\("aria-hidden", "true"\);/);
assert.match(modalFallback, /entry\.element\.removeAttribute\("aria-hidden"\);/);
assert.match(modalFallback, /entry\.element\.setAttribute\("aria-hidden", entry\.previousAriaHidden\);/);

const helperStart = layout.indexOf("function getYouTubeEmbedUrl(url)");
const helperEnd = layout.indexOf("function isFileUrl(url)", helperStart);
assert.notEqual(helperStart, -1, "YouTube helper must exist");
assert.notEqual(helperEnd, -1, "YouTube helper boundary must exist");

const context = vm.createContext({ URL });
vm.runInContext(layout.slice(helperStart, helperEnd), context);

const cases = [
  [
    "https://www.youtube.com/watch?v=Ub3GoFaUcds",
    "https://www.youtube.com/embed/Ub3GoFaUcds?rel=0"
  ],
  [
    "https://youtu.be/Ub3GoFaUcds",
    "https://www.youtube.com/embed/Ub3GoFaUcds?rel=0"
  ],
  [
    "https://www.youtube.com/embed/Ub3GoFaUcds",
    "https://www.youtube.com/embed/Ub3GoFaUcds?rel=0"
  ],
  [
    "https://www.youtube.com/shorts/Ub3GoFaUcds",
    "https://www.youtube.com/embed/Ub3GoFaUcds?rel=0"
  ],
  [
    "https://www.youtube.com/live/Ub3GoFaUcds",
    "https://www.youtube.com/embed/Ub3GoFaUcds?rel=0"
  ],
  [
    "https://www.youtube.com/playlist?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy",
    "https://www.youtube.com/embed/videoseries?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy&rel=0"
  ],
  [
    "https://www.youtube.com/watch?v=Ub3GoFaUcds&list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy",
    "https://www.youtube.com/embed/Ub3GoFaUcds?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy&rel=0"
  ]
];

cases.forEach(([source, expected]) => {
  assert.equal(context.getYouTubeEmbedUrl(new URL(source)), expected);
});

[
  "http://www.youtube.com/watch?v=Ub3GoFaUcds",
  "https://www.youtube.com:444/watch?v=Ub3GoFaUcds",
  "https://user:pass@www.youtube.com/watch?v=Ub3GoFaUcds",
  "https://example.com/video",
  "https://www.youtube.com/watch?v=bad",
  "https://www.youtube.com/watch?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy",
  "https://www.youtube.com/playlist",
  "https://www.youtube.com/watch/?v=Ub3GoFaUcds",
  "https://www.youtube.com/channel/example?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy",
  "https://youtu.be/Ub3GoFaUcds/extra",
  "https://youtu.be/not-video?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy",
  "https://www.youtube.com/embed/Ub3GoFaUcds/extra",
  "https://www.youtube.com/playlist/extra?list=PLoROMvodv4rOCXd21gf0CF4xr35yINeOy"
].forEach((source) => {
  assert.equal(context.getYouTubeEmbedUrl(new URL(source)), null, source);
});

assert.equal(context.isPdfUrl(new URL("https://arxiv.org/pdf/2006.11239")), true);
assert.equal(context.isPdfUrl(new URL("https://www.ti.com/lit/pdf/swra841")), true);
assert.equal(context.isPdfUrl(new URL("https://example.com/download?id=paper")), false);
assert.equal(
  context.isImageUrl(new URL("https://commons.wikimedia.org/wiki/File:Example.gif")),
  false
);
assert.equal(
  context.isImageUrl(new URL("https://upload.wikimedia.org/wikipedia/commons/example.gif")),
  true
);

console.log("PASS: responsive layout guards, resource reader lifecycle, and 25 URL-classification cases");
