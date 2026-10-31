# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-31 — mypy (strict, Pydantic plugin) is the type checker, not pyright or Astral's ty — pyright pulls in a Node runtime; ty is still beta, so revisit when it reaches a stable release. It runs on the whole project on Stop, pre-push and CI, not per edit, like the react stack's `tsc`.
- 2026-10-31 — mypy's config ships as `mypy.ini`, not `[tool.mypy]` in `pyproject.toml` — the starter ships no `pyproject.toml` (the scaffold creates it), so a standalone file is how the starter carries the setting, as the php stack's `phpstan.neon.dist` does.
