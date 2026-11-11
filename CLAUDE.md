# Tune

Minimal macOS tuner: listens to the mic, shows the nearest note (e.g. A4), cents off (±50), and Hz. Needle is green within 5¢, orange otherwise.

## Layout
- `Tune/Pitch.swift` (pure logic: `detectPitch`, `note`), `Tune/Tune.swift` (app, `Model`, `TunerView`) and `Tune/Logo.swift` (tuning-fork icon art, shared with `tools/main.swift`, which renders the icon). `tools/screenshot.swift` renders the README screenshot offscreen (compile it as `main.swift` with `Tune.swift` minus its `@main` section). No Xcode project, no deps. `build.sh` compiles with `swiftc` into `build/Tune.app` (hand-written Info.plist, ad-hoc `codesign`).

## Decisions
- `detectPitch`: normalized autocorrelation (McLeod-style), first peak within 90% of the best (avoids octave errors), parabolic interpolation, 50-1500 Hz, RMS gate 0.01. Chromatic only, 4096-sample buffers, no smoothing.
- `A4` (440 Hz) is the calibration knob.
- Mic access needs `NSMicrophoneUsageDescription` in Info.plist (in `build.sh`).
- Not notarized; add an Xcode project only if you need distribution.

## Build
`./build.sh && open build/Tune.app`

## Test
`./test.sh` compiles `Tune/Pitch.swift` with `tools/test/main.swift` (synthetic tones, silence, note/cents math).
