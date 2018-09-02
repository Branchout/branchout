load helper

@test "invoking branchout prints usage" {
  run branchout
  assert_success
  assert_output_start "branchout: a tool for managing multi-repo projects"
}

@test "no branchout is error" {
  cd /tmp
  run branchout status
  assert_failure ".branchout configuration not found in parent hierarchy, run branchout init" 
}

@test "shellcheck compliant with no exceptions" {
  run shellcheck branchout
  [ "$status" -eq 0 ]
}
