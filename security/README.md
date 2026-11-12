# security

Baseline secret-hygiene layer. Add it to every project, whatever the stack.

| File | What it does |
| --- | --- |
| `.github/workflows/secret-scan.yml` | TruffleHog on every push and PR, verified secrets only. Fails the build on a live credential. |
| `.github/workflows/actions-lock.yml` | `gh actions-lock --verify` on every PR and push to main. Fails when `actions.lock` is out of date with the workflows, or a locked commit no longer verifies. See [Locking GitHub Actions](#locking-github-actions). |
| `.github/dependabot.yml` | Weekly bumps for GitHub Actions tags (including the TruffleHog pin), with a 7 day cooldown. Each bump regenerates `actions.lock` in the same PR. |
| `.pre-commit-config.yaml` | zizmor over workflows, `dependabot.yml` and the pre-commit config. TruffleHog on the staged diff and pushed range, plus `detect-private-key`, `check-added-large-files`, `check-merge-conflict`, `forbid-submodules`, and `no-commit-to-branch` on main and master. |
| `.claude/settings.json` | Denies Claude reads of `.env`, `.env.local`, `.env.*.local`, `.env.{development,production,test}`, `*.pem`, `*.key`, `~/.ssh`, `~/.aws`. `.env.example` stays readable. Runs `guard-bash.sh` before every Bash call. |
| `.claude/hooks/guard-bash.sh` | Blocks Claude from committing on main or master, pushing to them, force pushing anywhere, and deleting them. Feature branches and worktrees push as normal. |
| `gitignore-env.txt` | The env/secret ignore block, for retrofitting an existing `.gitignore`. The stack starters already include it. |
| `.env.example` | Placeholder pattern: every variable the project reads, no real values. |

## Applying

- Copy `.github/` as is. If the stack already has `.github/workflows/ci.yml`, the files sit side by side.
- Append this `.pre-commit-config.yaml`'s `repos:` entries to the stack's.
- Copy `.claude/hooks/guard-bash.sh` into the project's `.claude/hooks/`.
- Merge `.claude/settings.json`: add `permissions`, and add its `PreToolUse` entry beside the stack's `PostToolUse` under `hooks`.
- Lock the workflows and commit the lockfile (below). Until then the `actions-lock` job and zizmor fail.

## Locking GitHub Actions

A tag can be moved to other code, so a `uses:` that names only a tag runs whatever the tag points at today. The workflows here carry exact `vX.Y.Z` tags, and `.github/workflows/actions.lock` records the commit behind each one, including the actions those actions use. GitHub runs the locked commit.

The starters can't ship a lockfile: a lockfile only covers workflows in its own repository. Each project writes its own, once, after applying a starter and this layer:

```sh
gh extension install github/gh-actions-lock --pin v0.4.1   # once per machine
gh actions-lock                                             # pins every action, writes .github/workflows/actions.lock
git add .github/workflows/ && git commit -m "ci: lock GitHub Actions dependencies"
```

Run `gh actions-lock` again after adding a workflow or changing a `uses:`. Never edit `actions.lock` by hand. Dependabot's bumps relock on their own.

zizmor needs v1.32.0 or later to read the lockfile; older versions report every tag as unpinned.

### Reusable workflows: pin to a full commit SHA

The lockfile does not lock a job that calls a reusable workflow in another repository. Pin those calls by hand, to the full 40 character commit SHA, with the version in a trailing comment:

```yaml
jobs:
  release:
    uses: owner/repo/.github/workflows/release.yml@0123456789abcdef0123456789abcdef01234567 # v1.2.3
```

Calls to a workflow in the same repository (`uses: ./.github/workflows/x.yml`) are exempt. zizmor enforces the rule in pre-commit: once the project is locked, its default policy accepts locked steps and still requires a hash pin on every reusable workflow call. Dependabot bumps a SHA-pinned reusable workflow ref and rewrites the version comment beside it. Its own test suite covers this case.

## Guarding main

Two local layers stop work from landing on main or master:

- `guard-bash.sh` stops Claude before the command runs.
- `no-commit-to-branch` stops any commit there, whoever makes it.

Both catch mistakes. They are not a security boundary. The guard reads the command line, so an alias, a script or `bash -c` gets past it, and `git commit --no-verify` skips pre-commit. The real gate is a branch ruleset on the server. Set one wherever the plan allows it. Repos without one, such as private repos on GitHub's free plan, still get these two layers.
- The pre-commit TruffleHog hook uses the system binary: install `trufflehog` locally (https://github.com/trufflesecurity/trufflehog#installation).

## Full-history scan

CI scans only new commits. To audit everything, once per repo (and after importing history):

```sh
trufflehog git file://. --results=verified --fail
```

## If a secret is found

Rotate the credential first, then remove it from history. Deleting the line in a new commit does not un-leak it.
