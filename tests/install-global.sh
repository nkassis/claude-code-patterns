#!/usr/bin/env bash
# Exercise install-global.sh against a fake $HOME: a clean machine, a re-run, an existing
# real ~/.claude/CLAUDE.md with and without --force, a stale symlink, and a worktree.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0
fail=0

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# A copy of the repo's installable parts, outside git, so the worktree guard doesn't fire.
src="$scratch/src"
mkdir -p "$src"
cp -r "$repo/install-global.sh" "$repo/CLAUDE-global.md" "$repo/skills" "$src/"

check() {
    local label="$1"
    shift
    if "$@"; then
        printf 'PASS  %s\n' "$label"
        pass=$((pass + 1))
    else
        printf 'FAIL  %s\n' "$label"
        fail=$((fail + 1))
    fi
}

# run <home> [args...]: run the installer, record its exit code in $got.
run() {
    local home="$1"
    shift
    got=0
    HOME="$home" "$src/install-global.sh" "$@" >/dev/null 2>&1 || got=$?
}

linked() {
    [[ -L "$1/.claude/CLAUDE.md" && "$(readlink "$1/.claude/CLAUDE.md")" == "$src/CLAUDE-global.md" ]] || return 1
    local skill
    for skill in "$src"/skills/*/; do
        skill="${skill%/}"
        [[ "$(readlink "$1/.claude/skills/$(basename "$skill")")" == "$skill" ]] || return 1
    done
}

home="$scratch/clean"
mkdir -p "$home"
run "$home"
check "clean home: exit 0" test "$got" = 0
check "clean home: CLAUDE.md and every skill linked" linked "$home"
run "$home"
check "re-run: exit 0, still linked" test "$got" = 0 -a "$(linked "$home" && echo y)" = y

home="$scratch/existing"
mkdir -p "$home/.claude/skills/other"
echo "mine" >"$home/.claude/CLAUDE.md"
run "$home"
check "real CLAUDE.md: exit 1" test "$got" = 1
check "real CLAUDE.md: left untouched" test "$(cat "$home/.claude/CLAUDE.md")" = mine
check "real CLAUDE.md: skills still linked" test -L "$home/.claude/skills/readme"
check "unrelated skill dir left alone" test -d "$home/.claude/skills/other" -a ! -L "$home/.claude/skills/other"
run "$home" --force
check "--force: exit 0" test "$got" = 0
check "--force: old file kept as CLAUDE.md.bak" test "$(cat "$home/.claude/CLAUDE.md.bak")" = mine
check "--force: linked" linked "$home"
run "$home" --force
check "--force re-run with .bak present: exit 0" test "$got" = 0

home="$scratch/stale"
mkdir -p "$home/.claude"
ln -s /nonexistent/CLAUDE.md "$home/.claude/CLAUDE.md"
run "$home"
check "stale symlink: relinked without --force" test "$got" = 0 -a "$(linked "$home" && echo y)" = y

run "$scratch/clean" --bogus
check "unknown flag: exit 1" test "$got" = 1

# A worktree's links would dangle once it is removed, so the installer refuses.
main="$scratch/main"
cp -r "$src" "$main"
git -C "$main" init -q
git -C "$main" add -A
git -C "$main" -c user.name=t -c user.email=t@t commit -qm init
git -C "$main" worktree add -q "$scratch/wt" -b wt
home="$scratch/wt-home"
mkdir -p "$home"
got=0
HOME="$home" "$scratch/wt/install-global.sh" >/dev/null 2>&1 || got=$?
check "worktree: exit 1, nothing linked" test "$got" = 1 -a ! -e "$home/.claude/CLAUDE.md"
got=0
HOME="$home" "$main/install-global.sh" >/dev/null 2>&1 || got=$?
check "main clone in git: exit 0" test "$got" = 0

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
