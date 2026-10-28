# {{PROJECT}}

{{One paragraph: what this game/engine is and the one thing it must get right (frame budget, determinism, …).}}

When a question is not answered here, stop and ask; do not decide silently. Commands run from the repo root.

## Stack

- C++{{23}}, CMake + Ninja, `CMAKE_EXPORT_COMPILE_COMMANDS=ON`.
- EnTT (ECS), SDL3 + Vulkan, Dear ImGui, spdlog. Catch2 for tests.
- Modules are unit-testable in isolation.

## Setup

```sh
sudo apt install ninja-build clang clang-format clang-tidy
cmake --preset dev        # CMakePresets.json: Ninja, Debug, clang++, build/, compile_commands.json
pre-commit install --hook-type pre-commit --hook-type pre-push   # pre-commit itself: `uv tool install pre-commit`, once per machine
```

## Commands

| Command | What it does |
| --- | --- |
| `cmake --build --preset dev` | Build |
| `ctest --preset dev` | Catch2 tests |
| `run-clang-tidy -p build 'src/\|include/'` | Lint project translation units (not deps) |
| `git ls-files '*.cpp' '*.hpp' \| xargs clang-format -i` | Format |

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| clang-format | applied on every edit | yes | `--dry-run -Werror` |
| clang-tidy clean | blocks on edit when `build/compile_commands.json` exists | on push | yes |
| Builds and tests pass | — | — | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

Style lives in `.clang-format` (LLVM base, 4-space indent) and the check set in `.clang-tidy` (every check is an error). Change those files, with a reason, rather than working around them.

Fix clang-tidy findings; do not add `NOLINT` without a comment saying why.

## Lint config

- `.clang-format`: LLVM base, 4-space indent, 100 columns.
- `.clang-tidy`: bugprone, clang-analyzer, cppcoreguidelines, modernize, performance, readability; `WarningsAsErrors: '*'`. Disabled checks are listed in the file with the reason (e.g. `modernize-use-auto` conflicts with explicit types). Project headers under `src/` and `include/` are linted; `_deps/` headers are not. clang-tidy 20 ignores the header filters in `.clang-tidy`, so the hook, pre-commit and CI also pass them as `--header-filter` / `--exclude-header-filter`; keep all four places in sync.
- `src/platform/.clang-tidy`: inherits the root config and relaxes three checks for SDL interop; see `docs/sdl3.md`.

## Done means

`cmake --build build && ctest --test-dir build` passes and clang-tidy is clean.

## Rules

- Deviating from a global default (a library, tool or pattern)? In an interactive session, ask first; unattended, decide. Either way, add one line to `docs/decisions.md` (date, what, why) and flag it in the PR. Read that file before changing a choice it records.
- All SDL3 and ImGui backend calls live in `src/platform/`; game logic never includes an SDL header. Partly enforced: `src/platform/.clang-tidy` is the only place SDL interop checks are relaxed, so the same code elsewhere fails lint.
- `docs/` holds guidance for specific areas; read a doc only when your task touches it. SDL3 / platform code: `docs/sdl3.md` (also linked from `src/platform/CLAUDE.md`).
- Small `CMakeLists.txt` edits are fine; flag any significant restructuring for review first.
- No new third-party library without asking.
- Explicit types; when `auto` is unavoidable, add `// inferred: …`.
