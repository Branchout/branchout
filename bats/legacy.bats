load helper

@test "legacy branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir target/legacy/missing-name -p
  cd target/legacy/missing-name
  touch .branchout
  run branchout status
  assert_error "Branchout name not defined in .branchout, run branchout init" 
}

@test "legacy branchout configuration missing BRANCHOUT_GIT_BASEURL fails" {
  mkdir -p target/legacy/missing-giturl target/branchout/missing-giturl 
  cd target/legacy/missing-giturl
  echo 'BRANCHOUT_NAME="missing-giturl"' > .branchout 
  run branchout status
  assert_error "Git base url is not defined in .branchout, run branchout init" 
}

@test "legacy branchout home is missing fails" {
  mkdir target/legacy/missing-branchout-home -p
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
  legacyExample legacy-pull-all
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph-before-pull
  run branchout pull
  assert_success 
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph
}

@test "legacy branchout init from url" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/legacy
  assert_success "Cloning into 'legacy'..."
  cd target/projects/legacy
  run branchout status
  assert_success_file_sort init/from-url
}



