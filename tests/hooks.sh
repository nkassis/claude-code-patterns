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

# Optional per-stack hooks: setup_<stack> <project> <target> <mode> prepares the scratch project;
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

setup_python() {
    # Stop runs in a uv project only. Give it one with the starter's mypy.ini and the dev tools
    # it calls; uv resolves them on first run. Edit cases stay project-less (the uvx fallback).
    [[ "$3" == stop && -n "$2" ]] || return 0
    cp "$repo/stacks/python/mypy.ini" "$1/"
    local mypy
    mypy="$(grep -o 'mypy==[0-9.]*' "$repo/stacks/python/AGENTS.md")"
    printf '[project]\nname = "fixture"\nversion = "0"\nrequires-python = ">=3.10"\ndependencies = ["pydantic"]\n\n[dependency-groups]\ndev = ["ruff", "%s"]\n\n[tool.uv]\npackage = false\n' \
        "$mypy" >"$1/pyproject.toml"
}

setup_php() {
    # A project whose PHPStan config covers app/ only, at the starter's level. Larastan's
    # include is left out: the fixtures aren't a Laravel app.
    local level
    level="$(sed -n 's/^ *level: *//p' "$repo/stacks/php/phpstan.neon.dist")"
    mkdir -p "$1/app"
    cp "$fixtures/php/good.php" "$1/app/Clean.php"
    printf 'parameters:\n    level: %s\n    paths:\n        - app/\n' "$level" >"$1/phpstan.neon"
}

verify_cpp() {
    # The hook applied clang-format, so CI's check must now pass.
    [[ "$1" == *.cpp ]] || return 0
    clang-format --dry-run -Werror "$1" 2>&1
}

# Astro's linters come from one install, shared by every case through a node_modules symlink.
astro_deps="$scratch/astro-deps"
astro_install=""

install_astro_deps() {
    [[ -z "$astro_install" ]] || return 0
    astro_install=unavailable
    command -v pnpm >/dev/null 2>&1 || return 0
    mkdir -p "$astro_deps"
    cp "$fixtures/astro/project/package.json" "$astro_deps/"
    if pnpm --dir "$astro_deps" install >/dev/null 2>&1; then
        astro_install=ready
    fi
}

ready_astro() {
    [[ "$astro_install" == ready ]]
}

setup_astro() {
    # The site is the project root, or site/ when the case puts its file there.
    local site="$1"
    [[ "$2" != "$1"/site/* ]] || site="$1/site"
    install_astro_deps
    cp "$fixtures/astro/project/.prettierrc" "$fixtures/astro/project/eslint.config.mjs" "$site/"
    [[ -f "$site/package.json" ]] || cp "$fixtures/astro/project/package.json" "$site/"
    if ready_astro; then
        ln -s "$astro_deps/node_modules" "$site/node_modules"
    fi
}

verify_astro() {
    # The hook applied Prettier: the unformatted fixture must now match the formatted one.
    [[ "$1" == */unformatted.astro ]] || return 0
    cmp "$1" "$fixtures/astro/good.astro" 2>&1
}

# must_run <stack>: the stack declares ready_<stack> and it holds, so its tools are installed
# and a hook exiting 1 is a failure, not a SKIP.
must_run() {
    declare -F "ready_$1" >/dev/null && "ready_$1"
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
        "setup_$stack" "$project" "$target" "$mode"
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
    elif [[ "$got" == 1 ]] && ! must_run "$stack"; then
        printf 'SKIP  %s (%s)\n' "$label" "${err%%$'\n'*}"
        skip=$((skip + 1))
    else
        printf 'FAIL  %s: exit %s, want %s\n%s\n' "$label" "$got" "$want" "$err"
        fail=$((fail + 1))
    fi
}

for stack in python shell rust cpp react php astro; do
    expect "$stack" edit other.txt 0
done

expect python edit python/good.py 0
expect python edit python/bad.py 2
expect python stop - 0 true
# mypy strict on Stop: a clean project (Pydantic plugin loaded) passes; an unannotated def blocks.
expect python stop python/good.py 0
expect python stop python/model.py 0
expect python stop python/untyped.py 2

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
# AGENTS.md requires parameter and return types; the starter's level must report them.
expect php edit php/untyped-method.php 2 false app
expect php stop php/untyped-method.php 2 false app
# Outside the configured paths: CI doesn't analyse it, so neither does the hook.
expect php edit php/bad.php 0 false tests
expect php stop php/bad.php 2 false app
expect php stop - 0 true

expect astro edit astro/good.astro 0 false src
expect astro edit astro/unformatted.astro 0 false src
expect astro edit astro/bad.astro 2 false src
# package.json in a subdirectory, none at the project root.
expect astro edit astro/unformatted.astro 0 false site/src
expect astro edit astro/bad.astro 2 false site/src
expect astro stop astro/stop-pass/package.json 0
expect astro stop astro/stop-fail/package.json 2
expect astro stop astro/stop-missing/package.json 1
expect astro stop - 0 true

