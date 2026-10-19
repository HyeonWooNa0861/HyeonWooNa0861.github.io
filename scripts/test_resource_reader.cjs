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
assert.match(initialization, /data-pdf-reader-close-all[^>]*>Hide all<\/button>/);
assert.match(initialization, /data-resource-reader-picker/);
assert.doesNotMatch(initialization, /Preview unavailable\?/);

const openReader = between("function openResourceReader(link, resource)", "function closeResourceReader()");
assert.match(openReader, /readerPanel\.setAttribute\("aria-hidden", "false"\);/);
assert.match(openReader, /readerPanel\.hidden = false;/);

const closeReader = between("function closeResourceReader()", "readerLinks\.forEach");
assert.match(closeReader, /\.frame\.removeAttribute\("src"\);/);
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

// Execute the production initializer against a small DOM surface. Iframes need
// no renderer for identity, reload, focus, and independent-close assertions.
class ReaderElement {
  constructor(tagName, document) {
    this.tagName = tagName.toUpperCase();
    this.ownerDocument = document;
    this.attributes = new Map();
    this.children = [];
    this.parentElement = null;
    this.listeners = new Map();
    this.dataset = {};
    this.hidden = false;
    this.disabled = false;
    this._text = "";
    this.srcWrites = 0;
    this.classList = {
      contains: (name) => this.className.split(/\s+/).includes(name),
      add: (...names) => { this.className = Array.from(new Set([...this.className.split(/\s+/).filter(Boolean), ...names])).join(" "); },
      remove: (...names) => { this.className = this.className.split(/\s+/).filter((name) => !names.includes(name)).join(" "); },
      toggle: (name, force) => {
        const enabled = force === undefined ? !this.classList.contains(name) : Boolean(force);
        if (enabled) this.classList.add(name); else this.classList.remove(name);
        return enabled;
      }
    };
  }
  setAttribute(name, value) {
    this.attributes.set(name, String(value));
    if (name === "src") this.srcWrites += 1;
    if (name.startsWith("data-")) this.dataset[name.slice(5).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = String(value);
    if (name === "disabled") this.disabled = true;
  }
  getAttribute(name) { return this.attributes.has(name) ? this.attributes.get(name) : null; }
  hasAttribute(name) { return this.attributes.has(name); }
  removeAttribute(name) {
    this.attributes.delete(name);
    if (name === "disabled") this.disabled = false;
    if (name.startsWith("data-")) delete this.dataset[name.slice(5).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())];
  }
  get className() { return this.getAttribute("class") || ""; }
  set className(value) { this.setAttribute("class", value); }
  get src() { return this.getAttribute("src") || ""; }
  set src(value) { this.setAttribute("src", value); }
  get href() { return this.getAttribute("href") || ""; }
  set href(value) { this.setAttribute("href", value); }
  get value() { return this.getAttribute("value") || ""; }
  set value(value) { this.setAttribute("value", value); }
  get inert() { return this.hasAttribute("inert"); }
  set inert(value) { if (value) this.setAttribute("inert", ""); else this.removeAttribute("inert"); }
  get textContent() { return this._text + this.children.map((child) => child.textContent).join(""); }
  set textContent(value) { this._text = String(value); this.replaceChildren(); }
  get options() { return this.querySelectorAll("option"); }
  get isConnected() { return this.ownerDocument.contains(this); }
  appendChild(child) {
    if (child.parentElement) child.remove();
    child.parentElement = this;
    this.children.push(child);
    return child;
  }
  removeChild(child) {
    const index = this.children.indexOf(child);
    if (index !== -1) this.children.splice(index, 1);
    child.parentElement = null;
    return child;
  }
  replaceChildren() { this.children.slice().forEach((child) => this.removeChild(child)); }
  remove() { if (this.parentElement) this.parentElement.removeChild(this); }
  contains(element) { return this === element || this.children.some((child) => child.contains(element)); }
  addEventListener(type, listener) {
    if (!this.listeners.has(type)) this.listeners.set(type, []);
    this.listeners.get(type).push(listener);
  }
  dispatch(type, properties = {}) {
    const event = { type, target: this, button: 0, defaultPrevented: false,
      preventDefault() { this.defaultPrevented = true; }, ...properties };
    (this.listeners.get(type) || []).forEach((listener) => listener(event));
    return event;
  }
  focus() { this.ownerDocument.activeElement = this; }
  scrollIntoView() {}
  matches(selector) {
    return selector.split(",").some((part) => {
      let current = part.trim();
      const exclusions = [...current.matchAll(/:not\(([^)]+)\)/g)].map((match) => match[1]);
      current = current.replace(/:not\([^)]+\)/g, "");
      if (exclusions.some((excluded) => this.matches(excluded))) return false;
      const tag = current.match(/^[a-z][\w-]*/i);
      if (tag && this.tagName !== tag[0].toUpperCase()) return false;
      for (const match of current.matchAll(/\.([\w-]+)/g)) if (!this.classList.contains(match[1])) return false;
      for (const match of current.matchAll(/\[([^\]=]+)(?:=["']?([^\]"']*)["']?)?\]/g)) {
        if (!this.hasAttribute(match[1])) return false;
        if (match[2] !== undefined && this.getAttribute(match[1]) !== match[2]) return false;
      }
      return true;
    });
  }
  closest(selector) { return this.matches(selector) ? this : this.parentElement?.closest(selector) || null; }
  querySelectorAll(selector) {
    const found = [];
    this.children.forEach((child) => {
      if (child.matches(selector)) found.push(child);
      found.push(...child.querySelectorAll(selector));
    });
    return found;
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  set innerHTML(markup) {
    this.replaceChildren();
    this._text = "";
    const stack = [this];
    for (const token of markup.match(/<[^>]+>|[^<]+/g) || []) {
      if (token.startsWith("</")) { stack.pop(); continue; }
      if (!token.startsWith("<")) { stack.at(-1)._text += token; continue; }
      const tag = token.match(/^<([\w-]+)/)?.[1];
      if (!tag) continue;
      const child = this.ownerDocument.createElement(tag);
      const attributes = token.slice(tag.length + 1, -1);
      for (const match of attributes.matchAll(/([^\s=/>]+)(?:="([^"]*)"|='([^']*)'|=([^\s>]+))?/g)) {
        child.setAttribute(match[1], match[2] ?? match[3] ?? match[4] ?? "");
      }
      stack.at(-1).appendChild(child);
      if (!/\/$/.test(attributes) && !["input", "img", "br", "hr", "meta", "link"].includes(tag)) stack.push(child);
    }
  }
}

