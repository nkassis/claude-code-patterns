# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-26 — Commits are Conventional Commits with `Refs <key>` in the body, not `<key>: type: ...` — NIM-68 picks one format; the NIM-63 and NIM-67 commits used the key prefix.
- 2026-10-26 — `install-global.sh --force` moves a real file to `<target>.bak` instead of deleting it, and skips if a `.bak` already exists — nothing hand-written in `~/.claude` is lost.
- 2026-10-26 — `install-global.sh` refuses to run from a git worktree — its symlinks would dangle once the worktree is removed after merge.
- 2026-10-26 — `readme` skill: first command within 25 lines, not 20; a one-command caveat goes in a `#` comment — this repo's README, the first one the skill was applied to, needs a four-row directory table before Use.
- 2026-10-27 — `AGENTS.md` is the source of project instructions and each stack's `CLAUDE.md` imports it with `@AGENTS.md`, adding only Claude Code hooks — `AGENTS.md` is the cross-tool standard other agents read; with a `CLAUDE.md` present Claude Code reads `AGENTS.md` only through the import (documented `@path` syntax, so no symlink). Replaces the singular `AGENT.md`.
- 2026-10-27 — The guardrails table, with its Claude hook column, lives in `AGENTS.md`, not `CLAUDE.md` — its pre-commit and CI columns bind every agent; the hook column is informational there.
- 2026-10-27 — The repo root gets `AGENTS.md` and no `CLAUDE.md` — it has nothing Claude-only to add, and Claude Code (v2.1.277+) reads `AGENTS.md` directly when no `CLAUDE.md` exists.
- 2026-10-27 — `decide` skill: when the decision-log rule's `paths:` glob matches several logs, it files to the current milestone's; with no milestone or rule it falls back to `docs/decisions.md` — NIM-94 names the glob first but moriarty's glob `docs/decisions-*.md` matches one file per milestone.
