#!/usr/bin/env bash
# Create or update a ruleset named "main" protecting the repo's default branch.
#   protect.sh [--repo owner/name] [--check ctx]... [--allow-admin-bypass] [--off|--on] [--dry-run]
# Idempotent: re-running updates the existing ruleset in place.
set -euo pipefail

# Built-in repository admin role, as used in GitHub's ruleset examples. There is no API to
# look up built-in role ids on a personal repo.
readonly ADMIN_ROLE_ID=5
readonly RULESET_NAME="main"

usage() {
    cat >&2 <<'EOF'
usage: protect.sh [--repo owner/name] [--check ctx]... [--allow-admin-bypass] [--off|--on] [--dry-run]
  --repo owner/name     target repo (default: the current directory's gh repo)
  --check ctx           required status check; repeatable (default: every check run that
                        reported on the default branch's latest commit)
  --allow-admin-bypass  let repository admins bypass (default: nobody bypasses)
  --off / --on          only disable / enable the existing ruleset, without deleting it
  --dry-run             print the JSON that would be sent and exit
EOF
    exit 1
}

die() {
    echo "protect: $*" >&2
    exit 1
}

# api_fail <what> <output>: report a failed gh api call, with the plan limit spelled out.
api_fail() {
    echo "protect: $1 failed: $2" >&2
    if [[ "$2" == *"403"* || "$2" == *[Uu]pgrade* ]]; then
        echo "protect: rulesets on a private repo need GitHub Pro (or make the repo public)" >&2
    fi
    exit 1
}

# discover_checks <repo>: names of the check runs on the default branch's latest commit.
discover_checks() {
    local branch out
    branch="$(gh api "repos/$1" --jq .default_branch 2>&1)" || api_fail "reading $1" "$branch"
    out="$(gh api --paginate "repos/$1/commits/$branch/check-runs?per_page=100" \
        --jq '.check_runs[].name' 2>&1)" || api_fail "reading check runs on $branch" "$out"
    printf '%s\n' "$out" | sed '/^$/d' | sort -u
}

# build_body <enforcement> <bypass:true|false> <check>...: the full ruleset JSON.
build_body() {
    local enforcement="$1" bypass="$2"
    shift 2
    if command -v jq >/dev/null 2>&1; then
        printf '%s\n' "$@" | jq -R . | jq -s \
            --arg name "$RULESET_NAME" --arg enf "$enforcement" \
            --argjson bypass "$bypass" --argjson role "$ADMIN_ROLE_ID" '{
          name: $name,
          target: "branch",
          enforcement: $enf,
          conditions: { ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] } },
          bypass_actors: (if $bypass then [{ actor_id: $role, actor_type: "RepositoryRole", bypass_mode: "always" }] else [] end),
          rules: [
            { type: "deletion" },
            { type: "non_fast_forward" },
            { type: "required_linear_history" },
            { type: "pull_request", parameters: {
                required_approving_review_count: 0,
                dismiss_stale_reviews_on_push: true,
                require_code_owner_review: false,
                require_last_push_approval: false,
                required_review_thread_resolution: true } },
            { type: "required_status_checks", parameters: {
                strict_required_status_checks_policy: true,
                required_status_checks: map({ context: . }) } }
          ]
        }'
    else
        python3 - "$RULESET_NAME" "$enforcement" "$bypass" "$ADMIN_ROLE_ID" "$@" <<'EOF'
import json, sys

name, enforcement, bypass, role, *checks = sys.argv[1:]
actors = [{"actor_id": int(role), "actor_type": "RepositoryRole", "bypass_mode": "always"}]
print(json.dumps({
    "name": name,
    "target": "branch",
    "enforcement": enforcement,
    "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
    "bypass_actors": actors if bypass == "true" else [],
    "rules": [
        {"type": "deletion"},
        {"type": "non_fast_forward"},
        {"type": "required_linear_history"},
        {"type": "pull_request", "parameters": {
            "required_approving_review_count": 0,
            "dismiss_stale_reviews_on_push": True,
            "require_code_owner_review": False,
            "require_last_push_approval": False,
            "required_review_thread_resolution": True}},
        {"type": "required_status_checks", "parameters": {
            "strict_required_status_checks_policy": True,
            "required_status_checks": [{"context": c} for c in checks]}},
    ],
}, indent=2))
EOF
    fi
}

repo=""
checks=()
bypass=false
toggle=""
dry_run=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            [[ $# -ge 2 ]] || usage
            repo="$2"
            shift 2
            ;;
        --check)
            [[ $# -ge 2 ]] || usage
            checks+=("$2")
            shift 2
            ;;
        --allow-admin-bypass)
            bypass=true
            shift
            ;;
        --off)
            toggle="disabled"
            shift
            ;;
        --on)
            toggle="active"
            shift
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        *) usage ;;
    esac
done

command -v gh >/dev/null 2>&1 || die "gh not found (https://cli.github.com)"
command -v jq >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || die "needs jq or python3"
gh auth status >/dev/null 2>&1 || die "gh is not logged in (gh auth login)"
if [[ -z "$repo" ]]; then
    repo="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" ||
        die "not in a GitHub repo; pass --repo owner/name"
fi

existing="$(gh api "repos/$repo/rulesets?includes_parents=false&per_page=100" \
    --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>&1)" ||
    api_fail "listing rulesets on $repo" "$existing"

if [[ -n "$toggle" ]]; then
    # Only flip enforcement; the rules and checks already set stay as they are.
    body="{\"enforcement\": \"$toggle\"}"
    if [[ "$dry_run" == true ]]; then
        printf '%s\n' "$body"
        exit 0
    fi
    [[ -n "$existing" ]] || die "no ruleset \"$RULESET_NAME\" on $repo; run without --off/--on first"
    out="$(printf '%s' "$body" | gh api -X PUT "repos/$repo/rulesets/$existing" --input - 2>&1)" ||
        api_fail "update" "$out"
    echo "updated  ruleset $RULESET_NAME (#$existing) on $repo: enforcement=$toggle"
    exit 0
fi

if [[ ${#checks[@]} -eq 0 ]]; then
    discovered="$(discover_checks "$repo")" || exit 1
    # A read loop, not mapfile: mapfile needs bash 4 and macOS ships 3.2.
    if [[ -n "$discovered" ]]; then
        while IFS= read -r check; do checks+=("$check"); done <<<"$discovered"
    fi
    [[ ${#checks[@]} -gt 0 ]] ||
        die "no check runs on $repo's default branch yet; push CI first or pass --check"
fi

body="$(build_body active "$bypass" "${checks[@]}")"
if [[ "$dry_run" == true ]]; then
    printf '%s\n' "$body"
    exit 0
fi

if [[ -n "$existing" ]]; then
    out="$(printf '%s' "$body" | gh api -X PUT "repos/$repo/rulesets/$existing" --input - 2>&1)" ||
        api_fail "update" "$out"
    echo "updated  ruleset $RULESET_NAME (#$existing) on $repo: enforcement=active checks=${checks[*]}"
else
    out="$(printf '%s' "$body" | gh api -X POST "repos/$repo/rulesets" --input - 2>&1)" ||
        api_fail "create" "$out"
    echo "created  ruleset $RULESET_NAME on $repo: enforcement=active checks=${checks[*]}"
fi
