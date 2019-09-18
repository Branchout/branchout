load helper

teardown() {
  test -d "${GNUPGHOME_TEMP}/.gpg.s" && GNUPGHOME="${GNUPGHOME_TEMP}/.gpg.s" gpgconf --kill gpg-agent || true
  test -d "${GNUPGHOME_TEMP}/.gpg.d" && GNUPGHOME="${GNUPGHOME_TEMP}/.gpg.d" gpgconf --kill gpg-agent || true
  test -d "${GNUPGHOME_TEMP}" && rm -rf "/tmp/$(basename ${GNUPGHOME_TEMP})" || true
}

@test "secret - register public key" {
  secretExample secrets-register-key
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout secrets register-key "branchout2@example.com"
  assert_success_file secrets/main-key
  run branchout-secrets show-keys
  assert_success_file secrets/main-key
}

@test "secret - register public key twice" {
  secretExample secrets-register-key-twice
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout secrets register-key "branchout2@example.com"
  assert_success_file secrets/main-key
  run branchout secrets register-key "branchout2@example.com"
  assert_error "Key branchout2@example.com is already registered"
}

@test "secret - register public key by file" {
  secretExample secrets-register-key-by-file
  run branchout secrets use-key "branchout@example.com"
  assert_success_file secrets/use-branchout
  run branchout secrets register-key "${EXAMPLES}/gnupg/branchout3.pub"
  assert_success_file secrets/main-key
  run branchout secrets users "branchout@example.com"
  assert_error "Key branchout@example.com is already registered"
}