function readerFixture({ modal = false, inert = true } = {}) {
  const document = {
    activeElement: null,
    listeners: new Map(),
    createElement(tagName) { return new ReaderElement(tagName, this); },
    contains(element) { return this.documentElement.contains(element); },
    querySelector(selector) { return this.documentElement.querySelector(selector); },
    addEventListener: ReaderElement.prototype.addEventListener,
    dispatch: ReaderElement.prototype.dispatch
  };
  document.documentElement = document.createElement("html");
  document.body = document.createElement("body");
  document.documentElement.appendChild(document.body);
  const background = document.createElement("header");
  background.setAttribute("aria-hidden", "false");
  document.body.appendChild(background);
  const shell = document.createElement("main");
  shell.className = "page-shell";
  document.body.appendChild(shell);
  const content = document.createElement("article");
  content.className = "page-content";
  shell.appendChild(content);
  const links = ["/assets/pdfs/first.pdf", "/assets/pdfs/second.pdf", "/assets/pdfs/first.pdf", "/study/another-note/"].map((href, index) => {
    const link = document.createElement("a");
    link.href = href;
    link.textContent = `Resource ${index + 1}`;
    content.appendChild(link);
    return link;
  });
  const searchResults = document.createElement("div");
  searchResults.setAttribute("data-library-search-results", "");
  const searchLink = document.createElement("a");
  searchLink.href = "/study/search-result/";
  searchResults.appendChild(searchLink);
  content.appendChild(searchResults);
  const mediaListeners = [];
  const media = { matches: modal, addEventListener(type, listener) { mediaListeners.push(listener); } };
  class FixtureHTMLElement {}
  if (inert) Object.defineProperty(FixtureHTMLElement.prototype, "inert", { writable: true, value: false });
  const window = {
    location: new URL("https://hyeonwoona0861.github.io/study/example/"),
    matchMedia() { return media; }
  };
  const readerStart = layout.indexOf("function initResourceReader()");
  const readerEnd = layout.indexOf("\n        initResourceReader();", readerStart);
  assert.notEqual(readerStart, -1);
  assert.notEqual(readerEnd, -1);
  vm.runInNewContext(`${layout.slice(readerStart, readerEnd)}\ninitResourceReader();`, { document, window, URL, HTMLElement: FixtureHTMLElement });
  return {
    document, content, links, background, searchLink,
    panel: () => document.querySelector("[data-pdf-reader-panel]"),
    frames: () => shell.querySelectorAll("[data-pdf-reader-frame]"),
    closeButtons: () => shell.querySelectorAll("[data-pdf-reader-close]"),
    setModal(matches) { media.matches = matches; mediaListeners.forEach((listener) => listener()); }
  };
}

