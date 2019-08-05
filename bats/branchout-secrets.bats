load helper

@test "secret - shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-secrets
  assert_success
}

@test "secret - invoking branchout secret usage" {
  secretExample secrets-usage
  run branchout-secrets --no-pinentry
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "secret - setup my key" {
  secretExample secrets-setup
  run branchout set-config "EMAIL" "branchout-test@example.com"
  run branchout-secrets setup --no-pinentry <<< ""
  assert_success_firstline "Generating key for branchout-test@example.com"
}

@test "secret - setup my key prompting for email" {
  secretExample secrets-setup-with-prompt
  run branchout-secrets setup --no-pinentry <<< "branchout-test@example.com"
  assert_success_firstline "Please provide your email address: Generating key for branchout-test@example.com"
}

@test "secret - setup my key fails when key exists" {
  secretExample secrets-already-setup
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout-secrets setup --no-pinentry <<< ""
  assert_error "Key already exists for branchout@example.com"
}

@test "secret - show my keys" {
  secretExample secrets-show-keys
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout-secrets show --no-pinentry
  assert_success_file secrets/show
}

@test "secret - create secret fails when template doesnt exist" {
  secretExample secrets-create-no-template
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  run branchout-secrets create example-application/secret --no-pinentry
  assert_error "Template example-application/secret.template not found"
}

@test "secret - create secret when it doesnt exist" {
  secretExample secrets-create
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets create example-application/secret --no-pinentry
  assert_success_file secrets/create
}

@test "secret - fail to create secret when it exists" {
  secretExample secrets-create-already-exists
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets create example-application/secret --no-pinentry
  run branchout-secrets create example-application/secret --no-pinentry
  assert_error "Secret already exists for example-application"
}

@test "secret - verify secret fails when keys mismatch" {
  secretExample secrets-verify-fails
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets verify example-application/secret --no-pinentry
  assert_error_file secrets/secret-key-mismatch
}

@test "secret - verify secrets fails when keys mismatch" {
  secretExample secrets-verify-all-fails
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets verify --no-pinentry
  assert_error_file secrets/secrets-key-mismatch
}

@test "secret - verify secrets succeeds for all secrets" {
  secretExample secrets-verify-all-succeeds
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets verify --no-pinentry
}

@test "secret - verify secrets succeeds for one secret" {
  secretExample secrets-verify-success
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  skip "Not implemented"
  run branchout-secrets verify example-application/secret --no-pinentry
}

@test "secret - fail to add key to secret when don't have permission" {
  skip "Not implemented"
  run branchout-secrets add-key keyid --no-pinentry
}

@test "secret - add new key to secret" {
  skip "Not implemented"
  run branchout-secrets add-key keyid some-secret --no-pinentry
  assert_success_file secrets/add-key
}

@test "secret - add new key to all secrets" {
  skip "Not implemented"
  run branchout-secrets add-key keyid --no-pinentry
  assert_success_file secrets/add-key-to-all
}

@test "secret - remove key from secret" {
  skip "Not implemented"
  run branchout-secrets remove-key keyid some-secret --no-pinentry
  assert_success_file secrets/remove-key
}

@test "secret - edit a secret" {
  skip "Not implemented"
  EDITOR="cat"
  run branchout-secrets edit some-secret --no-pinentry
  assert_success_file secrets/edit
}

@test "secret - patch a secret value" {
  skip "Not implemented"
  run branchout-secrets patch some-secret key --no-pinentry <<< 'newvalue'
  assert_success_file secrets/patch
}
