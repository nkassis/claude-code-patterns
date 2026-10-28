# How it works

## How a guardrail is enforced

Each rule is stated once and checked at four points:

1. **`AGENTS.md`**: tells any coding agent the rule and what "done" means. `CLAUDE.md` imports it with `@AGENTS.md` and adds only what Claude Code alone needs (its hooks).
2. **Claude Code hook** (`.claude/settings.json` → `.claude/hooks/check-<stack>.sh`): runs on every Edit/Write. Formatters apply; lint findings exit 2, which blocks Claude and feeds it the output. Some stacks also run a project-wide check on **Stop**.
3. **pre-commit**: the same tools on commit/push, for humans and agents alike.
4. **GitHub Actions CI**: the gate.

## CI is the floor, not the ceiling

**What the harness guarantees.** Code is formatted, lint and type checks are clean, the tests already in the repo pass, and no secrets go into a commit. These checks are deterministic, so an agent can't argue its way past them. It either fixes the finding or stays blocked.

**What it can't.** CI can tell that the tests pass. It can't tell whether they test the right thing. When one agent writes both the code and its tests, the tests can end up shaped to pass instead of shaped by the requirement, and CI goes green anyway. Green CI shows the work is consistent with itself, not that it's correct.

**The layers above it.**

- **Acceptance criteria written by a human** in the Linear issue. The agent works toward them but never writes them, so its own tests aren't the only definition of done.
- **Review by a separate agent** that sees the brief and the diff but not the conversation that produced them. It has no stake in the approach and none of the reasoning that made the shortcuts look fine.
- **Property or mutation tests on critical code.** Property tests check invariants across generated inputs, not examples the author picked. Mutation tests show whether the suite actually fails when the code is wrong.
- **Done is kept by a human.** This is why `implement-issue` stops at In Review and its PRs say `Refs`, never `Closes`.

## Reading the global file

`CLAUDE-global.md` has three tiers, each with its own verb. **Rules** are enforced by a hook, pre-commit or CI, so there is nothing to decide. **Defaults** (every library choice) are used unless a reason fits the exit condition written next to them, and any deviation gets one line in the project's `docs/decisions.md` (every starter ships one). **Taste** is followed when it's free and never argued over. When you copy a starter, resolve the defaults into its `AGENTS.md` as facts ("Logging: stdlib logging (CLI, see decisions.md)"); from then on the global file is reference, not a standing instruction.
