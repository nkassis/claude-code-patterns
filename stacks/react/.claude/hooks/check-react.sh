#!/usr/bin/env bash
# Claude Code hook: enforce Prettier, ESLint and tsc on the frontend.
#   check-react.sh edit  -> PostToolUse: prettier the edited file, then eslint it
#   check-react.sh stop  -> Stop: pnpm typecheck before Claude finishes
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

require_pnpm() {
    command -v pnpm >/dev/null 2>&1 && [[ -d node_modules ]] && return 0
    echo "check-react: pnpm or node_modules missing; run 'pnpm install'. Frontend checks skipped." >&2
    exit 1
}

case "$mode" in
    edit)
        file="$(json_field .tool_input.file_path)"
        [[ -f "$file" ]] || exit 0
        case "$file" in
            *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs) lint=1 ;;
            *.css | *.json | *.md | *.html) lint=0 ;;
            *) exit 0 ;;
        esac
        require_pnpm
        pnpm exec prettier --write --log-level warn "$file" >&2 || true
        [[ "$lint" == 1 ]] || exit 0
        if ! out="$(pnpm exec eslint --max-warnings=0 "$file" 2>&1)"; then
            printf 'eslint found problems in %s; fix them:\n%s\n' "$file" "$out" >&2
            exit 2
        fi
        ;;
    stop)
        # Don't loop: if Claude is already continuing because of this hook, let it stop.
        [[ "$(json_field .stop_hook_active)" == "true" ]] && exit 0
        [[ -f package.json ]] || exit 0
        require_pnpm
        if ! out="$(pnpm --silent typecheck 2>&1)"; then
            printf 'pnpm typecheck fails; fix before finishing:\n%s\n' "$out" >&2
            exit 2
        fi
        ;;
    *)
        echo "check-react: unknown mode '$mode'" >&2
        exit 1
        ;;
esac
