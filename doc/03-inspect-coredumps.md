# Tutorial 3

## Calling shutdown() causes a segmentation fault

I noticed a peculiar behavior: if I create a function named `shutdown()` and put `SDL_Quit()` inside of this function:

```c
void shutdown(void) {
    SDL_Quit();
}
int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
    SDL_Init(SDL_INIT_VIDEO);
    shutdown();
    return EXIT_SUCCESS;
}
```

Then I get a segmentation fault:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x `pkg-config --cflags sdl2` src/main.c -o build/main `pkg-config --libs sdl2`
./build/main
make: *** [Makefile:5: run] Segmentation fault (core dumped)
```

## Fix by renaming shutdown()

First, the issue is a namespace conflict: `shutdown()` means something either
to `SDL` or to `stdio`. So the fix is simply to rename this. I use my initials, `MG`:

```c
void MG_shutdown(void) {
    SDL_Quit();
}
int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
    SDL_Init(SDL_INIT_VIDEO);
    MG_shutdown();
    return EXIT_SUCCESS;
}
```

## Explore the core dump file

But, let's leave the function name as `shutdown()` for now and let's try to use the core dump file.

We can use the core dump file with gdb (the GNU Debugger), but first we need to do a few things.

## Generate debug symbols

Add compiler flag `-g` to generate debug symbols:

```make
CFLAGS += -g
```

Build again:

```
$ make
cc -Wall -Wextra -pedantic -std=c2x `pkg-config --cflags sdl2` src/main.c -o build/main `pkg-config --libs sdl2`
./build/main
make: *** [Makefile:5: run] Segmentation fault (core dumped)
```

## Start saving core dump files

By default, Ubuntu does not save core dump files (for security reasons):

```
$ ulimit -c
0
```

To save the core dump file, set the size of the core dump file to "unlimited"
(don't worry, if you forget you changed it, this will automatically reset to
`0` the next time you reboot):

```
$ ulimit -S -c unlimited
```

Generate the core dump again:

```
$ ./build/main 
./build/main
Segmentation fault (core dumped)
```

## Find the core dump file

Ubunutu does not put the cored dump file in your current directory. The
following command will print the location of the latest (`-1`) core dump file:

```
$ coredumpctl info -1 | grep Storage
       Storage: /var/lib/systemd/coredump/core.main.1000.8d3e41325c5b4921912693faec98e027.10840.1756832315000000.zst (present)
```

But we don't really care where it is located. It is a compressed file that
`gdb` cannot use. 

## Extract the core dump file

Decompress the file with `coredumpctl dump` and save it to `build/coredump`:

```
$ coredumpctl dump -1 --output=build/coredump
```

That command also prints the contents of the core dump file to stdout. It
starts with metadata:

```
$ coredumpctl dump -1 --output=build/coredump
           PID: 10997 (main)
           UID: 1000 (you)
           GID: 1000 (you)
        Signal: 11 (SEGV)
     Timestamp: Tue 2025-09-02 13:04:59 EDT (9min ago)
  Command Line: ./build/main
    Executable: /home/you/mike/bricked/home/mike/MikeRepos/sdl/tutorial/build/main
 Control Group: /user.slice/user-1000.slice/user@1000.service/app.slice/app-org.gnome.Terminal.slice/vte-spawn-ac594b98-235d-4947-ad65-7c151e1f06dd.scope
          Unit: user@1000.service
     User Unit: vte-spawn-ac594b98-235d-4947-ad65-7c151e1f06dd.scope
         Slice: user-1000.slice
     Owner UID: 1000 (you)
       Boot ID: 8d3e41325c5b4921912693faec98e027
    Machine ID: e3a67066399c4aaf8695fd984baab880
      Hostname: YOUR-COMPUTER
       Storage: /var/lib/systemd/coredump/core.main.1000.8d3e41325c5b4921912693faec98e027.10997.1756832699000000.zst (present)
     Disk Size: 1.6M
       Message: Process 10997 (main) of user 1000 dumped core.
                
                Found module /home/you/MikeRepos/sdl/tutorial/build/main with build-id: d89a665f1da13226c48721d3b5e1d4f2c8b31140
                Found module linux-vdso.so.1 with build-id: 861246cefcde06926c4842224c8e75022a1a0185
