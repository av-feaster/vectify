# Stitch ↔ Vectify alignment

This document maps the **plan screens** (Stitch-oriented spec) to the **SwiftUI** implementation and shared tokens.

## Global

| Spec | Implementation |
|------|------------------|
| Single window ~900×600 | Default `WindowGroup` sizing; resize freely. |
| SF Symbols toolbar | `Label` + system images in `ConvertView` (`folder`, `play`, etc.). |
| Dark, low-chrome palette | `AppTheme` (`canvas`, `panel`, `accent`, `body`, `secondary`, `danger`). |

## Screen — Convert

| Spec | Implementation |
|------|------------------|
| Input / output folder pickers | `ConversionViewModel.chooseInputFolder` / `chooseOutputFolder` (`NSOpenPanel`). |
| Security-scoped access | `startAccessingSecurityScopedResource()` around I/O in the view model and `RepairView`. |
| Apply SVGO (default off) | `ConversionViewModel.applySvgo` + `SvgoRunner` (`npx --yes svgo`, bundled `svgo-icons.config.mjs`). |
| Overwrite / collision suffixes | `overwrite` → `DrawableNaming.allocateOutputXML(force:)`. |
| Table: name, status, output, message | `ConvertView` `Table` bound to `rows`. |
| Log | `TextEditor` + Clear / Copy. |

## Screen — Repair

| Spec | Implementation |
|------|------------------|
| Folder of XML, batch finalize | `RepairView` → `VectorDrawablePostProcessor.repairDrawables(in:)`. |

## Screen — Environment

| Spec | Implementation |
|------|------------------|
| Java, vd-tool, Node diagnostics | `PrerequisiteChecker` + `EnvironmentDiagnosticsView`. |
| Install guidance | Temurin link + copyable diagnostics. |

## Screen — About

| Spec | Implementation |
|------|------------------|
| Version / build / credits | `AboutView` (`CFBundleShortVersionString`, bundled vd-tool pin). |

## Tokens (`AppTheme`)

Use these for any new UI so the app stays visually consistent with the Stitch intent (dark surfaces, single accent, readable secondary text):

- **Canvas:** `#0F1115` — window background.
- **Panel:** `#171A20` — cards / inset areas.
- **Accent:** `#6C8CFF` — primary actions and key links.
- **Body / secondary:** `#E7EAF0` / `#9AA3B2`.
- **Danger:** `#FF6B6B` — failures in tables or logs.

When Stitch exports exact hex values, prefer updating **`AppTheme`** once rather than scattering literals in views.
