# AGENT.md

Tooling for working on this repo (the templates themselves). Commands run from the repo root.

## Layout

- `stacks/<stack>/`: starter files copied verbatim into new projects. Keep `CLAUDE.md` short: stack, guardrails table, "done means", a few rules.
- `security/`: stack-independent secret hygiene.
- `skills/<name>/SKILL.md`: global Claude Code skills. `install-global.sh` symlinks each one, and `CLAUDE-global.md`, into `~/.claude/`; run it from the main clone (it refuses in a worktree, whose links would dangle after removal). A real file at a target is skipped (exit 1) unless `--force`, which moves it to `<target>.bak`.
- `tests/hooks.sh` + `tests/fixtures/<stack>/`: hook script tests. `tests/install-global.sh`: installer tests against a fake `$HOME`.

## Checks

| Command | What it does |
| --- | --- |
| `shellcheck install-global.sh stacks/*/.claude/hooks/*.sh tests/*.sh` | Every script here must be shellcheck-clean |
| `bash tests/install-global.sh` | Runs the installer against a fake `$HOME`: clean, re-run, existing file with and without `--force`, stale symlink, worktree. Exits non-zero on any FAIL. |
| `bash tests/hooks.sh` | Runs each `check-<stack>.sh` with fake hook JSON against good/bad fixtures. PASS/FAIL per case; SKIP when that stack's linter isn't installed. Exits non-zero on any FAIL. |

## Hook script contract

Every `check-<stack>.sh` takes a mode (`edit` | `stop`), reads the hook JSON on stdin and `cd`s to `$CLAUDE_PROJECT_DIR`:
- exit 0: passed, or not this stack's file
- exit 2: lint failure, with the findings on stderr (blocks Claude)
- exit 1: tool missing; warns without blocking
- `stop` exits 0 when `stop_hook_active` is true, so a hook can't loop

When adding a stack: write the hook to this contract, add good/bad fixtures and `expect` lines in `tests/hooks.sh`, and add a row to the README table.
