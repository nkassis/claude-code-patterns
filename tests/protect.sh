#!/usr/bin/env bash
# Exercise github/protect.sh against a stub gh on PATH: check discovery and overrides, the
# JSON it sends, create vs update, --off/--on, the plan-limit error, and the python3 fallback.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo/github/protect.sh"
pass=0
fail=0

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# The stub answers each gh call protect.sh makes, already filtered as --jq would leave it.
# STUB_EXISTING: id of an existing "main" ruleset; STUB_CHECKS: check run names, one per line;
# STUB_LIST_ERROR: make the ruleset listing fail with this text. Writes go to $STUB_LOG and
# their bodies to $STUB_BODY.
mkdir -p "$scratch/bin"
cat >"$scratch/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
    "auth status") exit 0 ;;
    "repo view") echo "stub/repo"; exit 0 ;;
esac
method=GET path=""
for arg in "$@"; do
    case "$arg" in
        PUT | POST) method="$arg" ;;
        repos/*) path="$arg" ;;
    esac
done
if [[ "$method" != GET ]]; then
    echo "$method $path" >>"$STUB_LOG"
    cat >"$STUB_BODY"
    echo '{}'
    exit 0
fi
case "$path" in
    */rulesets\?*)
        if [[ -n "${STUB_LIST_ERROR:-}" ]]; then
            echo "$STUB_LIST_ERROR" >&2
            exit 1
        fi
        [[ -z "${STUB_EXISTING:-}" ]] || echo "$STUB_EXISTING"
        ;;
    */check-runs*) [[ -z "${STUB_CHECKS:-}" ]] || printf '%s\n' "$STUB_CHECKS" ;;
    repos/stub/repo) echo main ;;
    *) echo "stub gh: unexpected $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$scratch/bin/gh"

export STUB_LOG="$scratch/log" STUB_BODY="$scratch/body"

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

# run [args...]: run protect.sh with the stub first on PATH; sets $got, $out, $err.
run() {
    : >"$STUB_LOG"
    rm -f "$STUB_BODY"
    got=0
    PATH="$scratch/bin:$PATH" "$script" "$@" >"$scratch/out" 2>"$scratch/err" || got=$?
    out="$(cat "$scratch/out")"
    err="$(cat "$scratch/err")"
}

# field <json> <python expression over j>: print a value from the JSON.
field() {
    python3 -c 'import json, sys; j = json.loads(sys.argv[1]); print(eval(sys.argv[2]))' "$1" "$2"
}

contexts='[c["context"] for r in j["rules"] if r["type"] == "required_status_checks" for c in r["parameters"]["required_status_checks"]]'
rule_types='sorted(r["type"] for r in j["rules"])'

export STUB_CHECKS=$'ci\nsecret-scan\nci' STUB_EXISTING=""

run --dry-run
check "dry-run: exit 0" test "$got" = 0
check "dry-run: sends nothing" test ! -s "$STUB_LOG"
check "dry-run: discovered checks, deduplicated" test "$(field "$out" "$contexts")" = "['ci', 'secret-scan']"
check "dry-run: every rule" test "$(field "$out" "$rule_types")" = \
    "['deletion', 'non_fast_forward', 'pull_request', 'required_linear_history', 'required_status_checks']"
check "dry-run: active, default branch, no bypass" test \
    "$(field "$out" '(j["enforcement"], j["conditions"]["ref_name"]["include"], j["bypass_actors"])')" = \
    "('active', ['~DEFAULT_BRANCH'], [])"
check "dry-run: strict, 0 approvals" test \
    "$(field "$out" '[(r["parameters"].get("strict_required_status_checks_policy"), r["parameters"].get("required_approving_review_count")) for r in j["rules"] if "parameters" in r]')" = \
    "[(None, 0), (True, None)]"

run --dry-run --check build --check lint
check "--check overrides discovery" test "$(field "$out" "$contexts")" = "['build', 'lint']"

run --dry-run --allow-admin-bypass
check "--allow-admin-bypass: admin role, always" test "$(field "$out" 'j["bypass_actors"]')" = \
    "[{'actor_id': 5, 'actor_type': 'RepositoryRole', 'bypass_mode': 'always'}]"

STUB_CHECKS="" run
check "no check runs: exit 1" test "$got" = 1
check "no check runs: says to pass --check" grep -q -- "--check" <<<"$err"
check "no check runs: sends nothing" test ! -s "$STUB_LOG"

run
check "no ruleset yet: exit 0" test "$got" = 0
check "no ruleset yet: POST to rulesets" test "$(cat "$STUB_LOG")" = "POST repos/stub/repo/rulesets"
check "no ruleset yet: sends the full body" test "$(field "$(cat "$STUB_BODY")" "$contexts")" = "['ci', 'secret-scan']"

STUB_EXISTING=42 run
check "existing ruleset: exit 0" test "$got" = 0
check "existing ruleset: PUT to its id" test "$(cat "$STUB_LOG")" = "PUT repos/stub/repo/rulesets/42"

STUB_EXISTING=42 run --off
check "--off: PUT to the existing id" test "$(cat "$STUB_LOG")" = "PUT repos/stub/repo/rulesets/42"
check "--off: sends only enforcement=disabled" test "$(field "$(cat "$STUB_BODY")" 'j')" = "{'enforcement': 'disabled'}"
STUB_EXISTING=42 run --on
check "--on: sends only enforcement=active" test "$(field "$(cat "$STUB_BODY")" 'j')" = "{'enforcement': 'active'}"

run --off
check "--off without a ruleset: exit 1" test "$got" = 1
check "--off without a ruleset: sends nothing" test ! -s "$STUB_LOG"

STUB_LIST_ERROR="HTTP 403: Upgrade to GitHub Pro or make this repository public" run
check "plan limit: exit 1" test "$got" = 1
check "plan limit: names GitHub Pro" grep -q "need GitHub Pro" <<<"$err"
check "plan limit: sends nothing" test ! -s "$STUB_LOG"

# python3 fallback: a PATH holding only what protect.sh needs, without jq.
mkdir -p "$scratch/nojq"
for tool in bash env sed sort cat python3; do
    ln -sf "$(command -v "$tool")" "$scratch/nojq/$tool"
done
ln -sf "$scratch/bin/gh" "$scratch/nojq/gh"
jq_out=""
if command -v jq >/dev/null 2>&1; then
    run --dry-run --allow-admin-bypass
    jq_out="$out"
fi
got=0
py_out="$(PATH="$scratch/nojq" "$script" --dry-run --allow-admin-bypass 2>"$scratch/err")" || got=$?
check "python3 fallback: exit 0" test "$got" = 0
check "python3 fallback: discovered checks" test "$(field "$py_out" "$contexts")" = "['ci', 'secret-scan']"
if [[ -n "$jq_out" ]]; then
    check "python3 fallback: same JSON as jq" test "$(field "$py_out" 'j')" = "$(field "$jq_out" 'j')"
else
    printf 'SKIP  python3 fallback: same JSON as jq (jq not installed)\n'
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
