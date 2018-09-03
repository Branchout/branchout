rm -rf target
load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout
  assert_success
}

@test "invoking branchout prints usage" {
  run branchout
  assert_error "branchout: a tool for managing multi-repo projects"
}

@test "no Branchoutfile is error" {
  cd /tmp
  run branchout status
  assert_error "Branchoutfile configuration not found in parent hierarchy, run branchout init" 
}

@test "branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir target/missing-name -p
  cd target/missing-name
  touch Branchoutfile
  run branchout status
  assert_error "Branchout name not defined in Branchoutfile, run branchout init" 
}

@test "branchout directory is missing fails" {
  mkdir target/missing-directory -p
  cd target/missing-directory
  echo "BRANCHOUT_NAME=notexists" > Branchoutfile
  run branchout status
  assert_error "Branchout home 'target/branchout/notexists' does not exist, run branchout init" 
}

@test "missing projects prompts" {
  mkdir target -p
  cp -fax examples/no-projects target
  cd target/no-projects
  HOME=./
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}
