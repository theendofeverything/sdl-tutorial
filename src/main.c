#include <stdio.h>
#include "SDL.h"

void MG_shutdown(void)
{
    SDL_Quit();
}
int main(int argc, char** argv) {
    for (int i=0; i<argc; i++) {puts(argv[i]);}
    SDL_Init(SDL_INIT_VIDEO);
    MG_shutdown();
    return EXIT_SUCCESS;
}
