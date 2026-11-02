#!/usr/bin/env bash
# Exercise skills/readme/readme-lint.sh: this repo's READMEs pass, and the fixture under
# tests/fixtures/readme/bad/ yields exactly one finding per rule.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lint="$repo/skills/readme/readme-lint.sh"
pass=0
fail=0

ok() {
    printf 'PASS  %s\n' "$1"
    pass=$((pass + 1))
}

ko() {
    printf 'FAIL  %s\n%s\n' "$1" "${2:-}"
    fail=$((fail + 1))
}

# clean <readme>: the lint exits 0 and prints nothing.
clean() {
    local out got=0
    out="$(cd "$repo" && "$lint" "$1" 2>&1)" || got=$?
    if [[ "$got" == 0 && -z "$out" ]]; then
        ok "clean $1"
    else
        ko "clean $1: exit $got" "$out"
    fi
}

clean README.md
clean security/README.md
clean github/README.md

# The bad fixture: exit 1, and each pattern matches exactly one finding line.
bad=0
out="$(cd "$repo" && "$lint" tests/fixtures/readme/bad/README.md 2>&1)" || bad=$?
fixture="tests/fixtures/readme/bad"
if [[ "$bad" == 1 ]]; then
    ok "bad fixture exits 1"
else
    ko "bad fixture exits 1: exit $bad" "$out"
fi

# finds <label> <pattern>: exactly one finding line matches the extended regex.
finds() {
    local n
    n="$(grep -cE "$2" <<<"$out" || true)"
    if [[ "$n" == 1 ]]; then
        ok "finds $1"
    else
        ko "finds $1: $n matching lines, want 1" "$out"
    fi
}

finds "line budget" "^$fixture/README.md:1: [0-9]+ lines, budget is under 100"
finds "byte budget" "^$fixture/README.md:1: [0-9]+ bytes, budget is under 10240"
finds "late first command" "^$fixture/README.md:[0-9]+: first fenced command block is at line"
finds "long paragraph" "^$fixture/README.md:[0-9]+: paragraph has 4 sentences"
finds "banned heading" "^$fixture/README.md:[0-9]+: banned heading \"## Features\""
finds "em dash in docs" "^$fixture/docs/page.md:3: em dash"
finds "broken link" "^$fixture/README.md:[0-9]+: link target docs/missing.md does not exist"
finds "orphan docs page" "^$fixture/docs/orphan.md:1: orphan"

total="$(grep -c . <<<"$out" || true)"
if [[ "$total" == 8 ]]; then
    ok "bad fixture has 8 findings, none from the exempt decision log"
else
    ko "bad fixture has $total findings, want 8" "$out"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
((fail == 0))
