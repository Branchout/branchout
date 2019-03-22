load helper

@test "branchout init is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-init
  assert_success
}

@test "branchout init from url" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/base
  assert_success "Cloning into 'base'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"
  cd target/projects/base
  run branchout status
  assert_success_file_sort init/from-url
}

@test "branchout init from url.git" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git
  assert_success "Cloning into 'ghbase'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"
  cd target/projects/ghbase
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

@test "branchout init from url.git with local name" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git localname
  assert_success "Cloning into 'localname'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"
  cd target/projects/localname
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

@test "branchout init not in git repository" {
  mkdir -p target/tests/init-notgit
  cd target/tests/init-notgit
  HOME=${BUILD_DIRECTORY}
  run branchout init <<< 'init'
  assert_error "${BUILD_DIRECTORY}/tests/init-notgit is not a git repository, try git init first"
}

@test "branchout init in git repository, no branchout" {
  mkdir -p target/tests/init-ingit
  cd target/tests/init-ingit
  HOME=${BUILD_DIRECTORY}
  git init
  run branchout init <<< ''
  assert_error "Enter branchout name [init-ingit]: "
}

@test "branchout init in git repository, interactive" {
  mkdir -p target/tests/init-interactive
  cd target/tests/init-interactive
  HOME=${BUILD_DIRECTORY}
  git init
  run branchout init <<< "brname
gitty"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
}

@test "branchout init in git repository, add projects" {
  mkdir -p target/tests/init-git 
  cd target/tests/init-git
  HOME=${BUILD_DIRECTORY}
  git init
  run branchout init <<< "brname
gitty"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
}

@test "branchout init from url then clone projects" {
  HOME=${BUILD_DIRECTORY}
  
  run branchout init file://${BUILD_DIRECTORY}/repositories/base clone
  assert_success "Cloning into 'clone'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"

  cd target/projects/clone
  run branchout status
  assert_success_file_sort init/from-url
  run branchout clone toad-aleph
  assert_success_file clone/clone-one
}

@test "branchout init from url then clone projects with group folder" {
  HOME=${BUILD_DIRECTORY}
  
  run branchout init file://${BUILD_DIRECTORY}/repositories/base clone-folder
  assert_success "Cloning into 'clone-folder'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"

  cd target/projects/clone-folder
  run branchout status
  assert_success_file_sort init/from-url
  mkdir toad
  run branchout clone toad-aleph
  assert_success_file status/clone-one-with-group-folder
}

@test "branchout init from url with flat structure" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/frog
  assert_success "Cloning into 'frog'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"
  cd target/projects/frog
  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}

@test "branchout init with relocated projects folder" {
  HOME=${BUILD_DIRECTORY}/relocated
  mkdir -p ${BUILD_DIRECTORY}/relocated/.config
  echo "BRANCHOUT_PROJECTS_DIRECTORY=notprojects" > ${BUILD_DIRECTORY}/relocated/.config/branchoutrc
  run branchout init file://${BUILD_DIRECTORY}/repositories/frog
  assert_success "Cloning into 'frog'...
BRANCHOUT_GIT_BASEURL=file://${BUILD_DIRECTORY}/repositories"
  cd target/relocated/notprojects/frog
  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}
