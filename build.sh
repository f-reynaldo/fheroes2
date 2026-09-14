#!/usr/bin/env bash
#
# build-web.sh — builds fheroes2 for the web via Emscripten.
#
# Run this from the repo root (the directory containing CMakeLists.txt),
# inside the emsdk container, e.g.:
#
#   docker run --rm -it -v $(pwd):/code/fheroes2 -w /code/fheroes2 \
#       emscripten/emsdk:latest bash build-web.sh
#
# It checks that you've supplied your own copy of the original HOMM2 game
# data (data/, maps/, files/) before doing anything — these are copyrighted
# and are never included in the repo, so this script won't fetch or assume
# them. If they're present, it builds everything through to index.html;
# after that, just start a web server and open it in a browser.

set -euo pipefail

# Make sure the emsdk tools (embuilder, emcmake, emmake, em++) are on PATH.
# Depending on how the container is invoked, the image's normal entrypoint
# that sources this may get skipped (e.g. running `bash build-web.sh`
# directly instead of an interactive shell), so do it explicitly here.
if ! command -v embuilder >/dev/null 2>&1; then
    if [ -f /emsdk/emsdk_env.sh ]; then
        echo "==> embuilder not on PATH — sourcing /emsdk/emsdk_env.sh..."
        # shellcheck source=/dev/null
        source /emsdk/emsdk_env.sh
    else
        echo "embuilder not found and /emsdk/emsdk_env.sh doesn't exist."
        echo "Are you running this inside the emscripten/emsdk container?"
        exit 1
    fi
fi

REPO_ROOT="$(pwd)"
BUILD_DIR="$REPO_ROOT/build"

# ---------------------------------------------------------------------------
# 1. Check for the copyrighted game data. We look for a handful of
#    known files rather than just directory existence, so an empty
#    placeholder folder doesn't fool the check.
# ---------------------------------------------------------------------------
missing=()

[ -f "$REPO_ROOT/data/HEROES2.AGG" ]   || missing+=("data/HEROES2.AGG")
[ -d "$REPO_ROOT/maps" ] && [ -n "$(ls -A "$REPO_ROOT/maps" 2>/dev/null)" ] || missing+=("maps/ (empty or missing)")
[ -d "$REPO_ROOT/files" ] && [ -n "$(ls -A "$REPO_ROOT/files" 2>/dev/null)" ] || missing+=("files/ (empty or missing)")

if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing required game data — the original Heroes of Might and Magic II"
    echo "files, which are copyrighted and must be supplied by you (this script"
    echo "will not download them):"
    echo
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    echo
    echo "Place them at:"
    echo "  $REPO_ROOT/data/"
    echo "  $REPO_ROOT/maps/"
    echo "  $REPO_ROOT/files/"
    echo
    echo "Then re-run this script."
    exit 1
fi

echo "Game data found. Proceeding with build..."

# ---------------------------------------------------------------------------
# 2. Configure (only builds the SDL2/SDL2_mixer/zlib ports if not cached
#    already — embuilder skips work it's already done).
# ---------------------------------------------------------------------------
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "==> Building Emscripten ports (sdl2, sdl2_mixer, zlib)..."
embuilder build sdl2
embuilder build sdl2_mixer
embuilder build zlib

echo "==> Configuring with emcmake..."
emcmake cmake ..

# ---------------------------------------------------------------------------
# 3. Compile.
# ---------------------------------------------------------------------------
echo "==> Compiling..."
emmake make -j"$(nproc)"

# ---------------------------------------------------------------------------
# 4. Locate the object files and static libraries. We search rather than
#    hardcode paths, since the exact nesting can vary by CMake generator.
# ---------------------------------------------------------------------------
echo "==> Locating build artifacts..."

mapfile -t OBJ_FILES < <(find . -path '*fheroes2.dir*' -name '*.o')
if [ "${#OBJ_FILES[@]}" -eq 0 ]; then
    echo "No object files found under build/ — the compile step may have failed."
    exit 1
fi

LIBENGINE=$(find . -name 'libengine.a' | head -n1)
LIBSMACKER=$(find . -name 'libsmacker.a' | head -n1)

if [ -z "$LIBENGINE" ] || [ -z "$LIBSMACKER" ]; then
    echo "Could not find libengine.a and/or libsmacker.a under build/."
    exit 1
fi

echo "  Objects: ${#OBJ_FILES[@]} files"
echo "  $LIBENGINE"
echo "  $LIBSMACKER"

# ---------------------------------------------------------------------------
# 5. Optional MIDI patch set (dgguspat). Included automatically if you've
#    placed it at the repo root; otherwise the build proceeds without it
#    and MIDI tracks simply won't produce sound.
# ---------------------------------------------------------------------------
PRELOAD_ARGS=(--preload-file "$REPO_ROOT/data/@data/" \
              --preload-file "$REPO_ROOT/maps/@maps/" \
              --preload-file "$REPO_ROOT/files/@files/")

if [ -d "$REPO_ROOT/dgguspat" ] && [ -n "$(ls -A "$REPO_ROOT/dgguspat" 2>/dev/null)" ]; then
    echo "==> Found dgguspat/ — including MIDI patch set."
    PRELOAD_ARGS+=(--preload-file "$REPO_ROOT/dgguspat@/etc/timidity")
else
    echo "==> No dgguspat/ folder found — building without MIDI patch support."
fi

# ---------------------------------------------------------------------------
# 6. Link.
# ---------------------------------------------------------------------------
echo "==> Linking..."
em++ -flto -O3 "${OBJ_FILES[@]}" \
    "$LIBENGINE" "$LIBSMACKER" \
    -o index.html \
    -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mid"]' \
    -sUSE_ZLIB -sASYNCIFY -sASYNCIFY_STACK_SIZE=81920 \
    -sINITIAL_MEMORY=256MB -sENVIRONMENT=web \
    "${PRELOAD_ARGS[@]}" \
    --closure 1

echo
echo "Build complete: $BUILD_DIR/index.html"
echo
echo "To play, serve this directory over HTTP (WASM won't run from file://):"
echo "  cd $BUILD_DIR && python3 -m http.server 8000"
echo "Then open http://localhost:8000/index.html"
