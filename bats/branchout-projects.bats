load helper

@test "branchout project is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-project
  assert_success
}

@test "project list" {
  example project-list
  run branchout project list
  assert_success "fox-aleph
fox-bet
fox-gemel
frog-aleph
frog-bet
frog-gemel
lion-aleph
rabbit-aleph
snake-aleph
snake-bet
snake-gemel
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

@test "project pull twice" {
  example fresh-clone-then-pull
  run branchout project pull frog-gemel
  assert_success_file pull/fresh-clone
  run branchout project pull frog-gemel
  assert_success_file pull/fresh-clone-then-pull
}

@test "a project in rebase" {
  example rebase
  run branchout project pull frog-bet
  cd frog/frog-bet
  git reset --hard step-2
  echo "changes" > README.md
  git config user.email "branchout@example.com"
  git config user.name "branchout"
  git commit -a -m"conflict"
  cd ../..
  run branchout project pull frog-bet
  assert_success_file pull/rebase
  run branchout project status frog-bet
  assert_success_file status/rebase
}

@test "a project on master" {
  example master
  run branchout project pull frog-gemel
  run branchout project status frog-gemel
  assert_success_file status/master
}

@test "pull fails with changes" {
  example changes
  run branchout project pull frog-aleph
  run branchout project status frog-aleph
  pwd 1>&2
  cd frog/frog-aleph
  git reset --hard step-2
  echo "changes" >> README.md
  cd ../..
  pwd 1>&2
  run branchout project status frog-aleph
  run branchout project pull frog-aleph
  assert_success_file pull/changes
}


@test "branchout a non repository project group then update" {
  example branchout-a-non-repository-project-group-then-update
  run branchout lion-aleph
  assert_success_file pull/lion-clone
  run branchout lion-aleph
  assert_success_file pull/lion-update
}

@test "branchout imaginary project does nothing" {
  example branchout-imaginary-project-does-nothing
  run branchout elephant
  assert_success ""
}

@test "project that does not exist" {
  example not-exists
  run branchout project pull frog-lamed
  assert_success_file pull/not-exists
}
