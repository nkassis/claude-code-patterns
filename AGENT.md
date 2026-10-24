# AGENT.md

Tooling for working on this repo (the templates themselves). Commands run from the repo root.

## Layout

- `stacks/<stack>/`: starter files copied verbatim into new projects. Keep `CLAUDE.md` short: stack, guardrails table, "done means", a few rules.
- `security/`: stack-independent secret hygiene.
- `tests/hooks.sh` + `tests/fixtures/<stack>/`: hook script tests.

## Checks

| Command | What it does |
| --- | --- |
| `shellcheck stacks/*/.claude/hooks/*.sh tests/hooks.sh` | Every script here must be shellcheck-clean |
| `bash tests/hooks.sh` | Runs each `check-<stack>.sh` with fake hook JSON against good/bad fixtures. PASS/FAIL per case; SKIP when that stack's linter isn't installed. Exits non-zero on any FAIL. |

## Hook script contract

Every `check-<stack>.sh` takes a mode (`edit` | `stop`), reads the hook JSON on stdin and `cd`s to `$CLAUDE_PROJECT_DIR`:
- exit 0: passed, or not this stack's file
- exit 2: lint failure, with the findings on stderr (blocks Claude)
- exit 1: tool missing; warns without blocking
- `stop` exits 0 when `stop_hook_active` is true, so a hook can't loop

When adding a stack: write the hook to this contract, add good/bad fixtures and `expect` lines in `tests/hooks.sh`, and add a row to the README table.
