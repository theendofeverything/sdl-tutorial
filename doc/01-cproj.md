# Tutorial 1

## Folder and file setup

Step                                         | Code
-------------------------------------------- | -------------------------
Make a project directory and source folder.  | `$ mkdir -p tutorial/src`
Enter the project folder.                    | `$ cd tutorial`
Initialize the project Git repo.             | `$ git init`
Create empty `README.md` and `main.c` files. | `$ touch README.md src/main.c`

## Kickoff the files

Kickoff the `README.md` with some text:

```markdown
# About

This is a simple C project that will (eventually) use SDL to draw to the screen.
```

Kickoff `main.c` with an empty program:

```c
int main() {}
```

Kickoff the `Makefile`:

```make
CFLAGS := -Wall -Wextra -pedantic -std=c2x

run: build/main; @./build/main

build/main: src/main.c | build
	$(CC) $(CFLAGS) $^ -o $@

build: ; mkdir $@
```

Note the recipes for `run` and `build` are:

```make
run: build/main
	@./build/main

build:
	mkdir $@
```

But I like one-liners (if they are short) so I joined the recipe and
prerequisites onto a single line, using a semicolon to separate the
prerequisites from the recipes.

## Test the Makefile build

Test the `make` recipe:

```
$ make -n
mkdir build
cc -Wall -Wextra -pedantic -std=c2x src/main.c -o build/main
./build/main
```

Find out what compiler is invoked with `cc`:

```
$ realpath $(which cc)
/usr/bin/x86_64-linux-gnu-gcc-11
```

## Build

Build and run:

```
$ make
mkdir build
cc -Wall -Wextra -pedantic -std=c2x src/main.c -o build/main
```

The program builds but does nothing. All we can do is check that it exited successfully (with exit status zero):

```
$ echo $?
0
```

## Make the C project do something

Modify `main.c` to print its input arguments:

```c
#include <stdio.h>

int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
}
```

Build and run again:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x src/main.c -o build/main
./build/main
```

Now the program prints its arguments. The only argument is the executable name,
`./build/main`.

Try running it with a few more arguments:

```
$ ./build/main "I say!" "Now, look here!"
./build/main
I say!
Now, look here!
```

## Create a Git ignore file

Check the Git status to see all of the untracked files:

```
$ git status -uall
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        Makefile
        README.md
        build/main
        src/main.c
```

Look at each untracked file and ask yourself if that file should be under
version control:

File       | Should this be under version control?
----       | -------------------------------------
Makefile   | Yes
README.md  | Yes
build/main | No
src/main.c | Yes

Do not track `build/main`:

1. It will change often, so it will add a lot of noise to our Git history if we
   track changes to it.
2. We will push this project to a remote to share it with others. They can
   build the executable `build/main` from our source code and Makefile. That is
   preferable to them downloading the executable from our remote repository.
3. The executable will eventually be a large file. When we start adding assets,
   we will have other large files we want to store on the remote repository.
   Storing the executable on the remote is a waste of space.

Create the following `.gitignore` file:

```
build
```

Run `git status -uall` again:

```
$ git status -uall
...
        .gitignore
        Makefile
        README.md
        doc/01-cproj.md
        src/main.c
```

Check what files are staged if we stage the entire current directory

```
$ git add -n .
add '.gitignore'
add 'Makefile'
add 'README.md'
add 'doc/01-cproj.md'
add 'src/main.c'
```

Looks good. Stage and commit:

```
$ git add .
$ git commit -m "Initial commit"
```

Create the remote repository on GitHub.

Add the remote:

```
$ git remote add origin github:theendofeverything/sdl-tutorial.git
```

Note: my SSH address starts with `github:` instead of `git@github.com:`. This
is thanks to my `~/.ssh/config`:

```
host github
        HostName github.com
        IdentityFile ~/.ssh/github_key
        User git
```

Push to the remote. Since this is the first time pushing, set upstream to
`origin main` with `-u origin main`. Subsequent pushes/pulls to/from upstream
`origin main` will just be `git push` and `git pull`.

```
git push -u origin main
```
