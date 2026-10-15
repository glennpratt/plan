# plan (tooling repo)

This repo is the generic tooling for a personal beads planning workspace:
`bin/plan`, the agent skills in `skills/`, and the agent test harness. It
holds no planning data and nothing specific to one person or company; those
live in the workspace (`plan where`): its `plan.toml`, `AGENTS.md`, beads
config and `agent-tests/`. Keep it that way: no hostnames, project keys,
usernames, board IDs or credential references here, only placeholders in
docs.

## Develop

- `nix develop` (or direnv) gives `bd` from the beads fork, python3, jq and
  shellcheck. Run commands as written; no absolute binary paths.
- Try changes against the real workspace read-only:
  `PLAN_DATA=<workspace> bin/plan mine`. Never run `plan push --yes`,
  `bd jira sync` or other Jira writes while developing; previews
  (`plan push KEY`) are fine.
- `nix build` must pass; `shellcheck bin/agent-test bin/agent-test-suite`.
- `bin/plan` stays stdlib-only Python (3.11+, for tomllib).

## Safety properties to preserve

- `plan push` needs explicit keys or IDs and sends only with `--yes`, after
  printing the same preview.
- No environment override chooses the `bd` binary (an agent once used one
  to swap in another program); `bd` comes from `PATH`.
- With no Jira token, `plan` says so and names the command for the user to
  run; it must not suggest finding credentials or loosening a sandbox.
- The agent harness denies the real workspace and credential directories;
  test agents get a clone and no network.

## Agent files

`AGENTS.md` is the source; `CLAUDE.md` is a symlink. Skills are written
once in `skills/` and linked into `~/.agents/skills` and `~/.claude/skills`.
