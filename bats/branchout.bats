load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout
  assert_success
}


@test "invoke version" {
  run branchout version
  assert_success "branchout-1.3"
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
  mkdir -p target/missing-giturl target/branchout/missing-giturl 
  cd target/missing-giturl
  echo 'BRANCHOUT_NAME="missing-giturl"' > Branchoutfile 
  run branchout status
  assert_error "Git base url is not defined in Branchoutfile, run branchout init" 
}

@test "branchout home is missing fails" {
  mkdir target/missing-branchout-home -p
  HOME=..
  cd target/missing-branchout-home
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="missing-branchout-home"' >> Branchoutfile 
  run branchout status
  assert_error "Branchout home '../branchout/missing-branchout-home' does not exist, run branchout init" 
}

@test "missing projects prompts" {
  mkdir -p target/no-projects target/branchout/no-projects 
  cd target/no-projects
  HOME=..
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="no-projects"' >> Branchoutfile 
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "project prefix is removed" {
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

@test "can pull all" {
  example pull-all
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph-before-pull
  run branchout pull
  assert_success 
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph
}

@test "branchout init from url" {
  HOME=./target
  run branchout init file://${BUILD_DIRECTORY}/repositories/base
  assert_success "Cloning into 'base'..."
  cd target/projects/base
  run branchout status
  assert_success_file_sort init/from-url
}

@test "branchout init" {
  mkdir -p target/init target/branchout/init 
  cd target/init
  HOME=..
  run branchout init <<< 'init'
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
}

@test "branchout add" {
  mkdir -p target/add target/branchout/add
  cd target/add
  HOME=..
  run branchout init <<< 'init'
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
  run branchout status
  assert_success_file status/no-clone
  run branchout add frog-beta
  assert_success_file status/two-no-clone
}

