load helper

@test "branchout group prefix" {
  run branchout-group derive a-b-c
  assert_success "a"
  
  run branchout-group derive some-artifact
  assert_success "some"
  
  run branchout-group derive artifact
  assert_success "artifact"
}

@test "branchout group list" {
  example branchout-group-list
  run branchout group list
  assert_success "frog
rabbit
toad"
}
