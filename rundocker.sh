docker build -t fheroes2-emscripten .
docker run --rm -it \
  -v /home/fsanchez/heroes2/fheroes2:/code/fheroes2 \
  -v /home/fsanchez/heroes2/heroes2_data:/code/fheroes2_data \
  -w /code \
  fheroes2-emscripten \
  bash