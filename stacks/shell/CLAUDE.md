# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-shell.sh` runs on PostToolUse (Edit/Write): shfmt (if installed), then shellcheck; findings block Claude until fixed. `jq` is used if present, else `python3`.
