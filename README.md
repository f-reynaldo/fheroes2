# fheroes2

**fheroes2** is a recreation of the Heroes of Might and Magic II game engine.

This open source multiplatform project, written from scratch, is designed to reproduce the original game with significant
improvements in gameplay, graphics and logic (including support for high-resolution graphics, improved AI, numerous fixes
and user interface improvements), breathing new life into one of the most addictive turn-based strategy games.

You can find a complete list of all of our changes and enhancements in [**its own wiki page**](https://github.com/ihhub/fheroes2/wiki/Features-and-enhancements-of-the-project).

<p align="center">
    <img src="docs/images/screenshots/screenshot_world_map.png?raw=true" width="820">
</p>

<p align="center">
    <img src="docs/images/screenshots/screenshot_battle.png?raw=true" width="410"> <img src="docs/images/screenshots/screenshot_castle.png?raw=true" width="410">
</p>

## Download and install

Please follow the [**installation guide**](docs/INSTALL.md) to download and install fheroes2.

[![Github Downloads](https://img.shields.io/github/downloads/ihhub/fheroes2/total.svg)](https://github.com/ihhub/fheroes2/releases)

## WebAssembly / Emscripten build

This branch contains an experimental browser build of fheroes2 using Emscripten. The generated application runs entirely in the browser.

### Prerequisites

Install the Emscripten SDK (emsdk) and activate an environment that provides `emcmake` and `em++`:

```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

You also need `cmake` and `make`. **Do not install a native SDL2 development package for this build.** Emscripten provides SDL2, SDL2_mixer and zlib as Emscripten ports. The Emscripten build therefore does not use the repository's native `FindSDL2.cmake` / `FindSDL2_mixer.cmake` package discovery; CMake creates the SDL targets required by the project and Emscripten supplies the actual libraries and headers.

You also need the original Heroes of Might and Magic II data files. fheroes2 does not include the copyrighted game resources. See the [installation guide](docs/INSTALL.md) for information about obtaining supported game data.

### Build

Clone this repository and switch to the `emscripten` branch:

```bash
git clone --branch emscripten https://github.com/f-reynaldo/fheroes2.git
cd fheroes2
```

Configure and compile the project:

```bash
mkdir build
cd build
emcmake cmake ..
cmake --build . -j$(nproc)
```

The CMake step uses Emscripten's SDL2 and SDL2_mixer ports directly; there is no `apt install libsdl2-dev` step and no separate SDL2 SDK to install.

The final browser application is linked with Emscripten. From the build directory, use the link command documented in [EMSCRIPTEN.md](EMSCRIPTEN.md). It produces an `index.html` launcher together with the JavaScript, WebAssembly and preloaded data files required by the application.

### Game data

The browser build needs the original HoMM II resources in the directories preloaded by the Emscripten linker:

- `data/`
- `maps/`
- `files/`

The exact link command in [EMSCRIPTEN.md](EMSCRIPTEN.md) packages these directories into the browser application's virtual filesystem. Make sure the required game data is present before linking.

### Host locally

Do not normally open `index.html` directly with `file://`, because browsers restrict WebAssembly and data loading in that mode. Serve the generated files through an HTTP server instead.

For example, from the directory containing the generated `index.html`:

```bash
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080/
```

Any other static web server works as well, including nginx, Apache, Caddy or GitHub Pages.

### Deploy

The generated output is a static web application. Upload all generated files together to the same web server directory, including:

- `index.html`
- the generated `.js` file
- the generated `.wasm` file
- the Emscripten preloaded data file(s)

Do not rename or omit generated files unless you also update the references emitted by Emscripten.

### Persistent saves and configuration

This branch uses Emscripten `IDBFS` backed by the browser's IndexedDB. fheroes2 user data is loaded before the application starts and synchronized back to browser storage periodically and when the page is hidden or unloaded.

This persists, per browser and per website origin:

- fheroes2 configuration
- save games

Browser data is tied to the site's origin. For example, `localhost:8080` and a production domain use separate IndexedDB storage. Clearing the site's browser storage also removes the persisted configuration and save games.

For implementation and linker details, see [EMSCRIPTEN.md](EMSCRIPTEN.md).

## Copyright

All rights for the original game and its resources belong to former The 3DO Company. These rights were transferred to Ubisoft.
We do not encourage and do not support any form of illegal usage of the original game. We strongly advise to purchase the original
game on [**GOG**](https://www.gog.com) or [**Ubisoft Store**](https://store.ubi.com) platforms. Alternatively, you can download a
free demo version of the game. Please refer to the [**installation guide**](docs/INSTALL.md) for more information.

## License

This project is licensed under the [**GNU General Public License v2.0**](https://github.com/ihhub/fheroes2/blob/master/LICENSE).

Initially, the project was developed on [**sourceforge**](https://sourceforge.net/projects/fheroes2/).

## Contribution and Development

This repository is a place for everyone. If you want to contribute, please read more [**here**](https://github.com/ihhub/fheroes2/wiki/F.A.Q.#q-how-can-i-contribute-to-the-project).

To build the project from source, please follow [**this guide**](docs/DEVELOPMENT.md).

[![Build Status](https://github.com/ihhub/fheroes2/actions/workflows/push.yml/badge.svg)](https://github.com/ihhub/fheroes2/actions)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=ihhub_fheroes2&metric=bugs)](https://sonarcloud.io/dashboard?id=ihhub_fheroes2)
[![Code Smells](https://sonarcloud.io/api/project_badges/measure?project=ihhub_fheroes2&metric=code_smells)](https://sonarcloud.io/dashboard?id=ihhub_fheroes2)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=ihhub_fheroes2&metric=duplicated_lines_density)](https://sonarcloud.io/dashboard?id=ihhub_fheroes2)

To assist with the graphical asset efforts of the project, please look at our [**graphical artist guide**](docs/GRAPHICAL_ASSETS.md).

If you would like to help translating the project, please read the [**translation guide**](docs/TRANSLATION.md).

## Donation

We accept donations via [**Patreon**](https://www.patreon.com/fheroes2), [**PayPal**](https://www.paypal.com/paypalme/fheroes2) or [**Boosty**](https://boosty.to/fheroes2). All donations will be used only for the future project development as we do not
consider this project as a source of income by any means.

[![Donate](https://img.shields.io/badge/Donate-Patreon-green.svg)](https://www.patreon.com/fheroes2)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/fheroes2)
[![Donate](https://img.shields.io/badge/Donate-Boosty-green.svg)](https://boosty.to/fheroes2)

## Contacts

Follow us on social networks: [**Facebook**](https://www.facebook.com/groups/fheroes2) or [**VK**](https://vk.com/fheroes2).
We also have a [**Discord**](https://discord.gg/xF85vbZ) server to discuss fheroes2.

[![Facebook](https://img.shields.io/badge/Facebook-blue.svg)](https://www.facebook.com/groups/fheroes2)
[![VK](https://img.shields.io/badge/VK-blue.svg)](https://vk.com/fheroes2)
[![Discord](https://img.shields.io/discord/733093692860137523.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/xF85vbZ)

## FAQ

You can find answers to the most commonly asked questions on our [**F.A.Q. page**](https://github.com/ihhub/fheroes2/wiki/F.A.Q.).
