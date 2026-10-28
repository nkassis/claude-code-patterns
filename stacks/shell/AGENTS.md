# {{PROJECT}}

{{One paragraph: what these scripts do and where they run.}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root.

## Stack

- Bash {{5}}. Scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`.
- 4-space indent (`shfmt -i 4 -ci` if installed).
- Scripts in `scripts/` source `.env.local` if it exists. Config resolution: env already set > `.env.local` > tool fallbacks. Never hardcode URLs or keys; fail with a clear message when one is missing.

## Setup

```sh
sudo apt install shellcheck        # or: brew install shellcheck
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
cp .env.example .env.local         # then fill in the placeholders
```

## Commands

| Command | What it does |
| --- | --- |
| `shellcheck -x --source-path=SCRIPTDIR <file>` | Lint one script |
| `pre-commit run --all-files` | Every hook against the whole tree |

## Scripts

| Script | What it does |
| --- | --- |
| {{`scripts/x.sh`}} | {{…}} |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| shellcheck clean | blocks on every edit (`.sh`, `.bash`, or sh/bash shebang) | yes | yes |
| Formatting | `shfmt` on edit if installed | — | — |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

Fix shellcheck findings; do not add `# shellcheck disable=` without a comment saying why that specific case is safe.

## Done means

Every script passes `shellcheck -x`, and has been run once against a real or dry-run input.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- Quote every expansion. Use arrays for argument lists, never word-split strings.
- `mktemp` + `trap 'rm -rf …' EXIT` for temp files.
- New scripts are documented in `README.md` (humans) and `AGENTS.md` (agents).
