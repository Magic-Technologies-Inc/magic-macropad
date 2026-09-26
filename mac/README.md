# Magic Macropad for Mac

The SwiftUI menu-bar app for the Magic Macropad. It receives key events over
vendor HID, detects tap, double-tap, triple-tap, and hold, and runs the
configured actions using per-app profiles.

The Xcode target and Swift package keep the older names (`MagicKeys`,
`MagicKeysCore`), but the built app is **Magic Macropad.app**.

## Structure

- `MagicKeysCore/`: SwiftPM package with protocol parsing, the gesture engine,
  config models/store, and the shell-script presets. Test with `swift test` (no
  hardware needed).
- `MagicKeys/Sources/`: the app target, with HIDService (IOKit),
  GesturePipeline, ActionEngine, and the SwiftUI UI. XcodeGen generates the
  project.
- `scripts/`: example shell-script actions (Claude CLI helpers).

## Build

You need macOS 15 or later and Xcode 26; the app icon is an Icon Composer
file.

    brew install xcodegen   # once
    xcodegen generate
    xcodebuild -project MagicKeys.xcodeproj -scheme MagicKeys -configuration Debug build

You can also open `MagicKeys.xcodeproj` in Xcode after `xcodegen generate`.

## Fonts

The UI uses two fonts:

- **Inter** is bundled (OFL licensed).
- **Advercase**, Magic's display font, is commercially licensed and **not** in
  this repo. Without it, the app falls back to the system font. If you have a
  license, put `Advercase-Regular.ttf` and `Advercase-Bold.ttf` in
  `MagicKeys/Resources/` (they're gitignored) and rebuild.

## Developing without hardware

The menu-bar panel has a **Test keys** menu. It fires virtual taps,
double-taps, triple-taps, and holds on each key.

## Permissions

- Vendor HID input: none needed.
- Keystroke actions: Accessibility (prompted on first use).
- Failure notifications: Notifications (prompted on first failure).
