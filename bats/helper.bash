BASEDIR="${PWD}"
BUILD_DIRECTORY="${BASEDIR}/target"
EXAMPLES="${BASEDIR}/examples"
GPG_COMMAND="gpg"
command -v gpg2 >/dev/null && GPG_COMMAND="gpg2"

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
  test -d "target/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/${1}" "target/branchout/${1}"
  echo "BRANCHOUT_CONFIG_GIT_EMAIL=\"${1}@example.com\"" > "target/branchout/${1}/branchoutrc"
  cd "target/${1}" || bail "Failed to enter target/${1}"
  git init || bail "failed to initilise the git repository"
  git remote add origin file://${BUILD_DIRECTORY}/repositories/base || bail "failed to set the origin which is needed to derive base url"
  export HOME=..
  echo "BRANCHOUT_NAME=\"${1}\"" > Branchoutfile
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

prefixExample() {
  test -z "$1" && bail "examples need a name"
  test -d "target/${1}" && bail "example already exists: ${1}"
  mkdir -p "target/${1}" "target/branchout/${1}"
  cd "target/${1}" || bail "Failed to enter target/${1}"
  git init || bail "failed to initilise the git repository"
  git remote add origin file://${BUILD_DIRECTORY}/repositories/base || bail "failed to set the origin which is needed to derive base url"
  export HOME=../
  echo "BRANCHOUT_NAME=\"${1}\"" > Branchoutfile
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
