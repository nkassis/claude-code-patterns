# Guarding main

What the two local branch guards in `security/` catch and what gets past them, for anyone deciding whether a project also needs a server-side ruleset.

Two local layers stop work from landing on main or master:

- `guard-bash.sh` stops Claude before the command runs.
- `no-commit-to-branch` stops any commit there, whoever makes it.

Both catch mistakes. They are not a security boundary.

The guard reads the command line, so an alias, a script or `bash -c` gets past it, and `git commit --no-verify` skips pre-commit.

The real gate is a branch ruleset on the server, which `github/protect.sh` sets. Set one wherever the plan allows it. Repos without one, such as private repos on GitHub's free plan, still get these two layers.
