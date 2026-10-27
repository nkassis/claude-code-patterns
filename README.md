# claude-code-patterns

[![ci](https://github.com/nkassis/claude-code-patterns/actions/workflows/ci.yml/badge.svg)](https://github.com/nkassis/claude-code-patterns/actions/workflows/ci.yml)

Utopia Planitia: where the ships get fitted out.

Per-stack starters for Claude Code projects. Each one states a guardrail once in `AGENTS.md`, which any coding agent reads and `CLAUDE.md` imports, and enforces it three times: a Claude Code hook on every edit, pre-commit on every commit, CI on every push. A shared security layer goes on every project.

| Directory | Contents |
| --- | --- |
| `stacks/<stack>/` | Starter files for one language |
| `security/` | Secret scanning, read-deny rules, env hygiene |
| `CLAUDE-global.md` | Personal defaults, goes in `~/.claude/CLAUDE.md` |
| `skills/` | Claude Code skills, go in `~/.claude/skills/` |
| `rules/` | Path-scoped Claude Code rules, go in a project's `.claude/rules/` |

How it works: [docs/how-it-works.md](docs/how-it-works.md)

## Use

Prerequisites: `uv`, `jq` or `python3`, `trufflehog`, and the stack's own tools (see the table below). Commands run from a clone of this repo.

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

Merge `security/.claude/settings.json` and `security/.pre-commit-config.yaml` into the project's copies, and append `security/gitignore-env.txt` to `.gitignore`. In an existing project, also merge anything `--update=none` skipped, such as `AGENTS.md`, `CLAUDE.md` and `.gitignore`. Two stacks in one repo merge the same way; hook scripts have distinct names and coexist.

Fill in the `{{placeholders}}` in `AGENTS.md` and `CLAUDE.md`. Record any deviation from `CLAUDE-global.md`'s defaults in `docs/decisions.md`.

For a decision log, copy `rules/decision-log.md` into the project's `.claude/rules/`. At a real fork it has agents run `/decide`, which asks you and writes the entry.

## Stacks

| Stack | On edit | On stop | pre-commit and CI |
| --- | --- | --- | --- |
| `python` | Black, Ruff | `ruff check .` | ruff, black, pytest |
| `shell` | shfmt, shellcheck | | shellcheck |
| `rust` | `cargo fmt` | `cargo clippy -D warnings` | fmt, clippy, test |
| `cpp` | clang-format, clang-tidy (needs `build/compile_commands.json`) | | format, tidy, build, ctest |
| `react` | Prettier, ESLint | `pnpm typecheck` | `pnpm check`, build |

Formatters apply. Lint findings block Claude and are fed back to it. A missing tool warns and does not block.

## Covered

**Code quality.** Format and lint on every edit, a project-wide check before Claude stops (python, rust, react), the same tools in pre-commit. `AGENTS.md` states what "done" means.

**CI.** One GitHub Actions workflow per stack. Actions pinned to release tags, Dependabot to keep the pins current.

**Security.** TruffleHog on every push and PR, plus `detect-private-key` and large-file checks in pre-commit. Claude is denied reads of `.env` files (not `.env.example`), keys, `~/.ssh` and `~/.aws`, and every project gets a `.env.example` and a gitignore block.

## Developing this repo

`AGENTS.md` has the hook contract; `tests/hooks.sh` runs every hook against good and bad fixtures, `tests/install-global.sh` the installer against a fake `$HOME`, `tests/agents-md.sh` checks the AGENTS.md / CLAUDE.md split.
