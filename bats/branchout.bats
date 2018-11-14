load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout
  assert_success
}


@test "invoke version" {
  run branchout version
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

@test "branchout can pull all" {
  example pull-all
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph-before-pull
  run branchout pull
  assert_success 
  run branchout project status frog-aleph
  assert_success_file all/frog-aleph
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

@test "branchout add" {
  mkdir -p target/tests/add
  cd target/tests/add
  HOME=${BUILD_DIRECTORY}
  git init
  run branchout init <<< "brname
gitty"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
  run branchout status
  assert_success_file status/no-clone
  run branchout add frog-beta
  assert_success_file_sort status/two-no-clone
}

