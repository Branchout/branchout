load helper

@test "secret - shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-secrets
  assert_success
}

@test "secret - setup my key" {
  secretExample secrets-setup
  run branchout-secrets setup --for-testing <<< "john@example.com"
  assert_success_file secrets/setup
}
#
@test "secret - setup my key fails when key exists" {
  secretExample secrets-already-setup
  run branchout-secrets setup --for-testing <<< "john@example.com"
  run branchout-secrets setup --for-testing <<< ""
  assert_error "branchout secrets setup: you have already setup your key"
}

@test "secret - invoking branchout secret usage" {
  run branchout-secrets --for-testing
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "secret - create secret when it doesnt exist" {
  secretExample secrets-create
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  run branchout-secrets create some-secret --for-testing
  assert_success_file secrets/create
}

@test "secret - fail to create secret when it exists" {
  secretExample secrets-create-already-exists
  run branchout-secrets create existing --for-testing
  assert_error "oops"
}

@test "secret - fail to add key to secret when don't have permission" {
  run branchout-secrets add-key keyid --for-testing
  assert_error "oops"
}

@test "secret - add new key to secret" {
  run branchout-secrets add-key keyid some-secret --for-testing
  assert_success_file secrets/add-key
}

@test "secret - add new key to all secrets" {
  run branchout-secrets add-key keyid --for-testing
  assert_success_file secrets/add-key-to-all
}

@test "secret - remove key from secret" {
  run branchout-secrets remove-key keyid some-secret --for-testing
  assert_success_file secrets/remove-key
}

@test "secret - edit a secret" {
  EDITOR="cat"
  run branchout-secrets edit some-secret --for-testing
  assert_success_file secrets/edit
}

@test "secret - patch a secret value" {
  run branchout-secrets patch some-secret key --for-testing <<< 'newvalue'
  assert_success_file secrets/patch
}
