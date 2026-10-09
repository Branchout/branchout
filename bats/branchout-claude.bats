load helper

# Stub output without the claudeMdExcludes settings argument, which has its own tests
withoutExcludes() {
  echo "${output}" | grep -v '^arg: --settings={"claudeMdExcludes":'
}

# The single claudeMdExcludes settings argument passed to the stub
excludesArgument() {
  echo "${output}" | grep '^arg: --settings={"claudeMdExcludes":' | sed -e 's,^arg: --settings=,,'
}

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

@test "branchout claude env prints the export without needing claude" {
  example claude-env
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude env
  assert_success "export CLAUDE_CONFIG_DIR=\"${BUILD_DIRECTORY}/branchout/claude-env/claude\""
}

@test "branchout claude where with no shared config" {
  example claude-where-empty
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-empty
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-empty/claude
settings: not found
skills: not found
mcp: not found
credentials override: none"
}

@test "branchout claude where shows all shared config" {
  example claude-where-all
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
  mkdir -p .claude/skills
  echo '{}' > .claude/settings.json
  echo '{"mcpServers":{}}' > .mcp.json
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-all
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-all/claude
settings: ${BUILD_DIRECTORY}/claude-where-all/.claude/settings.json
skills: ${BUILD_DIRECTORY}/claude-where-all/.claude/skills
mcp: ${BUILD_DIRECTORY}/claude-where-all/.mcp.json
credentials override: none"
}

@test "branchout claude where reports ambient credential overrides by name only" {
  example claude-where-credentials
  export CLAUDE_BIN=claude-does-not-exist
  export ANTHROPIC_API_KEY=secret-value
  export CLAUDE_CODE_OAUTH_TOKEN=other-secret
  run branchout claude where
  assert_success_only
  assert_equal "credentials override: ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN" "${lines[${#lines[@]}-1]}"
  [[ "${output}" != *secret-value* ]]
}

@test "branchout claude -- forces passthrough of intercepted words" {
  example claude-double-dash
  run branchout claude -- env
  assert_success_only
  assert_equal "CLAUDE_CONFIG_DIR=${BUILD_DIRECTORY}/branchout/claude-double-dash/claude
PWD=${BUILD_DIRECTORY}/claude-double-dash
arg: env" "$(withoutExcludes)"
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
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
  mkdir -p .claude/settings.json
  touch .claude/skills
  echo '{"mcpServers":{}}' > .mcp.json
  export CLAUDE_BIN=claude-does-not-exist
  run branchout claude where
  assert_success "projection: ${BUILD_DIRECTORY}/claude-where-mcp
claude config: ${BUILD_DIRECTORY}/branchout/claude-where-mcp/claude
settings: not found
skills: not found
mcp: ${BUILD_DIRECTORY}/claude-where-mcp/.mcp.json
credentials override: none"
}

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
