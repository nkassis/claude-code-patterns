#!/usr/bin/env bash
# Symlink this repo's global Claude Code config into ~/.claude, so edits here apply immediately:
#   CLAUDE-global.md -> ~/.claude/CLAUDE.md
#   skills/<name>/   -> ~/.claude/skills/<name>
# Safe to re-run. A symlink at a target is replaced. A real file or directory is left alone
# (exit 1) unless --force, which moves it to <target>.bak first.
set -euo pipefail

usage() {
    echo "usage: install-global.sh [--force]" >&2
    exit 1
}

force=false
[[ $# -le 1 ]] || usage
case "${1:-}" in
    "") ;;
    --force) force=true ;;
    *) usage ;;
esac

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"
status=0

# Links into a worktree break when the worktree is removed after merge.
if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 &&
    [[ "$(git -C "$repo" rev-parse --path-format=absolute --git-dir)" != "$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir)" ]]; then
    echo "install-global: $repo is a git worktree; run this from the main clone" >&2
    exit 1
fi

link() {
    local src="$1" target="$2"
    if [[ -L "$target" ]]; then
        local old
        old="$(readlink "$target")"
        if [[ "$old" == "$src" ]]; then
            echo "ok        $target"
            return 0
        fi
        ln -sfn "$src" "$target"
        echo "relinked  $target (was -> $old)"
    elif [[ -e "$target" ]]; then
        if [[ "$force" != true ]]; then
            echo "skipped   $target: not a symlink; re-run with --force to move it to $target.bak" >&2
            status=1
            return 0
        fi
        if [[ -e "$target.bak" || -L "$target.bak" ]]; then
            echo "skipped   $target: $target.bak already exists; move it first" >&2
            status=1
            return 0
        fi
        mv "$target" "$target.bak"
        ln -s "$src" "$target"
        echo "linked    $target (previous one moved to $target.bak)"
    else
        ln -s "$src" "$target"
        echo "linked    $target"
    fi
}

mkdir -p "$dest/skills"
link "$repo/CLAUDE-global.md" "$dest/CLAUDE.md"
for skill in "$repo"/skills/*/; do
    skill="${skill%/}"
    link "$skill" "$dest/skills/$(basename "$skill")"
done
exit "$status"
