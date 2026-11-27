# OpenNOW Android (Flutter port)

This is a **separate Android client** for OpenNOW. It is not part of the Qt
desktop runtime in `opennow-qt/`; it reimplements the shell in Flutter and
keeps the heavy work in native Rust/Android code.

It is a working vertical slice, not a complete port of the desktop app. See
**What is not ported yet** below before planning a release.

## Architecture

```
Dart / Flutter                UI, navigation, state, theme
   │  MethodChannel JSON      (same envelope as docs/core-protocol.md)
   ▼
Kotlin (android/app)          lifecycle, foreground service, SurfaceTexture
   │  JNI                     bounded JSON strings + one Surface handle
   ▼
Rust (rust/opennow_mobile)    bridge state, event queue, stream lifetime
   │  (next) Rust crates      opennow-core library + opennow-streamer platform-android
   ▼
GFN / NVIDIA                  account, catalog, NVST session
```

Hard rules carried over from the desktop app:

- One video surface for the whole session. Stats, menus and exit confirmation
  are stacked **above** `Texture`, never replacing it.
- Local shortcuts (F11, Ctrl+N, Ctrl+G, Escape) are consumed in Dart before
  gameplay keys are forwarded through JNI.
- Every shutdown/focus-loss path releases keys, buttons and the Surface.
- Diagnostics keep receive / assembly / decode / presentation / feedback
  distinguishable — audio continuing does not prove video is healthy.

## What is ported

- **Theme** — all eight desktop theme packs with exact hex values, the accent
  maps, contrast-text calculation, type ramp (26/17/15/13/12/11/10/9), layout
  tokens and `scaleForWindow` from `Theme.qml` / `DesktopTokens.qml`.
- **Shell** — sidebar destinations (Home, Library, Store, Friends, Settings,
  Updates), header search, footer status/update chip, profile tile, responsive
  bottom bar under 900 px.
- **Screens** — home hero + three rails, filterable library grid, store
  marquee/shelves/filters, game-details modal, friends placeholder, updates,
  settings host with a wired Appearance page (theme pack, mode, accent,
  translucency), sign-in screen.
- **Stream surface** — `Texture`-backed video widget, key/text/mouse forwarding,
  in-stream menu, stage-by-stage statistics overlay, exit confirmation.
- **Core transport** — versioned JSON request/response envelope plus an event
  stream, matching `docs/core-protocol.md`.
- **Android host** — permissions, foreground service for live sessions,
  `SurfaceTexture` registered with Flutter's texture registry (zero-copy path),
  Gradle signing hooks and an opt-in `cargo-ndk` build task.

## What is not ported yet

These require changes in the Rust workspace and cannot be faked in Dart:

1. **`opennow-core` is a binary, not a library.** Its modules live in
   `native/opennow-core/src/main.rs`. To make live account/session calls work,
   expose them as `pub mod`s in `lib.rs` and import them from `main.rs`, then
   call them from `rust/opennow_mobile`. Until then the bridge answers
   `core.hello`, `shell.ping`, `settings.*` and `diagnostics.snapshot` locally
   and returns `not_implemented` for GFN calls; the UI falls back to demo data.
2. **No Android streamer platform crate.** `opennow-streamer-platform` has
   Linux/macOS/Windows backends only. Add
   `opennow-streamer-platform-android` implementing MediaCodec decode into the
   `SurfaceTexture`, AAudio/Oboe playout, and Android key/motion/controller
   input. The protocol, transport, queues and recording crates stay unchanged.
3. **Sign-in, catalog, launch, updates, media, friends, bug reports** are UI
   shells awaiting core methods.
4. **Fonts** — Nunito and IBM Plex Mono are referenced by name but not bundled.
   Add them under `fonts/` and register them in `pubspec.yaml` for pixel-accurate
   parity.
5. **Crowdin localization** — copy is still inline English source text; the
   `locales/en.json` source and `npm run locales:check` flow need wiring.
6. **Console-mode UI, onboarding, DLSS overrides, frame generation, recording,
   Decky/Steam Deck integration** are desktop-specific and out of this slice.

## Building

Do not build from this repo root; build from `flutter/`.

```sh
cd flutter
flutter pub get
# Rust bridge (requires cargo + cargo-ndk + Android NDK)
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 \
  -o android/app/src/main/jniLibs build --release \
  --manifest-path rust/opennow_mobile/Cargo.toml
flutter build apk --release --split-per-abi
```

Local debug runs do **not** need Rust: `flutter run` uses the Java/Kotlin side
with the bridge's offline responses.

The repository-level `codemagic.yaml` automates the same steps and publishes
the APKs. Signing uses a Codemagic Android keystore; release builds fall back
to debug signing locally so they still install.

## Verification already run

- `dart analyze` → **No issues found**
- `dart format lib test` → formatted
- No `flutter build` command was executed.

## Tests

`test/widget_test.dart` checks the theme token port and verifies the shell
renders demo data when the core bridge is unavailable.
