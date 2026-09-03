#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const { mathjax } = require("mathjax-full/js/mathjax.js");
const { TeX } = require("mathjax-full/js/input/tex.js");
const { CHTML } = require("mathjax-full/js/output/chtml.js");
const { liteAdaptor } = require("mathjax-full/js/adaptors/liteAdaptor.js");
const { RegisterHTMLHandler } = require("mathjax-full/js/handlers/html.js");
const { AllPackages } = require("mathjax-full/js/input/tex/AllPackages.js");

const root = path.resolve(process.env.BLOG_ROOT || path.join(__dirname, ".."));
const publicRoots = ["_posts", "_research", "_study", "_assignment", "pages", "post"];
const texChtmlAutoloadEquivalent = [
  "base",
  "ams",
  "newcommand",
  "configmacros",
  "action",
  "amscd",
  "bbox",
  "boldsymbol",
  "braket",
  "cancel",
  "color",
  "enclose",
  "extpfeil",
  "html",
  "mhchem",
  "unicode",
  "verb",
];
const files = [];

const missingPackages = texChtmlAutoloadEquivalent.filter((name) => !AllPackages.includes(name));
if (missingPackages.length) {
  throw new Error(`mathjax-full is missing expected tex-chtml packages: ${missingPackages.join(", ")}`);
}

function walk(directory) {
  if (!fs.existsSync(directory)) return;

  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) walk(fullPath);
    if (entry.isFile() && entry.name.endsWith(".md")) files.push(fullPath);
  }
}

function maskRange(source, start, end) {
  return source.slice(start, end).replace(/[^\n]/g, " ");
}

function maskLine(line) {
  return line.replace(/[^\r\n]/g, " ");
}

function indentationWidth(text) {
  let width = 0;
  for (const character of text) {
    width += character === "\t" ? 4 - (width % 4) : 1;
  }
  return width;
}

function stripIndentation(source, requiredWidth) {
  let index = 0;
  let width = 0;
  while (width < requiredWidth && index < source.length) {
    const character = source[index];
    if (character !== " " && character !== "\t") break;
    width += character === "\t" ? 4 - (width % 4) : 1;
    index += 1;
  }
  if (source.trim() === "") return "";
  return width < requiredWidth ? null : source.slice(index);
}

function fenceContainerContent(line, contexts) {
  let source = line.replace(/\r?\n$/, "");
  for (const context of contexts) {
    if (context.type === "blockquote") {
      const quote = source.match(/^ {0,3}>[ \t]?/);
      if (!quote) return null;
      source = source.slice(quote[0].length);
    } else {
      source = stripIndentation(source, context.indentation);
      if (source === null) return null;
    }
  }
  return source;
}

function definitionListTermBefore(lines, index, contexts) {
  let blankSeen = false;
  for (let candidate = index - 1; candidate >= 0; candidate -= 1) {
    const previous = fenceContainerContent(lines[candidate], contexts);
    if (previous === null) return false;
    if (previous.trim() === "") {
      if (blankSeen) return false;
      blankSeen = true;
      continue;
    }

    const stripped = previous.trimStart();
    if (/^(?: {4,}|\t)/.test(previous)) return false;
    if (/^(?:#{1,6}[ \t]|>|(?:[-+*]|\d+\.)[ \t]+|:[ \t]+|\[\^[^\]]+\]:|\[.*\]:|<|\{::)/.test(stripped)) {
      return false;
    }
    return true;
  }
  return false;
}

function activeListIndentation(lines, index, contexts, source) {
  const leadingWidth = indentationWidth(source.match(/^[ \t]*/)[0]);
  if (leadingWidth === 0) return null;

  for (let candidate = index - 1; candidate >= 0; candidate -= 1) {
    const previous = fenceContainerContent(lines[candidate], contexts);
    if (previous === null) break;
    if (previous.trim() === "") continue;

    let container = previous.match(/^( {0,3}(?:[-+*]|\d+\.)[ \t]+)/);
    if (!container && definitionListTermBefore(lines, candidate, contexts)) {
      container = previous.match(/^( {0,3}:[ \t]+)/);
    }
    if (container) {
      const containerWidth = indentationWidth(container[1]);
      if (leadingWidth >= containerWidth && leadingWidth - containerWidth <= 3) {
        return containerWidth;
      }
    }

    if (/^ {0,3}\[\^[^\]\n]+\]:/.test(previous)) {
      if (leadingWidth >= 4 && leadingWidth - 4 <= 3) return 4;
    }

    if (indentationWidth(previous.match(/^[ \t]*/)[0]) === 0) break;
  }
  return null;
}

