# Vectify

**SVG to XML Converter for Compose**

Vectify is a macOS tool to convert SVG files into Android VectorDrawable XML, optimized for Kotlin Multiplatform Compose (`composeResources/drawable`).

## Screenshots

All images live under [`screenshots/`](screenshots/).

<p align="center">
  <img src="screenshots/Screenshot%202026-05-03%20at%2004.42.04.png" alt="Vectify — screenshot 1" width="960" />
</p>

<p align="center">
  <img src="screenshots/Screenshot%202026-05-03%20at%2004.42.25.png" alt="Vectify — screenshot 2" width="960" />
</p>

<p align="center">
  <img src="screenshots/Screenshot%202026-05-03%20at%2004.42.33.png" alt="Vectify — screenshot 3" width="960" />
</p>

<p align="center">
  <img src="screenshots/Screenshot%202026-05-03%20at%2004.42.56.png" alt="Vectify — screenshot 4" width="960" />
</p>

## Why we built this

With **Kotlin Multiplatform** and **Compose Multiplatform**, you often want **one** shared resource tree—e.g. `composeApp/src/commonMain/composeResources/drawable/`—instead of maintaining separate “Android icons” and “iOS-equivalent” drops that drift out of sync. Put VectorDrawable XML there once; consume it from common code where your setup allows. The wrong place is still your Downloads folder, a temp directory named `final_final_v3`, or wherever Android Studio was feeling curious that day.

**Android Studio** remains the right tool when you need **Vector Asset**’s compatibility and editing workflow: it rewards patience, one file at a time. Vectify is different: **batch** SVG → XML so you get a folder of drawables quickly. It does **not** replace Studio’s import/editor features; it is a **ready path** when you already trust your SVGs and mostly need conversion at scale (plus optional SVGO and logs you can read).

Under the hood the app (and the Python CLI) run **vd-tool**, optional **SVGO**, and the same post-process we use in CI. If your idea of a good Friday is clicking **Vector Asset** until your wrist files for workers’ comp, Vectify will feel disappointingly efficient. Sorry about that.

**Optional discoverability:** If you write long-form posts (Medium, a dev blog, etc.), one link in the app is often enough—set `authorWritingURL` in `Vectify/Vectify/GitHubLinks.swift` to show a **Writing** card in **About**. You do not need to turn this README into a link farm.

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

---

Hope you like it — [**fork**](https://github.com/av-feaster/vectify/fork), [**star**](https://github.com/av-feaster/vectify), or clone the repo and [**get started**](https://github.com/av-feaster/vectify#readme).
