#!/usr/bin/env bash
# Golden parity: Python finalize_vector_xml_bytes vs fixtures/expected.xml,
# and Swift VectorDrawablePostProcessor (same source as the app) vs the same fixture.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BEFORE="$ROOT/fixtures/postprocess/before.xml"
EXPECTED="$ROOT/fixtures/postprocess/expected.xml"
if [[ ! -f "$BEFORE" || ! -f "$EXPECTED" ]]; then
  echo "Missing golden fixtures under fixtures/postprocess/" >&2
  exit 1
fi

TMP_PY="$(mktemp)"
TMP_SWIFT="$(mktemp)"
TMP_BIN="$(mktemp)"
cleanup() {
  rm -f "$TMP_PY" "$TMP_SWIFT" "$TMP_BIN"
}
trap cleanup EXIT

python3 -c "
from pathlib import Path
import sys
sys.path.insert(0, r'''$ROOT''')
from svg_icons_to_compose_resources import finalize_vector_xml_bytes
raw = Path(r'''$BEFORE''').read_bytes()
Path(r'''$TMP_PY''').write_bytes(finalize_vector_xml_bytes(raw))
"

if ! diff -q "$EXPECTED" "$TMP_PY" >/dev/null; then
  echo "ERROR: Python output does not match fixtures/postprocess/expected.xml" >&2
  diff -u "$EXPECTED" "$TMP_PY" >&2 || true
  exit 1
fi

xcrun swiftc \
  "$ROOT/Vectify/Vectify/VectorDrawablePostProcessor.swift" \
  "$ROOT/scripts/postprocess_driver.swift" \
  -o "$TMP_BIN"
"$TMP_BIN" "$BEFORE" "$TMP_SWIFT"

if ! diff -q "$EXPECTED" "$TMP_SWIFT" >/dev/null; then
  echo "ERROR: Swift post-process output does not match fixtures/postprocess/expected.xml" >&2
  diff -u "$EXPECTED" "$TMP_SWIFT" >&2 || true
  exit 1
fi

echo "postprocess golden OK (Python + Swift vs fixtures/postprocess/expected.xml)"
