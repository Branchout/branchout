load helper

@test "project list" {
  example project-list
  run branchout project list
  assert_success "frog-aleph
frog-bet
frog-gemel
rabbit-aleph
rabbit-bet
rabbit-gemel
toad-aleph
toad-bet
toad-gemel"
}

@test "project list only frog" {
  example project-list-frog
  run branchout project list frog
  assert_success "frog-aleph
frog-bet
frog-gemel"
}

@test "project list only frog-gemel" {
  example project-list-frog-gemel
  run branchout project list frog-gemel
  assert_success "frog-gemel"
}

@test "project not cloned yet" {
  example no-clone
  run branchout project status frog-aleph
  assert_success_file status/no-clone
}

@test "project pull" {
  example fresh-clone
  run branchout project pull frog-gemel
  assert_success_file pull/fresh-clone
}

@test "a project in rebase" {
  example rebase
  run branchout project status frog-gemel
  assert_success_file status/rebase
}

@test "a project on master" {
  example master
  run branchout project pull frog-gemel
  run branchout project status frog-gemel
  assert_success_file status/master
}
