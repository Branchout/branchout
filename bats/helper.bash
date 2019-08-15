BASEDIR="${PWD}"
BUILD_DIRECTORY="${BASEDIR}/target"
EXAMPLES="${BASEDIR}/examples"

bail() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    { echo "command failed with exit status $status"
      echo "output: $output"
    } | bail
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_success_firstline() {
  if [ "$status" -ne 0 ]; then
    { echo "command failed with exit status $status"
      echo "output: $output"
    } | bail
  elif [ "$#" -gt 0 ]; then
    assert_output_start "$1"
  fi
}

assert_error_file() {
  if [ "$status" -eq 0 ]; then
    { echo "command should have failed"
      echo "output: $output"
    } | bail
  elif [ "$#" -gt 0 ]; then
    test -f "${BUILD_DIRECTORY}/output/${1}.output" || bail "Could not find example output ${BUILD_DIRECTORY}/output/${1}.output"
    assert_output < "${BUILD_DIRECTORY}/output/${1}.output"
  fi
}

assert_success_file() {
  if [ "$status" -ne 0 ]; then
    { echo "command failed with exit status $status"
      echo "output: $output"
    } | bail
  elif [ "$#" -gt 0 ]; then
    test -f "${BUILD_DIRECTORY}/output/${1}.output" || bail "Could not find example output ${BUILD_DIRECTORY}/output/${1}.output"
    assert_output < "${BUILD_DIRECTORY}/output/${1}.output"
  fi
}

assert_success_file_sort() {
  if [ "$status" -ne 0 ]; then
    { echo "command failed with exit status $status"
      echo "output: $output"
    } | bail
  elif [ "$#" -gt 0 ]; then
    test -f "${BUILD_DIRECTORY}/output/${1}.output" || bail "Could not find example output ${BUILD_DIRECTORY}/output/${1}.output"
    assert_output_sort < "${BUILD_DIRECTORY}/output/${1}.output"
  fi
}

assert_error() {
  if [ "$status" -eq 0 ]; then
    bail "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output_start "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    bail "expected failed exit status"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_output_start() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="$1"
  fi
  assert_equal "$(echo "$expected" | head -n1)" "$(echo "$output" | head -n1)"
}

assert_output_sort() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    bail "sort expects a stream"
  fi
  assert_equal "$(echo "$expected" | sort)" "$(echo "$output" | sort)"
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then
    expected="$(cat -)"
  else
    expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: $1"
      echo "actual:   $2"
      echo "diff:"
      diff -u <(echo "$1") <(echo "$2")
    } | bail
  fi
}

example() {
  test -z "$1" && bail "examples need a name"
  test -d "target/tests/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/tests/${1}" "target/tests/branchout/${1}"
  cd "target/tests/${1}" || bail "Failed to enter target/tests/${1}"
  export HOME=..
  echo "BRANCHOUT_NAME=\"${1}\"" > Branchoutfile
  echo "BRANCHOUT_GIT_BASEURL=\"file://${BUILD_DIRECTORY}/repositories\"" >> Branchoutfile
  echo "frog-aleph
frog-gemel
frog-bet
lion-aleph
rabbit-aleph
toad-aleph
toad-gemel
toad-bet
snake-aleph
snake-bet
snake-gemel
fox-aleph
fox-bet
fox-gemel" > Branchoutprojects
}

secretSetup() {
  test -z "$1" && bail "examples need a name"
  test -d "target/tests/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/tests/${1}" "target/tests/${1}/home/branchout/${1}"
  cd "target/tests/${1}" || bail "Failed to enter target/tests/${1}"
  export HOME=home/branchout/${1}
  gpg2 -q --batch --pinentry=loopback --passphrase=test --no-default-keyring --keyring standard.keyring --import "${EXAMPLES}/gnupg/branchout.asc"
  gpg2 -q --batch --pinentry=loopback --passphrase=test --no-default-keyring --keyring standard.keyring --import "${EXAMPLES}/gnupg/branchout2.asc"
  gpg2 -q --batch --pinentry=loopback --passphrase=test --no-default-keyring --keyring standard.keyring --import "${EXAMPLES}/gnupg/branchout3.pub"
  gpg2 -q --batch --pinentry=loopback --passphrase=test --no-default-keyring --keyring decryption.keyring --import "${EXAMPLES}/gnupg/branchout.pub"
  gpg2 -q --batch --pinentry=loopback --passphrase=test --no-default-keyring --keyring decryption.keyring --import "${EXAMPLES}/gnupg/branchout3.asc"
  export HOME=home
  echo "BRANCHOUT_NAME=\"${1}\"" > Branchoutfile
  echo "BRANCHOUT_GIT_BASEURL=\"file://${BUILD_DIRECTORY}/repositories\"" >> Branchoutfile
  echo "frog-aleph
frog-gemel
frog-bet
lion-aleph
rabbit-aleph
toad-aleph
toad-gemel
toad-bet
snake-aleph
snake-bet
snake-gemel
fox-aleph
fox-bet
fox-gemel" > Branchoutprojects
}

secretExample() {
  secretSetup "${@}"
  mkdir -p target/resources/kubernetes src/main/secrets/
  cp -r "${EXAMPLES}"/secret-templates/* target/resources/kubernetes
  cp -r "${EXAMPLES}"/secrets/* src/main/secrets
}


legacyExample() {
  test -z "$1" && bail "exmaples need a name"
  test -d "target/tests/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/tests/${1}" "target/tests/branchout/${1}"
  cd "target/tests/${1}" || bail "Failed to enter target/tests/${1}"
  export HOME=../
  echo "BRANCHOUT_NAME=\"${1}\"" > .branchout
  echo "BRANCHOUT_GIT_BASEURL=\"file://${BUILD_DIRECTORY}/repositories\"" >> .branchout
  echo "frog-aleph
frog-gemel
frog-bet
lion-aleph
rabbit-aleph
toad-aleph
toad-gemel
toad-bet
snake-aleph
snake-bet
snake-gemel
fox-aleph
fox-bet
fox-gemel" > .projects
}

prefixExample() {
  test -z "$1" && bail "exmaples need a name"
  test -d "target/tests/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/tests/${1}" "target/tests/branchout/${1}"
  cd "target/tests/${1}" || bail "Failed to enter target/tests/${1}"
  export HOME=../
  echo "BRANCHOUT_NAME=\"${1}\"" > Branchoutfile
  echo "BRANCHOUT_GIT_BASEURL=\"file://${BUILD_DIRECTORY}/repositories\"" >> Branchoutfile
  echo "BRANCHOUT_PREFIX=\"prefix\"" >> Branchoutfile
  echo "toad-aleph
toad-gemel
toad-bet
prefix-sheep-aleph
prefix-sheep-bet
prefix-sheep-gemel
fox-aleph
fox-bet
fox-gemel" > Branchoutprojects
}
