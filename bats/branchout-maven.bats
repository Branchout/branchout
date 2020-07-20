load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-maven
  assert_success
}

@test "branchout-maven prints usage" {
  example maven-usage
  run branchout maven
  assert_error "branchout-maven settings|reactor|<alias>|<maven command>"
}

@test "branchout maven - ask for settings" {
  example maven-settings
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
uploaduser
uploadsecret
"
  assert_success
  run branchout maven show 
  assert_success_file maven/settings
}

@test "branchout maven - ask for settings default upload" {
  example maven-settings
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret


"
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
  assert_success_file maven/all-expansions
}

@test "branchout maven - expand commands head to head" {
  example maven-commands-hth
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  run branchout maven hth
  assert_success_file maven/hth
}
