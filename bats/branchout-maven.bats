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

@test "branchout maven - no settings - show" {
  example maven-no-settings-show
  run branchout maven show 
  assert_error "Maven settings '../branchout/maven-no-settings-show/maven/settings.xml' not found. Run 'branchout maven settings'"
}

@test "branchout maven - no settings - no docker" {
  example maven-no-settings-no-docker
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
stickycode
sshsupersecret
"
  assert_success
  run branchout maven show 
  assert_success_file maven/no-settings-no-docker
}

@test "branchout maven - no settings - with docker" {
  example maven-no-settings-with-docker
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  assert_success
  run branchout maven show 
  assert_success_file maven/no-settings-with-docker
}

@test "branchout maven - no settings - with upload" {
  example maven-no-settings-with-upload
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
https://maven.example.org/maven/branchout-upload
stickycode
sshsupersecret


"
  assert_success
  run branchout maven show 
  assert_success_file maven/no-settings-with-upload
}

@test "branchout maven - no settings - with upload and docker" {
  example maven-no-settings-with-upload-with-docker
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
https://maven.example.org/maven/branchout-upload
docker.example.org
docker-upload.example.org
stickycode
sshsupersecret


"
  assert_success
  run branchout maven show 
  assert_success_file maven/no-settings-with-upload-with-docker
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
