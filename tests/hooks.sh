#!/usr/bin/env bash
# Exercise every stacks/*/.claude/hooks/check-*.sh with fake Claude Code hook input.
# Each case copies a fixture into a scratch project, runs the hook, and checks the exit code:
#   0 = pass / not this stack's file, 2 = blocked (lint failure). A hook exiting 1
#   means its linter is not installed; that case is reported as SKIP, not FAIL.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixtures="$repo/tests/fixtures"
pass=0
fail=0
skip=0

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# expect <stack> <mode> <fixture|-> <expected exit> [stop_hook_active]
expect() {
    local stack="$1" mode="$2" fixture="$3" want="$4" active="${5:-false}"
    local hook="$repo/stacks/$stack/.claude/hooks/check-$stack.sh"
    local project="$scratch/$stack-$mode-${fixture//\//_}"
    local target="" input got=0 err

    mkdir -p "$project"
    if [[ "$fixture" != "-" ]]; then
        target="$project/$(basename "$fixture")"
        cp "$fixtures/$fixture" "$target"
    fi
    input="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"},"stop_hook_active":%s}' "$target" "$active")"
    err="$(CLAUDE_PROJECT_DIR="$project" "$hook" "$mode" <<<"$input" 2>&1 >/dev/null)" || got=$?

    local label="$stack $mode $fixture"
    if [[ "$got" == "$want" ]]; then
        printf 'PASS  %s\n' "$label"
        pass=$((pass + 1))
    elif [[ "$got" == 1 ]]; then
        printf 'SKIP  %s (%s)\n' "$label" "${err%%$'\n'*}"
        skip=$((skip + 1))
    else
        printf 'FAIL  %s: exit %s, want %s\n%s\n' "$label" "$got" "$want" "$err"
        fail=$((fail + 1))
    fi
}

for stack in python shell rust cpp react; do
    expect "$stack" edit other.txt 0
done

expect python edit python/good.py 0
expect python edit python/bad.py 2
expect python stop - 0 true

expect shell edit shell/good.sh 0
expect shell edit shell/bad.sh 2
expect shell edit shell/bad-no-ext 2

expect rust edit rust/good.rs 0
expect rust edit rust/bad.rs 2
expect rust stop - 0 true

expect cpp edit cpp/good.cpp 0

expect react edit react/good.ts 0
expect react stop - 0 true

printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[[ "$fail" == 0 ]]
