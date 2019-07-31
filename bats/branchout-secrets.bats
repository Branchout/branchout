load helper

@test "secret - shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-secrets
  assert_success
}

@test "secret - invoking branchout secret usage" {
  run branchout-secrets
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "secret - setup my key" {
  example secrets-setup
  run branchout-secrets setup
  assert_success_file secrets/setup
}

@test "secret - setup my key fails when key exists" {
  example secrets-already-setup
  run branchout-secrets setup
  assert_error "branchout secrets setup: you have already setup your key"
}

@test "secret - create secret when it doesnt exist" {
  example secrets-create
  run branchout-secrets create some-secret
  assert_success_file secrets/create
}

@test "secret - fail to create secret when it exists" {
  example secrets-create-already-exists
  run branchout-secrets create existing
  assert_error "oops"
}

@test "secret - fail to add key to secret when don't have permission" {
  run branchout-secrets add-key keyid
  assert_error "oops"
}

@test "secret - add new key to secret" {
  run branchout-secrets add-key keyid some-secret
  assert_success_file secrets/add-key
}

@test "secret - add new key to all secrets" {
  run branchout-secrets add-key keyid
  assert_success_file secrets/add-key-to-all
}

@test "secret - remove key from secret" {
  run branchout-secrets remove-key keyid some-secret
  assert_success_file secrets/remove-key
}

@test "secret - edit a secret" {
  EDITOR="cat"
  run branchout-secrets edit some-secret
  assert_success_file secrets/edit
}

@test "secret - patch a secret value" {
  run branchout-secrets patch some-secret key <<< 'newvalue'
  assert_success_file secrets/patch
}
