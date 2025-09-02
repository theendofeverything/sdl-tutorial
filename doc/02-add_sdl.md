# Tutorial 2

## Include SDL

Add the SDL2 dependency to `src/main.c`:

```c
#include <stdio.h>
#include "SDL.h"
```

Try to build. As expected, we get a compiler error:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x src/main.c -o build/main
src/main.c:2:10: fatal error: SDL.h: No such file or directory
    2 | #include "SDL.h"
      |          ^~~~~~~
compilation terminated.
make: *** [Makefile:6: build/main] Error 1
```

## Get compiler and linker flags

Include the SDL dependency with `pkg-config`.

Explore the installation on my development system:

```
$ pkg-config --list-all | grep -i sdl
SDL2_image  SDL2_image - image loading library for Simple DirectMedia...
SDL2_ttf    SDL2_ttf - ttf library for Simple DirectMedia Layer...
sdl2        sdl2 - Simple DirectMedia Layer is a cross-platform...
```

Get the compiler flags with `--cflags` and the linker flags with `--libs`:

```
$ pkg-config --sdl2 cflags
-D_REENTRANT -I/usr/include/SDL2

$ pkg-config --libs sdl2
-lSDL2
```

I don't need other libs yet, but note that I can give `pkg-config` multiple
module names:

```
$ pkg-config --cflags sdl2 SDL2_ttf SDL2_image
-D_REENTRANT -I/usr/include/SDL2

$ pkg-config --libs sdl2 SDL2_ttf SDL2_image
-lSDL2_ttf -lSDL2_image -lSDL2
```

The compiler flags are the same for all three modules, but we can see now there are three linker flags.

And rather than hard-code these flags in the Makefile, note that I use shell
command substitution (backticks):

```make
CFLAGS := -Wall -Wextra -pedantic -std=c2x
CFLAGS += `pkg-config --cflags sdl2`

build/main: src/main.c | build
	$(CC) $(CFLAGS) $^ -o $@
```

Command `make -n` will not show me the substitution, but if I want to
double-check it is correct, I make a throwaway recipe:

```make
what-cflags:
	@echo $(CFLAGS)
```

Then run the recipe:

```
$ make what-cflags
-Wall -Wextra -pedantic -std=c2x -D_REENTRANT -I/usr/include/SDL2
```

## Build again with compiler flags

Now the build works:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x `pkg-config --cflags sdl2` src/main.c -o build/main
./build/main
```

And it runs. Try running with some more arguments again:

```
$ ./build/main "Build works!" "But now let's use SDL."
./build/main
Build works!
But now let's use SDL.
```

Now let's use SDL. Jump to the header file (we know from `pkg-config --cflags
sdl2` that we are including `/usr/include/SDL2/SDL.h`).

In the header file `SDL.h`, we find the API for `SDL_Init()` and `SDL_Quit()`.
Each function has its documentation in a Doxygen docstring above the function
signature. Read the docstrings.

Add `SDL_Init()` and `SDL_Quit()` to our program.

```c
int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Quit();
}
```

Try building again:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x `pkg-config --cflags sdl2` src/main.c -o build/main
/usr/bin/ld: /tmp/ccILjfCR.o: in function `main':
main.c:(.text+0x4d): undefined reference to `SDL_Init'
/usr/bin/ld: main.c:(.text+0x52): undefined reference to `SDL_Quit'
collect2: error: ld returned 1 exit status
make: *** [Makefile:8: build/main] Error 1
```

As expected, we get linker errors. Include the linker flags in our `Makefile`.
Note the linker flags have to go **after** the output file:

```make
LIBS := `pkg-config --libs sdl2`

build/main: src/main.c | build
	$(CC) $(CFLAGS) $^ -o $@ $(LIBS)
```

The build succeeds:
```
$ make build/main
cc -Wall -Wextra -pedantic -std=c2x `pkg-config --cflags sdl2` src/main.c -o build/main `pkg-config --libs sdl2`
```

And the executable runs:
```
$ ./build/main "Build works!" "And now we are using SDL."
./build/main
Build works!
And now we are using SDL.
```

Here is the entire program so far:

```c
#include <stdio.h>
#include "SDL.h"

int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Quit();
    return EXIT_SUCCESS;
}
```

# Install SDL

## Install the SDL package

All of that is assuming I already have the `SDL2` package installed on my OS.
But if this returned no results:

```
$ pkg-config --list-all | grep -i sdl
```

Then I need to install the SDL package. In this case, I would first use `apt
search REGEX` to poke around for the package name:

```
$ apt search sdl
```

That has a lot of results. There are three lines per result (counting the blank
lines), so I can get a rough count with `wc -l` and dividing by three:

```
$ nlines=`apt search sdl | wc -l`; echo $(($nlines/3))
WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

215
```

Visually inspecting the results, I can see that adding the prefix `^lib`
narrows it down (the `^` means that the line must **begin** with `libsdl`):

```
$ nlines=`apt search ^libsdl | wc -l`; echo $(($nlines/3))

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

49
```

Here are the first and last results:

```
$ apt search ^libsdl
libsdl-console/jammy 2.1-6 amd64
  Console that can be added to any SDL application, libraries
...
libsdl2-ttf-dev/jammy,now 2.0.18+dfsg-2 amd64 [installed]
  TrueType Font library for Simple DirectMedia Layer 2, development files
```

It looks like my choices are limited to SDL1 and SDL2. I cannot use SDL3 unless
I want to build it from source. I'll use SDL2.

I know from experience that if I install `libsdl2-dev`, I will also get
`libsdl2-2.0-0` and `libsdl2-doc`, so I can get the base `SDL2` dependency with
just the one package:

```
$ sudo apt install libsdl2-dev
```

## Recipe to check if SDL is installed

Here is a recipe to check if SDL2 and/or SDL3 are installed:

```make
which-sdl: has-sdl2 has-sdl3

has-sdl2:
	@{ pkg-config --exists sdl2; } && echo SDL2 is installed || echo SDL2 is not installed

has-sdl3:
	@{ pkg-config --exists sdl3; } && echo SDL3 is installed || echo SDL3 is not installed
```
