# Claude Code

`AGENTS.md` is the project's instructions for every coding agent and is imported below. This file adds only what Claude Code alone reads.

@AGENTS.md

## Claude Code hooks

`.claude/hooks/check-cpp.sh` runs on PostToolUse (Edit/Write on C/C++ files): clang-format applies, then clang-tidy lints the file if `build/compile_commands.json` exists (headers are covered via their translation units). Findings block Claude until fixed. Configure the build once so the hook can lint.
