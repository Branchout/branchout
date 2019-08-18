load helper

@test "secret - shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-secrets
  assert_success
}

@test "secret - invoking branchout secret usage" {
  secretExample secrets-usage
  run branchout-secrets --passphrase=test
  assert_error "branchout secrets: a tool for managing kubebernetes secrets"
}

@test "secret - setup my key" {
  secretSetup secrets-setup
  run branchout set-config "EMAIL" "branchout-test@example.com"
  run branchout-secrets setup --passphrase=test <<< ""
  assert_success_firstline "Generating key for branchout-test@example.com"
}

@test "secret - setup my key prompting for email" {
  secretSetup secrets-setup-with-prompt
  run branchout-secrets setup --passphrase=test <<< "branchout-test@example.com"
  assert_success_firstline "Please provide your email address: Generating key for branchout-test@example.com"
}

@test "secret - setup shows my key when key exists" {
  secretSetup secrets-already-setup
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout-secrets setup --passphrase=test <<< ""
  assert_success_file secrets/show-keys
}

@test "secret - show my keys when setup" {
  secretSetup secrets-show-keys
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout-secrets view-setup --passphrase=test <<< ""
  assert_success_file secrets/show-keys
}

@test "secret - status fails before a build" {
  secretSetup secrets-status-needs-build
  run branchout-secrets status --passphrase=test
  assert_error "You need to build to get the templates"
}

@test "secret - status shows templates and secrets" {
  secretExample secrets-status
  run branchout-secrets status --passphrase=test
  assert_success_file secrets/status
}

@test "secret - show secret contents" {
  secretExample secrets-view
  run branchout-secrets view example-application/secret --passphrase=test
  assert_success_file secrets/show-secret
}

@test "secret - create secret fails when template doesnt exist" {
  secretExample secrets-create-no-template
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  run branchout-secrets create no-template-application/secret --passphrase=test
  assert_error "Secret template not found for no-template-application/secret"
}

@test "secret - create secret when it doesnt exist" {
  secretExample secrets-create
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  run branchout-secrets create missing-application/secret --passphrase=test
  assert_success_file secrets/create
}

@test "secret - fail to create secret when it exists" {
  secretExample secrets-create-already-exists
  run branchout set-config "EMAIL" "branchout@example.com"
  run branchout set-config "GPG_KEY" "520D39C127DA4C77B1CA7BD04B59A79F662253BA"
  run branchout-secrets create example-application/secret --passphrase=test
  assert_error "Secret already exists for example-application/secret"
}

@test "secret - key" {
  secretExample secrets-key
  run branchout secrets use-key "branchout@example.com"
  run branchout-secrets show-keys
  assert_success_file secrets/main-key
}

@test "secret - add key" {
  secretExample secrets-add-key
  run branchout secrets use-key "branchout@example.com"
  run branchout secrets add-key "pgp:4459A441306219F88CD7581E1A5669F6742AE4E2"
  assert_success_file secrets/two-keys
  run branchout-secrets show-keys
  assert_success_file secrets/two-keys
}

@test "secret - create secret with extra project keys" {
  secretExample secrets-create-with-extra-keys
  run branchout secrets use-key "branchout@example.com"
  run branchout secrets add-key "pgp:BBCBD423E6536F1A1EDABF95AAA99B3A301F5178" 
  assert_success_file secrets/external-key
  run branchout-secrets create missing-application/secret --passphrase=test
  assert_success_file secrets/create-with-project-keys 
  run branchout-secrets use-key "branchout3@example.com"
  run branchout-secrets view missing-application/secret --keyring=decryption.keyring
  assert_success_file secrets/show-secret 
}

@test "secret - verify secret fails when keys mismatch" {
  secretExample secrets-verify-fails
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout-secrets verify mismatch-application/secret --passphrase=test
  assert_error_file secrets/mismatched-keys
}

@test "secret - verify secrets fails when keys mismatch" {
  secretExample secrets-verify-all-fails
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout-secrets verify --passphrase=test
  assert_success_file secrets/verify-all-fails
}

@test "secret - verify secrets succeeds for all secrets" {
  secretSetup secrets-verify-all-succeeds
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  mkdir -p target/resources/kubernetes src/main/secrets/
  cp -r "${EXAMPLES}"/secret-templates/example-application target/resources/kubernetes/app-1
  cp -r "${EXAMPLES}"/secret-templates/example-application target/resources/kubernetes/app-2
  cp -r "${EXAMPLES}"/secret-templates/example-application target/resources/kubernetes/app3
  cp -r "${EXAMPLES}"/secrets/example-application src/main/secrets/app-1
  cp -r "${EXAMPLES}"/secrets/example-application src/main/secrets/app-2
  cp -r "${EXAMPLES}"/secrets/example-application src/main/secrets/app3
  run branchout-secrets verify --passphrase=test
  assert_success_file secrets/verify-all-success
}

@test "secret - verify secrets succeeds for one secrets" {
  secretSetup secrets-verify-one-succeeds
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  mkdir -p target/resources/kubernetes src/main/secrets/
  cp -r "${EXAMPLES}"/secret-templates/example-application target/resources/kubernetes/app-2
  cp -r "${EXAMPLES}"/secrets/example-application src/main/secrets/app-2
  run branchout-secrets verify --passphrase=test
  assert_success_file secrets/verify-one-success
}

@test "secret - verify secrets succeeds for one secret" {
  secretExample secrets-verify-success
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout-secrets verify example-application/secret --passphrase=test
  assert_success_file secrets/verify-success
}

@test "secret - fail to add key to secret when don't have permission" {
  secretExample secrets-are-safe-from-outsiders
  run branchout secrets use-key "branchout2@example.com"
  assert_success_file secrets/use-branchout2
  run branchout-secrets create missing-application/secret --passphrase=test
  assert_success_file secrets/create-with-project-keys
  run branchout-secrets use-key "branchout3@example.com"
  assert_success_file secrets/use-branchout3 
  run branchout-secrets update missing-application/secret --keyring=decryption.keyring --passphrase=test
  assert_error_file secrets/safe-from-outsiders
}

@test "secret - add new key to secret" {
  skip "Not implemented"
  run branchout-secrets add-key keyid some-secret --passphrase=test
  assert_success_file secrets/add-key
}

@test "secret - add new key to all secrets" {
  skip "Not implemented"
  run branchout-secrets add-key keyid --passphrase=test
  assert_success_file secrets/add-key-to-all
}

@test "secret - remove key from secret" {
  skip "Not implemented"
  run branchout-secrets remove-key keyid some-secret --passphrase=test
  assert_success_file secrets/remove-key
}

@test "secret - edit a secret" {
  skip "Not implemented"
  EDITOR="cat"
  run branchout-secrets edit some-secret --passphrase=test
  assert_success_file secrets/edit
}

@test "secret - patch a secret value" {
  skip "Not implemented"
  run branchout-secrets patch some-secret key --passphrase=test <<< 'newvalue'
  assert_success_file secrets/patch
}
