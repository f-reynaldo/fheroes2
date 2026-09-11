# Emscripten

## Build

The Emscripten build uses SDL2, SDL2_mixer and zlib from Emscripten's ports. Do not install native SDL2 development packages and do not try to satisfy `find_package(SDL2)` with a host SDL2 installation.

Configure and build the C++ targets with:

```bash
mkdir build && cd build
emcmake cmake ..
cmake --build . -j$(nproc)
```

The Emscripten-specific CMake configuration creates the SDL2/SDL2main targets expected by the existing project and enables the Emscripten SDL2, SDL2_mixer and zlib ports through compiler flags. The repository's `cmake/FindSDL2_mixer.cmake` is used for native builds; it is intentionally bypassed for Emscripten because it expects native SDL2 headers/libraries.

## Link

The CMake build generates the fheroes2 object files and static libraries. From the `build/src/fheroes2` directory, link the browser application with Emscripten:

```bash
cd build/src/fheroes2
em++ -flto -O3 CMakeFiles/fheroes2.dir/*.o ../engine/libengine.a ../thirdparty/libsmacker.a -o index.html -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 -sINITIAL_MEMORY=256MB -sENVIRONMENT=web --pre-js ../../../emscripten_persistence.js --preload-file ../../../data/ --preload-file ../../../maps/ --preload-file ../../../files/ --closure 1
```

The `--preload-file` paths above assume that the game data directories are in the repository root. If MIDI playback is configured to use a local TiMidity patch set, add the appropriate `--preload-file` mapping for that local directory; the old command in this document referenced a developer-specific `dgguspat` path and was not reproducible on a clean checkout.

The command produces `index.html`, the JavaScript and WebAssembly files, and the preloaded filesystem data needed by the browser build.

## Persistent browser storage

The Emscripten build uses IDBFS to persist the browser user's home directory in IndexedDB. This includes fheroes2 configuration under `~/.config/fheroes2` and save games under `~/.local/share/fheroes2/files/save`.

Persistent data is loaded before the application starts. Changes are synchronized to IndexedDB periodically and when the page is hidden or unloaded.
