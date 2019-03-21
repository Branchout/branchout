export PATH := $(PWD):$(PATH)

target/output:
	./output/escape-text

canned: target/output

clean:
	rm -rf target

repositories:
	mkdir -p target
	examples/make-repositories > target/repositories.log  2>&1

test: clean canned repositories
	bats --pretty bats

test-branchout: clean canned repositories
	bats --pretty bats/branchout.bats

test-branchout-init: clean canned repositories
	bats --pretty bats/branchout-init.bats

test-group: clean canned repositories
	bats --pretty bats/branchout-group.bats

travis: clean canned repositories
	bats --tap bats