const desktop = readerFixture();
assert.equal(desktop.links[0].dispatch("click", { ctrlKey: true }).defaultPrevented, false, "modified clicks must retain native browser behavior");
assert.equal(desktop.panel(), null);
desktop.links[0].dispatch("click");
assert.equal(desktop.searchLink.dispatch("click").defaultPrevented, false, "search-result links must retain normal navigation");
assert.equal(desktop.searchLink.hasAttribute("data-pdf-reader-link"), false);
assert.ok(desktop.panel().querySelector("[data-resource-reader-picker]").options.every((option) => !option.value.endsWith("/study/search-result/")), "search-result links must not appear in the resource picker");
const firstFrame = desktop.frames()[0];
assert.equal(firstFrame.src, "https://hyeonwoona0861.github.io/assets/pdfs/first.pdf");
assert.equal(desktop.panel().hidden, false);
assert.equal(desktop.panel().getAttribute("aria-hidden"), "false");
desktop.links[1].dispatch("click");
assert.equal(desktop.frames().length, 2, "opening another source must retain both iframe nodes");
assert.equal(desktop.frames()[0], firstFrame, "opening another source must retain the first iframe identity");
const secondFrame = desktop.frames()[1];
assert.equal(firstFrame.srcWrites, 1, "opening another source must not reload the first resource");
assert.equal(desktop.document.body.getAttribute("data-reader-count"), "2");
assert.equal(desktop.links[0].getAttribute("aria-expanded"), "true");
assert.equal(desktop.links[2].getAttribute("aria-expanded"), "true", "duplicate source links must reflect the same open resource");
desktop.links[2].dispatch("click");
assert.equal(desktop.frames().length, 2, "the same source must not produce a duplicate frame");
assert.equal(firstFrame.srcWrites, 1, "reopening an existing source must preserve its navigation state");
assert.equal(desktop.document.activeElement, desktop.closeButtons()[0]);
desktop.closeButtons()[0].dispatch("click");
assert.equal(firstFrame.hasAttribute("src"), false, "individual removal must unload only the removed iframe");
assert.equal(firstFrame.isConnected, false);
assert.equal(desktop.frames().length, 1);
assert.equal(desktop.frames()[0], secondFrame);
assert.equal(secondFrame.srcWrites, 1, "removing one resource must not reload another");
assert.equal(desktop.links[0].getAttribute("aria-expanded"), "false");
assert.equal(desktop.links[1].getAttribute("aria-expanded"), "true");
desktop.panel().querySelector("[data-pdf-reader-close-all]").dispatch("click");
assert.equal(secondFrame.hasAttribute("src"), false);
assert.equal(desktop.frames().length, 0);
assert.equal(desktop.panel().hidden, true);
assert.equal(desktop.panel().getAttribute("aria-hidden"), "true");
assert.equal(desktop.document.body.classList.contains("pdf-reader-active"), false);
assert.equal(desktop.document.body.hasAttribute("data-reader-count"), false);
assert.ok(desktop.panel().querySelector("[data-resource-reader-picker]").options.every((option) => !option.disabled));
assert.equal(desktop.document.activeElement, desktop.links[2], "Hide all must restore the most recent source trigger");
desktop.links[0].dispatch("click");
assert.equal(desktop.frames().length, 1, "the reader must reopen cleanly after Hide all");
assert.notEqual(desktop.frames()[0], firstFrame);
desktop.document.dispatch("keydown", { key: "Escape" });

