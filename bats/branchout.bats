load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout
  assert_success
}

@test "shellcheck compliant branchout-project" {
  run shellcheck -x branchout-project
  assert_success
}

@test "shellcheck compliant branchout-status" {
  run shellcheck -x branchout-status
  assert_success
}

@test "shellcheck compliant branchout-group" {
  run shellcheck -x branchout-group
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

@test "branchout configuration missing BRANCHOUT_GIT_BASEURL fails" {
  mkdir target/missing-giturl target/branchout/missing-giturl -p
  cd target/missing-giturl
  echo 'BRANCHOUT_NAME="missing-giturl"' > Branchoutfile 
  run branchout status
  assert_error "Git base url is not defined in Branchoutfile, run branchout init" 
}

@test "branchout home is missing fails" {
  mkdir target/missing-branchout-home -p
  HOME=..
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="missing-branchout-home"' >> Branchoutfile 
  cd target/missing-branchout-home
  run branchout status
  assert_error "Branchout home '../branchout/missing-branchout-home' does not exist, run branchout init" 
}

@test "missing projects prompts" {
  mkdir target/no-projects target/branchout/no-projects -p
  cd target/no-projects
  HOME=..
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="no-projects"' >> Branchoutfile 
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "can pull all" {
  example pull-all
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph-before-pull
  run branchout pull
  assert_success 
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph
}
