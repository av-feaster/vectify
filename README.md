# Vectify

**SVG to XML Converter for Compose**

Vectify is a macOS tool to convert SVG files into Android VectorDrawable XML, optimized for Kotlin Multiplatform Compose (`composeResources/drawable`).

## Features

- Batch SVG → XML conversion
- Compose-ready output
- Optional optimization (SVGO)
- Repair tool for VectorDrawable issues
- Environment diagnostics (Java, vd-tool)

## Usage

1. Select input SVG folder  
2. Select output folder  
3. Click **Convert**

## Xcode project

1. Open `Vectify/Vectify.xcodeproj` in Xcode.  
2. Scheme **Vectify**, destination **My Mac**, Run (⌘R).

Command-line build (project-local DerivedData):

```bash
cd Vectify
xcodebuild -scheme Vectify -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath ./.derivedData \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build
```

### vd-tool in the app bundle

Sources live under `Vectify/Vectify/Vendor/vd-tool/`. A **Run Script** build phase copies that tree to `Contents/Resources/Vendor/vd-tool/` so `bin/vd-tool` and `lib/*.jar` stay together. The Vectify target sets **`ENABLE_USER_SCRIPT_SANDBOXING = NO`** so that copy phase can run.

### Sandboxing

The app uses the **App Sandbox** with **user-selected read/write** and **outgoing network** (optional SVGO / `npx`).

**Java:** the app resolves the JDK via `JAVA_HOME`, `/usr/libexec/java_home`, `/Library/Java/JavaVirtualMachines`, and `java -XshowSettings:properties`.

## Python CLI (`svg_icons_to_compose_resources.py`)

SVGO (optional) → `npx --yes vd-tool` → `finalize_vector_xml_bytes` post-process.

- **Default paths:** `icons-src/*.svg` → `composeApp/src/commonMain/composeResources/drawable/`.
- **Explicit paths:** `--input-dir` / `--output-dir`.
- **Moves** processed SVGs only if **`--move-after-success`**.
- **JSON driver:** `--config path.json` (see `fixtures/vectify-ci.example.json`).

## Post-process golden check

```bash
./scripts/verify_postprocess_golden.sh
```

## DMG / notarization

See `scripts/build-dmg.sh` and Apple signing/notarization documentation.

## Optional: KMP smoke

After conversion, drop generated XML into a minimal Compose module and run on Android and iOS targets as needed.
