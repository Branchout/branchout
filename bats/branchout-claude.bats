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
