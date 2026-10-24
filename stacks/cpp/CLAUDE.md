# {{PROJECT}}

{{One paragraph: what this game/engine is and the one thing it must get right (frame budget, determinism, …).}}

`AGENT.md` has the tooling commands. When a question is not answered here, stop and ask; do not decide silently.

## Stack

- C++{{23}}, CMake + Ninja, `CMAKE_EXPORT_COMPILE_COMMANDS=ON`.
- EnTT (ECS), SDL3 + Vulkan, Dear ImGui, spdlog. Catch2 for tests.
- Modules are unit-testable in isolation: no rendering or SDL calls in game logic.

## Guardrails (enforced, not optional)

| Rule | Claude hook | pre-commit | CI |
| --- | --- | --- | --- |
| clang-format | applied on every edit | yes | `--dry-run -Werror` |
| clang-tidy clean | blocks on edit when `build/compile_commands.json` exists | on push | yes |
| Builds and tests pass | — | — | yes |
| No secrets committed | — | trufflehog, detect-private-key | secret-scan |

Fix clang-tidy findings; do not add `NOLINT` without a comment saying why.

## Done means

`cmake --build build && ctest --test-dir build` passes and clang-tidy is clean.

## Rules

- Small `CMakeLists.txt` edits are fine; flag any significant restructuring for review first.
- No new third-party library without asking.
- Explicit types; when `auto` is unavoidable, add `// inferred: …`.
