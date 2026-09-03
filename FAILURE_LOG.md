# Failure Log

## 2026-09-03 - Kramdown removed raw inline-math delimiters

- Symptom: deployed pages showed source expressions such as `\(Z\)` and `\(\Delta t\)` as plain `(Z)` and `(\Delta t)` instead of typeset math.
- Scope: public Markdown under `_posts`, `_research`, `_study`, `_assignment`, `pages`, and `post`; a direct `HEAD` inventory found 129 files with the affected source form (`_study` 82, `_research` 43, `_assignment` 3, `_posts` 1).
- Cause: Kramdown treats raw `\(`, `\)`, `\[`, and `\]` in Markdown source as escapes and removes their backslashes before MathJax runs. MathJax therefore receives ordinary text rather than math delimiters.
- Fix: migrated Markdown source to same-line `$$...$$` for inline math and standalone `$$` lines for display math; reduced the runtime MathJax configuration to the normalized delimiters emitted by Kramdown and changed the loader from `async` to `defer`.
- Prevention: `ruby scripts/validate_blog.rb` rejects raw delimiters, cross-line inline expressions, mixed display delimiters, unclosed blocks, malformed braces/environments, and common LaTeX escaping mistakes. `ruby scripts/test_validate_blog.rb` provides the regression suite. Do not commit or publish when either command fails.

## 2026-07-09 - MathJax double-escaped commands rendered as text

- Symptom: GitBlog page showed LaTeX command names as plain text, such as `odot` or `h^{top}`, and related superscript parsing failures.
- Scope: `_research/eptq-cikm.md`; related superscript brace fixes were also checked against `_posts/2026-05-19-kiit-summer-conference-qeco-adapt.md`.
- Cause: Markdown source used double-escaped LaTeX commands such as `\\odot`, `\\top`, and `\\widehat` inside MathJax expressions. MathJax source should use single backslash commands such as `\odot`, `\top`, and `\widehat`.
- Fix: Normalized EPTQ math source to single backslash commands and kept command superscripts braced, such as `h^{\top}` and `XX^{\top}`.
- Prevention: before posting or after math edits, run `rg -n '\\\\\\\\(odot|top|widehat|mathrm|frac|lVert|rVert|rho|tau|text|quad|leftarrow|times)' _research _posts --glob '*.md'` and inspect any matches.
