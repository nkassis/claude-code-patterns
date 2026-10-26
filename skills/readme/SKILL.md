---
name: readme
description: Use when writing or revising a README.md. Commands first, principles elsewhere, no filler.
---

A README answers two questions fast: what is this, how do I use it. Everything else lives in docs/ and is linked once.

## Order

1. Title. Optional one-line tagline under it.
2. Description. Two or three sentences, then one line per top-level directory or component.
3. One link to docs/ for how it works, if there is more to say.
4. Use. Prerequisites in one line. Then command blocks: install or setup, start, apply or run. Each block runnable as pasted.
5. A table for the parts that vary (stacks, commands, modules). Tables over prose for anything with more than two columns of fact.
6. Covered or Scope. One short paragraph per area.
7. Status, only when the repo is incomplete: what works, what is a stub, what is missing.
8. Developing this repo. One or two lines pointing at AGENT.md and the tests.

## Rules

- First command within the first 20 lines.
- No paragraph longer than three sentences.
- At most one sentence before a command block, none after unless it is a next step.
- Principles, rationale, design history: not in the README. Move to docs/<topic>.md, link once.
- No headings named Overview, Introduction, Getting Started, Features, Philosophy. Use Description, Use, Covered.
- No bullet lists of adjectives. A feature is a row in a table or a sentence that says what it does.
- No roadmap. The issue tracker holds it.
- No badges except CI status, no emoji, no em dashes anywhere, including table cells and directory bullets. Empty table cells stay empty. Separate a path from its description with a plain hyphen or use a two-column table.
- Placeholders are written as {{placeholder}} and listed once under the command that needs them filled.
- When a command will change soon (a tool not yet built), write the current command and nothing about the future one.

## Check before finishing

- Read the first 20 lines as a stranger. Can they tell what it is and type the first command?
- Count paragraphs over three sentences. Should be zero.
- Search for "—". Should be zero.
