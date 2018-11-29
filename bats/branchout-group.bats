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
  run branchout rabbit
  assert_success_file pull/rabbit-clone 
}

@test "group pull then update" {
  example branchout-a-group-then-update
  run branchout rabbit
  assert_success_file pull/rabbit-clone
  run branchout rabbit
  assert_success_file pull/rabbit-update
}

@test "group pull for non repository group then update" {
  example branchout-a-non-repository-group-then-update
  run branchout lion
  assert_success_file pull/lion-clone
  run branchout lion
  assert_success_file pull/lion-update
}

@test "group pull group from another group directory then update" {
  example branchout-a-group-not-from-basedir
  HOME=$(dirname ${PWD})
  run branchout lion
  assert_success_file pull/lion-clone
  cd lion
  run branchout rabbit
  assert_success_file pull/rabbit-clone
  run branchout rabbit
  assert_success_file pull/rabbit-update
}

@test "group pull of a non repository group not from basedir then update" {
  example branchout-a-non-repository-group-then-update-not-from-basedir
  HOME=$(dirname ${PWD})
  run branchout rabbit
  assert_success_file pull/rabbit-clone
  cd rabbit
  run branchout lion
  assert_success_file pull/lion-clone
  run branchout lion
  assert_success_file pull/lion-update
}

@test "group with prefix pull" {
  prefixExample branchout-a-prefix-group
  run branchout sheep
  assert_success_file_sort pull/sheep-clone 
}
