# AGENT.md

Developer tooling. Commands run from the repo root.

## Setup

```sh
sudo apt install shellcheck        # or: brew install shellcheck
uvx pre-commit install --hook-type pre-commit --hook-type pre-push
cp .env.example .env.local         # then fill in the placeholders
```

## Commands

| Command | What it does |
| --- | --- |
| `shellcheck -x --source-path=SCRIPTDIR <file>` | Lint one script |
| `uvx pre-commit run --all-files` | Every hook against the whole tree |

## Scripts

| Script | What it does |
| --- | --- |
| {{`scripts/x.sh`}} | {{…}} |

## Claude Code hooks

`.claude/hooks/check-shell.sh` runs on PostToolUse (Edit/Write): shfmt (if installed), then shellcheck; findings block Claude until fixed. `jq` is used if present, else `python3`.