function fenceMarker(source) {
  const match = source.match(/^ {0,3}(`{3,}|~{3,})(.*)$/);
  if (!match) return null;
  const trailing = match[2].trim();
  if (trailing !== "" && !/^\S+$/.test(trailing)) return null;
  return { character: match[1][0], length: match[1].length };
}

function fencedCodeOpening(lines, index) {
  let source = lines[index].replace(/\r?\n$/, "");
  if (!/(?:`{3,}|~{3,})/.test(source)) return null;
  const contexts = [];

  while (true) {
    const listIndentation = activeListIndentation(lines, index, contexts, source);
    if (listIndentation !== null) {
      contexts.push({ type: "list", indentation: listIndentation });
      source = stripIndentation(source, listIndentation);
      continue;
    }

    const quote = source.match(/^ {0,3}>[ \t]?/);
    if (quote) {
      contexts.push({ type: "blockquote" });
      source = source.slice(quote[0].length);
      continue;
    }

    const list = source.match(/^(?<prefix> {0,3}(?:[-+*]|\d+\.)[ \t]+)(?<content>.*)$/);
    if (list) {
      contexts.push({ type: "list", indentation: indentationWidth(list.groups.prefix) });
      source = list.groups.content;
      continue;
    }

    const definition = source.match(/^(?<prefix> {0,3}:[ \t]+)(?<content>.*)$/);
    if (definition && definitionListTermBefore(lines, index, contexts)) {
      contexts.push({ type: "list", indentation: indentationWidth(definition.groups.prefix) });
      source = definition.groups.content;
      continue;
    }

    const footnote = source.match(/^ {0,3}\[\^[^\]\n]+\]:[ \t]*(?<content>.*)$/);
    if (footnote) {
      contexts.push({ type: "list", indentation: 4 });
      source = footnote.groups.content;
      continue;
    }
    break;
  }

  const marker = fenceMarker(source);
  return marker ? { contexts, ...marker } : null;
}

