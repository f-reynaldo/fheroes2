#!/usr/bin/env bash
#
# build-web.sh — builds fheroes2 for the web via Emscripten.
#
# Run this from the repo root (the directory containing CMakeLists.txt),
# inside the emsdk container, e.g.:
#
#   docker run --rm -it -v $(pwd):/code/fheroes2 -w /code/fheroes2 \
#       emscripten/emsdk:latest bash build-web.sh

set -euo pipefail

if ! command -v embuilder >/dev/null 2>&1; then
    if [ -f /emsdk/emsdk_env.sh ]; then
        echo "==> embuilder not on PATH — sourcing /emsdk/emsdk_env.sh..."
        source /emsdk/emsdk_env.sh
    else
        echo "embuilder not found and /emsdk/emsdk_env.sh doesn't exist."
        echo "Are you running this inside the emscripten/emsdk container?"
        exit 1
    fi
fi

REPO_ROOT="$(pwd)"
BUILD_DIR="$REPO_ROOT/build"

missing=()
[ -f "$REPO_ROOT/data/HEROES2.AGG" ] || missing+=("data/HEROES2.AGG")
[ -d "$REPO_ROOT/maps" ] && [ -n "$(ls -A "$REPO_ROOT/maps" 2>/dev/null)" ] || missing+=("maps/ (empty or missing)")
[ -d "$REPO_ROOT/files" ] && [ -n "$(ls -A "$REPO_ROOT/files" 2>/dev/null)" ] || missing+=("files/ (empty or missing)")

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing required game data:"
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    exit 1
fi

echo "Game data found. Proceeding with build..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "==> Building Emscripten ports (sdl2, sdl2_mixer, zlib)..."
embuilder build sdl2
embuilder build sdl2_mixer
embuilder build zlib

echo "==> Configuring with emcmake..."
emcmake cmake ..

echo "==> Compiling..."
emmake make -j"$(nproc)"

echo "==> Locating build artifacts..."
mapfile -t OBJ_FILES < <(find . -path '*fheroes2.dir*' -name '*.o')
if [ "${#OBJ_FILES[@]}" -eq 0 ]; then
    echo "No object files found under build/."
    exit 1
fi

LIBENGINE=$(find . -name 'libengine.a' | head -n1)
LIBSMACKER=$(find . -name 'libsmacker.a' | head -n1)
if [ -z "$LIBENGINE" ] || [ -z "$LIBSMACKER" ]; then
    echo "Could not find libengine.a and/or libsmacker.a."
    exit 1
fi

PRELOAD_ARGS=(--preload-file "$REPO_ROOT/data/@data/" \
              --preload-file "$REPO_ROOT/maps/@maps/" \
              --preload-file "$REPO_ROOT/files/@files/")

if [ -d "$REPO_ROOT/dgguspat" ] && [ -n "$(ls -A "$REPO_ROOT/dgguspat" 2>/dev/null)" ]; then
    PRELOAD_ARGS+=(--preload-file "$REPO_ROOT/dgguspat@/etc/timidity")
fi

echo "==> Linking..."
em++ -flto -O3 "${OBJ_FILES[@]}" \
    "$LIBENGINE" "$LIBSMACKER" \
    -o index.html \
    -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' \
    -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 \
    -sINITIAL_MEMORY=256MB -sENVIRONMENT=web -sFORCE_FILESYSTEM=1 \
    --pre-js "$REPO_ROOT/emscripten_persistence.js" \
    "${PRELOAD_ARGS[@]}" \
    --closure 1

echo
echo "Build complete: $BUILD_DIR/index.html"
echo "Persistent config and saves use browser IndexedDB."
echo
echo "To play:"
echo "  cd $BUILD_DIR && python3 -m http.server 8000"
echo "Then open http://localhost:8000/index.html"
