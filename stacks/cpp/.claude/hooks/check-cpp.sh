#!/usr/bin/env bash
# Claude Code hook: enforce clang-format and clang-tidy on C/C++ files.
#   check-cpp.sh edit  -> PostToolUse: clang-format the edited file, then clang-tidy it
# clang-tidy needs build/compile_commands.json (CMAKE_EXPORT_COMPILE_COMMANDS=ON); without it, tidy is skipped.
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

[[ "$mode" == "edit" ]] || exit 0

file="$(json_field .tool_input.file_path)"
[[ -f "$file" ]] || exit 0
case "${file##*.}" in
    cpp | cc | cxx | c) header=0 ;;
    hpp | hh | hxx | h | ipp) header=1 ;;
    *) exit 0 ;;
esac

if ! command -v clang-format >/dev/null 2>&1; then
    echo "check-cpp: clang-format not found; format skipped." >&2
    status=1
else
    clang-format -i "$file" >&2 || true
fi

# Headers are checked through the translation units that include them.
if [[ "$header" == 0 && -f build/compile_commands.json ]]; then
    if ! command -v clang-tidy >/dev/null 2>&1; then
        echo "check-cpp: clang-tidy not found; lint skipped." >&2
        exit 1
    fi
    if ! out="$(clang-tidy -p build --quiet --warnings-as-errors='*' "$file" 2>&1)"; then
        printf 'clang-tidy found problems in %s; fix them:\n%s\n' "$file" "$out" >&2
        exit 2
    fi
fi

exit "${status:-0}"
