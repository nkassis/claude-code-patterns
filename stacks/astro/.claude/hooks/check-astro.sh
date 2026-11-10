#!/usr/bin/env bash
# Claude Code hook: enforce Prettier, ESLint and `pnpm check` on an Astro site.
#   check-astro.sh edit  -> PostToolUse: prettier the edited file, then eslint it
#   check-astro.sh stop  -> Stop: pnpm check before Claude finishes
# Both run from the nearest package.json, so a site in a subdirectory works.
# Exit 2 blocks and feeds stderr back to Claude; exit 1 is a non-blocking warning.
set -euo pipefail

mode="${1:-edit}"
input="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root"

# Stop's input names no file, so the edit hook records each package directory here for it.
dirs_file="$root/.claude/check-astro.dirs"

# json_field <path> [json]: read a field from the hook input, or from the given JSON.
json_field() {
    # Prefer jq; fall back to python3 so the hook works without extra installs.
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${2:-$input}" | jq -r "$1 // empty"
    else
        printf '%s' "${2:-$input}" | python3 -c '
import json, sys
value = json.load(sys.stdin)
for key in sys.argv[1].lstrip(".").split("."):
    value = value.get(key) if isinstance(value, dict) else None
print("" if value is None else str(value).lower() if isinstance(value, bool) else value)
' "$1"
    fi
}

# nearest_package_dir <file>: walk up from the file, stopping at the project root.
nearest_package_dir() {
    local dir
    dir="$(dirname "$1")"
    while true; do
        if [[ -f "$dir/package.json" ]]; then
            printf '%s\n' "$dir"
            return 0
        fi
        [[ "$dir" != "$root" && "$dir" != / ]] || return 1
        dir="$(dirname "$dir")"
    done
}

record_dir() {
    mkdir -p "$(dirname "$dirs_file")"
    grep -qxF "$1" "$dirs_file" 2>/dev/null || printf '%s\n' "$1" >>"$dirs_file"
}

# stop_dirs: the recorded package directories, or the project root if none were recorded.
stop_dirs() {
    local dir found=0
    if [[ -f "$dirs_file" ]]; then
        while IFS= read -r dir; do
            [[ -f "$dir/package.json" ]] || continue
            printf '%s\n' "$dir"
            found=1
        done <"$dirs_file"
    fi
    if [[ "$found" == 0 && -f "$root/package.json" ]]; then
        printf '%s\n' "$root"
    fi
}

require_pnpm() {
    command -v pnpm >/dev/null 2>&1 && [[ -d node_modules ]] && return 0
    echo "check-astro: pnpm or node_modules missing in $PWD; run 'pnpm install'. Astro checks skipped." >&2
    return 1
}

require_check_script() {
    [[ -z "$(json_field .scripts.check "$(cat package.json)")" ]] || return 0
    echo "check-astro: no \"check\" script in $PWD/package.json; define \"check\" and \"build\" (see AGENTS.md). Astro checks skipped." >&2
    return 1
}

case "$mode" in
    edit)
        file="$(json_field .tool_input.file_path)"
        [[ -f "$file" ]] || exit 0
        case "$file" in
            *.astro | *.ts | *.tsx | *.js | *.jsx | *.mjs | *.cjs) lint=1 ;;
            *.css | *.json | *.md | *.mdx | *.html) lint=0 ;;
            *) exit 0 ;;
        esac
        [[ "$file" == /* ]] || file="$root/$file"
        package_dir="$(nearest_package_dir "$file")" || exit 0
        record_dir "$package_dir"
        cd "$package_dir"
        require_pnpm || exit 1
        pnpm exec prettier --write --log-level warn "$file" >&2 || true
        [[ "$lint" == 1 ]] || exit 0
        # --no-warn-ignored: an edit to a file the config ignores must not fail --max-warnings=0.
        if ! out="$(pnpm exec eslint --max-warnings=0 --no-warn-ignored "$file" 2>&1)"; then
            printf 'eslint found problems in %s; fix them:\n%s\n' "$file" "$out" >&2
            exit 2
        fi
        ;;
    stop)
        # Don't loop: if Claude is already continuing because of this hook, let it stop.
        [[ "$(json_field .stop_hook_active)" == "true" ]] && exit 0
        mapfile -t dirs < <(stop_dirs)
        skipped=0
        for dir in "${dirs[@]}"; do
            cd "$dir"
            # A package that can't be checked warns, and must not hide the ones after it.
            if ! require_check_script || ! require_pnpm; then
                skipped=1
                continue
            fi
            if ! out="$(pnpm --silent check 2>&1)"; then
                printf 'pnpm check fails in %s; fix before finishing:\n%s\n' "$dir" "$out" >&2
                exit 2
            fi
        done
        # Keep the record when a package was skipped, so it is checked once it can be.
        [[ "$skipped" == 0 ]] || exit 1
        rm -f "$dirs_file"
        ;;
    *)
        echo "check-astro: unknown mode '$mode'" >&2
        exit 1
        ;;
esac
