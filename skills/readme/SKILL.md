---
name: readme
description: Use when writing or revising README.md, and when a change adds a feature, command or component that needs documenting. Commands first, feature pages under docs/, a lint to check the budget.
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
8. Developing this repo. One or two lines pointing at AGENTS.md and the tests.

## Rules

- First command within the first 25 lines (one screen; a four-row directory table plus the docs link fits).
- No paragraph longer than three sentences.
- At most one sentence before a command block, none after unless it is a next step. A caveat about one command goes in a `#` comment on that line.
- Principles, rationale, design history: not in the README. Move to docs/<topic>.md, link once.
- No headings named Overview, Introduction, Getting Started, Features, Philosophy. Use Description, Use, Covered.
- No bullet lists of adjectives. A feature is a row in a table or a sentence that says what it does.
- No roadmap. The issue tracker holds it.
- No badges except CI status, no emoji, no em dashes anywhere, including table cells and directory bullets. Empty table cells stay empty. Separate a path from its description with a plain hyphen or use a two-column table.
- Placeholders are written as {{placeholder}} and listed once under the command that needs them filled.
- When a command will change soon (a tool not yet built), write the current command and nothing about the future one.

## Size budget

- README under 100 lines and under 10 KB (10240 bytes).
- A section about one feature is at most one table row plus one link.
- If a section needs a second paragraph, it is a docs page.

## Where things go

Consult this whenever a change adds or explains something.

| Content | Goes in |
| --- | --- |
| Command to run | README |
| What a feature checks or does | Its docs page |
| Why it is designed that way | Its docs page, or `docs/decisions.md` |
| Flags, output modes, exit codes | `docs/usage.md` |
| Config file keys | `docs/config.md` |
| Test seams, fixture regeneration, hook contracts | `AGENTS.md` |
| Recovery procedure | `docs/recovery.md` |
| Roadmap | Issue tracker |

## docs/ layout

| Page | Holds |
| --- | --- |
| `docs/usage.md` | Flags, output modes, exit codes |
| `docs/<feature>/<name>.md` or `docs/<topic>.md` | One page per feature or component, named after the thing as the CLI or README table names it |
| `docs/config.md` | The config file, when there is one |
| `docs/recovery.md` or `docs/troubleshooting.md` | How to undo or repair, when a tool can break something |
| `docs/development.md` | Contributor material that is not agent instructions. Agent instructions stay in `AGENTS.md`, linked, not duplicated |
| `docs/decisions.md` | Deviations and design choices, as `CLAUDE-global.md` requires |

Each page starts with one sentence saying what it covers and who it is for. Every top-level page is linked from README or another docs page.

## Cross-links from the tool

When a program prints findings or help text, each refers to its docs page by path (`see docs/checks/firewall.md`). Docs are then reachable from the terminal, not only from GitHub.

## Check before finishing

Run the lint from the project root. It checks the size budget, the first command block, paragraph length, banned headings, em dashes, relative links and orphan docs pages, and exits 1 with one line per finding.

```sh
~/.claude/skills/readme/readme-lint.sh README.md      # installed by install-global.sh
skills/readme/readme-lint.sh README.md                # from a claude-code-patterns checkout
```

Decision logs (`docs/decisions*.md`) are exempt from the em-dash check only. A project can wire the lint into pre-commit as a local hook.

Then read the first 25 lines as a stranger. Can they tell what it is and type the first command? The lint cannot judge that.
