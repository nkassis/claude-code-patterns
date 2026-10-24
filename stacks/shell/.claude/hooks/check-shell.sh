#!/usr/bin/env bash
# Claude Code hook: enforce shellcheck (and shfmt, if installed) on shell scripts.
#   check-shell.sh edit  -> PostToolUse: format the edited script, then shellcheck it
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

is_shell_script() {
    [[ "$1" == *.sh || "$1" == *.bash ]] && return 0
    # Extensionless scripts: trust the shebang. shellcheck does not support zsh/fish.
    head -n 1 "$1" 2>/dev/null | grep -Eq '^#!.*[/ ](ba|da|k)?sh([[:space:]]|$)'
}

[[ "$mode" == "edit" ]] || exit 0

file="$(json_field .tool_input.file_path)"
[[ -f "$file" ]] || exit 0
is_shell_script "$file" || exit 0

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "check-shell: shellcheck not found; lint skipped. Install it (apt install shellcheck)." >&2
    exit 1
fi

# 4-space indent per the global code style.
if command -v shfmt >/dev/null 2>&1; then
    shfmt -i 4 -ci -w "$file" >&2 || true
fi

if ! out="$(shellcheck -x --source-path=SCRIPTDIR "$file" 2>&1)"; then
    printf 'shellcheck found problems in %s; fix them (no blanket disables):\n%s\n' "$file" "$out" >&2
    exit 2
fi
