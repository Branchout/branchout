export PATH=${PATH}:bin
export HOME=target

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
  mkdir target/missing-branchout-home target/branchout/missing-branchout-home -p
  cd target/missing-branchout-home
  HOME=../
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile 
  run branchout status
  assert_error "Branchout home 'target/branchout/notexists' does not exist, run branchout init" 
}

@test "missing projects prompts" {
  mkdir target/no-projects target/branchout/no-projects -p
  cd target/no-projects
  HOME=../
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile 
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "no cloned projects" {
  example no-clones 
  mkdir target/no-clones/branchout -p
  cd target/no-clones
  HOME=./
  mkdir branchout/no-clones
  echo 'BRANCHOUT_NAME="no-clones"' > Branchoutfile 
  example no-clones
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}
