load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-maven
  assert_success
}

@test "invoking branchout prints usage" {
  run branchout maven
  assert_error "branchout-maven settings|reactor|<alias>|<maven command>"
}
