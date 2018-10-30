export PATH := $(PWD):$(PATH)

target:
	mkdir target

target/output/**/*.output: output/**/*.txt target
	mkdir -p target/output
	./output/escape-text $?

output: target/output/**/*.output

clean:
	rm -rf target

repositories: target
	examples/make-repositories > target/repositories.log  2>&1

test: clean output repositories
	bats --pretty bats

travis: clean output repositories
	bats --tap bats
