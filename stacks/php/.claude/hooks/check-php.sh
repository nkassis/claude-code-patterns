#!/usr/bin/env bash
# Claude Code hook: enforce Pint + PHPStan on PHP files.
#   check-php.sh edit  -> PostToolUse: format the edited file, then analyse it
#   check-php.sh stop  -> Stop: analyse the whole project before Claude finishes
# Exit 2 blocks and feeds stderr back to Claude; exit 1 is a non-blocking warning.
set -euo pipefail

mode="${1:-edit}"
input="$(cat)"
cd "${CLAUDE_PROJECT_DIR:-$PWD}"

json_field() {
    # Prefer jq; fall back to python3 so the hook works without extra installs.
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$input" | jq -r "$1 // empty"
    else
        printf '%s' "$input" | python3 -c '
import json, sys
value = json.load(sys.stdin)
for key in sys.argv[1].lstrip(".").split("."):
    value = value.get(key) if isinstance(value, dict) else None
print("" if value is None else str(value).lower() if isinstance(value, bool) else value)
' "$1"
    fi
}

# Use the project's pinned tools from vendor/bin; otherwise a global install on PATH.
tool() {
    if [[ -x "vendor/bin/$1" ]]; then
        echo "vendor/bin/$1"
    elif command -v "$1" >/dev/null 2>&1; then
        command -v "$1"
    else
        echo "check-php: $1 not found; PHP lint skipped. Run \`composer install\` (laravel/pint, larastan/larastan)." >&2
        exit 1
    fi
}

has_phpstan_config() {
    [[ -f phpstan.neon || -f phpstan.neon.dist || -f phpstan.dist.neon ]]
}

case "$mode" in
    edit)
        file="$(json_field .tool_input.file_path)"
        [[ "$file" == *.php && -f "$file" ]] || exit 0
        pint="$(tool pint)"
        "$pint" --quiet "$file" >&2 || true
        # Analyse the configured paths, as CI does, not just this file: a file outside them
        # (tests/, say) must not block on findings CI never checks.
        has_phpstan_config || exit 0
        phpstan="$(tool phpstan)"
        if ! out="$("$phpstan" analyse --no-progress --error-format=raw 2>&1)"; then
            printf 'phpstan analyse fails after editing %s; fix it:\n%s\n' "$file" "$out" >&2
            exit 2
        fi
        ;;
    stop)
        # Don't loop: if Claude is already continuing because of this hook, let it stop.
        [[ "$(json_field .stop_hook_active)" == "true" ]] && exit 0
        has_phpstan_config || exit 0
        phpstan="$(tool phpstan)"
        if ! out="$("$phpstan" analyse --no-progress --error-format=raw 2>&1)"; then
            printf 'phpstan analyse fails; fix before finishing:\n%s\n' "$out" >&2
            exit 2
        fi
        ;;
    *)
        echo "check-php: unknown mode '$mode'" >&2
        exit 1
        ;;
esac
