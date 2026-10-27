# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-26 — Commits are Conventional Commits with `Refs <key>` in the body, not `<key>: type: ...` — NIM-68 picks one format; the NIM-63 and NIM-67 commits used the key prefix.
- 2026-10-26 — `install-global.sh --force` moves a real file to `<target>.bak` instead of deleting it, and skips if a `.bak` already exists — nothing hand-written in `~/.claude` is lost.
- 2026-10-26 — `install-global.sh` refuses to run from a git worktree — its symlinks would dangle once the worktree is removed after merge.
- 2026-10-26 — `readme` skill: first command within 25 lines, not 20; a one-command caveat goes in a `#` comment — this repo's README, the first one the skill was applied to, needs a four-row directory table before Use.
- 2026-10-27 — CI job `name:` convention: the secret scan job is `secret-scan` (root and `security/`), each stack's CI job is `ci-<stack>`, and this repo's tier 1 job is `ci` — a job's name is its required-check context, so a stable name keeps branch protection (`github/protect.sh`) matching, and two stacks in one repo no longer collide on the key `check`.
