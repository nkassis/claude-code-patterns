# {{PROJECT}}

{{One paragraph: what this is, who uses it, and the one thing it must get right.}}

`AGENT.md` has the tooling commands. When a question is not answered here, stop and ask; do not decide silently.

## Stack

- Python {{3.13}}, managed with `uv`. Never `pip install`; add dependencies with `uv add` (and only after asking).
- {{FastAPI}} for HTTP, `structlog` for logging, `pydantic` at every external boundary.
- `pytest` (+ `pytest-asyncio`, `httpx` test client for FastAPI). Tests live next to the code or in `tests/`.
- Type hints on every function signature.

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| Black formatting (don't hand-format; let Black decide) | applied on every edit | yes | `black --check` |
| Ruff lint clean | blocks on every edit; `ruff check .` before stopping | yes | yes |
| Tests pass | — | on push | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

If a hook blocks you, fix the reported problem. Do not add `# noqa` or per-file ignores to get past it without saying why.

## Done means

`uv run ruff check . && uv run black --check . && uv run pytest` passes.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- Never hardcode secrets. Config comes from env (`.env` locally, `.env.example` documents it).
- Small, single-responsibility functions; modules importable and testable in isolation.
- A bug fix comes with the test that would have caught it. If a test fails, say whether the code or the test is wrong before changing either.
