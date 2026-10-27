# How it works

## How a guardrail is enforced

Each rule is stated once and checked at four points:

1. **`AGENTS.md`**: tells any coding agent the rule and what "done" means. `CLAUDE.md` imports it with `@AGENTS.md` and adds only what Claude Code alone needs (its hooks).
2. **Claude Code hook** (`.claude/settings.json` → `.claude/hooks/check-<stack>.sh`): runs on every Edit/Write. Formatters apply; lint findings exit 2, which blocks Claude and feeds it the output. Some stacks also run a project-wide check on **Stop**.
3. **pre-commit**: the same tools on commit/push, for humans and agents alike.
4. **GitHub Actions CI**: the gate.

## Reading the global file

`CLAUDE-global.md` has three tiers, each with its own verb. **Rules** are enforced by a hook, pre-commit or CI, so there is nothing to decide. **Defaults** (every library choice) are used unless a reason fits the exit condition written next to them, and any deviation gets one line in the project's `docs/decisions.md` (every starter ships one). **Taste** is followed when it's free and never argued over. When you copy a starter, resolve the defaults into its `AGENTS.md` as facts ("Logging: stdlib logging (CLI, see decisions.md)"); from then on the global file is reference, not a standing instruction.
