# branchout-claude Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `branchout-claude` module that runs Claude Code with a per-projection login/state directory and the projection's shared `.claude/` config, from any repo in the projection.

**Architecture:** A new module script `branchout-claude` (same shape as `branchout-yarn`) sources `branchout-configuration` and `branchout-environment`, exports `CLAUDE_CONFIG_DIR=${BRANCHOUT_STATE}/claude` (absolute), builds an array of injected flags from files present in `${PROJECTION_DIRECTORY}`, and `exec`s claude. Three intercepted first arguments (`env`, `where`, `--`) provide shell/IDE integration and an escape hatch. The dispatcher already routes `branchout claude` to `branchout-claude`.

> **Superseded in part:** the flag-injection design below was replaced by launching from the projection root — see "Revision 2026-10-09" near the end of this plan.

**Tech Stack:** Bash 3.2+, bats-core, shellcheck, Claude Code CLI (verified against 2.1.292).

**Spec:** `docs/superpowers/specs/2026-10-07-branchout-claude-design.md`

## Global Constraints

> **Superseded in part:** the flag-injection design below was replaced by launching from the projection root — see "Revision 2026-10-09" near the end of this plan.

- Bash 3.2 compatible: no `declare -A`, `mapfile`, `readarray`, `;&`. Indexed arrays are fine.
- `shellcheck -x branchout-claude` passes with no exceptions.
- No new dependencies beyond bash, git and standard Unix tools.
- Claude state lives in `${BRANCHOUT_STATE}/claude` (i.e. `~/branchout/<BRANCHOUT_NAME>/claude`); nothing is read from `~/.claude`.
- Shared config comes only from the projection's existing `.claude/` directory and `.mcp.json`.
- **Injected flags MUST use the `--flag=value` form.** Verified on Claude Code 2.1.292: `--add-dir` and `--mcp-config` are variadic, so `--add-dir DIR auth status` swallows `auth status` as directories. `--add-dir=DIR auth status` works for `auth status`, `mcp list`, `plugin list`.
- Injected flag order: `--add-dir=…`, then `--settings=…` (if present), then `--mcp-config=…` (if present), then the user's arguments unchanged.
- All work on branch `feature/branchout-claude`; merge via PR, never direct to master.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commits are GPG signed (repo default) — do not bypass signing.

## Test Harness Notes (read before Task 1)

- Run tests from the repo root via `make`; the Makefile puts `bats/bin` and the repo root first on `PATH`, so `branchout`, `branchout-claude` and the stub `claude` resolve there.
- `bats/helper.bash` `example <name>` creates `target/<name>` with a `Branchoutfile`, `Branchoutprojects`, a git origin, state dir `target/branchout/<name>`, `cd`s into it and sets `HOME=..` (relative).
- `BUILD_DIRECTORY` is the absolute `…/target`. So inside an example: `PROJECTION_DIRECTORY=${BUILD_DIRECTORY}/<name>` and the Claude config dir is `${BUILD_DIRECTORY}/branchout/<name>/claude` (the script makes it absolute).
- `assert_success "<text>"` = exit 0 and output exactly equal. `assert_success_firstline "<text>"` = first line equal. `assert_error "<text>"` = non-zero exit and first line equal.
- Each bats test runs in its own process, so `export`/`cd` inside a test does not leak.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `branchout-claude` | Create | The module: config dir, flag injection, `env`/`where`/`--`, exec claude |
| `bats/bin/claude` | Create | Test stub: prints `CLAUDE_CONFIG_DIR=` then one `arg: <x>` line per argument |
| `bats/branchout-claude.bats` | Create | All module tests |
| `Makefile` | Modify | Add `test-branchout-claude` target |
| `branchout` | Modify | Add `claude` line to the `usage` Modules list |
| `CLAUDE.md` | Modify | Document the module, test target, state/shared split |
| `README.md` | Modify | User-facing usage section |
| `docs/superpowers/specs/2026-10-07-branchout-claude-design.md` | Modify | Record verification outcomes |

---

### Task 1: Module skeleton — isolated config dir, `--add-dir`, passthrough

**Files:**
- Create: `branchout-claude`
- Create: `bats/bin/claude`
- Create: `bats/branchout-claude.bats`
- Modify: `Makefile` (after the `test-branchout-yarn` target)

**Interfaces:**
- Produces: script `branchout-claude` with functions `usage`, `claudeConfigDirectory` (sets+exports absolute `CLAUDE_CONFIG_DIR`), `runClaude "$@"` (builds global array `CLAUDE_FLAGS`, execs `${CLAUDE_BIN:-claude}`), `main "$@"`. Stub `bats/bin/claude` output format: line 1 `CLAUDE_CONFIG_DIR=<value>`, then `arg: <argument>` per argument.

