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

# Optional per-stack hooks: setup_<stack> <project> <target> prepares the scratch project;
# verify_<stack> <target> checks the file after a passing (exit 0) run.
setup_cpp() {
    # Lint with the starter's real configs and a compile database, as a configured project would.
    cp "$repo/stacks/cpp/.clang-format" "$repo/stacks/cpp/.clang-tidy" "$1/"
    mkdir -p "$1/src/platform"
    cp "$repo/stacks/cpp/src/platform/.clang-tidy" "$1/src/platform/"
    # A project header and a FetchContent-style dep header, both with findings.
    cp -r "$fixtures/cpp/project/." "$1/"
    [[ -n "$2" ]] || return 0
    local vendor="$1/build/_deps/vendor-src/include"
    printf '[{"directory":"%s","file":"%s","arguments":["clang++","-std=c++23","-I%s","-c","%s"]}]\n' \
        "$1" "$2" "$vendor" "$2" >"$1/build/compile_commands.json"
}

setup_php() {
    # A project whose PHPStan config covers app/ only, as the starter's does.
    mkdir -p "$1/app"
    cp "$fixtures/php/good.php" "$1/app/Clean.php"
    printf 'parameters:\n    level: 5\n    paths:\n        - app/\n' >"$1/phpstan.neon"
}

verify_cpp() {
    # The hook applied clang-format, so CI's check must now pass.
    [[ "$1" == *.cpp ]] || return 0
    clang-format --dry-run -Werror "$1" 2>&1
}

# expect <stack> <mode> <fixture|-> <expected exit> [stop_hook_active] [dest dir in project]
expect() {
    local stack="$1" mode="$2" fixture="$3" want="$4" active="${5:-false}" dest="${6:-}"
    local hook="$repo/stacks/$stack/.claude/hooks/check-$stack.sh"
    local project="$scratch/$stack-$mode-${fixture//\//_}${dest:+-${dest//\//_}}"
    local target="" input got=0 err

    mkdir -p "$project"
    if [[ "$fixture" != "-" ]]; then
        target="$project/${dest:+$dest/}$(basename "$fixture")"
        mkdir -p "$(dirname "$target")"
        cp "$fixtures/$fixture" "$target"
    fi
    if declare -F "setup_$stack" >/dev/null; then
        "setup_$stack" "$project" "$target"
    fi
    input="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"},"stop_hook_active":%s}' "$target" "$active")"
    err="$(CLAUDE_PROJECT_DIR="$project" "$hook" "$mode" <<<"$input" 2>&1 >/dev/null)" || got=$?

    local label="$stack $mode $fixture${dest:+ in $dest/}"
    if [[ "$got" == 0 && "$want" == 0 ]] && declare -F "verify_$stack" >/dev/null; then
        err="$("verify_$stack" "$target")" || got="verify failed"
    fi
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

for stack in python shell rust cpp react php; do
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
expect cpp edit cpp/bad-format.cpp 0
expect cpp edit cpp/bad-tidy.cpp 2
# SDL-style interop is allowed in src/platform/ and blocked everywhere else.
expect cpp edit cpp/platform/pixels.cpp 0 false src/platform
expect cpp edit cpp/platform/pixels.cpp 2 false src
# Findings in project headers block; findings in FetchContent deps (build/_deps/) don't.
expect cpp edit cpp/uses-project-header.cpp 2 false src
expect cpp edit cpp/uses-vendor-header.cpp 0 false src

expect react edit react/good.ts 0
expect react stop - 0 true

expect php edit php/good.php 0 false app
expect php edit php/bad.php 2 false app
# Outside the configured paths: CI doesn't analyse it, so neither does the hook.
expect php edit php/bad.php 0 false tests
expect php stop php/bad.php 2 false app
expect php stop - 0 true

printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[[ "$fail" == 0 ]]
