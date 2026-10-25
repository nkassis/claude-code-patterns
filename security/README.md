# security

Baseline secret-hygiene layer. Add it to every project, whatever the stack.

| File | What it does |
| --- | --- |
| `.github/workflows/secret-scan.yml` | TruffleHog on every push and PR, verified secrets only. Fails the build on a live credential. |
| `.github/dependabot.yml` | Weekly bumps for pinned GitHub Actions (including the TruffleHog pin). |
| `.pre-commit-config.yaml` | TruffleHog on the staged diff and pushed range, plus `detect-private-key`, `check-added-large-files`, `check-merge-conflict`, `forbid-submodules`. |
| `.claude/settings.json` | Denies Claude reads of `.env`, `.env.local`, `.env.*.local`, `.env.{development,production,test}`, `*.pem`, `*.key`, `~/.ssh`, `~/.aws`. `.env.example` stays readable. |
| `gitignore-env.txt` | The env/secret ignore block, for retrofitting an existing `.gitignore`. The stack starters already include it. |
| `.env.example` | Placeholder pattern: every variable the project reads, no real values. |

## Applying

- Copy `.github/` as is. If the stack already has `.github/workflows/ci.yml`, the files sit side by side.
- Append this `.pre-commit-config.yaml`'s `repos:` entries to the stack's.
- Merge `.claude/settings.json`: add `permissions` next to the stack's `hooks` key.
- The pre-commit TruffleHog hook uses the system binary: install `trufflehog` locally (https://github.com/trufflesecurity/trufflehog#installation).

## Full-history scan

CI scans only new commits. To audit everything, once per repo (and after importing history):

```sh
trufflehog git file://. --results=verified --fail
```

## If a secret is found

Rotate the credential first, then remove it from history. Deleting the line in a new commit does not un-leak it.
