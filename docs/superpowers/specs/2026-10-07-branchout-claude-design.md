# branchout-claude — Design Spec

Date: 2026-10-07
Status: Approved design, revised 2026-10-09 (launch from the projection root)

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

### Shared projection config (launch from the projection root)

The projection's existing `.claude/` directory (current convention) is the shared, controlled
config. The wrapper always launches claude **from the projection root**, whatever directory it was
run from:

```
cd "${PROJECTION_DIRECTORY}"
exec "${CLAUDE_BIN:-claude}" --settings="<claudeMdExcludes json>" "${@}"
```

Because the projection root is claude's project, Claude loads the shared config natively as
project scope: `.claude/settings.json`, `.claude/skills`, `.claude/agents`, `.claude/commands`,
`CLAUDE.md` and `.mcp.json` (with Claude's normal project MCP approval prompt). No
`--add-dir`/`--settings <file>`/`--mcp-config` injection is needed. Sub-repo `CLAUDE.md` files load
on demand when Claude works in them; a sub-repo's own `.claude/settings.json` does not apply (the
projection root is the unit of work).

Revised from flag injection: launching from the root is how projections are normally used, and it
makes the shared config load natively instead of relying on `--add-dir` to surface skills.

### Ancestor CLAUDE.md isolation

Claude loads `CLAUDE.md`, `CLAUDE.local.md` and `.claude/CLAUDE.md` from every directory above its
cwd. With `CLAUDE_CONFIG_DIR` moved, the user's personal `~/.claude/CLAUDE.md` is no longer user
config but is still an ancestor file (home is above `~/projects/...`), so it would leak in and
prompt for its external `@` imports. To keep the projection fully isolated the wrapper passes a
flag-settings JSON with `claudeMdExcludes` listing, for every directory strictly above the
projection up to `/`:

- `<dir>/CLAUDE.md`
- `<dir>/CLAUDE.local.md`
- `<dir>/.claude/**`

(at `/` these are `/CLAUDE.md`, `/CLAUDE.local.md`, `/.claude/**`). Paths are JSON-escaped (`\` and
`"`). Verified on Claude Code 2.1.295: absolute paths and globs in `claudeMdExcludes` passed via
`--settings=<json>` suppress an ancestor `.claude/CLAUDE.md`. Entries are globs, so glob metacharacters
(`[ ] { } * ?`) in ancestor directory names are not escaped: a known limitation.

### Environment hygiene

Before exec the wrapper unsets the variables `branchout-environment` exports (`BRANCHOUT_LOADED`,
`PROJECTION_DIRECTORY`, `BRANCHOUT_STATE`, `BRANCHOUT_NAME`, `BRANCHOUT_FILE`,
`BRANCHOUT_PROJECTS`, `BRANCHOUT_GIT_BASEURL`, `BRANCHOUT_PREFIX`, `BRANCHOUT_GROUPS_ARE_DIRS`,
`BRANCHOUT_MAVEN_REPOSITORY`, `BRANCHOUT_DOCKER_REGISTRY`) so `branchout` commands Claude runs
re-detect their own projection. `CLAUDE_CONFIG_DIR` is kept. The config directory is `chmod 700`.

### Interface

```
branchout claude [claude args...]   run claude from the projection root with the projection's state
branchout claude env                print: export CLAUDE_CONFIG_DIR="<state>/claude"
branchout claude where              print projection dir, Claude config dir, and which shared
                                    files (settings.json, skills/, .mcp.json) the root provides, and any ambient credential
                                    variables (ANTHROPIC_API_KEY, ANTHROPIC_AUTH_TOKEN,
                                    CLAUDE_CODE_OAUTH_TOKEN) that override the login, by name only
branchout claude -- [claude args]   force passthrough (escape hatch if claude gains env/where)
```

Only the exact first arguments `env`, `where` and `--` are intercepted; anything else passes
through untouched. `--` is stripped before passing the remaining args.

`env` output is suitable for `eval "$(branchout claude env)"` and for configuring IDE extensions.
It only switches the login and state: ancestor `CLAUDE.md` exclusion and launching from the root
happen only through `branchout claude`, so plain `claude` may still load `~/.claude/CLAUDE.md` and,
from a sub-repo, won't see the root `.claude/` config.

### Error handling

- Not inside a projection: existing `branchout-environment` failure message and exit code.
- Claude binary not found (`command -v "${CLAUDE_BIN:-claude}"` fails): print
  `claude not found on PATH, install Claude Code: https://claude.com/claude-code` and exit 1.
- `CLAUDE_BIN` env var overrides the binary (used by tests; also useful for pinned installs).

### Implementation-time verifications

1. **Subcommands accept injected flags** — verified on Claude Code 2.1.292: yes, when flags use
   `--flag=value`; the space form of variadic `--add-dir`/`--mcp-config` swallows subcommands such
   as `auth status`. The revised design injects only `--settings=<json>`, still in `=` form.
2. **Skills via `--add-dir`** — not verified; superseded by launching from the projection root,
   where `.claude/skills` load as ordinary project skills (observed with a probe skill).
3. **Ancestor CLAUDE.md** — found during verification: `~/.claude/CLAUDE.md` loads as an ancestor
   file once `CLAUDE_CONFIG_DIR` is moved. Resolved with `claudeMdExcludes` (verified 2.1.295).
4. **macOS keychain isolation** — unverified on macOS; Linux isolation confirmed
   (`${CLAUDE_CONFIG_DIR}/.credentials.json`, fresh dir reports "Not logged in"). Check on first
   macOS use and document if shared.
5. **Symlinked ancestors** — verified on Claude Code 2.1.295: with cwd reached through a symlinked
   ancestor, a `claudeMdExcludes` entry written with either the logical or the physical path
   suppresses the ancestor `.claude/CLAUDE.md` (control without the exclude loads it), so the
   wrapper's logical-path excludes are sufficient.

## Testing

Full bats coverage, following existing module test patterns.

- Stub `bats/bin/claude`: prints `CLAUDE_CONFIG_DIR=<value>`, `PWD=<cwd>` and each argument on its
  own line, so tests assert the launch directory and exact injected flags.
- New `bats/branchout-claude.bats`, plus a `test-branchout-claude` Makefile target.
- Cases:
  - sets `CLAUDE_CONFIG_DIR` to `${BRANCHOUT_STATE}/claude`, creates it with mode 700
  - launches from the projection root, including when run from a nested group/project directory
  - injects exactly one `--settings=` claudeMdExcludes JSON before user args, covering the
    directories above the projection and not the projection itself
  - user args are passed through after the injected flag, preserving quoting/spaces
  - does not leak the branchout environment into claude
  - `env` prints the correct export line and does not invoke claude
  - `where` prints projection dir, config dir and shared files, does not invoke claude
  - `where` reports ambient credential override variables by name only
  - `--` forces passthrough (e.g. `branchout claude -- env` invokes claude with `env`)
  - `branchout-claude` and `branchout claude` behave identically
  - fails with the environment error outside a projection
  - fails with the install hint when the claude binary is missing
- `shellcheck branchout-claude` passes.

## Documentation

- Add a `claude` line to the dispatcher `usage` Modules list.
- Add `branchout-claude` to CLAUDE.md "Main Scripts" and describe the state/shared split.
- README: short usage section (log in once per projection, launches from the root,
  `eval "$(branchout claude env)"`, trust note for shared hooks/MCP).
- Homebrew: `BranchoutClaude` formula in `.deploy-to-homebrew`, depended on by `branchout`.

## Delivery

Work on branch `feature/branchout-claude` in the `branchout` repo; merge via PR, never direct to
master.
