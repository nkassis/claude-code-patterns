# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-26 — Commits are Conventional Commits with `Refs <key>` in the body, not `<key>: type: ...` — NIM-68 picks one format; the NIM-63 and NIM-67 commits used the key prefix.
- 2026-10-26 — `install-global.sh --force` moves a real file to `<target>.bak` instead of deleting it, and skips if a `.bak` already exists — nothing hand-written in `~/.claude` is lost.
- 2026-10-26 — `install-global.sh` refuses to run from a git worktree — its symlinks would dangle once the worktree is removed after merge.
- 2026-10-26 — `readme` skill: first command within 25 lines, not 20; a one-command caveat goes in a `#` comment — this repo's README, the first one the skill was applied to, needs a four-row directory table before Use.
- 2026-10-27 — `AGENTS.md` is the source of project instructions and each stack's `CLAUDE.md` imports it with `@AGENTS.md`, adding only Claude Code hooks — `AGENTS.md` is the cross-tool standard other agents read; with a `CLAUDE.md` present Claude Code reads `AGENTS.md` only through the import (documented `@path` syntax, so no symlink). Replaces the singular `AGENT.md`.
- 2026-10-27 — The guardrails table, with its Claude hook column, lives in `AGENTS.md`, not `CLAUDE.md` — its pre-commit and CI columns bind every agent; the hook column is informational there.
- 2026-10-27 — The repo root gets `AGENTS.md` and no `CLAUDE.md` — it has nothing Claude-only to add, and Claude Code (v2.1.277+) reads `AGENTS.md` directly when no `CLAUDE.md` exists.
- 2026-10-28 — The `php` stack targets Laravel: `phpstan.neon.dist` includes Larastan by default, and a plain-PHP project drops that one line — the stack was built for a Laravel codebase, and leaving Larastan out would make PHPStan report false positives on facades and Eloquent.
- 2026-10-28 — `check-php.sh` uses `vendor/bin/<tool>`, falling back to `<tool>` on `PATH`, and exits 1 only when neither is there — this mirrors `check-python.sh`'s `uvx` fallback, so the hook still works outside a Composer project (and in the fixture tests).
- 2026-10-28 — The `php` edit hook and pre-commit run `phpstan analyse` over the configured paths, not the edited or staged files — per-file analysis also checked files outside those paths (Laravel's stock `tests/Unit/ExampleTest.php` fails at level 5), so a fresh app failed pre-commit while CI passed. It costs a slower edit hook; PHPStan's result cache keeps repeat runs short.
