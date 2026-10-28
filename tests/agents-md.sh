#!/usr/bin/env bash
# Check the AGENTS.md / CLAUDE.md split in every stack: AGENTS.md holds what any agent needs,
# CLAUDE.md imports it with @AGENTS.md and adds only Claude Code specifics, and nothing is in both.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The old singular file name, split so this script does not match its own search.
singular="AGENT"".md"
pass=0
fail=0

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

# imports <claude.md>: the file has an @AGENTS.md import on a line of its own.
imports() {
    grep -qx '@AGENTS.md' "$1"
}

# disjoint <a> <b>: no non-blank line appears in both files. Prints the shared lines on failure.
disjoint() {
    local shared
    shared="$(comm -12 <(grep -v '^[[:space:]]*$' "$1" | sort -u) <(grep -v '^[[:space:]]*$' "$2" | sort -u))"
    [[ -z "$shared" ]] || {
        printf '      shared: %s\n' "$shared"
        return 1
    }
}

# no_singular: no tracked file outside the decisions logs names the old singular file.
no_singular() {
    ! git -C "$repo" grep -nF "$singular" -- . ':!docs/decisions.md' ':!stacks/*/docs/decisions.md'
}

check "root: AGENTS.md exists" test -f "$repo/AGENTS.md"
for stack in "$repo"/stacks/*/; do
    stack="${stack%/}"
    name="$(basename "$stack")"
    check "$name: AGENTS.md exists" test -f "$stack/AGENTS.md"
    check "$name: no $singular" test ! -e "$stack/$singular"
    check "$name: CLAUDE.md imports @AGENTS.md" imports "$stack/CLAUDE.md"
    check "$name: no line in both files" disjoint "$stack/AGENTS.md" "$stack/CLAUDE.md"
done
check "no reference to the singular file" no_singular

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
