# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-python.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write): Black formats the file, then Ruff lints it; findings block Claude until fixed.
- **Stop**: `ruff check .` and `mypy .` across the project before Claude may finish.

Without `pyproject.toml` the hook falls back to `uvx` (ad-hoc tool versions). Needs `uv`; `jq` is used if present, else `python3`.
