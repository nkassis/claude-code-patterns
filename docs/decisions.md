# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-26 — Commits are Conventional Commits with `Refs <key>` in the body, not `<key>: type: ...` — NIM-68 picks one format; the NIM-63 and NIM-67 commits used the key prefix.
- 2026-10-26 — `install-global.sh --force` moves a real file to `<target>.bak` instead of deleting it, and skips if a `.bak` already exists — nothing hand-written in `~/.claude` is lost.
- 2026-10-26 — `install-global.sh` refuses to run from a git worktree — its symlinks would dangle once the worktree is removed after merge.
- 2026-10-26 — `readme` skill: first command within 25 lines, not 20; a one-command caveat goes in a `#` comment — this repo's README, the first one the skill was applied to, needs a four-row directory table before Use.
- 2026-10-27 — CI job `name:` convention: the secret scan job is `secret-scan` (root and `security/`), each stack's CI job is `ci-<stack>`, and this repo's tier 1 job is `ci` — a job's name is its required-check context, so a stable name keeps branch protection (`github/protect.sh`) matching, and two stacks in one repo no longer collide on the key `check`.
- 2026-10-27 — `protect.sh` requires the check runs found on the default branch's latest commit, not hardcoded `ci`/`secret-scan`; `--check` overrides, and finding none is an error — a renamed job or a two-stack project can't silently block every merge, and a ruleset with no checks is never created by accident.
- 2026-10-27 — `protect.sh --off`/`--on` send only `enforcement` and fail when no ruleset exists — a toggle must not rewrite the checks set by an earlier run with `--check`.
- 2026-10-27 — `protect.sh` uses `actor_id` 5 for the repository admin bypass role — GitHub's ruleset examples use it and there is no API to look up built-in role ids on a personal repo; verified on the live repo when the bypass was applied.
