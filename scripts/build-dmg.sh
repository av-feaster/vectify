#!/usr/bin/env bash
# Build Svg2Xml Release, produce a .app under build/, wrap in a DMG layout.
# Signing / notarization: set SIGNING_IDENTITY to your "Developer ID Application: …"
# and run notarytool + stapler after this script (see README).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Svg2Xml/Svg2Xml.xcodeproj"
SCHEME="Svg2Xml"
CONFIG="Release"
DERIVED="$ROOT/Svg2Xml/.derivedData-release"
ARCHIVE="$ROOT/build/Svg2Xml.xcarchive"
STAGE="$ROOT/build/dmg-stage"
DMG_OUT="$ROOT/build/Svg2Xml.dmg"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"

echo "==> Building $SCHEME ($CONFIG)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED" \
  -archivePath "$ARCHIVE" \
  archive \
  CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
  CODE_SIGNING_ALLOWED=YES

APP_SRC="$ARCHIVE/Products/Applications/Svg2Xml.app"
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
  VD_SH="$STAGE/Svg2Xml.app/Contents/Resources/Vendor/vd-tool/bin/vd-tool"
  if [[ -f "$VD_SH" ]]; then
    chmod +x "$VD_SH"
    codesign --force --sign "$SIGNING_IDENTITY" --options runtime "$VD_SH" || true
  fi
  echo "==> Signing app bundle"
  codesign --force --deep --sign "$SIGNING_IDENTITY" --options runtime "$STAGE/Svg2Xml.app"
fi

echo "==> Creating DMG (UDZO)"
mkdir -p "$(dirname "$DMG_OUT")"
rm -f "$DMG_OUT"
hdiutil create -volname "Svg2Xml" -srcfolder "$STAGE" -ov -format UDZO "$DMG_OUT"

echo "Built: $DMG_OUT"
echo ""
echo "Notarization (example — requires Apple ID app-specific password / API key):"
echo "  xcrun notarytool submit \"$DMG_OUT\" --wait --keychain-profile AC_NOTARY"
echo "  xcrun stapler staple \"$DMG_OUT\""
