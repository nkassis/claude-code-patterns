# security

Baseline secret-hygiene layer. Add it to every project, whatever the stack.

| File | What it does |
| --- | --- |
| `.github/workflows/secret-scan.yml` | TruffleHog on every push and PR, verified secrets only. Fails the build on a live credential. |
| `.github/dependabot.yml` | Weekly bumps for pinned GitHub Actions (including the TruffleHog pin). |
| `.pre-commit-config.yaml` | TruffleHog on the staged diff and pushed range, plus `detect-private-key`, `check-added-large-files`, `check-merge-conflict`, `forbid-submodules`, and `no-commit-to-branch` on main and master. |
| `.claude/settings.json` | Denies Claude reads of `.env`, `.env.local`, `.env.*.local`, `.env.{development,production,test}`, `*.pem`, `*.key`, `~/.ssh`, `~/.aws`. `.env.example` stays readable. Runs `guard-bash.sh` before every Bash call. |
| `.claude/hooks/guard-bash.sh` | Blocks Claude from committing on main or master, pushing to them, force pushing anywhere, and deleting them. Feature branches and worktrees push as normal. |
| `gitignore-env.txt` | The env/secret ignore block, for retrofitting an existing `.gitignore`. The stack starters already include it. |
| `.env.example` | Placeholder pattern: every variable the project reads, no real values. |

## Use

```sh
cp -r security/.github ~/projects/x/   # sits beside the stack's .github/workflows/ci.yml
mkdir -p ~/projects/x/.claude/hooks && cp security/.claude/hooks/guard-bash.sh ~/projects/x/.claude/hooks/
```

- Append this `.pre-commit-config.yaml`'s `repos:` entries to the stack's.
- Merge `.claude/settings.json`: add `permissions`, and add its `PreToolUse` entry beside the stack's `PostToolUse` under `hooks`.
- The pre-commit TruffleHog hook uses the system binary: install `trufflehog` locally (https://github.com/trufflesecurity/trufflehog#installation).

## Guarding main

`guard-bash.sh` stops Claude before the command runs, and `no-commit-to-branch` stops any commit on main or master, whoever makes it. Both catch mistakes and are not a security boundary: [docs/guarding-main.md](docs/guarding-main.md).

## Full-history scan

CI scans only new commits. To audit everything, once per repo (and after importing history):

```sh
trufflehog git file://. --results=verified --fail
```

## If a secret is found

Rotate the credential first, then remove it from history. Deleting the line in a new commit does not un-leak it.
