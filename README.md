# claude-code-patterns

My Claude Code setup patterns: per-stack starters that **enforce** my guardrails rather than just describe them, plus a shared security layer.

- `CLAUDE-global.md`: my all-project preferences (goes in `~/.claude/CLAUDE.md`).
- `stacks/<stack>/`: copy into a new project's root.
- `security/`: layer onto any stack. See `security/README.md`.

## Reading the global file

`CLAUDE-global.md` has three tiers, each with its own verb. **Rules** are enforced by a hook, pre-commit or CI, so there is nothing to decide. **Defaults** (every library choice) are used unless a reason fits the exit condition written next to them, and any deviation gets one line in the project's `docs/decisions.md` (every starter ships one). **Taste** is followed when it's free and never argued over. When you copy a starter, resolve the defaults into its `CLAUDE.md` as facts ("Logging: stdlib logging (CLI, see decisions.md)"); from then on the global file is reference, not a standing instruction.

## How a guardrail is enforced

Each rule is stated once and checked at four points:

1. **`CLAUDE.md`**: tells Claude the rule and what "done" means.
2. **Claude Code hook** (`.claude/settings.json` → `.claude/hooks/check-<stack>.sh`): runs on every Edit/Write. Formatters apply; lint findings exit 2, which blocks Claude and feeds it the output. Some stacks also run a project-wide check on **Stop**.
3. **pre-commit**: the same tools on commit/push, for humans and agents alike.
4. **GitHub Actions CI**: the gate.

## Stacks

| Stack | Edit hook | Stop hook | pre-commit / CI |
| --- | --- | --- | --- |
| `python` | Black (apply), Ruff (block) | `ruff check .` | ruff, black, pytest |
| `shell` | shfmt if installed (apply), shellcheck (block) | — | shellcheck |
| `rust` | `cargo fmt` (apply) | `cargo clippy -D warnings` | fmt, clippy, test |
| `cpp` | clang-format (apply), clang-tidy if `build/compile_commands.json` (block) | — | format, tidy, build, ctest |
| `react` | Prettier (apply), ESLint (block) | `pnpm typecheck` | `pnpm check`, build |

## Starting a project

```sh
cp -r stacks/python/. ~/projects/new-thing/
cp -r security/.github ~/projects/new-thing/
# then merge security/.pre-commit-config.yaml and security/.claude/settings.json in (see security/README.md)
```

Then fill in the `{{placeholders}}` in `CLAUDE.md` and `AGENT.md`.

**Combining stacks** (e.g. python + shell): hook scripts have distinct names, so copy both `.claude/hooks/` dirs. Then merge three files by hand:
- `.claude/settings.json`: concatenate the `PostToolUse` and `Stop` arrays.
- `.pre-commit-config.yaml`: concatenate the `repos:` lists.
- `.gitignore`: concatenate the lines.

## Prerequisites

- `python3` or `jq`: hooks parse the hook JSON with `jq` when present, otherwise `python3`.
- `uv`: pre-commit runs via `uvx pre-commit`; the python hook uses `uv`.
- The stack's own tools (shellcheck, cargo, clang-format/clang-tidy, pnpm). A hook whose tool is missing warns (exit 1) and doesn't block.
- `trufflehog` for the security pre-commit hook.

## Developing this repo

See `AGENT.md`. `tests/hooks.sh` exercises every hook script.
