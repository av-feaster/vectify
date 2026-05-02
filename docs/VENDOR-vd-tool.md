# Bundled vd-tool (npm)

- **Pinned version:** `4.0.2`
- **npm package:** [vd-tool](https://www.npmjs.com/package/vd-tool)
- **Tarball SHA-256:** `618665c3d1d0fb565a26d39d99c29323f5c61a8f235c40ae4d1b98e8769b9626` (`vd-tool-4.0.2.tgz`)

The app invokes the Unix launcher at `Vendor/vd-tool/bin/vd-tool` inside the target folder (copied to `Contents/Resources/Vendor/vd-tool/` in the built app, with `lib/*.jar` beside `bin/`), not the Node `cli.js` entry.

**Note:** Do not nest this tree under a source folder named `Resources/` at the project root—Xcode’s synchronized file groups can flatten those into the bundle and break the `bin`/`lib` layout. The repo keeps `Vectify/Vectify/Vendor/vd-tool/`.

## Refresh vendor copy

```bash
./scripts/fetch-vd-tool.sh
```

Recomputes the tarball checksum after download; update this doc if the pin changes.
