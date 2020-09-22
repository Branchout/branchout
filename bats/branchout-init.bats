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
  run branchout init file://${BUILD_DIRECTORY}/repositories/ghbase.git <<< "stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/ghbase.git' into ${BUILD_DIRECTORY}/projects/ghbase
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/ghbase
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
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/ghbase.git' into ${BUILD_DIRECTORY}/projects/localname
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/ghbase
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

@test "branchout init - new projection needs a url" {
  inEmptyDirectory "prompt-for-projection-url"
  run branchout init <<< ''
  assert_failure "Please provide projection url: 
Error: You must supply a value for projection url"
}

@test "branchout init - new projection defaults branchout name to project name" {
  inEmptyDirectory "projection-name-is-default-branchout-name"
  run branchout init <<< 'https://github.com/Branchout/example


stickycode@example.com'
  assert_success "Please provide projection url: 
Please provide local project name [example]: 
Branchout projection for 'https://github.com/Branchout/example' created in ${BUILD_DIRECTORY}/projects/example
Please provide branchout name [example]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/example
Please provide your git author email: 
Set the git author to stickycode@example.com"
}

@test "branchout init - new projection errors if name is already used" {
  inEmptyDirectory "init-already-exists"
  run branchout init <<< 'https://github.com/Branchout/already-exists


stickycode@example.com'
  assert_success "Please provide projection url: 
Please provide local project name [already-exists]: 
Branchout projection for 'https://github.com/Branchout/already-exists' created in ${BUILD_DIRECTORY}/projects/already-exists
Please provide branchout name [already-exists]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/already-exists
Please provide your git author email: 
Set the git author to stickycode@example.com"
  run branchout init <<< 'https://github.com/Branchout/already-exists'
  assert_failure "Please provide projection url: 
Please provide local project name [already-exists]: 
Branchout projection already exists at ${BUILD_DIRECTORY}/projects/already-exists

branchout-init [git-url] [relocation]

  To branchout from GitHub and use the repository name for the projection

    branchout init https://github.com/branchout/branchout-project

  To branchout from GitHub and use a different name for the projection

    branchout init https://github.com/branchout/branchout-project branchout

  To interactively initialise a projection locally

    branchout init"
}

@test "branchout init - new projection requires git url to setup git" {
  inEmptyProject init-new-requires-url
  run branchout init <<< ''
  assert_failure "Branchout projection created in ${BUILD_DIRECTORY}/projects/init-new-requires-url
Please provide projection url: 
Error: You must supply a value for projection url"
}

@test "branchout init - new projection url git url to setup git" {
  inEmptyProject init-new-projection
  run branchout init <<< 'https://github.com/Branchout/new-projection

stickycode@example.com'
  assert_success "Branchout projection created in ${BUILD_DIRECTORY}/projects/init-new-projection
Please provide projection url: 
Please provide branchout name [new-projection]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/new-projection
Please provide your git author email: 
Set the git author to stickycode@example.com"
  run git remote get-url origin
  assert_success "https://github.com/Branchout/new-projection"
}

function inEmptyRepository() {
  test -d "${BUILD_DIRECTORY}/projects/${1}" && bail "project ${BUILD_DIRECTORY}/projects/${1} already exists"
  git clone "file://${BUILD_DIRECTORY}/repositories/empty" "${BUILD_DIRECTORY}/projects/${1}"
  cd "${BUILD_DIRECTORY}/projects/${1}" || exit 77
  HOME=${BUILD_DIRECTORY}
}

@test "branchout init - in git repository, no branchout requires name uses default" {
  inEmptyRepository "init-in-git-require-name-uses-default"
  run branchout init <<< ''
  assert_success "Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/empty
Set the git author to stickycode@example.com"
}

@test "branchout init - in git repository, no branchout requires name" {
  inEmptyRepository "init-in-git-require-name"
  run branchout init <<< 'init-in-git-require-name
stickycode@example.com'
  assert_success "Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-in-git-require-name
Please provide your git author email: 
Set the git author to stickycode@example.com"
}

