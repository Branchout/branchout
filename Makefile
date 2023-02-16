BATS := $(shell which bats)
export PATH := $(PWD)/bats/bin:$(PWD):$(PATH)
VERSION := $(shell git describe --tags --abbrev=0)

target/output:
	./output/escape-text

canned: target/output

clean:
	rm -rf target

repositories:
	mkdir -p target
	examples/make-repositories > target/repositories.log  2>&1

test: clean canned repositories
	$(BATS) --pretty bats

test-branchout: clean canned repositories
	$(BATS) --pretty bats/branchout.bats

test-branchout-projects: clean canned repositories
	$(BATS) --pretty bats/branchout-projects.bats

test-branchout-maven: clean canned repositories
	$(BATS) --pretty bats/branchout-maven.bats

test-branchout-yarn: clean canned repositories
	$(BATS) --pretty bats/branchout-yarn.bats

test-branchout-init: clean canned repositories
	$(BATS) --pretty bats/branchout-init.bats

test-group: clean canned repositories
	$(BATS) --pretty bats/branchout-group.bats

test-current: clean canned repositories
	$(BATS) --pretty bats/current.bats

ci: clean canned repositories
	$(BATS) --tap bats

deploy-to-homebrew:
	VERSION=${VERSION} bash .deploy-to-homebrew
