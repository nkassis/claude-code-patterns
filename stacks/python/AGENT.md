# AGENT.md

Developer tooling. Commands run from the repo root.

## Setup

```sh
uv sync
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
cp .env.example .env    # then fill in the placeholders
```

## Commands

| Command | What it does |
| --- | --- |
| `uv run ruff check .` | Lint (`--fix` to apply safe fixes) |
| `uv run black .` | Format (`--check` in CI) |
| `uv run pytest` | Tests |
| `pre-commit run --all-files` | Every hook against the whole tree |

## Claude Code hooks

`.claude/hooks/check-python.sh` runs from `.claude/settings.json`:
- **PostToolUse** (Edit/Write): Black formats the file, then Ruff lints it; findings block Claude until fixed.
- **Stop**: `ruff check .` across the project before Claude may finish.

Without `pyproject.toml` the hook falls back to `uvx` (ad-hoc tool versions). Needs `uv`; `jq` is used if present, else `python3`.
