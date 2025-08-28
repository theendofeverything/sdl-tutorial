CFLAGS := -Wall -Wextra -pedantic -std=c2x

run: build/main; @./build/main

build/main: src/main.c | build
	$(CC) $(CFLAGS) $^ -o $@

build: ; mkdir $@