- [ ] **Step 1: Create the claude stub**

`bats/bin/claude`:

```bash
#!/bin/bash

echo "CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR}"
for each in "${@}"; do
  echo "arg: ${each}"
done
```

Run: `chmod +x bats/bin/claude`

- [ ] **Step 2: Add the Makefile target**

In `Makefile`, after the `test-branchout-yarn` target add:

```make
test-branchout-claude: clean canned repositories
	$(BATS) --pretty bats/branchout-claude.bats
```

(Recipe line is indented with a TAB.)

- [ ] **Step 3: Write the failing tests**

`bats/branchout-claude.bats`:

```bash
load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-claude
  assert_success
}

@test "branchout claude sets an absolute per projection CLAUDE_CONFIG_DIR and creates it" {
  example claude-config-dir
  run branchout claude
  assert_success_firstline "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-config-dir/claude"
  test -d "${BUILD_DIRECTORY}/branchout/claude-config-dir/claude" || bail "claude config directory was not created"
}

@test "branchout claude always adds the projection directory" {
  example claude-add-dir
  run branchout claude
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-add-dir/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-add-dir"
}

@test "branchout claude passes user arguments after the injected flags preserving spaces" {
  example claude-passthrough
  run branchout claude -p "hello world" --model opus
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-passthrough/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-passthrough
arg: -p
arg: hello world
arg: --model
arg: opus"
}

@test "branchout-claude behaves the same as branchout claude" {
  example claude-direct
  run branchout-claude auth status
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-direct/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-direct
arg: auth
arg: status"
}

@test "branchout claude from a nested project directory resolves the projection root" {
  example claude-nested
  mkdir -p frog/frog-aleph
  cd frog/frog-aleph
  export HOME="${BUILD_DIRECTORY}"
  run branchout claude
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-nested/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-nested"
}

@test "branchout claude fails with an install hint when claude is missing" {
  example claude-missing
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude
  assert_error "claude not found on PATH, install Claude Code: https://claude.com/claude-code"
}

@test "branchout claude outside a projection fails" {
  NO_PROJECTION="$(mktemp -d)"
  mkdir -p "${NO_PROJECTION}/projects"
  cd "${NO_PROJECTION}"
  export HOME="${NO_PROJECTION}"
  run branchout claude
  assert_error "Branchoutfile configuration not found in parent hierarchy, perhaps you need to be in a project directory ${NO_PROJECTION}/projects"
}
```

The nested test sets an absolute `HOME` because `example` sets `HOME=..`, which would resolve relative to the nested cwd.

- [ ] **Step 4: Run tests to verify they fail**

Run: `make test-branchout-claude`
Expected: all 8 fail (shellcheck cannot open `branchout-claude`; the others report `branchout-claude is not installed (or doesn't exist)`).

- [ ] **Step 5: Write the module**

`branchout-claude`:

```bash
#!/bin/bash

test -n "${DEBUG}" && set -x
set -e

function usage() {
  test -n "${1}" && echo "${1}" && echo
  echo "branchout-claude [env|where|--] [claude arguments]

  Run claude with this projection's own login and state, plus the shared
  .claude configuration from the projection root.

  env

      Print an export of CLAUDE_CONFIG_DIR for eval or IDE configuration

  where

      Show the projection, the claude config directory and the shared files found

  -- [claude arguments]

      Pass everything after -- straight to claude
  "

  exit 1
}

# Each projection gets its own claude login, history, memory and plugins
function claudeConfigDirectory() {
  mkdir -p "${BRANCHOUT_STATE}/claude"
  CLAUDE_CONFIG_DIR="$(cd "${BRANCHOUT_STATE}/claude" && pwd)"
  export CLAUDE_CONFIG_DIR
}

# Flags use --flag=value because --add-dir and --mcp-config are variadic and
# would otherwise swallow following arguments such as "auth status"
function runClaude() {
  CLAUDE_BIN="${CLAUDE_BIN:-claude}"
  command -v "${CLAUDE_BIN}" > /dev/null || fail "claude not found on PATH, install Claude Code: https://claude.com/claude-code"

  CLAUDE_FLAGS=("--add-dir=${PROJECTION_DIRECTORY}")

  exec "${CLAUDE_BIN}" "${CLAUDE_FLAGS[@]}" "${@}"
}

function main() {
  BRANCHOUT_PATH="$(dirname "$0")"

  # shellcheck source=branchout-configuration
  . "${BRANCHOUT_PATH}/branchout-configuration"
  # shellcheck source=branchout-environment
  . "${BRANCHOUT_PATH}/branchout-environment"

  claudeConfigDirectory

  runClaude "${@}"
}

main "${@}"
```

