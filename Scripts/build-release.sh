#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/Release"
DERIVED="$ROOT/build/DerivedData"

rm -rf "$OUT"
mkdir -p "$OUT"

xcodebuild \
  -project "$ROOT/Verba.xcodeproj" \
  -scheme Verba \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  build

APP="$DERIVED/Build/Products/Release/Verba.app"
cp -R "$APP" "$OUT/Verba.app"
xattr -cr "$OUT/Verba.app"

ditto -c -k --keepParent "$OUT/Verba.app" "$OUT/Verba.zip"

echo "build-release: Verba.app -> $OUT/Verba.app"
echo "build-release: Verba.zip -> $OUT/Verba.zip"
echo
echo "This build is ad-hoc signed (no paid Apple Developer account, no notarization)."
echo "On every Mac you copy it to, the first launch needs a Gatekeeper bypass:"
echo "  Right-click Verba.app -> Open -> Open, or if macOS still refuses:"
echo "  xattr -cr /path/to/Verba.app"
