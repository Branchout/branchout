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
  assert_success "frog
rabbit
toad"
}

@test "branchout group list filtering" {
  example branchout-group-filter
  run branchout group list frog
  assert_success "frog"
}
