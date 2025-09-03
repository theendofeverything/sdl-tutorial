# Tutorial 4

In [Tutorial 2](02-add_sdl.md#build-again-with-compiler-flags), we knew the
path to the SDL header file was `/usr/include/SDL2/` from doing `pkg-config
--cflags sdl2`. And since our source code has `#include "SDL.h"`, full path to
`SDL.h` must be `/usr/include/SDL2/SDL.h`.

But I don't want to manually open SDL header files to access function
signatures and docstrings. Or rather, I know the experience can be much better.
And I shouldn't have to do detective work to find my dependency header files.

This tutorial is a first step towards setting up keyboard shortcuts to jump to
the relevant line in a C-project dependency header file.

Since this is a C project, there is `cscope`. And I use Vim, which invokes
`cscope` in "line-oriented mode" (see `man cscope` manual page, section
"Line-Oriented interface") to integrate it with the Vim interface. Let's see
how far we can get just using `cscope` and its built-in Vim integration.

## Cscope database

Create a cscope-symbol-cross-reference-file (a.k.a., a `cscope` database). By
default this file is called `cscope.out`.

```
$ cscope -R -b
```

Option `-R` recurses into folders to find source files, so
we need not specify a source file as `-R` on its own will start at the current
directory.

Option `-b` limits `cscope` to just building the cross-reference. Otherwise
`cscope` goes into its interactive mode. If you try `cscope` without `-b`, use
`Ctrl+D` to exit `cscope` (`Ctrl+D` is the standard way to tell Linux you are
done entering user input at `stdin`).

We never want to track this file, so add it to `.gitignore`:

```
build
cscope.out
```

Get a sense of the size of `cscope.out`:

```
$ wc -l cscope.out 
2922 cscope.out
```

Inspect the first two and last two lines:

```
$ head -2 cscope.out; echo ---; tail -2 cscope.out 
cscope 15 $HOME/MikeRepos/sdl/tutorial               0000016071
        @src/main.c
---
src/main.c
/usr/include/stdio.h
```

It looks like ASCII text, but it contains raw binary as well. Confirm with
`file` that this is not a plain text file:

```
$ file scope.out
cscope.out: cscope reference data version 15
```

Check if this contains any SDL symbols:

```
$ grep -i "sdl" cscope.out 
cscope 15 $HOME/MikeRepos/sdl/tutorial               0000016071
        ~"SDL.h
SDL_INIT_VIDEO
grep: cscope.out: binary file matches
```

No, there isn't any SDL from the library itself. This only contains symbols in our project source code.

## Cscope database with SDL symbols

A quick fix to add the SDL header symbols is to use the `-Iincdir` option:

```
$ cscope -R -b -I/usr/include/SDL2/
```

The file is much longer:

```
$ wc -l cscope.out 
58186 cscope.out
```

And there are many more matches for `SDL`:

```
$ grep -i "sdl" cscope.out | wc -l
grep: cscope.out: binary file matches
3308
```

## Add symbols for any dependency

I called that a "quick fix" because it only helps us get symbols for `SDL` and it
doesn't lend itself to a universal invocation for mapping in Vim. The better
fix is to add a recipe that tells the compiler to generate a list of header
files in `build/main.d` (`d` is for "dependencies"):

```make
build/main.d: src/main.c | build
	$(CC) $(CFLAGS) -M $^ -MF $@
```

Build `main.d`:

```
$ make build/main.d
```

Inspect the file:

```
$ head -2 build/main.d; echo ---; tail -2 build/main.d
main.o: src/main.c /usr/include/stdc-predef.h /usr/include/stdio.h \
 /usr/include/x86_64-linux-gnu/bits/libc-header-start.h \
---
 /usr/include/SDL2/SDL_timer.h /usr/include/SDL2/SDL_version.h \
 /usr/include/SDL2/SDL_locale.h /usr/include/SDL2/SDL_misc.h
```

Instead of `-Iincdir`, `cscope` has option `-inamefile` where "namefile" is a
list of source file names.

Unfortunately, the output format of gcc `-M` is not compatible with
`-inamefile`, so we cannot simply do `-ibuild/main.d`. We run into a similar
issue with `ctags`. The solution is to write a small utility program that
reformats `build/main.d` for use with `ctags -L` and `cscope -i`.

## Reformat main.d in the next tutorial

In the next tutorial we will make the utility program to reformat
`build/main.d` and generate files `cscope.out` and `tags` that will both
include all of the project dependencies (so far, just SDL and the C standard
library).

Why Cscope and Ctags? Cscope is more precise in what it can jump to, while the
tags file is useful for:

- Vim omnicompletion with `i_Ctrl+X`,`i_Ctrl+O`
- `Ctrl+W`,`}` to open the function declaration in the Vim preview window

## Cscope in Vim

The `man cscope` manual page describes the interactive command line interface
in section "Requesting the initial search". This is neat, but rather than learn
the hotkeys for yet another tool, I prefer to use the Vim interface to
`cscope`. The full documentation is in the Vim help under `cscope` (do `:help
cscope`).

First, here are some `cscope` settings I need in my `vimrc`:

```vim
" Do not use cscope for tag commands.
set nocscopetag

" Go to the first result instead of being prompted to pick a number.
set cscopequickfix=s-,d-,c-,t-,e-,i-,a-

" Put cursor on the symbol then hit Ctrl+\ follwoed by the option letter
<C-\>s  :cs find s <cword><CR>  " SYMBOL
<C-\>g  :cs find g <cword><CR>  " GLOBAL DEFINITION
<C-\>d  :cs find d <cword><CR>  " DEPENDENCY functions used by this func
<C-\>c  :cs find c <cword><CR>  " CALLERS calling this function
<C-\>t  :cs find t <cword><CR>  " TEXT
<C-\>e  :cs find e <cword><CR>  " EGREP
<C-\>f  :cs find f <cword><CR>  " FILE
<C-\>i  :cs find i <cword><CR>  " INCLUDE files including this file
<C-\>a  :cs find a <cword><CR>  " ASSIGN (where a value is assigned)
```

Vim calls the cscope-symbol-cross-reference-file a "`cscope`
database/connection". In the Vimscript snippets below, I will say "`cscope`
database" to refer to the file itself and "connection" to refer to Vim using
the file.

This first snippet creates a `cscope` database and connects to it.

```vim
" Create a new cscope database for this project.
call system("cscope -R -b")
" Connect to the new cscope database file.
execute "cscope add cscope.out"
```

The following snippets are useful in an autocommand to connect to an existing
`cscope` database.

The autocommand triggers off of a `DirChanged`:

```vim
    au DirChanged * :call CscopeAddExisting()
```

Then in `CscopeAddExisting()`, some conditional combination of these snippets
breaks existing `cscope` connections and connects to the existing `cscope`
database. (`cscope.out`) in the new directory.

```vim
" Return 1 if cscope is connected to THIS project, 0 otherwise.
cscope_connection(2, expand(getcwd().'/cscope.out'))
" If connected to THIS project, we are done.

" Return 1 if ANY cscope connection exists, 0 otherwise.
cscope_connection(1, '/cscope.out')
" If we are connected to some other project, we might want to break that
" connection.

" Kill ALL cscope connections
execute "cscope kill -1"

" Return 1 if "cscope.out" does not exist in the current dir, 0 otherwise.
empty(findfile('cscope.out', expand(getcwd())))
" If there is no cscope.out in this directory, there is nothing to connect to.

" Connect to the existing 'cscope.out' file.
execute "cscope add cscope.out"
```

Lastly, it is up to us to update the `cscope` database when we edit source
code. Update the database by simply overwriting the existing database with a
new one: `cscope -R -b`. For Vim integration, we also need to reinitialize the
`cscope` connection with Vim command `cscope reset`:

```vim
    call system("cscope -R -b")
    silent cscope reset
```

I chose Vim shortcuts:

- `;cs` to create and connect to a new `cscope` databse
- `;cu` to update an existing `cscope` database

Vim command line:

- `:cs find <Tab>` shows a list of single-letter options.
- Use this if you want to enter the name of the symbol.

Vim mapping:

- I map these options to `Ctrl+\` followed by the option letter.
- Use this if you want to place your cursor on the symbol and then hit the
  `Ctrl+\`+option (e.g., `Ctrl+\` followed by `g` jumps to the definition).

Options:

* `s` find all occurrences of this symbol
* `a` jump to places where this symbol is assigned a value
* `g` jump to definition of this function/variable
* `c` jump to places where this function is called
* `d` jump to function calls made inside this function
* `f` jump to this file (same as `gf`)
* `i` jump to files that include this file
* `t` find all occurrences of this text

When multiple matches are found, `Alt+Right/Left` jumps me between the matches.
The matches are also shown in the quickfix window where I can visually scan the
matches and hit Enter to jump directly to a match.

## Cscope SDL API lookup within Vim

Here again is that quick fix line from above for including the SDL headers in
`cscope.out`:

```
$ cscope -R -b -I/usr/include/SDL2/
```

Since I only have access to the header files (I only included
`/usr/include/SDL2`), I still cannot jump to the definition of an `SDL`
function, so `:cs find g FUNCTION` does not work (though I could download the
SDL source code if I really wanted this).

But I can still do all of the practical things:

- Jump to a function signature or docstring, such as `SDL_Init`:
    - `:cs find s FUNCTION` (or `Ctrl+\` and `s` with cursor on FUNCTION)
- Find all occurrences of that FUNCTION name:
    - `:cs find t FUNCTION` (or `Ctrl+\` and `t` with cursor on FUNCTION)
    - `:copen` -- there will be a lot of results, so it might be easier to
      browse them in the quickfix window
- Jump to a `#define` definition, such as `SDL_INIT_VIDEO`:
    - `:cs find g SYMBOL` (or `Ctrl+\` and `g` with cursor on SYMBOL)
