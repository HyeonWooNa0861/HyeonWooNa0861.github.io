#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawnSync } = require("node:child_process");

const scanner = path.join(__dirname, "test_mathjax_tex_render.cjs");

function runScannerFiles(markdownFiles) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "gitblog-mathjax-fixture-"));
  const study = path.join(root, "_study");
  fs.mkdirSync(study);
  for (const [fileName, markdown] of Object.entries(markdownFiles)) {
    fs.writeFileSync(path.join(study, fileName), markdown);
  }

  try {
    return spawnSync(process.execPath, [scanner], {
      cwd: root,
      env: { ...process.env, BLOG_ROOT: root },
      encoding: "utf8",
    });
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function runScanner(markdown) {
  return runScannerFiles({ "fixture.md": markdown });
}

const ignoredInvalidTex = [
  "---",
  "title: Scanner fixture",
  "---",
  "",
  "Rendered formula:",
  "",
  "$$x^2 + y^2$$",
  "",
  "Inline code: `$$\\frac{1}{$$` and ``$$\\badcommand$$``.",
  "Inline code owns HTML-looking text: `<script>$$\\badcommand$$</script>`.",
  "",
  "```text",
  "$$\\frac{1}{$$",
  "```",
  "",
  "~~~text",
  "$$\\badcommand$$",
  "~~~",
  "",
  "    $$\\frac{1}{$$",
  "",
  "> ```text",
  "> $$\\badcommand$$",
  "> ```",
  "",
  "> > ~~~text",
  "> > $$\\badcommand$$",
  "> > ~~~",
  "",
  "- ```text",
  "  $$\\badcommand$$",
  "  ```",
  "",
  "- item",
  "  ```text",
  "  $$\\badcommand$$",
  "  ```",
  "",
  "- item",
  "  > ```text",
  "  > $$\\badcommand$$",
  "  > ```",
  "",
  "Term",
  ": ~~~text",
  "  $$\\badcommand$$",
  "  ~~~",
  "",
  "Text[^note]",
  "",
  "[^note]:",
  "    ~~~text",
  "    $$\\badcommand$$",
  "    ~~~",
  "",
  "> - ```text",
  ">   $$\\badcommand$$",
  ">   ```",
  "",
  ">     $$\\badcommand$$",
  "",
  "- item",
  "",
  "      $$\\badcommand$$",
  "",
  "> - item",
  ">",
  ">       $$\\badcommand$$",
  "",
  "-     $$\\badcommand$$",
  "",
  "> -     $$\\badcommand$$",
  "",
  "Definition",
  ": text",
  "",
  "      $$\\badcommand$$",
  "",
  "Inline definition",
  ":     $$\\badcommand$$",
  "",
  "Text[^code]",
  "",
  "[^code]: text",
  "",
  "        $$\\badcommand$$",
  "",
  "Text[^inline-code]",
  "",
  "[^inline-code]:     $$\\badcommand$$",
  "",
  "<!-- $$\\badcommand$$ -->",
  "",
  "<code>$$\\badcommand$$</code>",
  "<pre>$$\\badcommand$$</pre>",
  "<SCRIPT type=\"text/plain\">",
  "const tick = `$$\\badcommand$$`;",
  "$$\\badcommand$$",
  "</SCRIPT>",
  "<style>.sample::after { content: \"$$\\badcommand$$\"; }</style>",
  "<textarea>$$\\badcommand$$</textarea>",
  "",
].join("\n");

const passing = runScanner(ignoredInvalidTex);
assert.equal(passing.status, 0, passing.stderr || passing.stdout);
assert.match(passing.stdout, /rendered 1 formulas without TeX errors/);
assert.match(passing.stdout, /"_study":1/);

const failing = runScanner("$$\\frac{1}{$$");
assert.notEqual(failing.status, 0, "invalid rendered TeX must fail the scanner");
assert.match(failing.stderr, /ERROR: _study\/fixture\.md:1:/);
assert.match(failing.stderr, /FAIL: 1 MathJax TeX rendering issue/);

const containerBoundaryFailure = runScanner([
  "- ```text",
  "  code",
  "",
  "$$\\frac{1}{$$",
  "  ```",
].join("\n"));
assert.notEqual(
  containerBoundaryFailure.status,
  0,
  "a list fence must not hide rendered TeX beyond its container",
);
assert.match(containerBoundaryFailure.stderr, /ERROR: _study\/fixture\.md:4:/);

const blockquoteBoundaryFailure = runScanner([
  "> ```text",
  "> code",
  "",
  "$$\\frac{1}{$$",
  "> ```",
].join("\n"));
assert.notEqual(
  blockquoteBoundaryFailure.status,
  0,
  "a blockquote fence must not hide rendered TeX beyond its container",
);
assert.match(blockquoteBoundaryFailure.stderr, /ERROR: _study\/fixture\.md:4:/);

const paragraphInterruptionFailure = runScanner([
  "Paragraph",
  "    $$\\frac{1}{$$",
].join("\n"));
assert.notEqual(
  paragraphInterruptionFailure.status,
  0,
  "indented text interrupting a paragraph remains rendered Markdown",
);
assert.match(paragraphInterruptionFailure.stderr, /ERROR: _study\/fixture\.md:2:/);

const unknownCommand = runScanner("$$\\unknownrendercommand$$");
assert.notEqual(unknownCommand.status, 0, "unknown rendered TeX commands must fail the scanner");
assert.match(unknownCommand.stderr, /ERROR: _study\/fixture\.md:1:/);
assert.match(unknownCommand.stderr, /Undefined control sequence/);

const isolatedPages = runScannerFiles({
  "a.md": "$$\\newcommand{\\reviewmacro}{x}\\reviewmacro$$",
  "b.md": "$$\\reviewmacro$$",
});
assert.notEqual(isolatedPages.status, 0, "TeX macro definitions must not leak between pages");
assert.match(isolatedPages.stderr, /ERROR: _study\/b\.md:1:/);
assert.match(isolatedPages.stderr, /Undefined control sequence/);

const crlf = runScanner([
  "```text",
  "$$\\badcommand$$",
  "```",
  "",
  "$$\\unknownrendercommand$$",
  "",
].join("\r\n"));
assert.notEqual(crlf.status, 0, "CRLF Markdown must remain visible to the scanner");
assert.match(crlf.stderr, /ERROR: _study\/fixture\.md:5:/);

const autoloadedPackage = runScanner("$$\\cancel{x}$$");
assert.equal(autoloadedPackage.status, 0, autoloadedPackage.stderr || autoloadedPackage.stdout);

console.log("PASS: MathJax scanner ignores non-rendered Markdown and rejects invalid rendered TeX");