# Cases the exit code alone can't show, run directly on one project.
astro_hook="$repo/stacks/astro/.claude/hooks/check-astro.sh"

# A missing `check` script warns by name. Needs no pnpm: the script is looked for first.
astro_missing="$scratch/astro-missing"
mkdir -p "$astro_missing"
cp "$fixtures/astro/stop-missing/package.json" "$astro_missing/"
astro_err="$(CLAUDE_PROJECT_DIR="$astro_missing" "$astro_hook" stop <<<'{}' 2>&1 >/dev/null)" || true
if [[ "$astro_err" == *'"check" script'* ]]; then
    printf 'PASS  astro stop names the missing check script\n'
    pass=$((pass + 1))
else
    printf 'FAIL  astro stop: no message naming the missing check script\n'
    fail=$((fail + 1))
fi

# astro_edit <project> <file>: run the edit hook, which records the file's package for Stop.
astro_edit() {
    local input
    input="$(printf '{"tool_input":{"file_path":"%s"}}' "$2")"
    CLAUDE_PROJECT_DIR="$1" "$astro_hook" edit <<<"$input" >/dev/null 2>&1 || true
}

# astro_stop_after_edits <label> <root fixture|-> <site fixture> <expected exit>: edit a file in
# the root package (when there is one), then one in site/, then run Stop on the project.
astro_stop_after_edits() {
    local label="$1" root_fixture="$2" site_fixture="$3" want="$4" got=0
    local project="$scratch/astro-after-edits-${label// /-}"
    mkdir -p "$project/site/src"
    cp "$fixtures/astro/$site_fixture/package.json" "$project/site/"
    cp "$fixtures/astro/good.astro" "$project/site/src/"
    setup_astro "$project" "$project/site/src/good.astro" edit
    if [[ "$root_fixture" != - ]]; then
        cp "$fixtures/astro/$root_fixture/package.json" "$project/"
        printf '{}\n' >"$project/tooling.json"
        astro_edit "$project" "$project/tooling.json"
    fi
    astro_edit "$project" "$project/site/src/good.astro"
    CLAUDE_PROJECT_DIR="$project" "$astro_hook" stop <<<'{}' >/dev/null 2>&1 || got=$?
    if [[ "$got" == "$want" ]]; then
        printf 'PASS  astro stop: %s\n' "$label"
        pass=$((pass + 1))
    else
        printf 'FAIL  astro stop: %s: exit %s, want %s\n' "$label" "$got" "$want"
        fail=$((fail + 1))
    fi
}

# Stop's input has no file path: the edit hooks record the packages and Stop checks each one.
if ready_astro; then
    astro_stop_after_edits "runs check in the recorded subdirectory" - stop-fail 2
    astro_stop_after_edits "checks the site after a package with no check script" stop-missing stop-fail 2
    astro_stop_after_edits "checks the site after a package with no node_modules" stop-pass stop-fail 2
    astro_stop_after_edits "warns when one package is skipped and the site passes" stop-missing stop-pass 1
else
    printf 'SKIP  astro stop with recorded packages (pnpm or the fixture install unavailable)\n'
    skip=$((skip + 1))
fi

# The astro stack's CI link check, with the flags from its workflow. CI gets lychee from the
# action the stack uses. links <label> <pass|fail> <href>: the site has pages at /about/ and
# /blog/post/ only, and its home page links to href.
links() {
    local label="$1" want="$2" href="$3" site="$scratch/links-$2" got=pass args
    mkdir -p "$site/dist/about" "$site/dist/blog/post"
    printf '<a href="%s">link</a>\n' "$href" >"$site/dist/index.html"
    printf '<a href="/">home</a>\n' >"$site/dist/about/index.html"
    printf '<a href="/">home</a>\n' >"$site/dist/blog/post/index.html"
    read -ra args <<<"${lychee_args//@SITE@/$site}"
    (cd "$site" && lychee "${args[@]}") >/dev/null 2>&1 || got=fail
    if [[ "$got" == "$want" ]]; then
        printf 'PASS  astro link check: %s\n' "$label"
        pass=$((pass + 1))
    else
        printf 'FAIL  astro link check: %s: %s, want %s\n' "$label" "$got" "$want"
        fail=$((fail + 1))
    fi
}

if command -v lychee >/dev/null 2>&1; then
    lychee_args="$(sed -n -e 's/^ *args: //' -e 's/\${{ github.workspace }}/@SITE@/p' "$repo/stacks/astro/.github/workflows/ci.yml")"
    lychee_args="${lychee_args//\'/}"
    links "a directory route with an index page" pass /about/
    links "a directory with only child pages" fail /blog/
else
    printf 'SKIP  astro link check (lychee not installed)\n'
    skip=$((skip + 1))
