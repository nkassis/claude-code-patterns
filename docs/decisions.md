# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-26 — Commits are Conventional Commits with `Refs <key>` in the body, not `<key>: type: ...` — NIM-68 picks one format; the NIM-63 and NIM-67 commits used the key prefix.
- 2026-10-26 — `install-global.sh --force` moves a real file to `<target>.bak` instead of deleting it, and skips if a `.bak` already exists — nothing hand-written in `~/.claude` is lost.
- 2026-10-26 — `install-global.sh` refuses to run from a git worktree — its symlinks would dangle once the worktree is removed after merge.
- 2026-10-26 — `readme` skill: first command within 25 lines, not 20; a one-command caveat goes in a `#` comment — this repo's README, the first one the skill was applied to, needs a four-row directory table before Use.
- 2026-10-27 — `guard-bash.sh` also blocks `git push --all`, `--mirror` and `--branches` — each pushes main when a local main exists; NIM-82 lists refspec and bare pushes, and these are the same hole.
- 2026-10-27 — This repo runs `security/.claude/hooks/guard-bash.sh` in place from `.claude/settings.json` instead of copying it to `.claude/hooks/` — one copy, so the dogfooded guard can't drift from the template.
- 2026-10-27 — `guard-bash.sh` is pure bash with its own quote-aware tokenizer, no `shlex` — the hook needs only `jq` or `python3` for JSON, like the stack hooks.
