rm -rf target
load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout
  assert_success
}

@test "invoking branchout prints usage" {
  run branchout
  assert_failure
  assert_output_start "branchout: a tool for managing multi-repo projects"
}

@test "no .branchout is error" {
  cd /tmp
  run branchout status
  assert_failure ".branchout configuration not found in parent hierarchy, run branchout init" 
}

@test "branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir target/missing-name -p
  cd target/missing-name
  touch .branchout
  run branchout status
  assert_error "Branchout name not defined in .branchout, run branchout init" 
}

