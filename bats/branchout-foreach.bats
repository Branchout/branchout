load helper

@test "branchout foreach newbranch" {
  example foreach
  run branchout project pull frog-bet
  run branchout foreach frog-bet "git checkout -b newbranch"
  assert_success_file foreach/checkout-newbranch
  run branchout status frog-bet 
  assert_success_file foreach/newbranch-status
}
