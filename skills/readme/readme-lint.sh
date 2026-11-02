#!/usr/bin/env bash
# Check a README and the docs/ beside it against the readme skill (SKILL.md in this directory).
#   readme-lint.sh [path/to/README.md]   # default: ./README.md
# Prints one line per finding as <file>:<line>: <message> and exits 1 if there are any,
# 0 if clean, 2 on bad usage. Needs only bash, awk, grep and find (bash 3.2 works).
set -euo pipefail

# The budget, stated once. SKILL.md quotes these numbers.
max_lines=99
max_bytes=10239
first_command_by=25
max_sentences=3
banned_headings='overview|introduction|getting started|features|philosophy'
em_dash=$'\xe2\x80\x94'

usage() {
    echo "usage: readme-lint.sh [path/to/README.md]" >&2
    exit 2
}

[[ $# -le 1 ]] || usage
readme="${1:-README.md}"
[[ -f "$readme" ]] || {
    echo "readme-lint: $readme: no such file" >&2
    exit 2
}
docs="$(dirname "$readme")/docs"
docs="${docs#./}"
findings=0

report() {
    printf '%s\n' "$1"
    findings=$((findings + 1))
}

# resolve <path>: print the absolute, symlink-free path of an existing file, or fail.
resolve() {
    local dir
    [[ -f "$1" ]] || return 1
    dir="$(cd "$(dirname "$1")" && pwd -P)" || return 1
    printf '%s/%s\n' "$dir" "$(basename "$1")"
}

# Every markdown file the lint reads: the README, then docs/**/*.md.
pages() {
    printf '%s\n' "$readme"
    [[ -d "$docs" ]] || return 0
    find "$docs" -type f -name '*.md' | LC_ALL=C sort
}

check_size() {
    local lines bytes
    lines="$(wc -l <"$readme" | tr -d ' ')"
    bytes="$(wc -c <"$readme" | tr -d ' ')"
    if ((lines > max_lines)); then
        report "$readme:1: $lines lines, budget is under $((max_lines + 1)); move feature sections to docs/"
    fi
    if ((bytes > max_bytes)); then
        report "$readme:1: $bytes bytes, budget is under $((max_bytes + 1)); move feature sections to docs/"
    fi
}

# One pass over the README for what needs fence awareness: first command block, banned
# headings, and sentences per paragraph. A list item starts its own paragraph; tables,
# headings and fenced blocks are not paragraphs.
check_structure() {
    while IFS= read -r line; do
        report "$line"
    done < <(awk -v file="$readme" -v by="$first_command_by" -v max="$max_sentences" \
        -v banned="^#+[ \t]+(${banned_headings})[ \t#]*\$" '
        function flush() {
            if (para_start && sentences > max)
                printf "%s:%d: paragraph has %d sentences, max %d; split it or move it to docs/\n", file, para_start, sentences, max
            para_start = 0
            sentences = 0
        }
        function count(text,    n) {
            gsub(/`[^`]*`/, "x", text)          # inline code: .env, v1.2.3
            gsub(/\]\([^)]*\)/, "]", text)      # link targets
            gsub(/(e\.g|i\.e|etc|vs)\./, "x", text)
            n = gsub(/[.!?]["\047)]*( |$)/, "", text)
            return n
        }
        /^[ \t]*(```|~~~)/ {
            if (!first_fence) first_fence = NR
            flush()
            in_fence = !in_fence
            next
        }
        in_fence { next }
        /^[ \t]*$/ { flush(); next }
        /^#/ {
            flush()
            if (tolower($0) ~ banned)
                printf "%s:%d: banned heading \"%s\"; use Description, Use or Covered\n", file, NR, $0
            next
        }
        /^[ \t]*\|/ { flush(); next }
        /^[ \t]*([-*+]|[0-9]+\.)[ \t]/ { flush() }
        {
            if (!para_start) para_start = NR
            sentences += count($0)
        }
        END {
            flush()
            if (!first_fence)
                printf "%s:1: no fenced command block; the first one belongs within %d lines\n", file, by
            else if (first_fence > by)
                printf "%s:%d: first fenced command block is at line %d, want within %d\n", file, first_fence, first_fence, by
        }
    ' "$readme")
}

# Decision logs are exempt: they use the em dash as a field separator and are never rewritten.
check_em_dash() {
    local page hit
    while IFS= read -r page; do
        case "$page" in "$docs"/decisions*.md) continue ;; esac
        while IFS= read -r hit; do
            report "$page:${hit%%:*}: em dash; use a comma, colon, period or plain hyphen"
        done < <(LC_ALL=C grep -n -F "$em_dash" "$page" || true)
    done < <(pages)
}

# links <page>: print "<line> <target>" for every relative markdown link, anchor dropped.
links() {
    LC_ALL=C grep -n -o '\]([^)]*)' "$1" | while IFS= read -r hit; do
        local line="${hit%%:*}" target="${hit#*:](}"
        target="${target%)}"
        target="${target%% *}"
        target="${target%%#*}"
        case "$target" in "" | /* | *://* | mailto:*) continue ;; esac
        printf '%s %s\n' "$line" "$target"
    done || true
}

# Every relative link resolves; collect the resolved targets for the orphan check.
check_links() {
    local page line target found
    linked="$(mktemp)"
    trap 'rm -f "$linked"' EXIT
    while IFS= read -r page; do
        while IFS=' ' read -r line target; do
            if found="$(resolve "$(dirname "$page")/$target")"; then
                [[ "$found" == "$(resolve "$page")" ]] || printf '%s\n' "$found" >>"$linked"
            else
                report "$page:$line: link target $target does not exist"
            fi
        done < <(links "$page")
    done < <(pages)
}

# Every top-level docs page is linked from the README or another docs page.
check_orphans() {
    local page
    [[ -d "$docs" ]] || return 0
    for page in "$docs"/*.md; do
        [[ -f "$page" ]] || continue
        grep -qxF "$(resolve "$page")" "$linked" ||
            report "$page:1: orphan; link it from $readme or another docs page"
    done
}

check_size
check_structure
check_em_dash
check_links
check_orphans
((findings == 0)) || exit 1
