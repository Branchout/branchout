load helper

makeSettings() {
  run branchout yarn settings <<< "https://yarn.example.org/repository/npm-example
npmuser
supersecret
stickycode@example.org
"
  assert_success "Please provide your npm registry: 
Please provide npm registry username: 
Please provide npm registry secret: 
Please provide npm registry email (git commit author): 
create the branchout directory for node ../branchout/yarn-settings/node/
writing yarn config to ../branchout/yarn-settings/node/yarnrc
writing npm config to ../branchout/yarn-settings/node/.npmrc"
}

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-yarn
  assert_success
}

@test "branchout-yarn prints usage" {
  example yarn-usage
  run branchout yarn
  assert_error "branchout-yarn settings|show|install|<package.json command>"
}

@test "branchout yarn - ask for settings" {
  example yarn-settings
  makeSettings
  run branchout yarn show 
  assert_success_file yarn/yarnrc
}

@test "branchout yarn - missing registry fails" {
  example yarn-settings-missing-registry
  run branchout yarn clean <<<  "
"
  assert_failure "Please provide your npm registry: 
Error: You must supply a value for your npm registry"
}

@test "branchout yarn - missing npm user fails" {
  example yarn-settings-missing-npm-username
  run branchout yarn clean <<<  "https://yarn.example.org/repository/npm-example

"
  assert_failure "Please provide your npm registry: 
Please provide npm registry username: 
Error: You must supply a value for npm registry username"
}

@test "branchout yarn - missing npm pass fails" {
  example yarn-settings-missing-npm-password
  run branchout yarn clean <<<  "https://yarn.example.org/repository/npm-example
npmuser

"
  assert_failure "Please provide your npm registry: 
Please provide npm registry username: 
Please provide npm registry secret: 
Error: You must supply a value for npm registry secret"
}

@test "branchout yarn - missing npm email fails" {
  example yarn-settings-missing-npm-email
  run branchout yarn clean <<<  "https://yarn.example.org/repository/npm-example
npmuser
supersecret
"
  assert_failure "Please provide your npm registry: 
Please provide npm registry username: 
Please provide npm registry secret: 
Please provide npm registry email (git commit author): 
Error: You must supply a value for npm registry email (git commit author)"
}

@test "branchout yarn - ask for settings always https" {
  example yarn-settings-https
  run branchout yarn clean <<<  "http://yarn.example.org/repository/npm-example
npmuser
supersecret
stickycode@example.org
"
  assert_success "Please provide your npm registry: 
Please provide npm registry username: 
Please provide npm registry secret: 
Please provide npm registry email (git commit author): 
create the branchout directory for node ../branchout/yarn-settings-https/node/
writing yarn config to ../branchout/yarn-settings-https/node/yarnrc
writing npm config to ../branchout/yarn-settings-https/node/.npmrc"
  run branchout yarn show 
  assert_success_file yarn/yarnrc
}