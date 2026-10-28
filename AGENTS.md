# AGENTS.md

Tooling for working on this repo (the templates themselves). Commands run from the repo root.

## Layout

- `stacks/<stack>/`: starter files copied verbatim into new projects. `AGENTS.md` holds what any agent needs: stack, commands, guardrails table, "done means", rules. `CLAUDE.md` imports it with `@AGENTS.md` and adds only Claude Code specifics (hooks); no line appears in both.
- `security/`: stack-independent secret hygiene.
- `skills/<name>/SKILL.md`: global Claude Code skills. `install-global.sh` symlinks each one, and `CLAUDE-global.md`, into `~/.claude/`; run it from the main clone (it refuses in a worktree, whose links would dangle after removal). A real file at a target is skipped (exit 1) unless `--force`, which moves it to `<target>.bak`.
- `github/protect.sh`: branch protection as a ruleset on a project's default branch. Opt-in, like every layer that changes state on an external service: never run by default, only by hand or an explicit flag.
- `rules/<name>.md`: path-scoped Claude Code rules, copied by hand into a project's `.claude/rules/`; not installed globally. `rules/decision-log.md` comes from moriarty and tells agents when to run the `decide` skill.
- `tests/hooks.sh` + `tests/fixtures/<stack>/`: hook script tests. `tests/install-global.sh`: installer tests against a fake `$HOME`. `tests/agents-md.sh`: the AGENTS.md / CLAUDE.md split in every stack. `tests/protect.sh`: `protect.sh` against a stub `gh`.

CI job `name:`s are required-check contexts: `ci-<stack>` in the stacks, `secret-scan` for the scan, `ci` here. Keep them (`docs/decisions.md`).

## Checks

`.github/workflows/ci.yml` runs all of these on every PR and push to main, plus a JSON/YAML parse check over every tracked file; `secret-scan.yml` runs TruffleHog on every push.

| Command | What it does |
| --- | --- |
| `shellcheck install-global.sh github/*.sh stacks/*/.claude/hooks/*.sh security/.claude/hooks/*.sh tests/*.sh` | Every script here must be shellcheck-clean |
| `actionlint .github/workflows/*.yml stacks/*/.github/workflows/*.yml security/.github/workflows/*.yml` | Lints every workflow, including the templates that only run once copied into a project. CI pins v1.7.7. |
| `bash tests/install-global.sh` | Runs the installer against a fake `$HOME`: clean, re-run, existing file with and without `--force`, stale symlink, worktree. Exits non-zero on any FAIL. |
| `bash tests/agents-md.sh` | Every stack has `AGENTS.md`, its `CLAUDE.md` imports it with `@AGENTS.md`, no non-blank line is in both, and no tracked file outside `docs/decisions.md` names the old singular file. |
| `bash tests/hooks.sh` | Runs each `check-<stack>.sh` with fake hook JSON against good/bad fixtures, `guard-bash.sh` against blocked and allowed command lines in a scratch repo, and `no-commit-to-branch` against a real commit on main. PASS/FAIL per case; SKIP when that stack's linter, or `pre-commit`, isn't installed. Exits non-zero on any FAIL. |
| `bash tests/protect.sh` | Runs `github/protect.sh` against a stub `gh`: check discovery, the JSON sent, create vs update, `--off`/`--on`, the plan-limit error, the python3 fallback. Exits non-zero on any FAIL. |

## Guarding main here

This repo uses its own branch guard. `.claude/settings.json` runs `security/.claude/hooks/guard-bash.sh` in place before every Bash call, and `.pre-commit-config.yaml` has `no-commit-to-branch`. Run `pre-commit install` once per clone. Work on a feature branch or in a worktree.

`guard-bash.sh` doesn't follow the `check-<stack>.sh` contract. It is a PreToolUse hook: exit 2 blocks the command, exit 0 lets it run. To add a rule, write a `rule_<name>` function and chain it in `check_git`.

## Hook script contract

Every `check-<stack>.sh` takes a mode (`edit` | `stop`), reads the hook JSON on stdin and `cd`s to `$CLAUDE_PROJECT_DIR`:
- exit 0: passed, or not this stack's file
- exit 2: lint failure, with the findings on stderr (blocks Claude)
- exit 1: tool missing; warns without blocking
- `stop` exits 0 when `stop_hook_active` is true, so a hook can't loop

When adding a stack: write the hook to this contract, add good/bad fixtures and `expect` lines in `tests/hooks.sh`, and add a row to the README table.
