# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-react.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write): Prettier formats the file, then ESLint lints JS/TS; findings block Claude until fixed.
- **Stop**: `{{pnpm}} typecheck` before Claude may finish.

Needs `pnpm` and an installed `node_modules`; otherwise it warns and skips.
