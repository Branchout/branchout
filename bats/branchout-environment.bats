load helper

@test "branchout environment is shellcheck compliant with no exceptions" {
  run shellcheck -x branchout-environment
  assert_success
}


@test "branchout environment configuration missing BRANCHOUT_NAME fails" {
  mkdir -p target/missing-name
  cd target/missing-name
  HOME=..
  touch Branchoutfile
  run branchout status
  assert_error "Branchout name not defined in Branchoutfile, run branchout init" 
}

@test "branchout environment home is missing fails" {
  mkdir -p target/missing-branchout-home 
  HOME=..
  cd target/missing-branchout-home
  echo 'BRANCHOUT_NAME="missing-branchout-home"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="missing-branchout-home"' >> Branchoutfile 
  run branchout status
  assert_error "Branchout home '../branchout/missing-branchout-home' does not exist, run branchout init" 
}

@test "branchout environment missing projects prompts" {
  mkdir -p target/no-projects target/branchout/no-projects 
  cd target/no-projects
  HOME=..
  echo 'BRANCHOUT_NAME="no-projects"' > Branchoutfile 
  echo 'BRANCHOUT_GIT_BASEURL="no-projects"' >> Branchoutfile 
  run branchout status
  assert_error "Branchoutprojects file missing, try branchout add [repository]"
}

@test "branchout environment prefix is removed" {
  mkdir -p target/prefix target/branchout/prefix
  cd target/prefix
  HOME=..
  git init . || true
  git remote add origin git@sass.tld:prefix.git || true
  echo 'BRANCHOUT_NAME="prefix"' > Branchoutfile
  echo 'BRANCHOUT_PREFIX="prefix"' >> Branchoutfile
  echo 'prefix-frog-aleph' > Branchoutprojects
  run branchout status
  assert_success_file status/no-clone-prefix
}

@test "branchout environment git URL derived from remote" {
  mkdir -p target/git-url-from-remote target/branchout/git-url-from-remote
  cd target/git-url-from-remote
  HOME=..
  git init -b master
  git remote add origin https://github.com/someorg/somerepo.git
  echo 'BRANCHOUT_NAME="git-url-from-remote"' > Branchoutfile
  echo 'test-project' > Branchoutprojects
  run branchout status
  assert_success_only
}

@test "branchout environment manual git URL without remote" {
  mkdir -p target/manual-git-url target/branchout/manual-git-url
  cd target/manual-git-url
  HOME=..
  git init -b master
  # No git remote set - only manual URL
  echo 'BRANCHOUT_NAME="manual-git-url"' > Branchoutfile
  echo 'BRANCHOUT_GIT_BASEURL="https://github.com/myorg"' >> Branchoutfile
  echo 'test-project' > Branchoutprojects
  run branchout status
  assert_success_only
}

@test "branchout environment manual git URL takes precedence over remote" {
  mkdir -p target/manual-precedence target/branchout/manual-precedence
  cd target/manual-precedence
  git init -b master
  git remote add origin https://github.com/wrongorg/wrongrepo.git
  echo 'BRANCHOUT_NAME="manual-precedence"' > Branchoutfile
  echo 'BRANCHOUT_GIT_BASEURL="https://github.com/correctorg"' >> Branchoutfile
  echo 'test-project' > Branchoutprojects

  # Verify the correct URL is used (manual URL, not git remote URL)
  run bash -c 'export HOME=..; source ../../branchout-configuration; source ../../branchout-environment; echo "$BRANCHOUT_GIT_BASEURL"'
  assert_success "https://github.com/correctorg"
}

@test "branchout environment no remote and no manual URL fails with helpful error" {
  mkdir -p target/no-git-url target/branchout/no-git-url
  cd target/no-git-url
  HOME=..
  git init -b master
  # No git remote, no manual BRANCHOUT_GIT_BASEURL
  echo 'BRANCHOUT_NAME="no-git-url"' > Branchoutfile
  echo 'test-project' > Branchoutprojects
  run branchout status
  assert_error "Git base URL not configured. Either:
  1. Add a git remote: git remote add origin <url>
  2. Set BRANCHOUT_GIT_BASEURL in your Branchoutfile:
     - For HTTPS: BRANCHOUT_GIT_BASEURL=\"https://github.com/yourorg\"
     - For SSH: BRANCHOUT_GIT_BASEURL=\"git@github.com:yourorg\""
}

