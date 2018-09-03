

bail() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } >&2
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
  assert_equal $(echo "$expected" | head -n1) $(echo "$output" | head -n1)
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
  test -n "$1" && bail "exmaples need a name"
  test -d "target/${1}" && bail "example already exists: ${1}"
  mkdir  "target/${1}" "target/branchout/${1}" -p
  cd "target/${1}"
  HOME=../
  echo 'BRANCHOUT_NAME="${1}"' > Branchoutfile 
  echo "frog-one
frog-two
frog-three
rabbit-one
rabbit-two
rabbit-three
toad-one
toad-two
toad-three
" > Branchoutprojects
}
