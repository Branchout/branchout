@test "invoking branchout prints usage" {
  run branchout
  [ "$status" -eq 0 ]
  [ "$output" = "branchout: a tool for managing multi-repo projects" ]
}
