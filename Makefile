CFLAGS := -Wall -Wextra -pedantic -std=c2x
CFLAGS += `pkg-config --cflags sdl2`
CFLAGS += -g
LIBS := `pkg-config --libs sdl2`

run: build/main; @./build/main

build/main: src/main.c | build
	$(CC) $(CFLAGS) $^ -o $@ $(LIBS)

build: ; mkdir $@

build/main.d: src/main.c | build
	$(CC) $(CFLAGS) -M $^ -MF $@

which-sdl: has-sdl2 has-sdl3

has-sdl2:
	@{ pkg-config --exists sdl2; } && echo SDL2 is installed || echo SDL2 is not installed

has-sdl3:
	@{ pkg-config --exists sdl3; } && echo SDL3 is installed || echo SDL3 is not installed
