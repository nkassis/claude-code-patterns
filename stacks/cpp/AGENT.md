# AGENT.md

Developer tooling. Commands run from the repo root.

## Setup

```sh
sudo apt install ninja-build clang clang-format clang-tidy
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
```

## Commands

| Command | What it does |
| --- | --- |
| `cmake --build build` | Build |
| `ctest --test-dir build --output-on-failure` | Catch2 tests |
| `run-clang-tidy -p build` | Lint every translation unit |
| `git ls-files '*.cpp' '*.hpp' \| xargs clang-format -i` | Format |

## Lint config

- `.clang-format`: LLVM base, 4-space indent, 100 columns.
- `.clang-tidy`: bugprone, clang-analyzer, cppcoreguidelines, modernize, performance, readability; `WarningsAsErrors: '*'`. Disabled checks are listed in the file with the reason (e.g. `modernize-use-auto` conflicts with explicit types).

## Claude Code hooks

`.claude/hooks/check-cpp.sh` runs on PostToolUse (Edit/Write on C/C++ files): clang-format applies, then clang-tidy lints the file if `build/compile_commands.json` exists (headers are covered via their translation units). Findings block Claude until fixed. Configure the build once so the hook can lint.
