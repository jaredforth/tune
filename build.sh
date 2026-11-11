#!/bin/sh
# Builds build/Tune.app; run with `open build/Tune.app`.
set -e
cd "$(dirname "$0")"
app=build/Tune.app
rm -rf "$app" && mkdir -p "$app/Contents/MacOS"
swiftc -O -parse-as-library Tune/*.swift -o "$app/Contents/MacOS/Tune"
# App icon: render Logo to a PNG, then build the .icns from resized copies.
t=$(mktemp -d); mkdir "$t/i.iconset"
swiftc tools/main.swift Tune/Logo.swift -o "$t/icon"
"$t/icon" "$t/1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$t/1024.png" --out "$t/i.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$t/1024.png" --out "$t/i.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
mkdir -p "$app/Contents/Resources" && iconutil -c icns "$t/i.iconset" -o "$app/Contents/Resources/Tune.icns"
cp "$t/1024.png" build/icon.png; rm -rf "$t"
cat > "$app/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Tune</string>
<key>CFBundleIdentifier</key><string>dev.jaredforth.tune</string>
<key>CFBundleExecutable</key><string>Tune</string>
<key>CFBundleIconFile</key><string>Tune</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSMicrophoneUsageDescription</key><string>Tune listens to detect pitch.</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
P
codesign --force -s - "$app" 2>/dev/null
