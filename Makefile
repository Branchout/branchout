export PATH := $(PWD)/bats/bin:$(PWD):$(PATH)

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

test-branchout-maven: clean canned repositories
	bats --pretty bats/branchout-maven.bats

test-branchout-init: clean canned repositories
	bats --pretty bats/branchout-init.bats

test-group: clean canned repositories
	bats --pretty bats/branchout-group.bats

test-secrets: clean canned repositories
	bats --pretty bats/branchout-secrets.bats

test-current: clean canned repositories
	bats --pretty bats/current.bats

travis: clean canned repositories
	bats --tap bats
