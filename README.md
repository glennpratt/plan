# plan

Views and safe Jira sync for a personal planning workspace: a
[beads](https://github.com/gastownhall/beads) database that mirrors the Jira
issues one person cares about (their board, an on-call board, linked issues
from other teams) plus local-only work Jira doesn't track.

It is built on a [beads fork](https://github.com/glennpratt/beads/tree/jira-mtls)
with Jira Server/Data Center support: mTLS, epic/parent hierarchy, boards and
scopes, links, comments, and a push that only sends what changed.

`plan` adds:

- **Views** that read the local mirror, fast and without credentials:
  `plan mine`, `next`, `oncall`, `tree`, `blocked`, `find`, `show`.
- **Safe writes**: change beads locally, `plan push KEY` previews exactly
  what would change in Jira, and only `plan push KEY --yes` sends it. There
  is no push-everything.
- **Agent skills** (`skills/`) for VS Code Chat, Copilot CLI, Claude Code
  and Codex: `plan` (commands and safety rules), `work-board`, `oncall`,
  `jira-planning`.
- **An agent test harness** (`plan-agent-test`, `plan-agent-test-suite`):
  runs Copilot CLI scenarios against a sandboxed copy of the workspace with
  no Jira credentials (macOS Seatbelt via Copilot's sandbox).

## Install

```bash
nix profile install github:glennpratt/plan   # plan, bd, plan-agent-test*
```

or add `github:glennpratt/plan` as a flake input and include
`packages.<system>.default` in a profile.

Skills ship in `share/plan/skills`; link them where your agents look:

```bash
for s in ~/.nix-profile/share/plan/skills/*; do
  ln -sfn "$s" ~/.agents/skills/   # VS Code Chat, Copilot CLI, Codex
  ln -sfn "$s" ~/.claude/skills/   # Claude Code
done
```

## Configure

A per-device dotfile names the workspace:

```toml
# ~/.config/plan/config.toml
data = "~/path/to/planning"
```

The workspace (a directory with a beads database, typically its own
private git repo) holds the shared settings in `plan.toml`; the dotfile can
override any of them for one device:

```toml
# <workspace>/plan.toml
me = "jdoe"                                  # your Jira username

[jira]
api = "https://jira.example.com"             # REST base (…/rest/api/2)
browse = "https://jira.example.com/browse/"  # for links in output
token = "op://Private/Jira/credential"       # 1Password ref; $JIRA_API_TOKEN wins
client_cert = "~/.certs/me.pem"              # optional mTLS
client_key = "~/.certs/me.key"
ca_cert = "~/.certs/corp-root.crt"

[views]
work_board = "work"          # bd config jira.board.<name>
oncall_board = "oncall"
oncall_project = "OPS"       # for plan oncall --recent
```

The Jira sync itself (projects, scopes, boards, field and status maps) is
beads configuration: `bd config set jira.…` in the workspace.

Put the user's own context in the workspace's `AGENTS.md`: projects,
boards, work streams, team quirks. The skills tell agents to read it.

## Several machines

Give the workspace a git remote and `bd dolt push --yes` once: beads stores
the database under `refs/dolt/data` there, apart from your branches. On
another machine, clone it and run `bd bootstrap --yes`.

The beads fork's Jira commands then keep machines in step: `bd jira pull`
and `bd jira push` pull the Dolt remote first, and a real push pushes it
afterwards (`jira.dolt_sync=false` turns this off). `plan push` pulls
before previewing; a real push refuses if its own pull changed the issues
being pushed, so what is sent always matches a preview. Merges are per
field; the same field edited on two machines resolves last-write-wins, and
children created under the same parent on two machines collide (resolve
with `bd dolt pull --strategy theirs`, then re-create).

## Develop

```bash
nix develop          # bd (the fork), python3, jq, shellcheck
PLAN_DATA=~/path/to/planning bin/plan mine
```

`$PLAN_DATA` overrides the dotfile. A dev build of the fork earlier on
`PATH` wins over the packaged `bd`.