function neutralizeBlockFenceMarker(line) {
  const match = line.match(/^[ \t>]*(?:(?:(?:[-+*]|\d+\.|:)|\[\^[^\]\n]+\]:)[ \t]+)?[ \t]*(?<marker>`{3,}|~{3,})/);
  if (!match) return line;
  const start = match.index + match[0].lastIndexOf(match.groups.marker);
  return `${line.slice(0, start)}${" ".repeat(match.groups.marker.length)}${line.slice(start + match.groups.marker.length)}`;
}

function maskFencedCode(source) {
  const lines = source.match(/[^\n]*(?:\n|$)/g) || [];
  const result = [...lines];
  let index = 0;

  while (index < lines.length) {
    const opening = fencedCodeOpening(lines, index);
    if (!opening) {
      result[index] = neutralizeBlockFenceMarker(lines[index]);
      index += 1;
      continue;
    }

    let closing = null;
    for (let candidate = index + 1; candidate < lines.length; candidate += 1) {
      const content = fenceContainerContent(lines[candidate], opening.contexts);
      if (content === null) break;
      const closingPattern = new RegExp(
        `^ {0,3}${opening.character === "`" ? "`" : "~"}{${opening.length},}[ \\t]*$`,
      );
      if (closingPattern.test(content)) {
        closing = candidate;
        break;
      }
    }

    if (closing === null) {
      result[index] = neutralizeBlockFenceMarker(lines[index]);
      index += 1;
      continue;
    }

    for (let masked = index; masked <= closing; masked += 1) {
      result[masked] = maskLine(lines[masked]);
    }
    index = closing + 1;
  }
  return result.join("");
}

function blockquoteRemainder(line) {
  let source = line.replace(/\r?\n$/, "");
  let depth = 0;
  while (true) {
    const quote = source.match(/^ {0,3}>[ \t]?/);
    if (!quote) break;
    depth += 1;
    source = source.slice(quote[0].length);
  }
  return { depth, source };
}

function listContainerWidth(lines, index, quoteDepth) {
  const quoteContexts = Array.from({ length: quoteDepth }, () => ({ type: "blockquote" }));
  for (let candidate = index - 1; candidate >= 0; candidate -= 1) {
    const previous = blockquoteRemainder(lines[candidate]);
    if (previous.depth !== quoteDepth) break;
    if (previous.source.trim() === "") continue;

    const list = previous.source.match(/^( {0,3}(?:[-+*]|\d+\.)[ \t]+)/);
    if (list) return indentationWidth(list[1]);
    if (definitionListTermBefore(lines, candidate, quoteContexts)) {
      const definition = previous.source.match(/^( {0,3}:[ \t]+)/);
      if (definition) return indentationWidth(definition[1]);
    }
    if (/^ {0,3}\[\^[^\]\n]+\]:/.test(previous.source)) return 4;

    if (indentationWidth(previous.source.match(/^[ \t]*/)[0]) === 0) break;
  }
  return null;
}

function maskIndentedCode(source) {
  const lines = source.match(/[^\n]*(?:\n|$)/g) || [];
  const result = [...lines];
  const active = new Map();

  lines.forEach((line, index) => {
    const current = blockquoteRemainder(line);
    const blank = current.source.trim() === "";
    const leadingWidth = indentationWidth(current.source.match(/^[ \t]*/)[0]);
    const activeWidth = active.get(current.depth);
    const listWidth = leadingWidth >= 4 && activeWidth === undefined
      ? listContainerWidth(lines, index, current.depth)
      : null;
    const requiredWidth = listWidth === null ? 4 : listWidth + 4;
    const listMarker = current.source.match(/^(?<marker> {0,3}(?:[-+*]|\d+\.))(?<spacing>[ \t]+).*$/);
    const quoteContexts = Array.from({ length: current.depth }, () => ({ type: "blockquote" }));
    const definitionCandidate = current.source.match(/^(?<marker> {0,3}:)(?<spacing>[ \t]+).*$/);
    const definitionMarker = definitionCandidate && definitionListTermBefore(lines, index, quoteContexts)
      ? definitionCandidate
      : null;
    const footnoteMarker = current.source.match(/^(?<marker> {0,3}\[\^[^\]\n]+\]:)(?<spacing>[ \t]+).*$/);
    const inlineMarker = listMarker || definitionMarker || footnoteMarker;
    const inlineCode = inlineMarker && indentationWidth(inlineMarker.groups.spacing) >= 5;
    const previous = index > 0 ? blockquoteRemainder(lines[index - 1]) : { depth: current.depth, source: "" };
    const mayStart = index === 0 || previous.depth !== current.depth || previous.source.trim() === "";

    if (blank) {
      if (activeWidth !== undefined) result[index] = maskLine(line);
    } else if (inlineCode) {
      active.set(
        current.depth,
        indentationWidth(inlineMarker.groups.marker) + indentationWidth(inlineMarker.groups.spacing),
      );
      result[index] = maskLine(line);
    } else if (activeWidth !== undefined && leadingWidth >= activeWidth) {
      result[index] = maskLine(line);
    } else if (leadingWidth >= requiredWidth && mayStart) {
      active.set(current.depth, requiredWidth);
      result[index] = maskLine(line);
    } else {
      active.delete(current.depth);
    }
  });
  return result.join("");
}

function maskMarkdownCodeBlocks(source) {
  return maskIndentedCode(maskFencedCode(source));
}

function maskInlineNonRenderedContent(source) {
  let result = "";
  let cursor = 0;

  function isEscaped(index) {
    let backslashes = 0;
    for (let position = index - 1; position >= 0 && source[position] === "\\"; position -= 1) {
      backslashes += 1;
    }
    return backslashes % 2 === 1;
  }

  function findClosingCodeDelimiter(delimiter, start) {
    let candidate = source.indexOf(delimiter, start);
    while (candidate !== -1) {
      const hasAdjacentBacktick =
        source[candidate - 1] === "`" || source[candidate + delimiter.length] === "`";
      if (!hasAdjacentBacktick) return candidate;
      candidate = source.indexOf(delimiter, candidate + delimiter.length);
    }
    return -1;
  }

  while (cursor < source.length) {
    if (source.startsWith("<!--", cursor)) {
      const closing = source.indexOf("-->", cursor + 4);
      const end = closing === -1 ? source.length : closing + 3;
      result += maskRange(source, cursor, end);
      cursor = end;
      continue;
    }

    if (source[cursor] === "<") {
      const opening = source
        .slice(cursor)
        .match(/^<(code|pre|script|style|textarea)\b[^>]*>/i);
      if (opening) {
        const openingEnd = cursor + opening[0].length;
        if (/\/\s*>$/.test(opening[0])) {
          result += maskRange(source, cursor, openingEnd);
          cursor = openingEnd;
          continue;
        }

        const closingPattern = new RegExp(`<\\/${opening[1]}\\s*>`, "gi");
        closingPattern.lastIndex = openingEnd;
        const closing = closingPattern.exec(source);
        const end = closing ? closing.index + closing[0].length : source.length;
        result += maskRange(source, cursor, end);
        cursor = end;
        continue;
      }
    }

    if (source[cursor] !== "`" || isEscaped(cursor)) {
      result += source[cursor];
      cursor += 1;
      continue;
    }

    let runEnd = cursor;
    while (source[runEnd] === "`") runEnd += 1;
    const delimiter = source.slice(cursor, runEnd);
    const closing = findClosingCodeDelimiter(delimiter, runEnd);

    if (closing === -1) {
      result += delimiter;
      cursor = runEnd;
      continue;
    }

    const end = closing + delimiter.length;
    result += maskRange(source, cursor, end);
    cursor = end;
  }

  return result;
}

