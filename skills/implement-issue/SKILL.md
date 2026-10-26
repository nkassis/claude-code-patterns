---
name: implement-issue
description: Implement one Linear issue end to end. The issue holds the spec. Reads it, works in a worktree, implements, tests, opens a PR, and logs to Linear.
argument-hint:
- issue-key
arguments: issue
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh *)
---

# Implement Linear issue $issue

The Linear issue is the prompt. Everything you need should be in the issue and its comments. Do not expand scope beyond it.

You write comments on the issue, never its description. You never create issues and never set an issue to Done.

## 1. Load the issue

Using the Linear tools, fetch issue $issue with its description, comments, attachments, labels, parent, sub-issues, and blocking relations. Read any Linear documents it links to.

- The description is the spec. Comments refine it; when they conflict, the latest comment wins.
- If the issue is blocked by issues that are not Done, stop and report which ones.
- If the issue has open sub-issues, ask whether to implement the parent as a whole or one child, then stop.
- If the issue is Done or Canceled, stop and say so.

## 2. Plan before writing code

Explore the codebase for the code the issue touches. Then restate in a few lines: goal, acceptance criteria, what is explicitly out of scope, and the approach.

If something that changes the design is unspecified, ask one question before writing code. Do not guess on anything a reviewer would push back on. Small gaps you can fill with a reasonable default: fill them, add one line to `docs/decisions.md` (date, what, why), and list them in the closing comment.

## 3. Start the work

1. Post the restatement from step 2 as a comment on the issue, headed "Plan". This is the opening log entry; nothing is committed before it exists.
2. Move the issue to **In Progress**.
3. Create a worktree from fresh main using the branch name Linear returned for the issue:
   `git fetch origin && git worktree add ../<repo>-$issue -b <branch> origin/main && cd ../<repo>-$issue`
4. If a worktree or branch for this issue already exists, use it and continue from where it stopped.

## 4. Implement

- Follow the repo's CLAUDE.md conventions and tooling. Read `docs/decisions.md` before changing anything it covers.
- Commits are Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`), one concern each, with `Refs $issue` in the body. No attribution trailers.
- Add or update tests for every behavior the issue describes.
- Do not refactor or fix things outside the issue. If you find something worth fixing, note it for the closing comment.
- Never commit secrets, local config, or generated artifacts.

## 5. Verify

Run the full checks for the parts you touched (lint, type checks, unit tests, e2e where relevant). Fix what you broke. Then walk the acceptance criteria one by one and confirm each is met. If one cannot be met, say so in the PR and the closing comment rather than quietly skipping it.

## 6. Open the PR

Push the branch and run `gh pr create`:

- Title: `<type>: <short summary>` with `($issue)` at the end.
- Body: what changed and why, how it was verified, open questions. End with `Refs $issue`. Never `Closes`; closing is a human decision after review.

Never push to main.

## 7. Log to Linear

1. Attach the PR URL to the issue.
2. Add a closing comment, headed "Done for review": what changed, how it was verified (commands and results), defaults you chose, and a **Follow-ups** list of anything found but not done, one line each. Do not create issues for them.
3. Move the issue to **In Review**.

Do not move the issue to Done. That is decided after review.

## 8. Report

Finish with the PR link, the worktree path, a two-line summary, and anything that needs a decision from me.
