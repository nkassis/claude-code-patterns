# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-rust.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write on `.rs`): `cargo fmt` on the file; a parse error blocks Claude.
- **Stop**: `cargo clippy --all-targets -- -D warnings` before Claude may finish.
