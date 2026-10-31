# {{PROJECT}}

{{One paragraph: what this is, who uses it, and the one thing it must get right.}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root.

## Stack

- Python {{3.13}}, managed with `uv`. Never `pip install`; add dependencies with `uv add` (and only after asking).
- {{FastAPI}} for HTTP, `structlog` for logging, `pydantic` at every external boundary.
- `pytest` (+ `pytest-asyncio`, `httpx` test client for FastAPI). Tests live next to the code or in `tests/`.
- Type hints on every function signature, checked by `mypy` in strict mode (`mypy.ini`).

## Setup

```sh
uv sync
uv add --dev mypy==2.4.1                    # once, at project start: the type checker (config in mypy.ini)
uv add --dev vulture==2.16 deptry==0.25.1   # once, at project start: the Analysis tools below
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
cp .env.example .env    # then fill in the placeholders
```

## Commands

| Command | What it does |
| --- | --- |
| `uv run ruff check .` | Lint (`--fix` to apply safe fixes) |
| `uv run black .` | Format (`--check` in CI) |
| `uv run mypy .` | Type check (strict, Pydantic plugin; `mypy.ini`) |
| `uv run pytest` | Tests |
| `pre-commit run --all-files` | Every hook against the whole tree |

### Analysis

Run by hand or by a skill, never by a hook, pre-commit or CI: findings are leads to check, not failures. `scc` and `jscpd` need the machine tools in this repo's README.

| Command | What it does |
| --- | --- |
| `scc` | Count lines: code, comments and complexity per language; `--by-file --format json` for tooling |
| `uv run vulture . --exclude .venv`, `uv run deptry .` | Find dead code: unused functions, classes and variables; unused or missing dependencies |
| `pnpm dlx jscpd@5.4.2 .` | Find duplication: copy-pasted blocks across files |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| Black formatting (don't hand-format; let Black decide) | applied on every edit | yes | `black --check` |
| Ruff lint clean | blocks on every edit; `ruff check .` before stopping | yes | yes |
| mypy strict clean (type hints on every signature) | `mypy .` before stopping | on push | yes |
| Tests pass | — | on push | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

If a hook blocks you, fix the reported problem. Do not add `# noqa`, `# type: ignore` or per-file ignores to get past it without saying why.

## Done means

`uv run ruff check . && uv run black --check . && uv run mypy . && uv run pytest` passes.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- Never hardcode secrets. Config comes from env (`.env` locally, `.env.example` documents it).
- Small, single-responsibility functions; modules importable and testable in isolation.
- A bug fix comes with the test that would have caught it. If a test fails, say whether the code or the test is wrong before changing either.