@test "branchout init - in git repository, interactive" {
  inEmptyRepository "init-in-git-interactive"
  run branchout init <<< "init-in-git-interactive
stickycode@example.com"
  assert_success "Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-in-git-interactive
Please provide your git author email: 
Set the git author to stickycode@example.com"
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
}

@test "branchout init - in git repository, add projects" {
  inEmptyRepository "init-in-git-add-project"
  run branchout init <<< "
stickycode@example.com"
  assert_success "Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/empty
Set the git author to stickycode@example.com"
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout add frog-aleph
  assert_success_file status/no-clone
}

@test "branchout init - in git repository, clone projects" {
  inEmptyRepository "init-in-git-clone-projects"
  run branchout init <<< "init-in-git-clone-projects
stickycode@example.com"
  assert_success "Please provide branchout name [empty]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-in-git-clone-projects
Please provide your git author email: 
Set the git author to stickycode@example.com"
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  run branchout clone toad-aleph
  assert_success_file clone/clone-one
}

function inBaseRepository() {
  test -d "${BUILD_DIRECTORY}/projects/${1}" && bail "project ${BUILD_DIRECTORY}/projects/${1} already exists"
  HOME=${BUILD_DIRECTORY}
  run branchout init "file://${BUILD_DIRECTORY}/repositories/projects" "${1}" <<< "${1}
stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/projects' into ${BUILD_DIRECTORY}/projects/${1}
Please provide branchout name [projects]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/${1}
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd "${BUILD_DIRECTORY}/projects/${1}" || exit 77
}

@test "branchout init - from url, then clone projects" {
  inBaseRepository init-from-url-clone

  run branchout status
  assert_success_file_sort init/from-url
  run branchout clone toad-aleph
  assert_success_file clone/clone-one
}

@test "branchout init - from url then clone projects with group folder" {
  inBaseRepository init-from-url-clone-folder

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

  run branchout init file://${BUILD_DIRECTORY}/repositories/frog <<< "stickycode@example.com"
  assert_success "Branchout projected 'file://${BUILD_DIRECTORY}/repositories/frog' into ${BUILD_DIRECTORY}/relocated/notprojects/frog
Branchout state will be stored in ${BUILD_DIRECTORY}/relocated/branchout/frog
Please provide your git author email: 
Set the git author to stickycode@example.com"

  cd "${BUILD_DIRECTORY}/relocated/notprojects/frog"
  run branchout pull frog
  assert_success_file_sort init/from-url-with-flat-structure
}

@test "branchout init - local then add projects" {
  HOME=${BUILD_DIRECTORY}
  run branchout-init <<< "file://${BUILD_DIRECTORY}/repositories/frog
init-local-then-add
init-local-then-add
stickycode@example.com"
  assert_success "Please provide projection url: 
Please provide local project name [frog]: 
Branchout projection for 'file://${BUILD_DIRECTORY}/repositories/frog' created in ${BUILD_DIRECTORY}/projects/init-local-then-add
Please provide branchout name [frog]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-local-then-add
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd target/projects/init-local-then-add
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
  assert_success "Please provide projection url: 
Please provide local project name [init-branchoutfile]: 
Branchout projection for 'init-branchoutfile' created in ${BUILD_DIRECTORY}/projects/init-branchoutfile
Please provide branchout name [init-branchoutfile]: 
Branchout state will be stored in ${BUILD_DIRECTORY}/branchout/init-branchoutfile
Please provide your git author email: 
Set the git author to stickycode@example.com"
  cd "${BUILD_DIRECTORY}/projects/init-branchoutfile"
  run branchout status
  assert_error "No projects to show, try branchout add <project-name>"
  assert_equal "BRANCHOUT_NAME=\"init-branchoutfile\"" "$(cat Branchoutfile)"
}