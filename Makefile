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

travis: clean canned repositories
	bats --tap bats

watch:
	while true; do \
		make test; \
		inotifywait -qre close_write . bats; \
	done


