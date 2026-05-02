#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${VD_TOOL_VERSION:-4.0.2}"
DEST="$ROOT/Svg2Xml/Svg2Xml/Vendor/vd-tool"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
echo "Fetching vd-tool@${VERSION}..."
npm pack "vd-tool@${VERSION}" >/dev/null
TGZ=(vd-tool-*.tgz)
shasum -a 256 "${TGZ[0]}"
tar -xzf "${TGZ[0]}"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
mv package "$DEST"
chmod +x "$DEST/bin/vd-tool"
echo "Installed to $DEST ($(du -sh "$DEST" | cut -f1))"
