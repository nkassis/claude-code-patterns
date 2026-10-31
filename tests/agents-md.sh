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

# analysis_section <agents.md>: the "### Analysis" block, up to the next heading.
analysis_section() {
    awk '/^### Analysis$/ { on = 1; next } on && /^#/ { exit } on' "$1"
}

# analysis <agents.md> <row>...: the Analysis block has at most three table rows, and one row
# per <row>, given as "<label>=<tool>": a row whose description starts with <label> and whose
# command names <tool>.
analysis() {
    local file="$1" section row label tool
    shift
    section="$(analysis_section "$file")"
    [[ -n "$section" ]] || {
        printf '      no ### Analysis block\n'
        return 1
    }
    [[ "$(grep -c '^| `' <<<"$section")" -le 3 ]] || {
        printf '      more than three rows\n'
        return 1
    }
    for row in "$@"; do
        label="${row%%=*}"
        tool="${row#*=}"
        grep -q "^| \`[^|]*${tool}[^|]*\` | ${label}" <<<"$section" || {
            printf '      no "%s" row naming %s\n' "$label" "$tool"
            return 1
        }
    done
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
    # Every stack counts lines and finds duplication; each names its dead-code tool here, so
    # a new stack fails until it picks one (or is added to the shell case, with a reason).
    rows=("Count lines=scc" "Find duplication=jscpd")
    case "$name" in
        python) rows+=("Find dead code=vulture") ;;
        react) rows+=("Find dead code=knip") ;;
        rust) rows+=("Find dead code=cargo machete") ;;
        cpp) rows+=("Find dead code=cppcheck") ;;
        php) rows+=("Find dead code=phpstan.sweep.neon") ;;
        shell) ;; # no dead-code tool: SC2034 already reports unused variables
        *) rows+=("Find dead code=") ;;
    esac
    check "$name: Analysis block" analysis "$stack/AGENTS.md" "${rows[@]}"
done
check "no reference to the singular file" no_singular

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" == 0 ]]
