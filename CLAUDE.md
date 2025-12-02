# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Branchout is a tool for managing organizations with many repositories in a structured way (Projected Monorepo). It enforces consistent naming conventions using a `group-project-name` pattern where projects are organized into groups locally.

## Language and Architecture

**Core Technology**: Pure Bash shell scripts (ADR-0002)
- **Bash version**: 3.2+ compatible (macOS ships with bash 3.2.57)
- No dependencies beyond standard Unix tools (git, bash)
- Designed for universal portability across developer environments
- Uses bats-core for testing framework
- Uses shellcheck for portability validation

**Bash Compatibility Constraints**:
- Must remain bash 3.2+ compatible for macOS users (Apple stopped at 3.2.57 due to GPLv3)
- Avoid bash 4+ features: associative arrays (`declare -A`), `mapfile`, `readarray`, `;&` case fallthrough
- Safe to use: indexed arrays, `[[ =~ ]]` regex matching, parameter expansion, command substitution

**Architectural Pattern** (ADR-0004): Multiple small, focused shell script files
- Each script does one thing well
- Main entry point: `branchout` (dispatcher script)
- Module scripts: `branchout-<module>` (e.g., `branchout-project`, `branchout-group`, `branchout-init`)
- Shared libraries: `branchout-configuration`, `branchout-environment`

## Core Components

### Main Scripts
- **branchout**: Main dispatcher that routes commands to appropriate modules
- **branchout-init**: Initializes a branchout projection from a git URL or locally
- **branchout-project**: Manages individual project operations (list, status, pull)
- **branchout-group**: Manages project groups (derive group names, clone groups)
- **branchout-environment**: Locates Branchoutfile, sets up environment variables
- **branchout-configuration**: Handles configuration value storage and retrieval
- **branchout-maven**: Maven-specific integration
- **branchout-yarn**: Yarn-specific integration with CA bundle support
- **branchout-node**: Node.js-specific integration

### Configuration Files
- **Branchoutfile** (or `.branchout`): Stores projection-level configuration
  - `BRANCHOUT_NAME`: Required - name of the projection
  - `BRANCHOUT_PREFIX`: Optional - prefix to strip from project names when deriving groups
  - `BRANCHOUT_GROUPS_ARE_DIRS`: Optional - set to "true" to create group directories with mkdir instead of attempting git clone (avoids error messages when groups aren't repositories)
  - `BRANCHOUT_GIT_BASEURL`: Derived automatically from git remote origin
  - `BRANCHOUT_MAVEN_REPOSITORY`: Optional - Maven repository URL
  - `BRANCHOUT_DOCKER_REGISTRY`: Optional - Docker registry URL
- **Branchoutprojects** (or `.projects`): Lists all projects in the projection (one per line)
- **branchoutrc**: User-specific configuration stored in `~/branchout/${BRANCHOUT_NAME}/branchoutrc`
- **~/.config/branchoutrc**: Global user configuration (e.g., BRANCHOUT_PROJECTS_DIRECTORY)

### Directory Structure
- Projects stored in `~/projects/${BRANCHOUT_NAME}/` by default
- Groups become directories: `~/projects/${BRANCHOUT_NAME}/group-name/`
- Projects within groups: `~/projects/${BRANCHOUT_NAME}/group-name/project-name/`
- State directory: `~/branchout/${BRANCHOUT_NAME}/`

## Development Commands

### Running Tests
```bash
# Run all tests
make test

# Run specific test suites
make test-branchout          # Core branchout tests
make test-branchout-projects # Project management tests
make test-branchout-init     # Init command tests
make test-branchout-maven    # Maven integration tests
make test-branchout-yarn     # Yarn integration tests
make test-branchout-group    # Group management tests

# Run tests in CI format (TAP output)
make ci

# Clean test artifacts
make clean
```

### Test Infrastructure
- Tests are written in bats (Bash Automated Testing System)
- Test files located in `bats/` directory
- Test helper functions in `bats/helper.bash`
- Mock binaries for testing in `bats/bin/` (e.g., mvn, yarn)
- Test fixtures and expected output in `output/` directory
- Test repositories created by `examples/make-repositories`

### Prerequisites
Install required tools:
```bash
brew install git bats-core shellcheck
```

### Linting
Use shellcheck to validate shell script portability and correctness:
```bash
shellcheck branchout*
```

## Key Implementation Details

### Environment Loading Sequence
1. `branchout-environment` searches up directory hierarchy for Branchoutfile
2. Sources Branchoutfile to load BRANCHOUT_NAME
3. Determines BRANCHOUT_STATE location: `~/branchout/${BRANCHOUT_NAME}`
4. Sources `branchoutrc` from BRANCHOUT_STATE if present
5. Derives BRANCHOUT_GIT_BASEURL from git remote origin

### Group Name Derivation Logic
Projects named `group-project-name` derive group as:
- Remove optional BRANCHOUT_PREFIX
- Extract first segment before hyphen
- Special case: `*-maven-plugin` always goes in "plugins" group

### Parallel Execution
Commands use xargs with parallel execution:
- Default: 10 parallel threads (`BRANCHOUT_THREADS` can override)
- Example: `branchout pull` clones/updates multiple repos simultaneously

### Color-Coded Status Output
Status uses ANSI escape codes for visual feedback:
- Default (white): master branch or pulled successfully
- Green: feature branches
- Orange: rebase in progress or empty repository
- Purple: not cloned
- Red: failed operations

### Platform Compatibility
The `branchout_os` function detects platform for OS-specific behavior:
- macOS: Different sed in-place syntax (`sed -i ''`)
- Linux: Standard sed syntax (`sed -i`)
- Windows (Cygwin/MSYS): Detected but uses default behavior

### CA Bundle Support
For corporate environments with custom CA certificates:
- Place certificates in `${PROJECTION_DIRECTORY}/.branchout/cacerts`
- `branchout-yarn` configures yarn to trust these certificates

## Common Workflows

### Initializing a projection
```bash
branchout init https://github.com/org/repo.git
cd ~/projects/repo
branchout status
branchout pull
```

### Adding and cloning projects
```bash
branchout add group-project-name    # Add to Branchoutprojects (won't clone)
branchout clone group-project-name  # Add and immediately clone
branchout pull                      # Clone/update all projects
```

### Relocating git URLs
When git base URL changes (e.g., moving from GitHub to GitLab):
```bash
branchout relocate https://gitlab.com/org
```

## Testing Strategy

Tests verify behavior by:
1. Creating temporary git repositories in `target/`
2. Running branchout commands
3. Comparing output against canned fixtures in `output/`
4. Using stub binaries in `bats/bin/` to mock external tools
