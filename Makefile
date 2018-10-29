export PATH := $(PWD):$(PATH)

target/output/**/*.output: output/**/*.txt
	mkdir target/output -p
	./output/escape-text $?

output: target/output/**/*.output

clean:
	rm -rf target

repositories: 
	examples/make-repositories > target/repositories.log  2>&1

test: clean output repositories
	bats --pretty bats

travis: clean output repositories
	bats --tap bats
