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

## Not included

### Advercase (display font)

Magic's brand display face, © Indieground Design. It's commercially licensed
and can't be redistributed, so it isn't in this repo or its history. The app
falls back to the system font without it. Official builds add licensed copies
locally; the paths are gitignored.

## Fetched at build time (not vendored)

- [Raspberry Pi Pico SDK](https://github.com/raspberrypi/pico-sdk): BSD-3-Clause
- [TinyUSB](https://github.com/hathach/tinyusb), pulled in by the Pico SDK: MIT

Firmware binaries you build (`.uf2`) contain code from both. If you distribute
binaries, include their copyright notices.
