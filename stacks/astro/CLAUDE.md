# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-astro.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write): Prettier formats the file, then ESLint lints `.astro` and JS/TS; findings block Claude until fixed.
- **Stop**: `pnpm check` before Claude may finish.

Both run from the nearest `package.json` above the edited file, so a site in a subdirectory works. The edit hook records those directories in `.claude/check-astro.dirs` for Stop, which falls back to the project root when none are recorded.

Needs `pnpm` and an installed `node_modules`, and Stop needs a `check` script; otherwise it warns and skips. `jq` is used if present, else `python3`.
