# branchout-claude — Design Spec

Date: 2026-10-07
Status: Approved design, pending implementation

## Problem

Developers work across several branchout projections (clients, orgs, personal), each of which
may need a different Claude login, different memory/history, and a common set of team-controlled
skills, settings and MCP servers. Running plain `claude`:

- shares one login and one `~/.claude` (memory, history, plugins, hooks) across every projection
- does not apply the projection root's `.claude/settings.json` when launched inside a sub-repo,
  because the sub-repo is its own project root

## Goals

1. One Claude login (and all other user state) per projection, isolated from `~/.claude` and from
   other projections.
2. Shared, version-controlled Claude config in the projection applies to every user, from any
   repo within the projection.
3. Follow existing branchout module conventions; no new dependencies.

## Non-goals

- Inheriting or layering personal `~/.claude` config into a projection (decided: fully isolated).
- Login/logout/reset helpers — Claude's own `/login`, `/logout`, `claude auth status` already work
  once `CLAUDE_CONFIG_DIR` is set.
- Copying/merging/generating config files into the state directory.

## Design

### Component

New module script `branchout-claude` in the branchout repo root, alongside `branchout-yarn` and
`branchout-maven`.

- Bash 3.2 compatible, shellcheck clean (per CLAUDE.md constraints).
- Sources `branchout-configuration` then `branchout-environment`, exactly like `branchout-yarn`.
- Reachable as `branchout claude ...` via the dispatcher's existing `branchout-<module>`
  fallthrough; no dispatcher routing change needed.

### User state (isolated, per projection)

- `CLAUDE_CONFIG_DIR="${BRANCHOUT_STATE}/claude"` — i.e. `~/branchout/<BRANCHOUT_NAME>/claude`.
- Created with `mkdir -p` if missing, exported before exec.
- Holds credentials, history, memory, user-scope settings and installed plugins. Nothing is read
  from `~/.claude`. First run behaves like a fresh install; the user logs in with `/login`.

### Shared projection config

The projection's existing `.claude/` directory (current convention) is the shared, controlled
config. The wrapper injects:

| Condition | Injected flag |
|---|---|
| `${PROJECTION_DIRECTORY}/.claude/settings.json` exists | `--settings "${PROJECTION_DIRECTORY}/.claude/settings.json"` |
| always | `--add-dir "${PROJECTION_DIRECTORY}"` (exposes the projection, including `.claude/skills`) |
| `${PROJECTION_DIRECTORY}/.mcp.json` exists | `--mcp-config "${PROJECTION_DIRECTORY}/.mcp.json"` |

Flags are built in an indexed bash array (bash 3.2 safe) and placed before the user's arguments:

```
exec "${CLAUDE_BIN:-claude}" "${flags[@]}" "${@}"
```

The current sub-repo's own `.claude/` config continues to load normally. CLAUDE.md files in the
projection root are already loaded by Claude as parent-directory memory when cwd is inside it.

### Interface

```
branchout claude [claude args...]   run claude with the projection's state and shared config
branchout claude env                print: export CLAUDE_CONFIG_DIR="<state>/claude"
branchout claude where              print projection dir, Claude config dir, and which shared
                                    files (settings.json, skills/, .mcp.json) were detected
branchout claude -- [claude args]   force passthrough (escape hatch if claude gains env/where)
```

Only the exact first arguments `env`, `where` and `--` are intercepted; anything else passes
through untouched. `--` is stripped before passing the remaining args.

`env` output is suitable for `eval "$(branchout claude env)"` and for configuring IDE extensions.

### Error handling

- Not inside a projection: existing `branchout-environment` failure message and exit code.
- Claude binary not found (`command -v "${CLAUDE_BIN:-claude}"` fails): print
  `claude not found on PATH, install Claude Code: https://claude.com/claude-code` and exit 1.
- `CLAUDE_BIN` env var overrides the binary (used by tests; also useful for pinned installs).

### Implementation-time verifications

These must be checked against the installed Claude Code version before finalising, and the
outcome recorded in the module's comments or the PR:

1. **Subcommands accept injected flags.** Check `claude --settings X --add-dir Y auth status`,
   `mcp list`, `plugin list`. If any reject the flags, inject flags only when the first user
   argument is not one of a known subcommand list (`auth`, `mcp`, `plugin`, `doctor`, `update`,
   `install`, `setup-token`, `config`); those still receive `CLAUDE_CONFIG_DIR`.
2. **Skills via `--add-dir`.** Confirm `${PROJECTION_DIRECTORY}/.claude/skills` are discovered
   when launching from a sub-repo. If not, document the limitation and ship shared skills via a
   plugin enabled in the projection `settings.json`.
3. **macOS keychain isolation.** Confirm credentials are stored separately per
   `CLAUDE_CONFIG_DIR` on macOS (Linux uses `${CLAUDE_CONFIG_DIR}/.credentials.json`). If shared,
   document it as a known limitation.

## Testing

Full bats coverage, following existing module test patterns.

- Stub `bats/bin/claude`: prints `CLAUDE_CONFIG_DIR=<value>` and each argument on its own line,
  so tests assert exact injected flags and ordering.
- New `bats/branchout-claude.bats`, plus a `test-branchout-claude` Makefile target.
- Cases:
  - sets `CLAUDE_CONFIG_DIR` to `${BRANCHOUT_STATE}/claude` and creates the directory
  - injects `--settings` only when projection `.claude/settings.json` exists
  - injects `--mcp-config` only when projection `.mcp.json` exists
  - always injects `--add-dir <projection>`
  - user args are passed through after injected flags, preserving quoting/spaces
  - works when run from a nested group/project directory (resolves projection root)
  - `env` prints the correct export line and does not invoke claude
  - `where` prints projection dir, config dir and detected shared files, does not invoke claude
  - `--` forces passthrough (e.g. `branchout claude -- env` invokes claude with `env`)
  - `branchout-claude` and `branchout claude` behave identically
  - fails with the environment error outside a projection
  - fails with the install hint when the claude binary is missing
- `shellcheck branchout-claude` passes.

## Documentation

- Add `claude: see branchout claude where` to the dispatcher `usage` Modules list.
- Add `branchout-claude` to CLAUDE.md "Main Scripts" and describe the state/shared split.
- README: short usage section (log in once per projection, `eval "$(branchout claude env)"`).

## Delivery

Work on branch `feature/branchout-claude` in the `branchout` repo; merge via PR, never direct to
master.
