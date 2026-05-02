#!/usr/bin/env bash
# Build Vectify Release, produce a .app under build/, wrap in a DMG layout.
# Signing / notarization: set SIGNING_IDENTITY to your "Developer ID Application: …"
# and run notarytool + stapler after this script (see README).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Vectify/Vectify.xcodeproj"
SCHEME="Vectify"
CONFIG="Release"
DERIVED="$ROOT/Vectify/.derivedData-release"
ARCHIVE="$ROOT/build/Vectify.xcarchive"
STAGE="$ROOT/build/dmg-stage"
DMG_OUT="$ROOT/build/Vectify.dmg"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

# Only override CODE_SIGN_IDENTITY when SIGNING_IDENTITY is set (e.g. Developer ID).
# Passing CODE_SIGN_IDENTITY= empty would clear the project's "Apple Development" pin.
ARCHIVE_SIGN_FLAGS=(CODE_SIGNING_ALLOWED=YES)
if [[ -n "$SIGNING_IDENTITY" ]]; then
  ARCHIVE_SIGN_FLAGS=(CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" CODE_SIGNING_ALLOWED=YES)
fi

echo "==> Building $SCHEME ($CONFIG)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED" \
  -archivePath "$ARCHIVE" \
  archive \
  "${ARCHIVE_SIGN_FLAGS[@]}"

APP_SRC="$ARCHIVE/Products/Applications/Vectify.app"
if [[ ! -d "$APP_SRC" ]]; then
  echo "ERROR: archived app not found at $APP_SRC" >&2
  exit 1
fi

echo "==> Staging DMG contents"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_SRC" "$STAGE/"

if [[ -n "$SIGNING_IDENTITY" ]]; then
  echo "==> Signing embedded vd-tool launcher (if present)"
  VD_SH="$STAGE/Vectify.app/Contents/Resources/Vendor/vd-tool/bin/vd-tool"
  if [[ -f "$VD_SH" ]]; then
    chmod +x "$VD_SH"
    codesign --force --sign "$SIGNING_IDENTITY" --options runtime "$VD_SH" || true
  fi
  echo "==> Signing app bundle"
  codesign --force --deep --sign "$SIGNING_IDENTITY" --options runtime "$STAGE/Vectify.app"
fi

echo "==> Creating DMG (UDZO)"
mkdir -p "$(dirname "$DMG_OUT")"
rm -f "$DMG_OUT"
hdiutil create -volname "Vectify" -srcfolder "$STAGE" -ov -format UDZO "$DMG_OUT"

echo "Built: $DMG_OUT"
echo ""
echo "Notarization (example — requires Apple ID app-specific password / API key):"
echo "  xcrun notarytool submit \"$DMG_OUT\" --wait --keychain-profile AC_NOTARY"
echo "  xcrun stapler staple \"$DMG_OUT\""
