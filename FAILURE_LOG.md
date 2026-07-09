# Failure Log

## 2026-07-09 - MathJax double-escaped commands rendered as text

- Symptom: GitBlog page showed LaTeX command names as plain text, such as `odot` or `h^{top}`, and related superscript parsing failures.
- Scope: `_research/eptq-cikm.md`; related superscript brace fixes were also checked against `_posts/2026-05-19-kiit-summer-conference-qeco-adapt.md`.
- Cause: Markdown source used double-escaped LaTeX commands such as `\\odot`, `\\top`, and `\\widehat` inside MathJax expressions. MathJax source should use single backslash commands such as `\odot`, `\top`, and `\widehat`.
- Fix: Normalized EPTQ math source to single backslash commands and kept command superscripts braced, such as `h^{\top}` and `XX^{\top}`.
- Prevention: before posting or after math edits, run `rg -n '\\\\\\\\(odot|top|widehat|mathrm|frac|lVert|rVert|rho|tau|text|quad|leftarrow|times)' _research _posts --glob '*.md'` and inspect any matches.
