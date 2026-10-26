# AGENT.md

Developer tooling. Commands run from the repo root.

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

## Lint config

- `.clang-format`: LLVM base, 4-space indent, 100 columns.
- `.clang-tidy`: bugprone, clang-analyzer, cppcoreguidelines, modernize, performance, readability; `WarningsAsErrors: '*'`. Disabled checks are listed in the file with the reason (e.g. `modernize-use-auto` conflicts with explicit types). Project headers under `src/` and `include/` are linted; `_deps/` headers are not. clang-tidy 20 ignores the header filters in `.clang-tidy`, so the hook, pre-commit and CI also pass them as `--header-filter` / `--exclude-header-filter`; keep all four places in sync.
- `src/platform/.clang-tidy`: inherits the root config and relaxes three checks for SDL interop; see `docs/sdl3.md`.

## Claude Code hooks

`.claude/hooks/check-cpp.sh` runs on PostToolUse (Edit/Write on C/C++ files): clang-format applies, then clang-tidy lints the file if `build/compile_commands.json` exists (headers are covered via their translation units). Findings block Claude until fixed. Configure the build once so the hook can lint.
