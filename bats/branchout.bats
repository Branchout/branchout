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
  mkdir -p projects/project-a projects/project-b
  HOME=/tmp
  run branchout status
  assert_error "Branchoutfile configuration not found in parent hierarchy, perhaps you need to be in a project directory /tmp/projects"
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
  git init . || true
  git remote add origin git@saas.tld:prefix.git || true
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

@test "branchout relocate - three layers to local dir" {
  example relocate-three-layers

  # Set up fake git repos with remotes and realistic clone URLs that match our own origin
  PREFIX='file://'
  OLD_BASE="${PREFIX}$(dirname $(pwd))/repositories"

  # Politics does not belong in code, but here we are:
  git config --global init.defaultBranch slave

  # Must have "base" dir/repo to make remote check work correctly
  mkdir base
  git init base > /dev/null
  git --git-dir=base/.git remote add origin "${OLD_BASE}/base" # Same as our repo, but not important

  # Disparate group to prove others work
  mkdir group
  git init group > /dev/null
  git --git-dir=group/.git remote add sample "${OLD_BASE}/group" # Example of a branchout group

  # Example project nested in a group
  mkdir group/project
  git init group/project > /dev/null
  git --git-dir=group/project/.git remote add upstream "${OLD_BASE}/group/project" # Example of a project within a branchout group

  # Do the relocation and verify it worked
  NEW_BASE="${PREFIX}$(pwd)"
  run branchout relocate "${NEW_BASE}"
  assert_success_only # Command must succeed, then check details

  # Validate the sanity check logic and human readable output. Note: dirs/URLs vary per test runner, so using partial matches
  assert_string_present "Relocating all Git repos from"
  assert_string_present "and all nested repos 1 and 2 levels deep."
  assert_string_present "This is the current Git URL for"
  assert_string_present "This is the new Git URL for"
  # This is important to not break your entire tree of repos:
  assert_string_present "Validating the Git repo pointed at by the new URL above works..."
  assert_string_present "New URL exists and you have access, proceeding..."
  # This has to match what we actually had on disk:
  assert_string_present "Found 2 group .git/config files to process"
  assert_string_present "Found 1 project .git/config files to process"
  assert_string_present "Processing a total of 4 .git/config files, including the base directory"
  assert_string_present "Relocation complete. To reverse what you just did, run 'branchout relocate"

  # Covers all three layers and case of remotes not called origin and case of nested project URLs
  assert_equal "$(git remote get-url origin)" "${NEW_BASE}/base"
  assert_equal "$(git --git-dir=base/.git remote get-url origin)" "${NEW_BASE}/base"
  assert_equal "$(git --git-dir=group/.git remote get-url sample)" "${NEW_BASE}/group"
  assert_equal "$(git --git-dir=group/project/.git remote get-url upstream)" "${NEW_BASE}/group/project"
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
  run branchout get NAME
  assert_success "init-getvalue"
}

@test "branchout getvalue in child folder" {
  example init-getvalue-childfolder
  mkdir childfolder
  cd childfolder
  # for the sake of the tests the HOME is relative, that way the messages can be deterministic, but that means if you shift directories you need to account for it
  HOME=../../
  run branchout get NAME
  assert_success "init-getvalue-childfolder"
}

@test "branchout setvalue" {
  example init-setvalue
  run branchout set VALUE Example
  assert_success
  run branchout get VALUE
  assert_success "Example"
}

@test "branchout ensurevalue set it" {
  example init-ensure-setit
  run branchout ensure VALUE <<< "Example"
  assert_success "Please provide VALUE: "
  run branchout get VALUE
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
  run branchout set VALUE Example
  assert_success
  run branchout ensure VALUE <<< ""
  assert_success ""
  run branchout get VALUE
  assert_success "Example"
}

@test "branchout - ensurevalue uses default" {
  example init-ensure-uses-default
  run branchout ensure VALUE "default" <<< ""
  assert_success "Please provide VALUE [default]: "
  run branchout get VALUE
  assert_success "default"
}

@test "branchout - ensure value when set overrides default" {
  example init-ensure-overrides-default
  run branchout ensure VALUE "default" <<< "notdefault"
  assert_success "Please provide VALUE [default]: "
  run branchout get VALUE
  assert_success "notdefault"
}

@test "branchout setvalue from child folder" {
  example init-setvalue-childfolder
  mkdir childfolder
  cd childfolder
  # for the sake of the tests the HOME is relative, that way the messages can be deterministic, but that means if you shift directories you need to account for it
  HOME=../../
  run branchout set VALUE Example
  assert_success
  run branchout get VALUE
  assert_success "Example"
}

@test "branchout setvalue twice" {
  example init-setvalue-twice
  run branchout set VALUE "SAMESAME"
  assert_success
  run branchout get VALUE
  assert_success "SAMESAME"
  run branchout set VALUE "SAMESAME2"
  assert_success
  run branchout get VALUE
  assert_success "SAMESAME2"
}

@test "branchout setvalue many values" {
  example init-setvalue-many
  run branchout set VALUE "SAMESAME"
  assert_success
  run branchout get VALUE
  assert_success "SAMESAME"
  run branchout set VALUE2 "SAMESAME2"
  assert_success
  run branchout get VALUE2
  assert_success "SAMESAME2"
  run branchout get VALUE
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

@test "branchout ensure config value - set it" {
  example init-ensure-config-setit
  run branchout ensure-config VALUE <<< "Example"
  assert_success "Please provide VALUE: "
  run branchout get-config VALUE
  assert_success "Example"
}

@test "branchout ensure config value - fails with nothing" {
  example init-ensure-config-fails-on-nothing
  run branchout ensure-config VALUE <<< ""
  assert_error "Please provide VALUE: 
Error: You must supply a value for VALUE"
}

@test "branchout ensure config value - does nothing if set" {
  example init-ensure-config-idempotent
  run branchout set-config VALUE Example
  assert_success
  run branchout ensure-config VALUE <<< ""
  assert_success ""
  run branchout get-config VALUE
  assert_success "Example"
}

@test "branchout - ensure config value uses default" {
  example init-ensure-config-uses-default
  run branchout ensure-config VALUE "default" <<< ""
  assert_success "Please provide VALUE [default]: "
  run branchout get-config VALUE
  assert_success "default"
}

@test "branchout - ensure config value when set overrides default" {
  example init-ensure-config-overrides-default
  run branchout ensure-config VALUE "default" <<< "notdefault"
  assert_success "Please provide VALUE [default]: "
  run branchout get-config VALUE
  assert_success "notdefault"
}
