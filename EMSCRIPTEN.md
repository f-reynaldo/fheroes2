# Emscripten

## Build

```
mkdir build && cd build
emcmake cmake ..
```

## Link

```
em++ -flto -O3 fheroes2.dir/*/*.o fheroes2.dir/*/*/*.o ../../engine/libengine.a ../../thirdparty/libsmacker.a -o index.html -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 -sINITIAL_MEMORY=256MB -sENVIRONMENT=web --pre-js ../../emscripten_persistence.js --preload-file ../dgguspat@/etc/timidity --preload-file data/ --preload-file maps/ --preload-file files/ --closure 1
```

## Persistent browser storage

The Emscripten build uses IDBFS to persist the browser user's home directory in IndexedDB. This includes fheroes2 configuration under ~/.config/fheroes2 and save games under ~/.local/share/fheroes2/files/save.

Persistent data is loaded before the application starts. Changes are synchronized to IndexedDB periodically and when the page is hidden or unloaded.
