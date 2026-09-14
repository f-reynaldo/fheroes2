# Emscripten

## Docker

```
docker run --rm -it \
  -v /home/$USER/heroes2/fheroes2:/code/fheroes2 \
  -w /code \
  emscripten/emsdk:latest
```

## Build

```
mkdir build && cd build
embuilder build sdl2
embuilder build sdl2_mixer
embuilder build zlib
emcmake cmake ..
emmake make -j$(nproc)
```

## Link

Run this from the `build/` directory:

```
em++ -flto -O3 $(find src/fheroes2/CMakeFiles/fheroes2.dir -name '*.o') \
  src/engine/libengine.a src/thirdparty/libsmacker.a \
  -o index.html \
  -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' \
  -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 \
  -sINITIAL_MEMORY=256MB -sENVIRONMENT=web -sFORCE_FILESYSTEM=1 \
  --pre-js ../emscripten_persistence.js \
  --preload-file ../data/ --preload-file ../maps/ --preload-file ../files/ \
  --closure 1
```

## Persistent browser storage

The link command **must include** `--pre-js ../emscripten_persistence.js`. The script mounts Emscripten's `/home/web_user` directory on `IDBFS`, which is backed by browser IndexedDB.

fheroes2 stores:
- configuration: `/home/web_user/.config/fheroes2`
- save games: `/home/web_user/.local/share/fheroes2/files/save`

Persistent data is loaded before `main()` starts and is periodically synchronized back to IndexedDB.

## Run

Serve the output over HTTP:

```
python3 -m http.server 8000
```

Then open `http://localhost:8000/index.html`.
