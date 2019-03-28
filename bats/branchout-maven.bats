load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-maven
  assert_success
}

@test "branchout-maven prints usage" {
  run branchout maven
  assert_error "branchout-maven settings|reactor|<alias>|<maven command>"
}

@test "maven clean - no settings asks for details" {
  example maven-clean
  run branchout maven clean <<< "https://maven.example.org/maven/branchout
docker.example.org
stickycode
sshsupersecret
"
  assert_success
  run branchout maven show 
  assert_success_file maven/settings
}
