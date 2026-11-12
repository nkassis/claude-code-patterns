# claude-code-patterns

[![ci](https://github.com/nkassis/claude-code-patterns/actions/workflows/ci.yml/badge.svg)](https://github.com/nkassis/claude-code-patterns/actions/workflows/ci.yml)

Utopia Planitia: where the ships get fitted out.

Per-stack starters for Claude Code projects. Each one states a guardrail once in `AGENTS.md`, which any coding agent reads and `CLAUDE.md` imports, and enforces it three times: a Claude Code hook on every edit, pre-commit on every commit, CI on every push. A shared security layer goes on every project.

| Directory | Contents |
| --- | --- |
| `stacks/<stack>/` | Starter files for one language |
| `security/` | Secret scanning, read-deny rules, env hygiene |
| `github/` | Opt-in branch protection ruleset, see [github/README.md](github/README.md); the workflow ref check CI runs here |
| `CLAUDE-global.md` | Personal defaults, goes in `~/.claude/CLAUDE.md` |
| `skills/` | Claude Code skills, go in `~/.claude/skills/` |
| `rules/` | Path-scoped Claude Code rules, go in a project's `.claude/rules/` |

How it works: [docs/how-it-works.md](docs/how-it-works.md)

## Use

Prerequisites: `uv`, `jq` or `python3`, `trufflehog`, `gh` (logged in), and the stack's own tools (see the table below). Commands run from a clone of this repo.

Analysis tools, named in each stack's `AGENTS.md` under Analysis and never run by a hook or CI, need these on the machine (per-project ones are pinned by the stack's Setup):

| Tool | For | Install |
| --- | --- | --- |
| `scc` v3.7.0 | line counts and complexity, every stack | `go install github.com/boyter/scc/v3@v3.7.0` |
| Node and `pnpm` | `jscpd` duplication, every stack, run as `pnpm dlx jscpd@5.4.2` | `corepack enable pnpm` |
| `cargo-machete` 0.9.2 | rust dead dependencies | `cargo install cargo-machete --version 0.9.2 --locked` |
| `cppcheck` 2.17+ | cpp unused functions | `sudo apt install cppcheck` or `brew install cppcheck` |

### Once per machine

```sh
uv tool install pre-commit
./install-global.sh   # symlinks CLAUDE-global.md and skills/ into ~/.claude; --force moves existing files to .bak
```

### Start a project

```sh
cp -r stacks/python/. security/.github security/.env.example ~/projects/new-thing/
cd ~/projects/new-thing
pre-commit install --hook-type pre-commit --hook-type pre-push
```

### Apply to an existing project

```sh
cp -r --update=none stacks/python/. security/.github security/.env.example ~/projects/existing/   # never overwrites; GNU coreutils 9.3+, macOS: cp -rn
cd ~/projects/existing
pre-commit install --hook-type pre-commit --hook-type pre-push
pre-commit run --all-files
```

### Then, in both cases

Copy `security/.claude/hooks/guard-bash.sh` into the project's `.claude/hooks/`. Merge `security/.claude/settings.json` and `security/.pre-commit-config.yaml` into the project's copies, and append `security/gitignore-env.txt` to `.gitignore`. In an existing project, also merge anything `--update=none` skipped, such as `AGENTS.md`, `CLAUDE.md` and `.gitignore`. Two stacks in one repo merge the same way; hook scripts have distinct names and coexist.

Lock the project's GitHub Actions and commit the lockfile. The `actions-lock` CI job and zizmor fail until it exists. Details, and the rule for reusable workflows: [security/README.md](security/README.md#locking-github-actions).

```sh
gh extension install github/gh-actions-lock --pin v0.4.1   # once per machine
gh actions-lock && git add .github/workflows/ && git commit -m "ci: lock GitHub Actions dependencies"
```

Fill in the `{{placeholders}}` in `AGENTS.md` and `CLAUDE.md`. Record any deviation from `CLAUDE-global.md`'s defaults in `docs/decisions.md`.

For a decision log, copy `rules/decision-log.md` into the project's `.claude/rules/`. At a real fork it has agents run `/decide`, which asks you and writes the entry.

Before a PR, spec or report leaves your hands, `/blind-review` has a fresh subagent review it against the brief, without the conversation; other skills can call it as a gate.

## Stacks

| Stack | On edit | On stop | pre-commit and CI |
| --- | --- | --- | --- |
| `python` | Black, Ruff | `ruff check .` | ruff, black, pytest |
| `shell` | shfmt, shellcheck | | shellcheck |
| `rust` | `cargo fmt` | `cargo clippy -D warnings` | fmt, clippy, test |
| `cpp` | clang-format, clang-tidy (needs `build/compile_commands.json`) | | format, tidy, build, ctest |
| `react` | Prettier, ESLint | `pnpm typecheck` | `pnpm check`, build |
| `php` | Pint, PHPStan (Larastan) | `phpstan analyse` | pint, phpstan, pest |

Formatters apply. Lint findings block Claude and are fed back to it. A missing tool warns and does not block.

## Covered

**Code quality.** Format and lint on every edit, a project-wide check before Claude stops (python, rust, react, php), the same tools in pre-commit. `AGENTS.md` states what "done" means.

**CI.** One GitHub Actions workflow per stack. Actions carry exact release tags, and each project locks them to commits in `.github/workflows/actions.lock`, checked on every PR. Reusable workflows from other repos are pinned to a full SHA. zizmor audits the workflows, and Dependabot keeps the tags and the lockfile current, with a 7 day cooldown.

**Security.** TruffleHog on every push and PR, plus `detect-private-key` and large-file checks in pre-commit. Claude is denied reads of `.env` files (not `.env.example`), keys, `~/.ssh` and `~/.aws`, and every project gets a `.env.example` and a gitignore block. Main and master are guarded locally:
- A PreToolUse hook blocks Claude from committing on them, pushing to them, force pushing or deleting them.
- pre-commit `no-commit-to-branch` rejects anyone's commit there.

These layers catch mistakes. They don't stop someone determined: aliases, scripts, `bash -c` and `--no-verify` get past them. A server-side branch ruleset is the gate.

## Developing this repo

`AGENTS.md` has the hook contract; `tests/hooks.sh` runs every hook against good and bad fixtures, `tests/install-global.sh` the installer against a fake `$HOME`, `tests/agents-md.sh` checks the AGENTS.md / CLAUDE.md split, `tests/protect.sh` the ruleset script against a stub `gh`, `tests/check-workflow-refs.sh` the workflow ref check against good and bad fixtures.

This repo's own workflows are locked in `.github/workflows/actions.lock`. After changing a `uses:` here, run `gh actions-lock` and commit the result. `github/check-workflow-refs.sh <workflow.yml>...` fails on a reusable workflow call not pinned to a full SHA, and on a floating tag or branch. CI runs it over the root and template workflows, since zizmor accepts tags in the templates.