Run: `chmod +x branchout-claude`

Note: `usage` must be defined before sourcing `branchout-environment`, which calls `usage` when the state dir or projects file is missing. `fail` comes from `branchout-environment` (prints message, blank line, exits 1).

- [ ] **Step 6: Run tests to verify they pass**

Run: `make test-branchout-claude`
Expected: `8 tests, 0 failures`

- [ ] **Step 7: Commit**

```bash
git add branchout-claude bats/bin/claude bats/branchout-claude.bats Makefile
git commit -m "Add branchout-claude with a per projection claude config directory

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Inject shared projection settings and MCP config

**Files:**
- Modify: `branchout-claude` (`runClaude`)
- Test: `bats/branchout-claude.bats` (append)

**Interfaces:**
- Consumes: `runClaude`, `CLAUDE_FLAGS` from Task 1; stub output format from Task 1.
- Produces: `CLAUDE_FLAGS` order `--add-dir=`, `--settings=` (if `${PROJECTION_DIRECTORY}/.claude/settings.json` exists), `--mcp-config=` (if `${PROJECTION_DIRECTORY}/.mcp.json` exists).

- [ ] **Step 1: Write the failing tests**

Append to `bats/branchout-claude.bats`:

```bash
@test "branchout claude injects the projection settings when present" {
  example claude-settings
  mkdir -p .claude
  echo '{}' > .claude/settings.json
  run branchout claude
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-settings/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-settings
arg: --settings=${BUILD_DIRECTORY}/claude-settings/.claude/settings.json"
}

@test "branchout claude injects the projection mcp config when present" {
  example claude-mcp
  echo '{"mcpServers":{}}' > .mcp.json
  run branchout claude
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-mcp/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-mcp
arg: --mcp-config=${BUILD_DIRECTORY}/claude-mcp/.mcp.json"
}

