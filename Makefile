export PATH := $(PWD)/bats/bin:$(PWD):$(PATH)
VERSION := $(shell git describe --tags --abbrev=0)

target/output:
	bash -c ./output/escape-text

canned: target/output

clean:
	rm -rf target
	mkdir target

repositories:
	mkdir -p target
	examples/make-repositories > target/repositories.log  2>&1

test: clean canned repositories
	bats --pretty bats

test-branchout: clean canned repositories
	bats --pretty bats/branchout.bats

test-branchout-maven: clean canned repositories
	bats --pretty bats/branchout-maven.bats

test-branchout-yarn: clean canned repositories
	bats --pretty bats/branchout-yarn.bats

test-branchout-init: clean canned repositories
	bats --pretty bats/branchout-init.bats

test-group: clean canned repositories
	bats --pretty bats/branchout-group.bats

test-current: clean canned repositories
	bats --pretty bats/current.bats

travis: clean canned repositories
	bats --tap bats

deploy-to-homebrew:
	VERSION=${VERSION} bash .deploy-to-homebrew
