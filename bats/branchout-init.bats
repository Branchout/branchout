load helper

@test "branchout init - is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-init
  assert_success
}

@test "branchout init - from url, no email errors" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/base base-noemail <<< ""
  assert_failure "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/base' into ${BUILD_DIRECTORY}/projects/base-noemail
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/base
Please provide your git author email: 
Error: You must supply a value for your git author email"
}

@test "branchout init - from url using supplied branchout and supplied author email" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/empty rename-projection <<< "alternate-branchout-name
stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/empty' into ${BUILD_DIRECTORY}/projects/rename-projection
Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/alternate-branchout-name
Please provide your git author email: 
Set the git author to stickycode@example.com"
}

@test "branchout init - from url using default branchout and supplied author email" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/empty <<< "
stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/empty' into ${BUILD_DIRECTORY}/projects/empty
Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/empty
Please provide your git author email: 
Set the git author to stickycode@example.com"
}

@test "branchout init - from url using supplied branchout and existing author email" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/empty reuse-branchout <<< "reuse-branchout
stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/empty' into ${BUILD_DIRECTORY}/projects/reuse-branchout
Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/reuse-branchout
Please provide your git author email: 
Set the git author to stickycode@example.com"

  run branchout init file://${BUILD_DIRECTORY}/repositories/empty reuse-state <<< "reuse-branchout
stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/empty' into ${BUILD_DIRECTORY}/projects/reuse-state
Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/reuse-branchout
Set the git author to stickycode@example.com"
}

@test "branchout init - from url.git" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git <<< "
stickycode@example.com"
  assert_success "Branchout projected 'ghbase' into ${BUILD_DIRECTORY}/projects/ghbase
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd "${BUILD_DIRECTORY}/projects/ghbase"
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

@test "branchout init - from url.git with local rename" {
  HOME=${BUILD_DIRECTORY}
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git localname <<< "stickycode@example.com"
  assert_success "Branchout projected 'ghbase' into ${BUILD_DIRECTORY}/projects/localname
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd "${BUILD_DIRECTORY}/projects/localname"
  run branchout status
  assert_success_file_sort init/from-url
  run branchout add toad-gemel
  assert_success_file_sort init/with-toad
}

inEmptyDirectory() {
  mkdir -p "${BUILD_DIRECTORY}/tests/${1}"
  cd "${BUILD_DIRECTORY}/tests/${1}" || exit 77
  HOME=${BUILD_DIRECTORY}
}

inEmptyProject() {
  mkdir -p "${BUILD_DIRECTORY}/projects/${1}"
  cd "${BUILD_DIRECTORY}/projects/${1}" || exit 77
  HOME=${BUILD_DIRECTORY}
}

@test "branchout init - new projection needs a name" {
  inEmptyDirectory "prompt-for-projection-name"
  run branchout init <<< ''
  assert_failure "Enter new projection name: 
Error: You must provide a new projection name"
 }

@test "branchout init - new projection defaults branchout name to projection name" {
  inEmptyDirectory "projection-name-is-default-branchout-name"
  run branchout init <<< 'init'
  assert_success "Enter new projection name: 
Branchout projection 'init' created in ${BUILD_DIRECTORY}/projects/init
Enter branchout name [init]: 
Branchout state 'init' will be stored in ${BUILD_DIRECTORY}/branchout/init"
 }

@test "branchout init - new projection is current directory if its a project" {
  inEmptyDirectory new-projection
  run branchout init <<< ''
  assert_failure "Enter branchout name [new-projection]: 
Branchout state 'new-projection' will be stored in ${BUILD_DIRECTORY}/branchout/new-projection"
 }

 @test "branchout init - new projection errors if name is already used" {
  inEmptyDirectory "init-already-exists"
  run branchout init <<< 'already-exists'
  assert_success "Branchout projection 'already-exists' created in ${BUILD_DIRECTORY}/projects/already-exists"
  run branchout init <<< 'already-exists'
  assert_error "Branchout projection 'already-exists' already exists in ${BUILD_DIRECTORY}/projects/already-exists"
 }

function inEmptyRepository() {
  git clone "file://${BUILD_DIRECTORY}/repositories/empty" "${BUILD_DIRECTORY}/projects/${1}"
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
  run branchout init <<< "stickycode@example.com
brname"
  assert_success ""
  run branchout status
  assert_error "No projects to show, try branchout clone <project-name>"
}

@test "branchout init - in git repository, add projects" {
  inEmptyRepository "init-git-suggestion"
  run branchout init <<< "stickycode@example.com
brname"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
}

@test "branchout init - in git repository, clone projects" {
  inEmptyRepository "init-git-suggestion"
  run branchout init <<< "stickycode@example.com
brname"
  assert_success
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout clone frog-aleph
  assert_success_file status/clone
}

function inBaseRepository() {
  HOME=${BUILD_DIRECTORY}
  run branchout init "file://${BUILD_DIRECTORY}/repositories/base" "${1}" <<< "
stickycode@example.com"
  assert_success "Branchout projected 'base' into ${BUILD_DIRECTORY}/projects/${1}"
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

  run branchout init file://${BUILD_DIRECTORY}/repositories/frog <<< "
stickycode@example.com"
  assert_success "Branchout projected 'base' into ${BUILD_DIRECTORY}/relocated/${1}"

  cd "${BUILD_DIRECTORY}/relocated/notprojects/frog"
  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}

@test "branchout init - local then add projects" {
  mkdir -p target/tests/add
  cd target/tests/add
  HOME=${BUILD_DIRECTORY}
  run branchout-init <<< "
stickycode@example.com"
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
  HOME=${BUILD_DIRECTORY}
  run branchout-init <<< "init-branchoutfile

stickycode@example.com"
  assert_success "Please provide projection name: 
Branchout projection 'init-branchoutfile' created in ${BUILD_DIRECTORY}/projects/init-branchoutfile
Please provide branchout name [init-branchoutfile]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-branchoutfile
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd target/projects/init-branchoutfile
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  assert_equal "BRANCHOUT_NAME=brname" "$(cat Branchoutfile)"
}