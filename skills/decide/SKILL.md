---
name: decide
description: Use at a fork a competent engineer could take either way, where reversing costs more than a day. Asks the human with AskUserQuestion, then writes the decision log entry. Do not pick silently.
argument-hint:
- the fork, in a phrase
arguments: fork
---

# Decide: $fork

You have hit a fork that passes the three tests in the decision-log rule (`.claude/rules/decision-log.md`): a competent engineer could choose otherwise, reversing it costs more than a day, and an earlier decision or the stack does not already settle it. The human picks. You frame the choice, ask, and write it down.

## 1. Frame

- **Title** states the choice, not the topic. "README links the log once", not "README decisions".
- **Two to four options**, one line each: the choice and its cost. No option without a cost.
- **Your preference goes first**, labelled "(agent's pick)", so the human sees what would have happened silently.
- List only options someone would really argue for. Do not pad to four.

## 2. Ask

Make one `AskUserQuestion` call: the title as the question, the options as choices, each cost in its description.

Hard stop until the answer is back: no edits, no commands, no work on anything that depends on this choice.

If the human types a free answer, that becomes the choice and your pick becomes the alternative that lost.

If `AskUserQuestion` is unavailable (`claude -p`, a scheduled run), go to step 7.

## 3. Draft the entry

Write it to the rule's shape and voice, under 150 words:

```markdown
### N. <Title: the choice>

**Why:** <one or two sentences, with the constraint that forced it>
**Instead of:** <the option that lost, and the specific reason it lost>
**Cost:** <what this gives up or makes harder>
**Status:** Accepted
```

N is the next number in the log (step 5 finds it), never a reused one. Copy the heading style the log already uses if it differs. Draft the entry before writing the code, as the rule asks.

Then check it: under 150 words, all four lines present, a reader could disagree. If a reader could not disagree, the fork did not earn an entry; say so and stop.

## 4. Confirm

Show the draft and ask once (`AskUserQuestion`: "File it" or "Edit"). The human's edits win. Do not argue a second round.

## 5. File

Append the entry to the repo's log. The first one that exists wins:

1. The file matched by the `paths:` glob in `.claude/rules/decision-log.md`. If the glob matches several, take the one for the current milestone (below).
2. `docs/decisions-<milestone>.md`, where `<milestone>` comes from the "Current milestone" line in `CLAUDE.md` or `AGENTS.md`.
3. `docs/decisions.md`.

If none exists, create `docs/decisions.md`:

```markdown
# Decisions

Entries follow `.claude/rules/decision-log.md`: numbered, under 150 words, never rewritten.
```

Put the entry in the PR summary too, so it is reviewed like code.

## 6. Log

If the branch name contains a Linear issue key (`NIM-94`, `nickassis/nim-94-...`), post the entry as a comment on that issue. Comments only: never create an issue, never change one's state or description.

## 7. Headless

When you cannot ask (step 2), do not answer on the human's behalf:

1. Post the framed question from step 1 as a comment on the issue, under a `## Decision needed` heading.
2. Stop the work that depends on the choice. Carry on with anything that does not.
3. Say in your final message that a decision is waiting, and link the comment.

With no issue to comment on, put the framed question in your final message and stop the dependent work.