@test "branchout claude injects all shared config before user arguments" {
  example claude-all-shared
  mkdir -p .claude
  echo '{}' > .claude/settings.json
  echo '{"mcpServers":{}}' > .mcp.json
  run branchout claude mcp list
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-all-shared/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-all-shared
arg: --settings=${BUILD_DIRECTORY}/claude-all-shared/.claude/settings.json
arg: --mcp-config=${BUILD_DIRECTORY}/claude-all-shared/.mcp.json
arg: mcp
arg: list"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make test-branchout-claude`
Expected: the 3 new tests fail (output missing `--settings=`/`--mcp-config=` lines); the 8 from Task 1 pass.

- [ ] **Step 3: Implement**

In `branchout-claude`, replace the `CLAUDE_FLAGS=…` line in `runClaude` with:

```bash
  CLAUDE_FLAGS=("--add-dir=${PROJECTION_DIRECTORY}")
  if test -f "${PROJECTION_DIRECTORY}/.claude/settings.json"; then
    CLAUDE_FLAGS+=("--settings=${PROJECTION_DIRECTORY}/.claude/settings.json")
  fi
  if test -f "${PROJECTION_DIRECTORY}/.mcp.json"; then
    CLAUDE_FLAGS+=("--mcp-config=${PROJECTION_DIRECTORY}/.mcp.json")
  fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test-branchout-claude`
Expected: `11 tests, 0 failures`

- [ ] **Step 5: Commit**

```bash
git add branchout-claude bats/branchout-claude.bats
git commit -m "Inject the projection's shared claude settings and mcp config

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `env`, `where` and `--` subcommands

**Files:**
- Modify: `branchout-claude` (add `claudeEnv`, `claudeWhere`, `sharedFile`; `case` in `main`)
- Test: `bats/branchout-claude.bats` (append)

**Interfaces:**
- Consumes: `claudeConfigDirectory`, `runClaude` from Tasks 1–2.
- Produces:
  - `env` output, exactly one line: `export CLAUDE_CONFIG_DIR="<absolute config dir>"`
  - `where` output, exactly five lines, each value an absolute path or the literal `not found`:
    ```
    projection: <PROJECTION_DIRECTORY>
    claude config: <CLAUDE_CONFIG_DIR>
    settings: <PROJECTION_DIRECTORY>/.claude/settings.json | not found
    skills: <PROJECTION_DIRECTORY>/.claude/skills | not found
    mcp: <PROJECTION_DIRECTORY>/.mcp.json | not found
    ```
  - Neither `env` nor `where` invokes or requires the claude binary.
  - `--` is stripped and the rest goes to `runClaude`.

- [ ] **Step 1: Write the failing tests**

Append to `bats/branchout-claude.bats`:

```bash
@test "branchout claude env prints the export without needing claude" {
  example claude-env
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude env
  assert_success "export CLAUDE_CONFIG_DIR=\"${BUILD_DIRECTORY}/branchout/claude-env/claude\""
}

@test "branchout claude where with no shared config" {
  example claude-where-empty
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-empty
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-empty/claude
settings: not found
skills: not found
mcp: not found"
}

@test "branchout claude where shows all shared config" {
  example claude-where-all
  mkdir -p .claude/skills
  echo '{}' > .claude/settings.json
  echo '{"mcpServers":{}}' > .mcp.json
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-all
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-all/claude
settings: ${BUILD_DIRECTORY}/claude-where-all/.claude/settings.json
skills: ${BUILD_DIRECTORY}/claude-where-all/.claude/skills
mcp: ${BUILD_DIRECTORY}/claude-where-all/.mcp.json"
}

@test "branchout claude -- forces passthrough of intercepted words" {
  example claude-double-dash
  run branchout claude -- env
  assert_success "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-double-dash/claude
arg: --add-dir=${BUILD_DIRECTORY}/claude-double-dash
arg: env"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make test-branchout-claude`
Expected: the 4 new tests fail (`env`/`where` fail with the install hint; `-- env` output contains an extra `arg: --` line). Previous 11 pass.

- [ ] **Step 3: Implement**

In `branchout-claude`, add after `claudeConfigDirectory`:

```bash
function claudeEnv() {
  echo "export CLAUDE_CONFIG_DIR=\"${CLAUDE_CONFIG_DIR}\""
}

# Print the path when it exists, otherwise "not found"
function sharedFile() {
  if test -e "${1}"; then
    echo "${1}"
  else
    echo "not found"
  fi
}

function claudeWhere() {
  echo "projection: ${PROJECTION_DIRECTORY}"
  echo "claude config: ${CLAUDE_CONFIG_DIR}"
  echo "settings: $(sharedFile "${PROJECTION_DIRECTORY}/.claude/settings.json")"
  echo "skills: $(sharedFile "${PROJECTION_DIRECTORY}/.claude/skills")"
  echo "mcp: $(sharedFile "${PROJECTION_DIRECTORY}/.mcp.json")"
}
```

Replace the final `runClaude "${@}"` line in `main` with:

```bash
  case "${1}" in
    env)
      claudeEnv
      ;;
    where)
      claudeWhere
      ;;
    --)
      shift
      runClaude "${@}"
      ;;
    *)
      runClaude "${@}"
      ;;
  esac
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test-branchout-claude`
Expected: `15 tests, 0 failures`

- [ ] **Step 5: Commit**

```bash
git add branchout-claude bats/branchout-claude.bats
git commit -m "Add env, where and -- to branchout-claude

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Documentation and dispatcher usage

**Files:**
- Modify: `branchout` (`usage` function, Modules list after the `yarn:` line)
- Modify: `CLAUDE.md`
- Modify: `README.md` (after the "Need to trust a certificate or ca bundle" section)

**Interfaces:**
- Consumes: the behaviour from Tasks 1–3.

- [ ] **Step 1: Dispatcher usage**

In `branchout`, in `usage()`, after the line `      yarn: set branchout yarn help` add:

```
      claude: run claude with this projection's login and shared .claude config, see branchout claude where
```

- [ ] **Step 2: CLAUDE.md**

Under "### Main Scripts", after the `branchout-node` bullet add:

```markdown
- **branchout-claude**: Runs Claude Code with a per-projection login/state (`CLAUDE_CONFIG_DIR=~/branchout/${BRANCHOUT_NAME}/claude`) and injects the projection root's shared `.claude/settings.json`, `.claude/skills` (via `--add-dir`) and `.mcp.json`. Subcommands: `env`, `where`, `--`.
```

Under "### Running Tests", after the `make test-branchout-yarn` line add:

```
make test-branchout-claude   # Claude integration tests
```

Add a new section before "## Common Workflows":

```markdown
### Claude Integration
- User state (login, history, memory, plugins) is isolated per projection in `${BRANCHOUT_STATE}/claude`; nothing is inherited from `~/.claude`
- Shared, version-controlled config lives in the projection root `.claude/` and `.mcp.json`, applied from any repo in the projection
- Injected flags use `--flag=value` because `--add-dir` and `--mcp-config` are variadic and would swallow subcommands like `auth status`
```

Under "### Test Infrastructure", change `(e.g., mvn, yarn)` to `(e.g., mvn, yarn, claude)`.

- [ ] **Step 3: README.md**

After the "Need to trust a certificate or ca bundle" section add:

````markdown
### Claude Code per projection

`branchout claude` runs Claude Code with a login and state that belong to the projection, so each
branchout can use a different account. Log in once per projection with `/login`.

```
cd ~/projects/<projection>/<group>/<project>
branchout claude
```

Shared skills, settings and MCP servers for everyone go in the projection root's `.claude/` and
`.mcp.json`; they apply from any repo in the projection.

* `branchout claude where` shows what is being used
* `eval "$(branchout claude env)"` points plain `claude` (or your IDE) at the projection's state
* `branchout claude -- <args>` passes arguments straight through
````

- [ ] **Step 4: Run the full suite and shellcheck**

Run: `make test && shellcheck -x branchout*`
Expected: all tests pass (including `invoking branchout prints usage`, which only checks the first line), shellcheck prints nothing. If any pre-existing test fails, confirm it also fails on `master` before continuing and report it rather than changing it.

- [ ] **Step 5: Commit**

```bash
git add branchout CLAUDE.md README.md
git commit -m "Document branchout-claude

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Real-claude verification and record outcomes

Manual checks against the real Claude Code CLI (not the stub). Run outside `make` so the stub is not on `PATH`. Use the real branchout projection at `/home/michael/projects/branchout`.

**Files:**
- Modify: `docs/superpowers/specs/2026-10-07-branchout-claude-design.md` ("Implementation-time verifications" section)

- [ ] **Step 1: Subcommands work through the wrapper**

```bash
cd /home/michael/projects/branchout/branchout
./branchout-claude where
./branchout-claude auth status
./branchout-claude mcp list
```

Expected: `where` shows `~/branchout/branchout-project/claude` and `settings: /home/michael/projects/branchout/.claude/settings.json`; `auth status` prints `Not logged in · Please run /login` (fresh isolated state); `mcp list` runs without a "must provide input" error.

- [ ] **Step 2: Skills via `--add-dir`** (needs the user to log in once, interactively)

Ask the user to: create `/home/michael/projects/branchout/.claude/skills/bo-probe/SKILL.md` containing

```markdown
---
name: bo-probe
description: Probe skill to verify branchout-claude loads projection skills
---
Reply with "bo-probe loaded".
```

then run `! cd /home/michael/projects/branchout/branchout && ./branchout-claude`, `/login`, and `/skills` (or ask "use bo-probe"). Record whether `bo-probe` is listed. Delete the probe skill afterwards. If it is not listed, record the limitation and the workaround from the spec (ship shared skills as a plugin enabled in the projection `settings.json`).

- [ ] **Step 3: macOS keychain isolation**

Cannot be verified on this Linux machine (Linux stores credentials in `${CLAUDE_CONFIG_DIR}/.credentials.json`, confirmed by the fresh dir reporting "Not logged in"). Record as "unverified on macOS — check on first macOS use".

- [ ] **Step 4: Record outcomes in the spec**

Replace the three numbered items under "### Implementation-time verifications" with their outcomes, e.g.:

```markdown
1. **Subcommands accept injected flags** — verified on Claude Code 2.1.292: yes, provided flags use
   `--flag=value`; the space form of variadic `--add-dir`/`--mcp-config` swallows subcommands.
   No subcommand allowlist needed.
2. **Skills via `--add-dir`** — <result from Step 2>.
3. **macOS keychain isolation** — unverified on macOS; Linux isolation confirmed
   (`${CLAUDE_CONFIG_DIR}/.credentials.json`).
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-10-07-branchout-claude-design.md
git commit -m "Record branchout-claude verification outcomes

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Finish the branch

- [ ] **Step 1:** Use superpowers:finishing-a-development-branch. Expected outcome: push `feature/branchout-claude` with an explicit refspec (`git push origin feature/branchout-claude` — bare `git push` fails because `push.default = nothing`) and open a PR against `master` with `gh pr create`. PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Do not merge without the user's approval.

---

## Revision 2026-10-09: launch from the projection root

Tasks 1–4 and the final-review fixes are complete. Real-CLI verification changed the design (see the
spec's "Shared projection config (launch from the projection root)" and "Ancestor CLAUDE.md
isolation"): the wrapper now `cd`s to the projection root and injects only one flag,
`--settings=<claudeMdExcludes json>`. Tasks 7–8 implement that; Task 6 (finish the branch) runs after
them.

Revised global constraints (replace the flag-injection ones above):

- The wrapper launches claude with cwd = `${PROJECTION_DIRECTORY}`.
- The only injected flag is `--settings=<json>` (one argv element, `=` form), placed before the
  user's arguments. No `--add-dir`, no `--settings=<file>`, no `--mcp-config`.
- The JSON is exactly `{"claudeMdExcludes":[...]}` listing, for each directory strictly above the
  projection up to and including `/`, in order from the projection's parent upwards:
  `<dir>/CLAUDE.md`, `<dir>/CLAUDE.local.md`, `<dir>/.claude/**` (for `/`: `/CLAUDE.md`,
  `/CLAUDE.local.md`, `/.claude/**`). Values are JSON-escaped (`\` → `\\`, `"` → `\"`).
- The branchout environment unset before exec and the 700 config dir stay as they are.

### Task 7: Launch from the projection root with ancestor CLAUDE.md excludes

**Files:**
- Modify: `branchout-claude` (`usage`, add `jsonString` and `claudeMdExcludes`, `runClaude`)
- Modify: `bats/bin/claude` (also print the cwd)
- Modify: `bats/branchout-claude.bats` (rework flag tests)

**Interfaces:**
- Consumes: existing `claudeConfigDirectory`, `claudeEnv`, `claudeWhere`, `main` (unchanged).
- Produces: `jsonString <value>` prints a quoted JSON string; `claudeMdExcludes` prints the JSON
  object; `runClaude` execs `${CLAUDE_BIN}` with `CLAUDE_FLAGS=("--settings=$(claudeMdExcludes)")`
  from `${PROJECTION_DIRECTORY}`. Stub output: line 1 `CLAUDE_CONFIG_DIR=<value>`, line 2
  `PWD=<cwd>`, then `arg: <x>` per argument.

- [ ] **Step 1: Update the stub**

`bats/bin/claude`:

```bash
#!/bin/bash

echo "CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR}"
echo "PWD=${PWD}"
for each in "${@}"; do
  echo "arg: ${each}"
done
```

- [ ] **Step 2: Rework the tests**

In `bats/branchout-claude.bats`, directly after `load helper` add:

```bash
# Stub output without the claudeMdExcludes settings argument, which has its own tests
withoutExcludes() {
  echo "${output}" | grep -v '^arg: --settings={"claudeMdExcludes":'
}

# The single claudeMdExcludes settings argument passed to the stub
excludesArgument() {
  echo "${output}" | grep '^arg: --settings={"claudeMdExcludes":' | sed -e 's,^arg: --settings=,,'
}
```

Delete these tests (their behaviour no longer exists):
`branchout claude always adds the projection directory`,
`branchout claude injects the projection settings when present`,
`branchout claude injects the projection mcp config when present`,
`branchout claude injects all shared config before user arguments`.

Replace these tests' bodies so they assert via `withoutExcludes` (keep their names):

```bash
@test "branchout claude passes user arguments after the injected flags preserving spaces" {
  example claude-passthrough
  run branchout claude -p "hello world" --model opus
  assert_success_only
  assert_equal "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-passthrough/claude
PWD=${BUILD_DIRECTORY}/claude-passthrough
arg: -p
arg: hello world
arg: --model
arg: opus" "$(withoutExcludes)"
  assert_equal "arg: --settings=$(excludesArgument)" "$(echo "${output}" | sed -n 3p)"
}

@test "branchout-claude behaves the same as branchout claude" {
  example claude-direct
  run branchout-claude auth status
  assert_success_only
  assert_equal "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-direct/claude
PWD=${BUILD_DIRECTORY}/claude-direct
arg: auth
arg: status" "$(withoutExcludes)"
}

@test "branchout claude from a nested project directory launches from the projection root" {
  example claude-nested
  mkdir -p frog/frog-aleph
  cd frog/frog-aleph
  export HOME="${BUILD_DIRECTORY}"
  run branchout claude
  assert_success_only
  assert_equal "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-nested/claude
PWD=${BUILD_DIRECTORY}/claude-nested" "$(withoutExcludes)"
}

@test "branchout claude -- forces passthrough of intercepted words" {
  example claude-double-dash
  run branchout claude -- env
  assert_success_only
  assert_equal "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-double-dash/claude
PWD=${BUILD_DIRECTORY}/claude-double-dash
arg: env" "$(withoutExcludes)"
}
```

(The nested test was previously named "...resolves the projection root"; rename it as above.)

Append these new tests:

```bash
@test "branchout claude excludes CLAUDE.md files from every directory above the projection" {
  example claude-excludes
  run branchout claude
  assert_success_only
  excludes="$(excludesArgument)"
  test "$(echo "${output}" | grep -c '^arg: --settings=')" -eq 1 || bail "expected exactly one --settings argument: ${output}"
  for expected in "\"${BUILD_DIRECTORY}/CLAUDE.md\"" "\"${BUILD_DIRECTORY}/CLAUDE.local.md\"" "\"${BUILD_DIRECTORY}/.claude/**\"" \
      "\"$(dirname "${BUILD_DIRECTORY}")/.claude/**\"" '"/CLAUDE.md"' '"/CLAUDE.local.md"' '"/.claude/**"'; do
    case "${excludes}" in
      *"${expected}"*) ;;
      *) bail "missing ${expected} in ${excludes}" ;;
    esac
  done
  case "${excludes}" in
    *"${BUILD_DIRECTORY}/claude-excludes/"*) bail "projection itself must not be excluded: ${excludes}" ;;
  esac
}

@test "branchout claude excludes start with the projection parent and end with the filesystem root" {
  example claude-excludes-order
  run branchout claude
  assert_success_only
  assert_equal "{\"claudeMdExcludes\":[\"${BUILD_DIRECTORY}/CLAUDE.md\"," "$(excludesArgument | cut -c1-$((${#BUILD_DIRECTORY} + 34)))"
  assert_equal '"/CLAUDE.md","/CLAUDE.local.md","/.claude/**"]}' "$(excludesArgument | sed -e 's,.*\("/CLAUDE.md"\),\1,')"
}
```

(`{"claudeMdExcludes":["` is 22 characters, `/CLAUDE.md",` is 12, so the prefix is
`${#BUILD_DIRECTORY} + 34` characters.)

Leave the remaining tests (shellcheck, config dir/700, missing claude, outside projection, env,
both `where` tests, environment leak) unchanged — except the first assertion of
`branchout claude sets an absolute per projection CLAUDE_CONFIG_DIR and creates it`, which uses
`assert_success_firstline` and still holds.

- [ ] **Step 3: Run tests to verify they fail**

Run: `make test-branchout-claude`
Expected: the reworked and new tests fail (output still contains `arg: --add-dir=…`, no `PWD=` of
the projection when nested, no `--settings={"claudeMdExcludes"…` argument); others pass.

- [ ] **Step 4: Implement**

In `branchout-claude`, change the first paragraph of the `usage` text to:

```
  Run claude from the projection root with this projection's own login and state.
  The root's .claude configuration, skills and .mcp.json load as the project config.
```

Replace the comment above `runClaude` and `runClaude` itself with:

```bash
# Print a value as a JSON string
function jsonString() {
  local value="${1//\\/\\\\}"
  value="${value//\"/\\\"}"
  echo "\"${value}\""
}

# Claude loads CLAUDE.md files from every directory above its cwd; with CLAUDE_CONFIG_DIR moved
# that includes ~/.claude/CLAUDE.md, so exclude everything above the projection to keep it isolated
function claudeMdExcludes() {
  local directory base excludes=""
  directory="$(dirname "${PROJECTION_DIRECTORY}")"
  while true; do
    base="${directory%/}"
    excludes="${excludes}${excludes:+,}$(jsonString "${base}/CLAUDE.md"),$(jsonString "${base}/CLAUDE.local.md"),$(jsonString "${base}/.claude/**")"
    test "${directory}" = "/" && break
    directory="$(dirname "${directory}")"
  done
  echo "{\"claudeMdExcludes\":[${excludes}]}"
}

# Launch from the projection root so its .claude configuration is the project configuration
function runClaude() {
  CLAUDE_BIN="${CLAUDE_BIN:-claude}"
  command -v "${CLAUDE_BIN}" > /dev/null || fail "claude not found on PATH, install Claude Code: https://claude.com/claude-code"

  CLAUDE_FLAGS=("--settings=$(claudeMdExcludes)")
  cd "${PROJECTION_DIRECTORY}"

  # Claude must not inherit our environment or branchout commands it runs would short-circuit to this projection
  unset BRANCHOUT_LOADED PROJECTION_DIRECTORY BRANCHOUT_STATE BRANCHOUT_NAME BRANCHOUT_FILE BRANCHOUT_PROJECTS \
    BRANCHOUT_GIT_BASEURL BRANCHOUT_PREFIX BRANCHOUT_GROUPS_ARE_DIRS BRANCHOUT_MAVEN_REPOSITORY BRANCHOUT_DOCKER_REGISTRY

  exec "${CLAUDE_BIN}" "${CLAUDE_FLAGS[@]}" "${@}"
}
```

If `CLAUDE_BIN` is a relative path it would break after `cd`; resolve it first with
`CLAUDE_BIN="$(command -v "${CLAUDE_BIN}")"` right after the `command -v … || fail` check.

- [ ] **Step 5: Run tests to verify they pass**

Run: `make test-branchout-claude` then `make test`
Expected: all pass (module suite count = previous 17 − 4 deleted + 2 new = 15; full suite 145),
`shellcheck -x branchout-claude` clean.

- [ ] **Step 6: Real-CLI smoke check**

```bash
cd /home/michael/projects/branchout/branchout && ./branchout-claude auth status
```

Expected: JSON auth status (no "must provide input" error) — confirms the injected `--settings=` JSON
does not swallow subcommands.

- [ ] **Step 7: Commit**

```bash
git add branchout-claude bats/bin/claude bats/branchout-claude.bats
git commit -m "Launch claude from the projection root and exclude ancestor CLAUDE.md files

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Update docs for the root launch

**Files:**
- Modify: `CLAUDE.md` (the `branchout-claude` Main Scripts bullet; the "### Claude Integration" section)
- Modify: `README.md` ("### Claude Code per projection" section)

- [ ] **Step 1: CLAUDE.md bullet**

Replace the `- **branchout-claude**: …` bullet with:

```markdown
- **branchout-claude**: Runs Claude Code from the projection root with a per-projection login/state (`CLAUDE_CONFIG_DIR=~/branchout/${BRANCHOUT_NAME}/claude`), so the root's `.claude/` settings, skills, agents, commands and `.mcp.json` load as the project config. Subcommands: `env`, `where`, `--`.
```

- [ ] **Step 2: CLAUDE.md "Claude Integration" section**

Replace the section's bullets with:

```markdown
- User state (login, history, memory, plugins) is isolated per projection in `${BRANCHOUT_STATE}/claude` (mode 700); nothing is inherited from `~/.claude`
- Claude is always launched from the projection root, whatever directory `branchout claude` is run from; the root's `.claude/` and `.mcp.json` are the shared, version-controlled config. Sub-repo `CLAUDE.md` files load when Claude works in them; a sub-repo's own `.claude/settings.json` does not apply
- Claude loads `CLAUDE.md` files from every directory above its cwd, which would include `~/.claude/CLAUDE.md` once `CLAUDE_CONFIG_DIR` is moved; the wrapper passes `--settings={"claudeMdExcludes":[...]}` listing `CLAUDE.md`, `CLAUDE.local.md` and `.claude/**` for every directory above the projection
- The branchout environment variables (`BRANCHOUT_LOADED`, `PROJECTION_DIRECTORY`, `BRANCHOUT_STATE`, etc.) are unset before exec so branchout commands run by Claude re-detect their projection
- Hooks in the projection's `.claude/settings.json` run for every developer, and its `.mcp.json` servers are offered to everyone (Claude still asks for approval), so review changes to them (e.g. CODEOWNERS on those paths)
```

- [ ] **Step 3: README section**

Replace the "### Claude Code per projection" section (up to, not including, "## Grokking the code
and contributing") with:

````markdown
### Claude Code per projection

`branchout claude` runs Claude Code with a login and state that belong to the projection, so each
branchout can use a different account. Log in once per projection with `/login`.

```
cd ~/projects/<projection>
branchout claude
```

Claude always starts in the projection root, even if you run `branchout claude` from inside a
project, so the root's `.claude/` (settings, skills, agents, commands) and `.mcp.json` are the
shared configuration for everyone. Your personal `~/.claude` is not used.

* `branchout claude where` shows what is being used
* `eval "$(branchout claude env)"` points plain `claude` (or your IDE) at the projection's state
* `branchout claude <args>` passes arguments to claude; `--` is only needed when the first argument is `env` or `where`

Shared hooks in the projection's `.claude/settings.json` run for everyone using `branchout claude`,
and its MCP servers are offered to everyone, so review changes to them like code.

````

- [ ] **Step 4: Verify and commit**

Run: `make test` (expect 145 tests, 0 failures).

```bash
git add CLAUDE.md README.md
git commit -m "Document launching branchout-claude from the projection root

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
