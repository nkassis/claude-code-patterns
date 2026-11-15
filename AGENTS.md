# AGENTS.md

Tooling for working on this repo (the templates themselves). Commands run from the repo root.

## Layout

- `stacks/<stack>/`: starter files copied verbatim into new projects. `AGENTS.md` holds what any agent needs: stack, commands, guardrails table, "done means", rules. `CLAUDE.md` imports it with `@AGENTS.md` and adds only Claude Code specifics (hooks); no line appears in both.
- `security/`: stack-independent secret hygiene.
- `skills/<name>/SKILL.md`: global Claude Code skills. `install-global.sh` symlinks each one, and `CLAUDE-global.md`, into `~/.claude/`; run it from the main clone (it refuses in a worktree, whose links would dangle after removal). A real file at a target is skipped (exit 1) unless `--force`, which moves it to `<target>.bak`.
- `github/check-workflow-refs.sh`: read-only check of workflow `uses:` refs, run by CI here (see Checks).
- `github/protect.sh`: branch protection as a ruleset on a project's default branch. Opt-in, like every layer that changes state on an external service: never run by default, only by hand or an explicit flag.
- `rules/<name>.md`: path-scoped Claude Code rules, copied by hand into a project's `.claude/rules/`; not installed globally. `rules/decision-log.md` comes from moriarty and tells agents when to run the `decide` skill.
- `tests/hooks.sh` + `tests/fixtures/<stack>/`: hook script tests. `tests/install-global.sh`: installer tests against a fake `$HOME`. `tests/agents-md.sh`: the AGENTS.md / CLAUDE.md split in every stack. `tests/protect.sh`: `protect.sh` against a stub `gh`. `tests/check-workflow-refs.sh` + `tests/fixtures/workflow-refs/`: the workflow ref check.

CI job `name:`s are required-check contexts: `ci-<stack>` in the stacks, `secret-scan` for the scan, `actions-lock` for the lockfile check, `ci` here. Keep them (`docs/decisions.md`).

## Checks

`.github/workflows/ci.yml` runs all of these on every PR and push to main, plus a JSON/YAML parse check over every tracked file; `secret-scan.yml` runs TruffleHog on every push; `actions-lock.yml` runs `gh actions-lock --verify`.

This repo's workflows are locked in `.github/workflows/actions.lock`. After adding a workflow or changing a `uses:` under `.github/workflows/`, run `gh actions-lock` (extension pinned with `gh extension install github/gh-actions-lock --pin v0.4.1`) and commit the result; never edit the lockfile by hand. Template workflows under `stacks/` and `security/` are not in it: give them exact `vX.Y.Z` tags. `.github/workflows/actions-lock.yml` is a copy of `security/.github/workflows/actions-lock.yml`; keep them identical.

| Command | What it does |
| --- | --- |
| `shellcheck install-global.sh github/*.sh stacks/*/.claude/hooks/*.sh security/.claude/hooks/*.sh tests/*.sh` | Every script here must be shellcheck-clean |
| `actionlint .github/workflows/*.yml stacks/*/.github/workflows/*.yml security/.github/workflows/*.yml` | Lints every workflow, including the templates that only run once copied into a project. CI pins v1.7.7. |
| `zizmor .github/workflows/*.yml .github/dependabot.yml .pre-commit-config.yaml` | Security audit of this repo's workflows, default policy: locked steps pass, reusable workflow calls must be hash-pinned. CI pins v1.32.0, the first that reads `actions.lock`; pre-commit runs it too. |
| `zizmor --config .github/zizmor-templates.yml stacks/*/.github/workflows/*.yml security/.github/workflows/*.yml security/.github/dependabot.yml security/.pre-commit-config.yaml stacks/*/.pre-commit-config.yaml` | The same audit over the templates, with `unpinned-uses` relaxed to `ref-pin`: they are locked only once copied into a project. |
| `github/check-workflow-refs.sh .github/workflows/*.yml stacks/*/.github/workflows/*.yml security/.github/workflows/*.yml` | Fails on a reusable workflow call to another repo not pinned to a full SHA with a version comment, and on any floating tag (`v4`, `v4.1`) or branch. Covers the templates, where zizmor accepts tags. |
| `gh actions-lock --verify` | `actions.lock` matches the workflows and every locked commit verifies upstream. Run in `actions-lock.yml`. |
| `bash tests/install-global.sh` | Runs the installer against a fake `$HOME`: clean, re-run, existing file with and without `--force`, stale symlink, worktree. Exits non-zero on any FAIL. |
| `bash tests/agents-md.sh` | Every stack has `AGENTS.md`, its `CLAUDE.md` imports it with `@AGENTS.md`, no non-blank line is in both, `AGENTS.md` has an `### Analysis` block (at most three rows: count lines with `scc`, find duplication with `jscpd`, and the stack's dead-code tool, which the script names per stack), and no tracked file outside `docs/decisions.md` names the old singular file. |
| `bash tests/hooks.sh` | Runs each `check-<stack>.sh` with fake hook JSON against good/bad fixtures, `guard-bash.sh` against blocked and allowed command lines in a scratch repo, and `no-commit-to-branch` against a real commit on main. PASS/FAIL per case; SKIP when that stack's linter, or `pre-commit`, isn't installed. Exits non-zero on any FAIL. |
| `bash tests/protect.sh` | Runs `github/protect.sh` against a stub `gh`: check discovery, the JSON sent, create vs update, `--off`/`--on`, the plan-limit error, the python3 fallback. Exits non-zero on any FAIL. |
| `bash tests/check-workflow-refs.sh` | Runs `github/check-workflow-refs.sh` against `tests/fixtures/workflow-refs/`: every accepted form passes, every rejected form is reported at its line, exit codes 0/1/2, and the repo's own workflows pass. Exits non-zero on any FAIL. |

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
