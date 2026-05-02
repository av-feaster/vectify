# Plans and design docs (this repo)

Project-local copies of planning material for **Svgtoxmltool** (SVG → Android VectorDrawable XML for Kotlin Multiplatform Compose, plus the **Svg2Xml** macOS app track).

## Plan documents

| Document | Description |
|----------|-------------|
| [plan-svg2xml-dmg-compose.md](plan-svg2xml-dmg-compose.md) | macOS **Svg2Xml.app** + DMG, vd-tool/Java bundling, **input folder** / **output folder** UX, critical review, phased gates, **screen-by-screen UI**, **Stitch dark design system**, SwiftUI checklist |
| [plan-svg-icon-pipeline-script.md](plan-svg-icon-pipeline-script.md) | Original **Python pipeline** Cursor plan (early `svg2vd` shape); **naming rules**, `icons-src` placement, Gradle excludes — implementation evolved; see script at repo root |

## Stitch UI (HTML + tokens)

- [stitch_svg_vector_toolbox/](../stitch_svg_vector_toolbox/) — dark/light HTML screens and [desktop_professional/DESIGN.md](../stitch_svg_vector_toolbox/desktop_professional/DESIGN.md)

## Code entry points

- [svg_icons_to_compose_resources.py](../svg_icons_to_compose_resources.py) — current CLI (SVGO + **vd-tool** + post-process)
- [svgo-icons.config.mjs](../svgo-icons.config.mjs) — SVGO preset for icons
- [Svg2Xml/](../Svg2Xml/) — Xcode SwiftUI project shell

## Build (Svg2Xml Xcode)

From the machine (outside Cursor’s restricted sandbox, or with full permissions):

```bash
cd Svg2Xml
xcodebuild -scheme Svg2Xml -configuration Debug -destination 'platform=macOS' -derivedDataPath ./.derivedData build
```

Output app: `Svg2Xml/.derivedData/Build/Products/Debug/Svg2Xml.app`.  
`#Preview` macros were replaced with `PreviewProvider` so command-line builds do not depend on the Swift preview plugin server.

## Note on duplicates

A sibling copy of the main Svg2Xml plan may exist under Cursor’s global plans directory (`~/.cursor/plans/`). **This `docs/` tree is the version tied to the repository** — refresh it when the plan changes materially.
