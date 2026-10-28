# github

Branch protection for a project's default branch, as a GitHub ruleset named `main`. Opt-in: it changes settings on GitHub, so nothing applies it by default.

## Use

Prerequisites: `gh` logged in with admin rights on the repo, `jq` or `python3`. Run it after the project's CI has run once on the default branch, so its checks can be discovered.

```sh
github/protect.sh --dry-run   # print the ruleset JSON, change nothing
github/protect.sh             # create the ruleset, or update it in place
```

Re-run it whenever the project's CI jobs change. Same input, same ruleset.

| Flag | Effect |
| --- | --- |
| `--repo owner/name` | Target repo. Default: the repo of the current directory. |
| `--check ctx` | Require this check; repeatable. Default: every check run on the default branch's latest commit. |
| `--allow-admin-bypass` | Repository admins may bypass the ruleset. Default: nobody bypasses. |
| `--off` / `--on` | Only disable or enable the existing ruleset. Rules and checks stay as they are. |
| `--dry-run` | Print the JSON that would be sent and exit. |

```sh
gh ruleset list               # the result: "main", active
gh ruleset check main         # the rules that apply to main
```

## What it sets

| Rule | Setting |
| --- | --- |
| Target | The default branch (`~DEFAULT_BRANCH`), whatever it is called |
| Pull request | Required, 0 approvals, stale approvals dismissed, review threads resolved |
| Status checks | Required, branch must be up to date with the base |
| Force push, deletion | Blocked |
| Linear history | Required, so PRs merge by squash or rebase, not merge commits |

A required check is matched by the CI job's `name:`. The templates name them `ci-<stack>`, `secret-scan`, and `ci` for this repo; renaming a job means re-running `protect.sh`. A workflow with `paths:` filters never reports on PRs outside those paths, so do not require its checks.

## Limits

Rulesets on a private repo need GitHub Pro (or Team). Without it the API answers 403; `protect.sh` says so and exits 1.
