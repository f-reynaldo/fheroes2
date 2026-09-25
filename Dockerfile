FROM emscripten/emsdk:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext \
    && rm -rf /var/lib/apt/lists/*

RUN git config --global --add safe.directory /code/fheroes2