
rm -rf target/examples
mkdir target/examples p
cp -fax examples target

function example-missingname() {
  mkdir target/missing-name -p
  cd target/missing-name
  touch .branchout
}
