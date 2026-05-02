# Plans and design docs (this repo)

Project-local copies of planning material for **Svgtoxmltool** (SVG → Android VectorDrawable XML for Kotlin Multiplatform Compose, plus the **Vectify** macOS app track).

## Plan documents

| Document | Description |
|----------|-------------|
| [plan-svg2xml-dmg-compose.md](plan-svg2xml-dmg-compose.md) | macOS **Vectify.app** + DMG, vd-tool/Java bundling, **input folder** / **output folder** UX, critical review, phased gates, **screen-by-screen UI**, **Stitch dark design system**, SwiftUI checklist |
| [plan-svg-icon-pipeline-script.md](plan-svg-icon-pipeline-script.md) | Original **Python pipeline** Cursor plan (early `svg2vd` shape); **naming rules**, `icons-src` placement, Gradle excludes — implementation evolved; see script at repo root |

## Stitch UI (HTML + tokens)

- [stitch_svg_vector_toolbox/](../stitch_svg_vector_toolbox/) — dark/light HTML screens and [desktop_professional/DESIGN.md](../stitch_svg_vector_toolbox/desktop_professional/DESIGN.md)

## Code entry points

- [svg_icons_to_compose_resources.py](../svg_icons_to_compose_resources.py) — current CLI (SVGO + **vd-tool** + post-process)
- [svgo-icons.config.mjs](../svgo-icons.config.mjs) — SVGO preset for icons
- [Vectify/](../Vectify/) — Xcode SwiftUI project (**Vectify**)

## Build (Vectify Xcode)

From the machine (outside Cursor’s restricted sandbox, or with full permissions):

```bash
cd Vectify
xcodebuild -scheme Vectify -configuration Debug -destination 'platform=macOS' -derivedDataPath ./.derivedData build
```

Output app: `Vectify/.derivedData/Build/Products/Debug/Vectify.app`.  
`#Preview` macros were replaced with `PreviewProvider` so command-line builds do not depend on the Swift preview plugin server.

## Note on duplicates

A sibling copy of the original macOS plan may exist under Cursor’s global plans directory (`~/.cursor/plans/`). **This `docs/` tree is the version tied to the repository** — refresh it when the plan changes materially.
