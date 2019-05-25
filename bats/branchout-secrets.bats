load helper

@test "shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-secrets
  assert_success
}

@test "invoking branchout secret usage" {
  run branchout-secrets
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "settings creates key from nothing" {
  example settings-newkey
  run branchout-secrets settings
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "create secret when it doesnt exist" {
  run branchout-secrets create some-secret
  assert_success_file secrets/create
}

@test "fail to create secret when it exists" {
  run branchout-secrets create existing
  assert_error "oops"
}

@test "fail to add key to secret when don't have permission" {
  run branchout-secrets add-key keyid
  assert_error "oops"
}

@test "add new key to secret" {
  run branchout-secrets add-key keyid some-secret
  assert_success_file secrets/add-key
}

@test "add new key to all secrets" {
  run branchout-secrets add-key keyid
  assert_success_file secrets/add-key
}

@test "remove key from secret" {
  run branchout-secrets remove-key keyid some-secret
  assert_success_file secrets/remove-key
}

@test "edit a secret" {
  run branchout-secrets edit some-secret
  assert_success_file secrets/edit
}

@test "patch a secret value" {
  run branchout-secrets patch some-secret key
  assert_success_file secrets/patch
}
