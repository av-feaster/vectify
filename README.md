# Svgtoxmltool

Utilities and a macOS app (**Svg2Xml**) for converting **SVG** assets to **Android `vector` XML** suitable for **Kotlin Multiplatform Compose** `commonMain/composeResources/drawable/`.

## Distribution tier (shipping default)

**Tier A (recommended):** The DMG / app bundles **vd-tool** (`bin/` + `lib/` from npm, pinned version; see `docs/VENDOR-vd-tool.md`). Users install a **JDK or JRE 8+** separately (e.g. [Eclipse Temurin](https://adoptium.net/)). The app does **not** install Java or Node for you.

Optional **SVGO** (`Apply SVGO first`) uses **Node** (`npx --yes svgo`) when enabled; Tier A does not require Node for core conversion.

## Svg2Xml.app (Xcode)

1. Open `Svg2Xml/Svg2Xml.xcodeproj` in Xcode.
2. Scheme **Svg2Xml**, destination **My Mac**, Run (⌘R).

Command-line build (uses project-local DerivedData):

```bash
cd Svg2Xml
xcodebuild -scheme Svg2Xml -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath ./.derivedData \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build
```

### vd-tool in the app bundle

Sources live under `Svg2Xml/Svg2Xml/Vendor/vd-tool/` (not under a top-level `Resources/` folder in the target, which Xcode can flatten). A **Run Script** build phase copies that tree to `Contents/Resources/Vendor/vd-tool/` so `bin/vd-tool` and `lib/*.jar` stay together. The Svg2Xml target sets **`ENABLE_USER_SCRIPT_SANDBOXING = NO`** so that copy phase can run.

### Sandboxing

The app uses the **App Sandbox** with **user-selected read/write** (`com.apple.security.files.user-selected.read-write`) so you can pick input and output folders, plus **outgoing network** for optional `npx svgo`.

**Java:** the app resolves the JDK via `JAVA_HOME`, `/usr/libexec/java_home`, `/Library/Java/JavaVirtualMachines`, then `java -XshowSettings:properties`, so JDK **17** and other installs that are not the default for `java_home -v 1.8+` are still detected when `java` works in Terminal.

## Python CLI (`svg_icons_to_compose_resources.py`)

SVGO (optional) → `npx --yes vd-tool` → `finalize_vector_xml_bytes` post-process.

- **Default paths:** `icons-src/*.svg` → `composeApp/src/commonMain/composeResources/drawable/`.
- **Explicit paths:** `--input-dir` / `--output-dir`.
- **Moves** processed SVGs only if **`--move-after-success`** (default is *not* to move; matches the macOS app behavior).
- **XML archive copies** only if **`--archive-xml-dir`** is set.
- **JSON driver:** `--config path.json` (see `fixtures/svg2xml-ci.example.json`).

## Post-process golden check

Keeps Swift `VectorDrawablePostProcessor` aligned with Python `finalize_vector_xml_bytes`:

```bash
./scripts/verify_postprocess_golden.sh
```

## DMG / notarization (release)

See `scripts/build-dmg.sh`. You need an **Apple Developer Program** identity for signing, **notarytool** credentials for notarization, and a **hardened runtime**-compatible signing setup. The script archives Release, builds a DMG, and documents where to plug in `codesign` / `notarytool` / `stapler`.

## Optional: KMP smoke

After conversion, drop generated XML into a minimal Compose module and run on **Android** and **iOS** targets; iOS Compose may support a subset of vector features—treat visual smoke as best-effort beyond XML parity with the Python pipeline.
