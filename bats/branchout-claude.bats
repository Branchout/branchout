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
  mode="$(ls -ld "${BUILD_DIRECTORY}/branchout/claude-config-dir/claude" | cut -c1-10)"
  test "${mode}" = "drwx------" || bail "claude config directory mode was ${mode}, expected drwx------"
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
  rm -rf "${NO_PROJECTION}"
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

@test "branchout claude does not leak the branchout environment into claude" {
  example claude-isolated
  PROBE="${BUILD_DIRECTORY}/claude-env-probe"
  cat > "${PROBE}" <<'PROBE_EOF'
#!/bin/bash
echo "BRANCHOUT_LOADED=[${BRANCHOUT_LOADED}]"
echo "PROJECTION_DIRECTORY=[${PROJECTION_DIRECTORY}]"
echo "CLAUDE_CONFIG_DIR=[${CLAUDE_CONFIG_DIR}]"
PROBE_EOF
  chmod +x "${PROBE}"
  export CLAUDE_BIN="${PROBE}"
  run branchout claude
  assert_success "BRANCHOUT_LOADED=[]
PROJECTION_DIRECTORY=[]
CLAUDE_CONFIG_DIR=[${BUILD_DIRECTORY}/branchout/claude-isolated/claude]"
}

@test "branchout claude where only trusts regular files for settings and mcp" {
  example claude-where-mcp
  mkdir -p .claude/settings.json
  touch .claude/skills
  echo '{"mcpServers":{}}' > .mcp.json
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-mcp
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-mcp/claude
settings: not found
skills: not found
mcp: ${BUILD_DIRECTORY}/claude-where-mcp/.mcp.json"
}