```

After listing all of the modules, it shows a stack trace:

```
                Found module libSDL2-2.0.so.0 with build-id: 4d5b3c4d6ed820f4264d19e6b9dee40106d05359
                Stack trace of thread 10997:
                #0  0x00007f9f64a2cbf3 XCloseIM (libX11.so.6 + 0x53bf3)
                #1  0x00007f9f6509f32d n/a (libSDL2-2.0.so.0 + 0xfa32d)
                #2  0x00007f9f6507a6fb n/a (libSDL2-2.0.so.0 + 0xd56fb)
                #3  0x00007f9f64fd11e4 n/a (libSDL2-2.0.so.0 + 0x2c1e4)
                #4  0x00007f9f64fd14b6 n/a (libSDL2-2.0.so.0 + 0x2c4b6)
                #5  0x0000557320e56196 n/a (/home/you/MikeRepos/sdl/tutorial/build/main + 0x1196)
                #6  0x00007f9f64811715 xcb_disconnect (libxcb.so.1 + 0xd715)
                #7  0x00007f9f649fa8b9 XCloseDisplay (libX11.so.6 + 0x218b9)
                #8  0x00007f9f6509f53e n/a (libSDL2-2.0.so.0 + 0xfa53e)
                #9  0x00007f9f6507a83b n/a (libSDL2-2.0.so.0 + 0xd583b)
                #10 0x00007f9f64fd11e4 n/a (libSDL2-2.0.so.0 + 0x2c1e4)
                #11 0x00007f9f64fd14b6 n/a (libSDL2-2.0.so.0 + 0x2c4b6)
                #12 0x0000557320e56196 n/a (/home/you/MikeRepos/sdl/tutorial/build/main + 0x1196)
                #13 0x0000557320e561ef n/a (/home/you/MikeRepos/sdl/tutorial/build/main + 0x11ef)
                #14 0x00007f9f64c29d90 __libc_start_call_main (libc.so.6 + 0x29d90)
                #15 0x00007f9f64c29e40 __libc_start_main_impl (libc.so.6 + 0x29e40)
                #16 0x0000557320e560c5 n/a (/home/you/MikeRepos/sdl/tutorial/build/main + 0x10c5)
More than one entry matches, ignoring rest.
```

## Use the core dump file with gdb
To debug a program, it's `gdb PROGRAM`. To use the core dump file, it's `gdb
PROGRAM CORE_DUMP_FILE`

```
$ gdb build/main build/coredump
Reading symbols from build/main...
(No debugging symbols found in build/main)
[New LWP 10997]
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
Core was generated by `./build/main'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x00007f9f64a2cbf3 in XCloseIM () from /lib/x86_64-linux-gnu/libX11.so.6
(gdb) 
```

Get a backtrace with `bt`:

```
(gdb) bt
#0  0x00007f9f64a2cbf3 in XCloseIM () from /lib/x86_64-linux-gnu/libX11.so.6
#1  0x00007f9f6509f32d in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#2  0x00007f9f6507a6fb in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#3  0x00007f9f64fd11e4 in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#4  0x00007f9f64fd14b6 in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#5  0x0000557320e56196 in shutdown ()
#6  0x00007f9f64811715 in xcb_disconnect () from /lib/x86_64-linux-gnu/libxcb.so.1
#7  0x00007f9f649fa8b9 in XCloseDisplay () from /lib/x86_64-linux-gnu/libX11.so.6
#8  0x00007f9f6509f53e in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#9  0x00007f9f6507a83b in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#10 0x00007f9f64fd11e4 in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#11 0x00007f9f64fd14b6 in ?? () from /lib/x86_64-linux-gnu/libSDL2-2.0.so.0
#12 0x0000557320e56196 in shutdown ()
#13 0x0000557320e561ef in main ()
```

OK. I don't know that this tell us anything useful. But there you have it.
