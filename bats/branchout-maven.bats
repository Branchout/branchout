load helper

makeSettings() {
  run branchout maven settings <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  assert_success
}

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-maven
  assert_success
}

@test "branchout maven - prints usage" {
  example maven-usage
  run branchout maven
  assert_error "branchout-maven settings|reactor|<alias>|<maven command>"
}

@test "branchout mvn - prints usage" {
  example mvn-alias
  run branchout mvn
  assert_error "branchout-maven settings|reactor|<alias>|<maven command>"
}

@test "branchout maven - ask for settings" {
  example maven-settings
  makeSettings
  assert_success
  run branchout maven show 
  assert_success_file maven/settings
}

@test "branchout maven - ask for settings always https" {
  example maven-settings-https
  run branchout maven clean <<< "maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  assert_success
  run branchout maven show 
  assert_success_file maven/settings-https
}

@test "branchout maven - expand commands" {
  example maven-commands
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  assert_success
  run branchout maven cv
  assert_success_file maven/cv
}

@test "branchout maven - expand commands many" {
  example maven-commands-many
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  run branchout maven cv cvi pom tree par plu
  assert_success "mvn -f pom.xml -s ../branchout/maven-commands-many/maven/settings.xml clean verify -Pwebapp-interactive clean verify help:effective-pom dependency:tree versions:update-parent versions:display-plugin-updates"
}

@test "branchout maven - expand commands head to head" {
  example maven-commands-hth
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  run branchout maven hth
  assert_success "mvn -f head-to-head.xml -s ../branchout/maven-commands-hth/maven/settings.xml clean verify"
}

@test "branchout mvn - expand commands head to head" {
  example mvn-commands-hth
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  run branchout maven hth
  assert_success "mvn -f head-to-head.xml -s ../branchout/mvn-commands-hth/maven/settings.xml clean verify"
}

@test "branchout maven - reactor prompt for group" {
  example maven-reactor-no-group
  makeSettings
  run branchout maven reactor <<< "org.example
"
  assert_success_file maven/reactor-no-group
}

@test "branchout mvn - reactor prompt for group" {
  example mvn-reactor-no-group
  makeSettings
  run branchout mvn reactor <<< "org.example
"
  assert_success_file maven/reactor-no-group
}
@test "branchout maven - reactor fail on empty group at prompt" {
  example maven-reactor-empty-group
  makeSettings
  run branchout maven reactor <<< ""

  assert_error "Please provide the Maven group: Error: You must supply a value for the Maven group"
}

@test "branchout maven - reactor from group" {
  example maven-reactor-group
  makeSettings

  echo 'BRANCHOUT_GROUP="org.example"' >> Branchoutfile
  run branchout maven reactor <<< ""

  assert_success_file maven/reactor-group
}

