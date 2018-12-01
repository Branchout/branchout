load helper

@test "branchout environment is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-environment
  assert_success
}


@test "branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir -p target/missing-name
  cd target/missing-name
  touch Branchoutfile
  run branchout status
  assert_error "Branchout name not defined in Branchoutfile, run branchout init" 
}

@test "branchout configuration missing BRANCHOUT_GIT_BASEURL fails" {
  mkdir -p target/missing-giturl target/branchout/missing-giturl 
  cd target/missing-giturl
  echo 'BRANCHOUT_NAME="missing-giturl"' > Branchoutfile 
  run branchout status
  assert_error "Git base url is not defined in Branchoutfile, run branchout init" 
}

@test "branchout home is missing fails" {
  mkdir -p target/missing-branchout-home 
  HOME=..
  cd target/missing-branchout-home
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="missing-branchout-home"' >> Branchoutfile 
  run branchout status
  assert_error "Branchout home '../branchout/missing-branchout-home' does not exist, run branchout init" 
}

@test "branchout missing projects prompts" {
  mkdir -p target/no-projects target/branchout/no-projects 
  cd target/no-projects
  HOME=..
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="no-projects"' >> Branchoutfile 
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "branchout prefix is removed" {
  mkdir -p target/prefix target/branchout/prefix 
  cd target/prefix
  HOME=..
  echo 'BRANCHOUT_NAME="prefix"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="prefix"' >> Branchoutfile 
  echo 'BRANCHOUT_PREFIX="prefix"' >> Branchoutfile 
  echo 'prefix-frog-aleph' > Branchoutprojects
  run branchout status
  assert_success_file status/no-clone-prefix
}
