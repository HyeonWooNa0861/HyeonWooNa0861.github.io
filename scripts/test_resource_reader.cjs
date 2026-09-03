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

console.log("PASS: resource reader lifecycle and 25 URL-classification cases");
