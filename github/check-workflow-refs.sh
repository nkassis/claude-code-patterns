#!/usr/bin/env bash
# Check the `uses:` refs in GitHub Actions workflow files.
#   check-workflow-refs.sh <workflow.yml>...
# Two rules, one finding per line as file:line: message:
#   - A call to a reusable workflow in another repo (owner/repo/.github/workflows/x.yml@ref)
#     is pinned to a full 40 character commit SHA, with the version in a trailing comment.
#     The workflow lockfile does not lock these. Same-repo calls (./.github/workflows/...) are exempt.
#   - No action is pinned to a floating tag (v4, v4.1) or a branch (main, master).
# Exit 0 when clean, 1 on any finding, 2 on a usage error.
set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: check-workflow-refs.sh <workflow.yml>..." >&2
    exit 2
fi

# Group 2 is the uses value, group 3 the trailing comment.
readonly USES_RE="^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[\"']?([^\"'#[:space:]]+)[\"']?[[:space:]]*(#.*)?$"
readonly SHA_RE='^[0-9a-f]{40}$'
readonly FLOATING_RE='^v?[0-9]+(\.[0-9]+)?$'

# check_uses <value> <comment>: print the problem with one uses value, if any.
check_uses() {
    local value="$1" comment="$2" ref
    case "$value" in
        ./* | docker://*) return 0 ;;
        *@*) ref="${value##*@}" ;;
        *)
            echo "$value has no @ref"
            return 0
            ;;
    esac
    if [[ "$value" == */.github/workflows/* ]]; then
        if [[ ! "$ref" =~ $SHA_RE ]]; then
            echo "reusable workflow $value must be pinned to a full commit SHA (the lockfile does not lock it)"
        elif [[ -z "$comment" ]]; then
            echo "reusable workflow $value needs the version in a trailing comment, e.g. # v1.2.3"
        fi
    elif [[ "$ref" =~ $FLOATING_RE || "$ref" == main || "$ref" == master ]]; then
        echo "$value follows a floating tag or branch; use an exact vX.Y.Z tag"
    fi
}

status=0
for file in "$@"; do
    if [[ ! -r "$file" ]]; then
        echo "check-workflow-refs: cannot read $file" >&2
        exit 2
    fi
    lineno=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        [[ "$line" =~ $USES_RE ]] || continue
        problem="$(check_uses "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}")"
        if [[ -n "$problem" ]]; then
            echo "$file:$lineno: $problem"
            status=1
        fi
    done <"$file"
done
exit "$status"