function maskNonRenderedMarkdown(source) {
  return maskInlineNonRenderedContent(maskMarkdownCodeBlocks(source));
}

for (const publicRoot of publicRoots) walk(path.join(root, publicRoot));

const adaptor = liteAdaptor();
RegisterHTMLHandler(adaptor);
const counts = Object.fromEntries(publicRoots.map((publicRoot) => [publicRoot, 0]));
const failures = [];

function createMathDocument() {
  const input = new TeX({
    packages: texChtmlAutoloadEquivalent,
    formatError(_jax, error) {
      throw error;
    },
  });
  const output = new CHTML({ fontURL: "" });
  return mathjax.document("", { InputJax: input, OutputJax: output });
}

for (const file of files.sort()) {
  const document = createMathDocument();
  const source = maskNonRenderedMarkdown(fs.readFileSync(file, "utf8"));
  const relative = path.relative(root, file);
  const collection = relative.split(path.sep)[0];
  const formulaPattern = /\$\$([\s\S]*?)\$\$/g;
  let match;

  while ((match = formulaPattern.exec(source))) {
    const formula = match[1].trim();
    const line = source.slice(0, match.index).split("\n").length;
    counts[collection] += 1;

    try {
      const node = document.convert(formula, { display: match[0].includes("\n") });
      const rendered = adaptor.outerHTML(node);
      if (rendered.includes("mjx-merror") || rendered.includes("data-mjx-error")) {
        failures.push(`${relative}:${line}: MathJax emitted an error node`);
      }
    } catch (error) {
      failures.push(`${relative}:${line}: ${error.message}`);
    }
  }
}

const total = Object.values(counts).reduce((sum, count) => sum + count, 0);
if (failures.length === 0) {
  console.log(`PASS: MathJax 3.2.2 rendered ${total} formulas without TeX errors`);
  console.log(JSON.stringify(counts));
  process.exit(0);
}

for (const failure of failures) console.error(`ERROR: ${failure}`);
console.error(`FAIL: ${failures.length} MathJax TeX rendering issue(s) across ${total} formulas`);
process.exit(1);
