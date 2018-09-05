target/output/**/*.output: output/**/*.txt
	mkdir target/output -p
	./output/escape-text $?
	
output: target/output/**/*.output

clean:
	rm -rf target
	
repositories:
	mkdir target/repositories -p
	tar xz -C target/repositories -f examples/repositories.tgz
	
test: clean repositories output
	bats --pretty bats