const mobile = readerFixture({ modal: true });
mobile.links[0].dispatch("click");
assert.equal(mobile.panel().getAttribute("aria-modal"), "true");
assert.equal(mobile.content.inert, true);
assert.equal(mobile.background.inert, true);
const picker = mobile.panel().querySelector("[data-resource-reader-picker]");
assert.ok(picker, "a modal reader needs an internal picker to open additional sources");
assert.equal(picker.options.length, 4, "picker must deduplicate three unique sources plus its prompt");
assert.equal(picker.options.find((option) => option.value.endsWith("first.pdf")).disabled, true);
picker.value = "https://hyeonwoona0861.github.io/assets/pdfs/second.pdf";
picker.dispatch("change");
assert.equal(mobile.frames().length, 2, "the internal picker must add a resource while background links are inert");
assert.equal(picker.value, "");
assert.equal(mobile.document.activeElement, mobile.closeButtons()[1]);
assert.equal(mobile.panel().getAttribute("aria-modal"), "true");
mobile.document.dispatch("focusin", { target: mobile.links[0] });
assert.equal(mobile.document.activeElement, mobile.panel().querySelector("[data-pdf-reader-close-all]"), "focus leaving the modal must return to its controls");
const focusable = mobile.panel().querySelectorAll('a[href], button:not([disabled]), select:not([disabled]), iframe, [tabindex]:not([tabindex="-1"])');
assert.ok(focusable.includes(picker));
focusable.at(-1).focus();
const wrap = mobile.document.dispatch("keydown", { key: "Tab" });
assert.equal(wrap.defaultPrevented, true, "Tab at the final control must wrap inside the modal");
assert.equal(mobile.document.activeElement, focusable[0]);
const twoMobileFrames = mobile.frames();
mobile.setModal(false);
assert.equal(mobile.panel().hasAttribute("aria-modal"), false);
assert.equal(mobile.content.inert, false, "desktop resize must restore background interactivity");
assert.equal(mobile.background.inert, false);
assert.deepEqual(mobile.frames(), twoMobileFrames, "resize must preserve iframe identities");
mobile.setModal(true);
assert.equal(mobile.content.inert, true);
mobile.document.dispatch("keydown", { key: "Escape" });
assert.equal(mobile.panel().hidden, true);
assert.equal(mobile.content.inert, false);
assert.equal(mobile.background.inert, false);
twoMobileFrames.forEach((frame) => assert.equal(frame.hasAttribute("src"), false));

const fallback = readerFixture({ modal: true, inert: false });
fallback.links[0].dispatch("click");
assert.equal(fallback.content.getAttribute("aria-hidden"), "true");
assert.equal(fallback.background.getAttribute("aria-hidden"), "true");
fallback.closeButtons()[0].dispatch("click");
assert.equal(fallback.panel().hidden, true, "removing the final card must close the reader");
assert.equal(fallback.content.hasAttribute("aria-hidden"), false);
assert.equal(fallback.background.getAttribute("aria-hidden"), "false", "fallback must restore pre-existing ARIA state");
assert.equal(fallback.document.activeElement, fallback.links[0]);

const previouslyInert = readerFixture({ modal: true });
previouslyInert.background.inert = true;
previouslyInert.links[0].dispatch("click");
previouslyInert.document.querySelector("[data-pdf-reader-backdrop]").dispatch("click");
assert.equal(previouslyInert.panel().hidden, true, "the backdrop must close every resource");
assert.equal(previouslyInert.background.inert, true, "closing the modal must preserve an already-inert background");
assert.equal(previouslyInert.content.inert, false);

console.log("PASS: independent multi-resource lifecycle, mobile picker/focus/inert/resize, responsive layout guards, and 25 URL-classification cases");
