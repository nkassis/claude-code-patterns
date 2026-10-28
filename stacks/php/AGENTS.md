# {{PROJECT}}

{{One paragraph: what this is, who uses it, and the one thing it must get right.}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root.

## Stack

- PHP {{8.4}}, managed with Composer. Add dependencies with `composer require` (and only after asking); commit `composer.lock`.
- Laravel {{13}}. Config comes from `config/` reading env; never call `env()` outside `config/`.
- Pint (Laravel preset) for formatting, PHPStan with Larastan for static analysis (`phpstan.neon.dist`).
- Pest for tests, in `tests/Feature` and `tests/Unit`.
- Typed parameters and return types on every function and method.

## Setup

```sh
composer install
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
cp .env.example .env    # then fill in the placeholders
php artisan key:generate
```

## Commands

| Command | What it does |
| --- | --- |
| `vendor/bin/pint` | Format (`--test` in CI) |
| `vendor/bin/phpstan analyse` | Static analysis at the level in `phpstan.neon.dist` |
| `vendor/bin/pest` | Tests |
| `pre-commit run --all-files` | Every hook against the whole tree |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| Pint formatting (don't hand-format; let Pint decide) | applied on every edit | yes | `pint --test` |
| PHPStan clean | blocks on every edit; `phpstan analyse` before stopping | yes | yes |
| Tests pass | — | on push | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

If a hook blocks you, fix the reported problem. Do not add `@phpstan-ignore`, baseline entries or lower the level to get past it without saying why.

## Done means

`vendor/bin/pint --test && vendor/bin/phpstan analyse && vendor/bin/pest` passes.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- Never hardcode secrets. Config comes from env (`.env` locally, `.env.example` documents it).
- Small, single-responsibility classes and methods; resolve dependencies through the container so they can be faked in tests.
- A bug fix comes with the test that would have caught it. If a test fails, say whether the code or the test is wrong before changing either.
