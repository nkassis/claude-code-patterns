# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-php.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write on `.php`): Pint formats the file, then PHPStan analyses it; findings block Claude until fixed.
- **Stop**: `phpstan analyse` across the project before Claude may finish (skipped when there is no `phpstan.neon` or `phpstan.neon.dist`).

Tools come from `vendor/bin`, falling back to `pint` and `phpstan` on `PATH`. `jq` is used if present, else `python3`.
