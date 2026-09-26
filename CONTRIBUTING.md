# Contributing

Issues and pull requests are welcome. For anything bigger than a bug fix,
please open an issue first so we can agree on the approach. The design specs
in [`docs/superpowers/specs/`](docs/superpowers/specs/) explain how the pieces
fit together.

## Ground rules

- **The firmware stays dumb.** The device reports only debounced key down/up
  events with a sequence byte. Gesture detection (tap, double, triple, hold)
  and all actions live in the Mac app, so timing can change without a reflash.
- **Protocol changes touch both sides.** A report-format change updates
  `firmware/main/protocol.h`, `mac/MagicKeysCore/Sources/MagicKeysCore/Protocol.swift`,
  and the spec in one pull request.
- **Three keys, everywhere:** CAD, firmware, and app.
- **Keep the Mac app's units separate.** `HIDService` is the only code that
  touches IOKit. `GestureEngine` is pure logic with unit tests. Actions run
  through `ActionEngine`. Config is Codable JSON in `ConfigStore`.
- **Config is a wire format.** `ActionConfig` case names and labels are
  persisted as JSON. Don't rename them without explicit `CodingKeys`.
- **Only add third-party assets whose license allows redistribution.** Record
  any new font, sound, or image in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
  in the same pull request.

## Build and test

- **Mac app:** run `cd mac/MagicKeysCore && swift test` for the core logic,
  then build the app as described in [mac/README.md](mac/README.md). The
  **Test keys** menu fires virtual presses, so you don't need hardware.
- **Firmware:** see [firmware/README.md](firmware/README.md). The host-side
  debounce tests run without a board.
- **CAD:** edit the `.scad` source and re-export the STLs using the commands
  at the top of each file. Commit the source and the exports together.

## Licensing of contributions

By submitting a contribution, you agree that:

1. it is licensed to everyone under this repository's
   [CC BY-NC-SA 4.0](LICENSE) license;
2. you also grant Magic Technologies Inc. a perpetual, worldwide,
   non-exclusive, royalty-free, irrevocable license to use, modify,
   sublicense, and distribute your contribution under any terms, including
   commercial ones; and
3. you have the right to make these grants, because it's your own work or you
   have permission.

Point 2 lets Magic include community improvements in the official product.
