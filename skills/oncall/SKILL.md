---
name: oncall
description: Help the user clear their on-call escalation board using their personal planning workspace (`plan oncall`). Use when they say they are on call, ask to "clear the board", "triage escalations", "what's on the on-call board", or about tickets in the on-call project.
---

# On-call board

Follow the `plan` skill's rules (views, local → preview → push). The
workspace's `AGENTS.md` (`plan where`) names the on-call board, its project
and the status to clear.

The goal is to get every ticket **out of the escalated status**: to In
Progress (we are taking it) or Closed (resolved / not ours / duplicate).
Tickets are assigned to whoever filed or owns them on the support side;
being on call is not reflected in the assignee, so never filter by assignee.

## 1. Refresh and list

```bash
plan pull
plan oncall --recent 7   # board in rank order, plus recently moved off
```

Jira priority is often unset on these, so **board rank** is the order.
Note ages; old tickets need attention first unless rank says otherwise.

## 2. Triage one ticket at a time

1. Read it fully: `plan ticket KEY` (description, comments, links).
2. Check whether existing work already covers it: `plan find WORDS`,
   `plan blocked`.
3. Propose exactly one action, with a one-paragraph rationale:
   - **Take it**: status in_progress plus a comment ("Taking this: ...").
   - **Close it**: with a reason that becomes the Jira comment.
   - **Ask for information**: a comment with the specific questions.
   - **Link a fix**: create or find the fix story and
     `bd dep add <escalation-id> <fix-id>` (the escalation waits on the
     fix); the push creates the Jira link.
4. Apply locally, then preview: `plan push KEY`. Show the preview.
   Only after the user approves: `plan push KEY --yes`.

Service-desk workflows may require fields on close (resolution is handled;
others show up as push errors). If a push fails, report it and suggest
doing that step in Jira. Private reasoning goes in `bd note`, never
`bd comment`.

## 3. Wrap up

Re-run `plan oncall` and summarize what moved and what remains, with keys.
