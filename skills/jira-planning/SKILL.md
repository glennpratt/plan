---
name: jira-planning
description: Plan and correct Jira work across people and teams with the user's personal planning workspace (`plan`). Use when they ask to plan or break down an epic, assign or rebalance work, see who is doing what, file requests to other teams, find cross-team blockers, or fix/correct Jira tickets (titles, parents, links, assignees).
---

# Jira planning

Follow the `plan` skill's rules (views, local → preview → push). The
workspace's `AGENTS.md` (`plan where`) lists the user's projects and the
teams they file requests with.

## See the plan

```bash
plan pull
plan tree KEY               # epic subtree: assignees, blocked [!], ready-unassigned
plan blocked                # who waits on whom; other teams' blockers first
plan find WORDS             # locate issues across everything pulled
```

`plan tree` ends with open counts per assignee and ready-but-unassigned
work: the input for assigning and rebalancing.

## Change the plan (locally first)

- New stories under an epic: `bd create -t story "..." --parent <epic-id> -l jira`
  (the `jira` label is what makes it go to Jira; children do not inherit it).
- Work for another team: add `--metadata '{"jira_project":"KEY"}'` (or
  create it under that team's ticket); the preview reports required fields
  to supply via `jira_fields` metadata. Model it on that team's existing
  requests (`plan find`), and make the work that needs it wait on it
  (`bd dep add <waiting-id> <new-id>`).
- Assign: `bd update <id> --assignee <jira-username>`.
- Re-parent (move to another epic): remove the old parent-child dependency,
  add the new one. Sub-task re-parenting is not supported (needs Jira Move).
- Links: `bd dep add <a> <b>` (a waits on b -> Jira "b blocks a"),
  `--type related` for "relates to"; `bd dep remove` deletes the link.
- Fix text: `bd update <id> --title ... --description ...`.

Personal sub-steps and notes: local beads without the `jira` label,
`me:*` labels, and `bd note` never reach Jira.

## Push (always preview, explicit issues only)

```bash
plan push KEY_OR_ID ...         # preview only; show it to the user
plan push KEY_OR_ID ... --yes   # only after the user approves that preview
```

Previews list each change (fields, "+P-2 blocks P-1", "epic/parent link
...", "+comment", creates with their project and placement). Other people's
tickets are shared state: keep pushes small and say what each one does.
