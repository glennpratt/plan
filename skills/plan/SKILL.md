---
name: plan
description: How to read and change the user's personal Jira planning workspace (a beads database mirroring Jira) with the `plan` and `bd` commands, and the rules that keep Jira safe. Use whenever you look up, plan, track, or update tickets, epics, stories, tasks, blockers or discovered bugs in "planning", or before any other planning skill (work-board, oncall, jira-planning).
---

# Planning workspace

The user keeps a personal mirror of Jira in a beads (`bd`) database: their
board, an on-call board, and issues linked from other teams, plus local-only
work Jira doesn't track. Pulled tickets are **shared state**: other people
see every change that reaches Jira.

`plan where` prints the workspace directory. Its `AGENTS.md` has the user's
own context (projects, boards, work streams, quirks): read it before
planning work. `plan` works from any directory; for `bd`, run it in the
workspace (or pass `-C "$(plan where)"`).

## Views (read-only, local, no credentials)

| Command | Use |
|---|---|
| `plan mine` | My work-board items by column, then board rank |
| `plan next [-n N] [WORDS]` | Unblocked candidates to start: To Do, then the board, then the backlog |
| `plan oncall [--recent DAYS]` | On-call board in rank order (+ tickets recently moved off it) |
| `plan tree KEY` | An epic's subtree with assignees, blocked items, ready-but-unassigned work |
| `plan blocked [--mine]` | Open work waiting on open blockers, other teams' first |
| `plan find WORDS` | Search pulled issues |
| `plan show KEY\|ID` | One issue from the mirror: fields, labels, links, parent, comments, notes |
| `plan ticket KEY` | Full Jira issue with live comments (needs Jira access) |
| `plan pull [KEY...]` | Refresh from Jira, or just the named issues |
| `bd list -l me:stream:NAME --all` | One work stream |

Views take `--json`. Lines show the Jira key and the bead ID; `plan` accepts
either, `bd` needs the bead ID. `plan --help` lists everything. Don't use
`bd ready`: it lists every unblocked bead from every team.

## Writing: local first, then preview, then push named issues

1. Change beads locally: `bd update <id> --status in_progress`,
   `--assignee <user>`, `--title ...`, `bd close <id> -r "reason"`,
   `bd comment <id> "text"`, `bd dep add <a> <b>` (a waits on b),
   `bd create ... --parent <epic> -l jira`.
2. Preview: `plan push <KEY|ID>...` (no `--yes`). Show the preview to the user.
3. Only after the user approves that exact preview:
   `plan push <KEY|ID>... --yes`.

Never run `bd jira sync --push` or `bd jira sync` without `--pull`: they push
everything that differs. `plan push` refuses to run without explicit IDs.

Don't claim (`bd update --claim`) or close pulled tickets unless the user
asks: both become Jira changes on the next push of that ticket.

Before closing, reassigning or marking a ticket a duplicate on request, read
it (`plan show`, and `plan ticket` for live comments). If its comments or
history argue against the change (it was reopened, someone disagreed, the
"duplicate" target closed while this one stayed open), tell the user and ask
before changing anything.

If a Jira step fails because there is no token or no network (agent
sandboxes have neither), still make the local change and stop: say what
failed and give the user the exact `plan` command to run themselves. Don't
look for credentials and don't suggest loosening a sandbox.

`bd` takes the bead ID, not the Jira key: copy it exactly from `plan show
KEY` (`pl-42.1` is a child of `pl-42`; the suffix matters). To undo
something you added by mistake, remove just that: `bd dep remove` for a
dependency; for a note, rewrite the notes field keeping the other text
(`bd note` appends to one text field). Comments can't be deleted, so check
the ID before `bd comment`.

## Conventions

- **Comments are shared, notes are private.** `bd comment` is pushed to
  Jira; `bd note` never is. A close reason (`bd close -r`) is posted as a
  Jira comment when the close is pushed.
- **The `jira` label** marks a new local bead to be created in Jira.
  Children do not inherit it. Without it, beads stay local (personal tasks,
  sub-steps, stream epics, gates).
- **`me:*` labels** are personal and never sent to Jira; pulls keep them.
- `board:<name>` / `backlog:<name>` labels mirror Jira boards; don't set
  them by hand.
- New beads under a Jira epic become stories with an Epic Link; under a
  story, sub-tasks. `--metadata '{"jira_project":"KEY"}'` files into another
  project; the preview lists required fields it lacks.
- Local edits to pulled issues survive pulls until pushed; if Jira changed
  the same field, Jira wins with a warning.
- Ticket descriptions don't list blockers; Jira links are the record.

## Several machines

The workspace can be shared between machines through its Dolt remote
(`refs/dolt/data` on its git remote).

- Jira commands sync it: `plan pull` and `plan push` pull the Dolt remote
  first, and a real push publishes it afterwards. For local-only changes
  (notes, labels, local beads), `bd dolt push` before leaving a machine and
  `bd dolt pull` on arriving.
- If a push says its Dolt pull brought in changes to the issues being
  pushed, preview again (`plan push KEY`) and show the user the new preview.
- The same field edited on two machines between syncs: the later edit wins
  silently (`Notice: ... last-write-wins`). Mention such notices to the user.
- Two machines adding a child under the same parent between syncs get the
  same ID (`.1`, `.2`, ...), and `bd dolt pull` stops with a conflict.
  `bd dolt pull --strategy theirs` keeps the other machine's child; then
  re-create this machine's child (it gets the next number).

## Work streams and gates

- A **work stream** is a local epic plus a `me:stream:<name>` label on its
  Jira tickets. Tickets join by label, never by local parent: a local parent
  would push as an Epic Link change. A ticket may be in several streams.
- When work waits on **any one** of several tickets, add a local gate bead
  `related` to each (`bd dep relate`), make the work depend on the gate, and
  close the gate by hand when the first lands. Beads dependencies all have
  to close, so they can't express "any one".
