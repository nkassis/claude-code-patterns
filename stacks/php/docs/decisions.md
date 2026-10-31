# Decisions

One line per deviation from a global default or other design choice, newest last: `YYYY-MM-DD — what was chosen — why`.

- 2026-10-31 — `phpstan.neon.dist` starts at level 6, not Larastan's recommended 5 — level 6 is the first that reports missing parameter and return types, and AGENTS.md requires them on every function and method; at 5 the rule had no check.
