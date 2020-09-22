load helper

@test "branchout init - is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-init
  assert_success
}

@test "branchout init - from url" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/base
  assert_success "Branchout projection 'base' in ${BUILD_DIRECTORY}/projects/base"
  cd "${BUILD_DIRECTORY}/projects/base"
  run branchout status
  assert_success_file_sort init/from-url
}

@test "branchout init - from url.git" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git
  assert_success "Branchout projection 'ghbase' in ${BUILD_DIRECTORY}/projects/ghbase"
  cd "${BUILD_DIRECTORY}/projects/ghbase"
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

@test "branchout init - from url.git with local name" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git localname
  assert_success "Branchout projection 'ghbase' in ${BUILD_DIRECTORY}/projects/localname"
  cd "${BUILD_DIRECTORY}/projects/localname"
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

@test "branchout init - not in git repository, require name to init" {
  mkdir -p target/tests/init-notgit-needname
  cd target/tests/init-notgit-needname
  HOME=${BUILD_DIRECTORY}
  run branchout init <<< ''
  assert_failure "Enter branchout name [init-ingit]: 
Error: You must provide a branchout name"
 }

@test "branchout init - init git as needed" {
  mkdir -p target/tests/init-notgit
  cd target/tests/init-notgit
  HOME=${BUILD_DIRECTORY}
  run branchout init <<< 'init'
  assert_success "Branchout projection 'init' in ${BUILD_DIRECTORY}/projects/init"
  run branchout status
  assert_success ""
 }

function inEmptyRepository() {
  git clone file://${BUILD_DIRECTORY}/repositories/empty "${BUILD_DIRECTORY}/projects/${1}"
  cd "${BUILD_DIRECTORY}/projects/${1}" || exit 77
  HOME=${BUILD_DIRECTORY}
}

@test "branchout init - in git repository, no branchout requires name" {
  inEmptyRepository "init-in-git-require-name"
  run branchout init <<< ''
  assert_failure "Enter branchout name [init-ingit]: "
}

@test "branchout init - in git repository, interactive" {
  inEmptyRepository "init-interactive"
  run branchout init <<< "brname"
  assert_success ""
  run branchout status
  assert_error "No projects to show, try branchout clone <project-name>"
}

@test "branchout init - in git repository, add projects" {
  inEmptyRepository "init-git-suggestion"
  run branchout init <<< "brname"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
}

@test "branchout init - in git repository, clone projects" {
  inEmptyRepository "init-git-suggestion"
  run branchout init <<< "brname"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout clone frog-aleph
  assert_success_file status/clone
}

function inBaseRepository() {
  HOME=${BUILD_DIRECTORY}
  run branchout init "file://${BUILD_DIRECTORY}/repositories/base" "${1}"
  assert_success "Branchout projection 'base' in ${BUILD_DIRECTORY}/projects/${1}"
  cd "${BUILD_DIRECTORY}/projects/${1}" || exit 77
}

@test "branchout init - from url, then clone projects" {
  inBaseRepository clone

  run branchout status
  assert_success_file_sort init/from-url
  run branchout clone toad-aleph
  assert_success_file clone/clone-one
}

@test "branchout init - from url then clone projects with group folder" {
  inBaseRepository clone-folder

  run branchout status
  assert_success_file_sort init/from-url

  mkdir toad
  run branchout clone toad-aleph
  assert_success_file status/clone-one-with-group-folder
}

@test "branchout init - from url with flat structure" {
  inBaseRepository frog

  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}

@test "branchout init - with relocated projects folder" {
  HOME=${BUILD_DIRECTORY}/relocated
  mkdir -p "${BUILD_DIRECTORY}/relocated/.config"
  echo "BRANCHOUT_PROJECTS_DIRECTORY=notprojects" > "${BUILD_DIRECTORY}/relocated/.config/branchoutrc"

  run branchout init file://${BUILD_DIRECTORY}/repositories/frog
  assert_success "Branchout projection 'base' in ${BUILD_DIRECTORY}/relocated/${1}"

  cd "${BUILD_DIRECTORY}/relocated/notprojects/frog"
  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}

@test "branchout init - local then add projects" {
  mkdir -p target/tests/add
  cd target/tests/add
  HOME=${BUILD_DIRECTORY}
  run branchout-init <<< "brname"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
  run branchout status frog-aleph
  assert_success_file status/no-clone
  run branchout add frog-beta
  assert_success_file_sort status/two-no-clone
}

@test "branchout init - only sets url and name" {
  mkdir -p target/tests/init-branchoutfile
  cd target/tests/init-branchoutfile
  HOME=${BUILD_DIRECTORY}
  run branchout-init <<< "brname"
  assert_success ""
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  assert_equal "BRANCHOUT_NAME=brname" "$(cat Branchoutfile)"
}