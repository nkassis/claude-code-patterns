#!/usr/bin/env bash
# Run github/check-workflow-refs.sh against tests/fixtures/workflow-refs/: every accepted form
# passes, every rejected form is reported at its line, and the exit codes match the contract.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo/github/check-workflow-refs.sh"
fixtures="$repo/tests/fixtures/workflow-refs"
pass=0
fail=0

ok() {
    echo "PASS $1"
    pass=$((pass + 1))
}
ko() {
    echo "FAIL $1"
    fail=$((fail + 1))
}

# expect_exit <name> <code> <args>...: the script exits with <code>.
expect_exit() {
    local name="$1" want="$2" got=0
    shift 2
    "$script" "$@" >/dev/null 2>&1 || got=$?
    if [[ "$got" == "$want" ]]; then ok "$name"; else ko "$name (exit $got, want $want)"; fi
}

expect_exit "good fixture passes" 0 "$fixtures/good.yml"
expect_exit "bad fixture fails" 1 "$fixtures/bad.yml"
expect_exit "a bad file among good ones fails" 1 "$fixtures/good.yml" "$fixtures/bad.yml"
expect_exit "no arguments is a usage error" 2
expect_exit "unreadable file is a usage error" 2 "$fixtures/missing.yml"

out="$("$script" "$fixtures/bad.yml" || true)"
# line:what the message must contain
for want in \
    "8:actions/checkout@v4 follows a floating tag" \
    "9:actions/setup-node@v4.4 follows a floating tag" \
    "10:owner/action@main follows a floating tag or branch" \
    "11:owner/action@master follows a floating tag or branch" \
    "12:owner/action has no @ref" \
    "14:reusable workflow owner/repo/.github/workflows/reusable.yml@v1.2.3 must be pinned to a full commit SHA" \
    "16:reusable workflow owner/repo/.github/workflows/reusable.yml@11d5960 must be pinned to a full commit SHA" \
    "18:needs the version in a trailing comment"; do
    line="${want%%:*}"
    text="${want#*:}"
    if grep -qF "$fixtures/bad.yml:$line: " <<<"$out" && grep -F "$fixtures/bad.yml:$line: " <<<"$out" | grep -qF "$text"; then
        ok "bad.yml:$line reported"
    else
        ko "bad.yml:$line not reported as: $text"
    fi
done
count="$(grep -c . <<<"$out")"
if [[ "$count" == 8 ]]; then ok "exactly 8 findings"; else ko "exactly 8 findings (got $count)"; fi

expect_exit "repo and template workflows pass" 0 \
    "$repo"/.github/workflows/*.yml "$repo"/stacks/*/.github/workflows/*.yml "$repo"/security/.github/workflows/*.yml

echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
