load helper

@test "branchout group works for single letter" {
  example group-is-a-single-letter
  run branchout group derive a-b-c
  assert_success "a"
}

@test "branchout group is a word" {
  example group-is-a-word
  
  run branchout group derive some-artifact
  assert_success "some"
}

@test "branchout group with plugin is plugin" {
  example plugin-is-plugin
  
  run branchout group derive wait-maven-plugin
  assert_success "plugins"
}

@test "branchout group is just one word" {
  example group-is-project
  run branchout group derive artifact
  assert_success "artifact"
}

@test "branchout group has a prefix to drop" {
  example group-prefix
  export BRANCHOUT_PREFIX=prefix
  run branchout group derive prefix-some-artifact
  assert_success "some"
}

@test "branchout group list" {
  example branchout-group-list
  run branchout group list
  assert_success "fox
frog
lion
rabbit
snake
toad"
}

@test "branchout group list filtering" {
  example branchout-group-filter
  run branchout group list frog
  assert_success "frog"
}

@test "branchout a group" {
  example branchout-a-group
  run branchout rabbit
  assert_success_file pull/rabbit-clone 
}

@test "branchout a group then update" {
  example branchout-a-group-then-update
  run branchout rabbit
  assert_success_file pull/rabbit-clone
  run branchout rabbit
  assert_success_file pull/rabbit-update
}

@test "branchout a non repository group then update" {
  example branchout-a-non-repository-group-then-update
  run branchout lion
  assert_success_file pull/lion-clone
  run branchout lion
  assert_success_file pull/lion-update
}
