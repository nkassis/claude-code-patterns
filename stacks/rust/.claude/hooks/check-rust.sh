#!/usr/bin/env bash
# Claude Code hook: enforce rustfmt and Clippy.
#   check-rust.sh edit  -> PostToolUse: rustfmt the edited file
#   check-rust.sh stop  -> Stop: cargo clippy with warnings denied before Claude finishes
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

require_cargo() {
    command -v cargo >/dev/null 2>&1 && return 0
    echo "check-rust: cargo not found; Rust checks skipped. Install via rustup." >&2
    exit 1
}

case "$mode" in
    edit)
        file="$(json_field .tool_input.file_path)"
        [[ "$file" == *.rs && -f "$file" ]] || exit 0
        require_cargo
        # Inside a crate, cargo fmt picks up the crate's edition; outside one, assume 2024.
        if [[ -f Cargo.toml ]]; then
            fmt=(cargo fmt -- "$file")
        else
            fmt=(rustfmt --edition 2024 "$file")
        fi
        if ! out="$("${fmt[@]}" 2>&1)"; then
            printf 'rustfmt could not parse %s; fix the syntax:\n%s\n' "$file" "$out" >&2
            exit 2
        fi
        ;;
    stop)
        # Don't loop: if Claude is already continuing because of this hook, let it stop.
        [[ "$(json_field .stop_hook_active)" == "true" ]] && exit 0
        [[ -f Cargo.toml ]] || exit 0
        require_cargo
        if ! out="$(cargo clippy --quiet --all-targets -- -D warnings 2>&1)"; then
            printf 'cargo clippy fails; fix before finishing:\n%s\n' "$out" >&2
            exit 2
        fi
        ;;
    *)
        echo "check-rust: unknown mode '$mode'" >&2
        exit 1
        ;;
esac
