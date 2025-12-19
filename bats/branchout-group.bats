load helper

@test "branchout group is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-group
  assert_success
}

@test "group works for single letter" {
  example group-is-a-single-letter
  run branchout group derive a-b-c
  assert_success "a"
}

@test "group is a word" {
  example group-is-a-word
  
  run branchout group derive some-artifact
  assert_success "some"
}

@test "group with plugin is plugin" {
  example plugin-is-plugin
  
  run branchout group derive wait-maven-plugin
  assert_success "plugins"
}

@test "group is just one word" {
  example group-is-project
  run branchout group derive artifact
  assert_success "artifact"
}

@test "group has a prefix to drop" {
  example group-prefix
  export BRANCHOUT_PREFIX=prefix
  run branchout group derive prefix-some-artifact
  assert_success "some"
}

@test "group list" {
  example branchout-group-list
  run branchout group list
  assert_success "fox
frog
lion
rabbit
snake
toad"
}

@test "group prefix list" {
  prefixExample group-prefix-list
  run branchout group list
  assert_success "fox
sheep
toad"
}

@test "group list filtering" {
  example branchout-group-filter
  run branchout group list frog
  assert_success "frog"
}

@test "group prefix list filtering" {
  prefixExample group-prefix-filter
  run branchout group list sheep
  assert_success "sheep"
}

@test "group pull" {
  example branchout-a-group
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone 
}

@test "group project pull where plain directory exists" {
  example branchout-a-group-that-exists
  mkdir lion
  run branchout pull lion
  assert_success_file pull/lion-already-exists
}

@test "group pull where plain directory exists" {
  example branchout-group-that-exists
  mkdir lion
  run branchout group pull lion
  assert_success_file pull/lion-is-not-a-repository
}

@test "group pull then update" {
  example branchout-a-group-then-update
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone
  run branchout pull rabbit
  assert_success_file pull/rabbit-update
}

@test "group pull for non repository group then update" {
  example branchout-a-non-repository-group-then-update
  run branchout pull lion
  assert_success_file pull/lion-clone
  run branchout pull lion
  assert_success_file pull/lion-update
}

@test "group pull group from another group directory then update" {
  example branchout-a-group-not-from-basedir
  HOME=$(dirname ${PWD})
  run branchout pull lion
  assert_success_file pull/lion-clone
  cd lion
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone
  run branchout pull rabbit
  assert_success_file pull/rabbit-update
}

@test "group pull of a non repository group not from basedir then update" {
  example branchout-a-non-repository-group-then-update-not-from-basedir
  HOME=$(dirname ${PWD})
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone
  cd rabbit
  run branchout pull lion
  assert_success_file pull/lion-clone
  run branchout pull lion
  assert_success_file pull/lion-update
}

@test "group with prefix pull" {
  prefixExample branchout-a-prefix-group
  run branchout pull sheep
  assert_success_file_sort pull/sheep-clone
}

@test "group pull with BRANCHOUT_GROUPS_ARE_DIRS creates plain directory" {
  example branchout-groups-are-dirs
  echo 'BRANCHOUT_GROUPS_ARE_DIRS="true"' >> Branchoutfile
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone-plain-dir
  # Verify it's a plain directory, not a git repo
  [ ! -d rabbit/.git ]
}

@test "group update with BRANCHOUT_GROUPS_ARE_DIRS shows directory only" {
  example branchout-groups-are-dirs-update
  echo 'BRANCHOUT_GROUPS_ARE_DIRS="true"' >> Branchoutfile
  run branchout pull rabbit
  assert_success_file pull/rabbit-clone-plain-dir
  run branchout pull rabbit
  assert_success_file pull/rabbit-update-plain-dir
}

@test "BRANCHOUT_GROUPS_ARE_DIRS creates group dir even when BRANCHOUT_NAME matches group" {
  # Setup: BRANCHOUT_NAME=snake, which matches the group derived from snake-aleph
  test -d "target/branchout-name-matches-group" && bail "example already exists"
  mkdir -p "target/branchout-name-matches-group" "target/branchout/snake"
  echo 'BRANCHOUT_CONFIG_GIT_EMAIL="test@example.com"' > "target/branchout/snake/branchoutrc"
  cd "target/branchout-name-matches-group" || bail "Failed to enter target dir"
  git init 2>/dev/null 1>&2
  git remote add origin file://${BUILD_DIRECTORY}/repositories/base 2>/dev/null 1>&2
  export HOME=..
  echo 'BRANCHOUT_NAME="snake"' > Branchoutfile
  echo 'BRANCHOUT_GROUPS_ARE_DIRS="true"' >> Branchoutfile
  echo "snake-aleph" > Branchoutprojects

  run branchout pull snake
  assert_success_file pull/snake-clone-matching-name

  # Verify the directory structure: snake/snake-aleph should exist, not just snake-aleph
  [ -d snake/snake-aleph ]
  [ ! -d snake-aleph ] || bail "snake-aleph should be in snake/ subdirectory, not base"
}
