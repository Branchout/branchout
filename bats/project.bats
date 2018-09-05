load helper

@test "project list" {
  example project-list
  run branchout project list
  assert_success "frog-one
frog-three
frog-two
rabbit-one
rabbit-three
rabbit-two
toad-one
toad-three
toad-two"
}

@test "project list only frog" {
  example project-list-frog
  run branchout project list frog
  assert_success "frog-one
frog-three
frog-two"
}

@test "project list only frog-two" {
  example project-list-frog-two
  run branchout project list frog-two
  assert_success "frog-two"
}

@test "project not cloned yet" {
  example no-clone
  run branchout project status frog-one
  assert_success_file status/no-clone
}

@test "a project in rebase" {
  example rebase
  run branchout project status frog-two
  assert_success_file status/rebase
}

@test "a project on master" {
  example rebase
  run branchout project status frog-two
  assert_success_file status/rebase
}
