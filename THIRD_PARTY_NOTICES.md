# Third-party notices

Magic Macropad is licensed under [CC BY-NC-SA 4.0](LICENSE). The third-party
material below is **not** covered by that license. Each item keeps its own
license. The Magic name and logo aren't licensed at all; see
[TRADEMARKS.md](TRADEMARKS.md).

## Included in this repository

### Inter (UI text font)

- Files: `mac/MagicKeys/Resources/Inter-{Regular,Medium,SemiBold,Bold}.ttf`
- Copyright 2016 The Inter Project Authors (<https://github.com/rsms/inter>)
- License: SIL Open Font License 1.1. The full text ships next to the fonts in
  [`mac/MagicKeys/Resources/Inter-OFL.txt`](mac/MagicKeys/Resources/Inter-OFL.txt)
  and is bundled into the app.

### Easter-egg sound

- File: `mac/MagicKeys/Resources/fart.mp3`
- Source: Pixabay sound effect #6139 ("wet fart", uploaded by
  freesound_community)
- License: [Pixabay Content License](https://pixabay.com/service/license-summary/).
  It's bundled as an app resource. Don't redistribute it on its own.

### Raspberry Pi code (BSD-3-Clause)

- `firmware/main/ws2812.pio`: the WS2812 driver from
  [pico-examples](https://github.com/raspberrypi/pico-examples), trimmed
- `firmware/pico_sdk_import.cmake`: copied from the
  [Pico SDK](https://github.com/raspberrypi/pico-sdk)

Both are under this license:

```text
Copyright 2020 (c) 2020 Raspberry Pi (Trading) Ltd.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
   disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
   disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Not included

### Advercase (display font)

Magic's brand display face, © Indieground Design. It's commercially licensed
and can't be redistributed, so it isn't in this repo or its history. The app
falls back to the system font without it. Official builds add licensed copies
locally; the paths are gitignored.

## Fetched at build time (not vendored, apart from the two files above)

- [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk): BSD-3-Clause
- [TinyUSB](https://github.com/hathach/tinyusb), pulled in by the Pico SDK: MIT

Firmware binaries you build (`.uf2`) contain code from both. If you distribute
binaries, include their copyright notices.
