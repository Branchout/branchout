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
  assert_error "Branchoutfile configuration not found in parent hierarchy, perhaps you need to be in a project directory /home/michael/projects"
}

@test "branchout configuration missing BRANCHOUT_NAME fails" {
  mkdir -p target/missing-name
  cd target/missing-name
  touch Branchoutfile
  run branchout status
  assert_error "Branchout name not defined in Branchoutfile, run branchout init"
}

@test "branchout home is missing fails" {
  mkdir -p target/missing-branchout-home
  HOME=..
  cd target/missing-branchout-home
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile
  run branchout status
  assert_error "Branchout home '../branchout/missing-branchout-home' does not exist, run branchout init"
}

@test "branchout missing projects prompts" {
  mkdir -p target/no-projects target/branchout/no-projects
  cd target/no-projects
  HOME=..
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "branchout prefix is removed" {
  mkdir -p target/prefix target/branchout/prefix
  cd target/prefix
  HOME=..
  echo 'BRANCHOUT_NAME="prefix"' > Branchoutfile
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

@test "branchout add no params should error" {
  example add-no-parameters
  run branchout add
  assert_error "Specify the repository to add, try branchout add <project-name>"
}

@test "branchout clone" {
  example clone
  run branchout status rabbit-aleph
  assert_success_file all/rabbit-aleph-before-pull
  run branchout clone toad-aleph
  assert_success_file clone/clone-one
  run branchout status toad-aleph
  assert_success_file status/clone-one
  run branchout clone frog-aleph
  assert_success_file_sort clone/clone-two
}

@test "branchout clone no params should error" {
  example clone-no-parameters
  run branchout clone
  assert_error "Specify the repository to clone, try branchout clone <project-name>"
}

@test "branchout clone a bare repository" {
  example clone-bare-repository
  run branchout clone bear-aleph
  assert_success_file clone/empty-repository
}

@test "branchout getvalue" {
  example init-getvalue
  run branchout get BRANCHOUT_GIT_BASEURL
  assert_success "file://${BUILD_DIRECTORY}/repositories"
}

@test "branchout getvalue in child folder" {
  example init-getvalue-childfolder
  mkdir childfolder
  cd childfolder
  # for the sake of the tests the HOME is relative, that way the messages can be deterministic, but that means if you shift directories you need to account for it
  HOME=../../
  run branchout get BRANCHOUT_GIT_BASEURL
  assert_success "file://${BUILD_DIRECTORY}/repositories"
}

@test "branchout setvalue" {
  example init-setvalue
  run branchout set BRANCHOUT_VALUE Example
  assert_success
  run branchout get BRANCHOUT_VALUE
  assert_success "Example"
}

@test "branchout ensurevalue set it" {
  example init-ensure-setit
  run branchout ensure VALUE <<< "Example"
  assert_success "Please provide VALUE: "
  run branchout get BRANCHOUT_VALUE
  assert_success "Example"
}

@test "branchout ensurevalue fails with nothing" {
  example init-ensure-fails-on-nothing
  run branchout ensure VALUE <<< ""
  assert_error "Please provide VALUE: 
Error: You must supply a value for VALUE"
}

@test "branchout ensurevalue does nothing if set" {
  example init-ensure-idempotent
  run branchout set BRANCHOUT_VALUE Example
  assert_success
  run branchout ensure VALUE <<< ""
  assert_success ""
  run branchout get BRANCHOUT_VALUE
  assert_success "Example"
}

@test "branchout setvalue from child folder" {
  example init-setvalue-childfolder
  mkdir childfolder
  cd childfolder
  # for the sake of the tests the HOME is relative, that way the messages can be deterministic, but that means if you shift directories you need to account for it
  HOME=../../
  run branchout set BRANCHOUT_VALUE Example
  assert_success
  run branchout get BRANCHOUT_VALUE
  assert_success "Example"
}

@test "branchout setvalue twice" {
  example init-setvalue-twice
  run branchout set BRANCHOUT_VALUE "SAMESAME"
  assert_success
  run branchout get BRANCHOUT_VALUE
  assert_success "SAMESAME"
  run branchout set BRANCHOUT_VALUE "SAMESAME2"
  assert_success
  run branchout get BRANCHOUT_VALUE
  assert_success "SAMESAME2"
}

@test "branchout setvalue many values" {
  example init-setvalue-many
  run branchout set BRANCHOUT_VALUE "SAMESAME"
  assert_success
  run branchout get BRANCHOUT_VALUE
  assert_success "SAMESAME"
  run branchout set BRANCHOUT_VALUE2 "SAMESAME2"
  assert_success
  run branchout get BRANCHOUT_VALUE2
  assert_success "SAMESAME2"
  run branchout get BRANCHOUT_VALUE
  assert_success "SAMESAME"
}

@test "branchout get config nothing is nothing" {
  example init-get-config
  run branchout get-config EMAIL
  assert_success ""
}

@test "branchout set config" {
  example init-set-config
  run branchout set-config EMAIL "john@example.com"
  assert_success
  run branchout get-config EMAIL
  assert_success "john@example.com"
}

@test "branchout set config to nothing fails" {
  example init-set-config-to-nothing
  run branchout set-config EMAIL ""
  assert_error "You must supply a value to set"
}

@test "branchout set config twice" {
  example init-set-config-twice
  run branchout set-config VALUE "SAMESAME"
  assert_success
  run branchout get-config VALUE
  assert_success "SAMESAME"
  run branchout set-config VALUE "SAMESAME2"
  assert_success
  run branchout get-config VALUE
  assert_success "SAMESAME2"
}

@test "branchout set config many values" {
  example init-set-config-many
  run branchout set-config VALUE "SAMESAME"
  assert_success
  run branchout get-config VALUE
  assert_success "SAMESAME"
  run branchout set-config VALUE2 "SAMESAME2"
  assert_success
  run branchout get-config VALUE2
  assert_success "SAMESAME2"
  run branchout get-config VALUE
  assert_success "SAMESAME"
}
