---
name: work-board
description: Work through the user's Jira work board using their personal planning workspace (`plan`). Use when they ask about "my work board", "stuff assigned to me", "what should I work on", "pick the most important / easiest win", "work through my tickets", or to triage their backlog.
---

# Work board

Follow the `plan` skill's rules (views, local → preview → push). The
workspace's `AGENTS.md` (`plan where`) says which board this is and what its
columns mean for the user.

## 1. Refresh and look

```bash
plan pull          # skip if pulled in the last few minutes
plan mine          # my items on the board, by column then board rank
```

Read the columns as the board does: **In Progress** = active, continue it;
**Code Review / Testing** = waiting on others (check status, nudge, verify),
not new work; **Blocked** = see `plan blocked --mine`; **To Do** = next.

## 2. Pick

- **"Most important"**: unblocked items first; To Do before backlog; then
  Jira priority (Undetermined last); then board rank. That is the order of
  `plan next`. Prefer finishing In Progress items over starting new ones,
  and say so if several are open.
- **"Easiest win"**: the board has no estimates. Take the top ~10 of
  `plan next --json`, read descriptions (and `plan ticket KEY` for
  comments), look at the code they touch, and judge effort. Record your
  estimate so later picks are cheaper: `bd update <id> --estimate <minutes>`.
- **Search**: `plan next WORDS` or `plan find WORDS` narrows candidates.
- **"Work through it"**: with many aging backlog items, offer a triage pass
  first (still relevant? close? reprioritize?) before doing them top-down.

Present 1-3 recommendations with the key, why, and the evidence. Let the
user choose unless they asked you to just pick.

## 3. Do the work

The code lives in other repos; find the right one from the ticket and its
epic (`plan tree KEY`). Track sub-steps as local beads under the ticket (no
`jira` label, so they stay local): `bd create -t task "..." --parent <id>`.

## 4. Update Jira (always preview first)

Change beads locally (status, assignee, comment, close with reason), then:

```bash
plan push KEY            # preview only; show it to the user
plan push KEY --yes      # only after the user approves that preview
```

Never push without explicit keys, never `bd jira sync --push`.
`bd note` stays private; `bd comment` goes to Jira.
