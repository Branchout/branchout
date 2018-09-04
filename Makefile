output/**/*.output: output/**/*.txt
	./output/escape-text $?

test: target
	bats --pretty bats
