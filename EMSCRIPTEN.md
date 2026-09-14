# Emscripten

## Docker

```
docker run --rm -it \
  -v /home/$USER/heroes2/fheroes2:/code/fheroes2 \
  -w /code \
  emscripten/emsdk:latest \
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

`embuilder` must build the SDL2/SDL2_mixer/zlib ports into the sysroot *before*
`emcmake cmake ..` runs, or CMake's `find_package(SDL2)` will fail (this
changed in Emscripten 4.0.9+; older versions built the ports automatically on
first use).

`emmake make -j$(nproc)` (or `emmake ninja`, depending on which generator
your CMake picked) actually compiles the project. Without this step there
are no object files yet to link in the next stage.

## Link

Run this from the `build/` directory:

```
em++ -flto -O3 $(find src/fheroes2/CMakeFiles/fheroes2.dir -name '*.o') \
  src/engine/libengine.a src/thirdparty/libsmacker.a \
  -o index.html \
  -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' \
  -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 \
  -sINITIAL_MEMORY=256MB -sENVIRONMENT=web \
  --preload-file ../data/ --preload-file ../maps/ --preload-file ../files/ \
  --closure 1
```

Notes on the paths above, since they depend on your CMake generator and
directory layout and may need adjusting:

- The object files and static libraries (`libengine.a`, `libsmacker.a`) are
  found relative to `build/`, not relative to `fheroes2.dir` itself as in
  earlier drafts of this doc. Use `find . -name 'libengine.a'` and
  `find . -name 'libsmacker.a'` from `build/` if your layout differs.
- `data/`, `maps/`, `files/` are the original HOMM2 data directories (not
  included in this repo — supply your own copy). The `../` prefix assumes
  they live in the repo root, one level above `build/`; adjust if you've
  placed them elsewhere.
- An optional `--preload-file <path-to-dgguspat>@/etc/timidity` argument can
  be added if you want in-browser MIDI playback via SDL2_mixer's Timidity
  backend. This requires a Gravis UltraSound patch set (e.g.
  `dgguspat.zip` from the idgames archive) that isn't bundled here. Without
  it, the build still works fine; MIDI-based tracks just won't produce
  sound.

## Run

The output uses WASM + `ASYNCIFY`, so it won't run from a `file://` URL.
Serve it over HTTP instead:

```
python3 -m http.server 8000
```

Then open `http://localhost:8000/index.html`.
