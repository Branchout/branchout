#!/bin/bash

load helper

@test "branchout configuration is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-configuration
  assert_success
}