fi

# security/.claude/hooks/guard-bash.sh: PreToolUse on Bash. A scratch repo on main with a
# worktree on a feature branch; each case runs one command line from one of them.
git_q() { git -c user.name=test -c user.email=test@example.com "$@" >/dev/null 2>&1; }
main_repo="$scratch/guard-main"
feature_repo="$scratch/guard-feature"
git_q init -b main "$main_repo"
git_q -C "$main_repo" commit --allow-empty -m init
git_q -C "$main_repo" worktree add -b feat "$feature_repo"

# guard <expected exit> <main|feature> <command line>
guard() {
    local want="$1" where="$2" cmd="$3" dir got=0 err input
    [[ "$where" == main ]] && dir="$main_repo" || dir="$feature_repo"
    cmd="${cmd//\\/\\\\}"
    input="$(printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "${cmd//\"/\\\"}" "$dir")"
    err="$(CLAUDE_PROJECT_DIR="$dir" "$repo/security/.claude/hooks/guard-bash.sh" <<<"$input" 2>&1)" || got=$?
    if [[ "$got" == "$want" ]]; then
        printf 'PASS  guard on %s: %s\n' "$where" "$3"
        pass=$((pass + 1))
    else
        printf 'FAIL  guard on %s: %s: exit %s, want %s\n%s\n' "$where" "$3" "$got" "$want" "$err"
        fail=$((fail + 1))
    fi
}

# Blocked: commit on main, push to main, force push, delete main.
guard 2 main 'git commit -m "wip"'
guard 2 main 'git commit --amend --no-edit'
guard 2 feature "git -C $main_repo commit -m wip"
guard 2 feature "cd $main_repo && git commit -m wip"
guard 2 feature 'git add -A && git commit -m wip; git push origin main'
guard 2 feature 'git push origin HEAD:main'
guard 2 feature 'git push origin feat:refs/heads/master'
guard 2 feature 'git push origin :main'
guard 2 feature 'git push origin --delete main'
guard 2 main 'git push'
guard 2 main 'git push origin'
guard 2 main 'git push -u origin HEAD'
guard 2 feature 'git push --all origin'
guard 2 feature 'git push -f origin feat'
guard 2 feature 'git push -uf origin feat'
guard 2 feature 'git push --force origin feat'
guard 2 feature 'git push --force-with-lease origin feat'
guard 2 feature 'git push origin +feat'
guard 2 feature 'git branch -D main'
guard 2 feature 'git branch -d master'
guard 2 feature 'git branch --delete --force main'

# Allowed: the normal feature-branch flow, and reads.
guard 0 feature 'git commit -m "fix: guard main; tests for git push origin main"'
guard 0 feature 'git push -u origin feat'
guard 0 feature 'git push -u origin HEAD'
guard 0 feature 'git push'
guard 0 feature 'git push origin feat:feat'
guard 0 main "cd $feature_repo && git commit -m wip && git push -u origin feat"
guard 0 main 'git fetch origin'
guard 0 main 'git pull --ff-only'
guard 0 main 'git switch -c feat-2'
guard 0 main 'git log --oneline main'
guard 0 feature 'git branch -D old-feature'
guard 0 main 'echo "git push origin main"'
guard 0 main 'ls'

# security/.pre-commit-config.yaml: no-commit-to-branch rejects a real commit on main.
# Needs pre-commit (CI installs it) and network for the first hook-repo clone.
if command -v pre-commit >/dev/null 2>&1; then
    precommit_repo="$scratch/precommit"
    git_q init -b main "$precommit_repo"
    cp "$repo/security/.pre-commit-config.yaml" "$precommit_repo/.pre-commit-config.yaml"
    git_q -C "$precommit_repo" add .pre-commit-config.yaml
    (cd "$precommit_repo" && pre-commit install >/dev/null)
    # trufflehog is a system binary that CI doesn't install; it isn't what this case tests.
    if SKIP=trufflehog git_q -C "$precommit_repo" commit -m "on main"; then
        printf 'FAIL  pre-commit no-commit-to-branch: commit on main succeeded\n'
        fail=$((fail + 1))
    else
        printf 'PASS  pre-commit no-commit-to-branch rejects a commit on main\n'
        pass=$((pass + 1))
    fi
    git_q -C "$precommit_repo" switch -c feat
    if SKIP=trufflehog git_q -C "$precommit_repo" commit -m "on feat"; then
        printf 'PASS  pre-commit no-commit-to-branch allows a commit on a feature branch\n'
        pass=$((pass + 1))
    else
        printf 'FAIL  pre-commit no-commit-to-branch: commit on feat rejected\n'
        fail=$((fail + 1))
    fi
else
    printf 'SKIP  pre-commit no-commit-to-branch (pre-commit not installed)\n'
    skip=$((skip + 1))
fi

printf '\n%d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"
[[ "$fail" == 0 ]]
