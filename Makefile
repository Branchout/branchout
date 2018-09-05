output/**/*.output: output/**/*.txt
	./output/escape-text $?

clean:
	rm -rf target
	
repositories:
	mkdir target/repositories -p
	tar xz -C target/repositories -f examples/repositories.tgz
	
test: clean repositories target
	bats --pretty bats
