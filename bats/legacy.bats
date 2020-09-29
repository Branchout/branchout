load helper

@test "legacy branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir -p target/legacy/missing-name 
  cd target/legacy/missing-name
  touch .branchout
  run branchout status
  assert_error "Branchout name not defined in .branchout, run branchout init" 
}

@test "legacy branchout home is missing fails" {
  mkdir -p target/legacy/missing-branchout-home 
  HOME=${BUILD_DIRECTORY}
  cd target/legacy/missing-branchout-home
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > .branchout 
  echo 'BRANCHOUT_GIT_BASEURL="missing-branchout-home"' >> .branchout 
  run branchout status
  assert_error "Branchout home '${BUILD_DIRECTORY}/branchout/missing-branchout-home' does not exist, run branchout init" 
}

@test "legacy missing projects prompts" {
  mkdir -p target/legacy/no-projects target/branchout/legacy-no-projects 
  cd target/legacy/no-projects
  HOME=${BUILD_DIRECTORY}
  echo 'BRANCHOUT_NAME="legacy-no-projects"' > .branchout 
  echo 'BRANCHOUT_GIT_BASEURL="no-projects"' >> .branchout 
  run branchout status
  assert_error ".projects file missing, try branchout add [repository]"
}

@test "legacy project prefix is removed" {
  mkdir -p target/legacy/prefix target/branchout/legacy-prefix 
  cd target/legacy/prefix
  HOME=${BUILD_DIRECTORY}
  echo 'BRANCHOUT_NAME="legacy-prefix"' > .branchout 
  echo 'BRANCHOUT_GIT_BASEURL="prefix"' >> .branchout 
  echo 'BRANCHOUT_PREFIX="prefix"' >> .branchout 
  echo 'prefix-frog-aleph' > .projects
  run branchout status
  assert_success_file status/no-clone-prefix
}

@test "legacy can pull all" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/legacy "legacy-pull-all" <<< "legacy-pull-all@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/legacy' into ${BUILD_DIRECTORY}/projects/legacy-pull-all
Branchout state will be stored in /home/michael/projects/branchout-project/branchout/branchout/target/branchout/legacy
Please provide your git author email: 
Set the git author to legacy-pull-all@example.com"

  cd target/projects/legacy-pull-all
  run branchout status
  assert_success_file_sort init/from-url
  
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph-before-pull
  run branchout pull
  assert_success 
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph
}

@test "legacy branchout init from url" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/legacy <<< ""
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/legacy' into ${BUILD_DIRECTORY}/projects/legacy
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/legacy
Set the git author to legacy-pull-all@example.com"

  cd target/projects/legacy
  run branchout status
  assert_success_file_sort init/from-url
}



