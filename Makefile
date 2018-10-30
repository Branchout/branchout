export PATH := $(PWD):$(PATH)

target/output/**/*.output: output/**/*.txt
	mkdir -p target/output
	./output/escape-text $?

canned-output: target/output/**/*.output

clean:
	rm -rf target

repositories:
	mkdir -p target
	examples/make-repositories > target/repositories.log  2>&1

test: clean canned-output repositories
	bats --pretty bats

travis: clean canned-output repositories
	bats --tap bats
