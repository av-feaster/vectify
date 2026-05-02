#!/usr/bin/env python3
"""
Optimize top-level SVGs with SVGO, convert to Android VectorDrawable XML via ``npx --yes vd-tool``
(same engine family as Android Studio Vector Asset), and write drawable XML.

- **Default repo layout:** ``icons-src/*.svg`` → ``composeApp/src/commonMain/composeResources/drawable/``.
  Override with ``--input-dir`` and ``--output-dir`` (or ``--config`` JSON) for CI or arbitrary folders.
- **Move after success:** off by default (GUI-friendly). Pass ``--move-after-success`` to move each
  processed SVG into ``<input-dir>/converted/`` (legacy script behavior).
- SVGO: only explicit ``*.svg`` paths (chunked). Uses ``scripts/svgo-icons.config.mjs`` when present.
  Pass ``--no-svgo`` to skip optimization.
- Conversion: ``npx --yes vd-tool -c -in <file> -out <dir>`` (requires Node, npm, and Java on PATH).
- Stems are lowercased; naming uses ic_/ice*/icon*/glued-ic rules (see icon_base_from_stem).
- finalize_vector_xml_bytes() post-processes XML (viewport / stroke-only fill).
- Optional ``--archive-xml-dir``: copies each finalized XML into a timestamped subfolder under that path.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path

DRAWABLE_REL = Path("composeApp/src/commonMain/composeResources/drawable")
ICONS_SRC_REL = Path("icons-src")

# Keep SVGO argv under typical OS limits when many icons exist
_SVGO_ARG_CHUNK = 40


def resolve_repo_root(explicit: Path | None) -> Path:
    if explicit is not None:
        return explicit.resolve()
    script = Path(__file__).resolve()
    if script.parent.name == "scripts":
        return script.parent.parent
    return Path.cwd().resolve()


def list_svg_files(icons_src: Path) -> list[Path]:
    return sorted(icons_src.glob("*.svg"))


def icon_base_from_stem(stem_lower: str) -> str:
    """Pure naming rules; stem must already be lowercased."""
    if stem_lower.startswith("ic_"):
        return stem_lower
    if stem_lower.startswith("ice"):
        return "ic_" + stem_lower
    if stem_lower.startswith("icon"):
        return "ic_" + stem_lower
    if len(stem_lower) > 2 and stem_lower.startswith("ic") and stem_lower[2] != "_":
        return "ic_" + stem_lower[2:]
    return "ic_" + stem_lower


def normalize_android_drawable_base(icon_base: str) -> tuple[str | None, str]:
    """
    Normalize to a valid Android drawable base name [a-z][a-z0-9_]*.
    Returns (normalized, "") on success, or (None, error_message).
    """
    s = icon_base.lower()
    s = re.sub(r"[^a-z0-9_]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    if not s:
        return None, "empty resource name after normalization"
    if s[0].isdigit():
        s = "ic_" + s
    if not re.match(r"^[a-z][a-z0-9_]*$", s):
        return None, f"invalid resource name after normalization: {icon_base!r}"
    if len(s) > 200:
        return None, "resource name too long"
    return s, ""


def allocate_output_xml(
    drawable: Path,
    stem_lower: str,
    force: bool,
) -> tuple[Path | None, str, bool]:
    """
    Returns (output_path, error_message, used_collision_suffix).
    error_message non-empty means allocation failed.
    """
    raw_base = icon_base_from_stem(stem_lower)
    icon_base, err = normalize_android_drawable_base(raw_base)
    if err:
        return None, err, False
    primary = drawable / f"{icon_base}.xml"
    if force:
        return primary, "", False
    if not primary.exists():
        return primary, "", False
    n = 1
    while True:
        candidate = drawable / f"{icon_base}_{n}.xml"
        if not candidate.exists():
            return candidate, "", True
        n += 1
        if n > 10_000:
            return None, f"could not allocate free name for {icon_base}", False


def is_valid_svg(path: Path) -> tuple[bool, str]:
    if path.suffix.lower() != ".svg":
        return False, "not an svg file"
    try:
        size = path.stat().st_size
    except OSError as e:
        return False, f"stat failed: {e}"
    if size == 0:
        return False, "empty file"
    try:
        prefix = path.read_bytes()[:65536]
    except OSError as e:
        return False, f"read failed: {e}"
    text = prefix.decode("utf-8", errors="ignore").lstrip("\ufeff \t\r\n")
    if "<svg" not in text.lower():
        return False, "missing <svg> in file header"
    return True, ""


def _default_svgo_config_path() -> Path:
    root = Path(__file__).resolve().parent
    scripts = root / "scripts" / "svgo-icons.config.mjs"
    if scripts.is_file():
        return scripts
    return root / "svgo-icons.config.mjs"


def run_svgo(
    repo_root: Path,
    svg_paths: list[Path],
    *,
    no_svgo: bool,
    svgo_config: Path | None,
) -> bool:
    """Run SVGO on explicit paths only. Returns True if SVGO succeeded or was skipped."""
    if not svg_paths:
        return True
    if no_svgo:
        print("SVGO: skipped (--no-svgo); using original SVG bytes for vd-tool.")
        return True

    config_path = svgo_config if svgo_config is not None else _default_svgo_config_path()
    config_args: list[str] = []
    if config_path.is_file():
        config_args = ["--config", str(config_path.resolve())]
    else:
        print(
            f"WARNING: SVGO config missing ({config_path}); using SVGO defaults.",
            file=sys.stderr,
        )

    for i in range(0, len(svg_paths), _SVGO_ARG_CHUNK):
        chunk = svg_paths[i : i + _SVGO_ARG_CHUNK]
        cmd = ["npx", "--yes", "svgo", *config_args, *[str(p.resolve()) for p in chunk]]
        r = subprocess.run(
            cmd,
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            check=False,
        )
        if r.returncode != 0:
            tail = (r.stderr or r.stdout or "").strip()
            if tail:
                print(f"WARNING: SVGO failed (exit {r.returncode}): {tail[:800]}", file=sys.stderr)
            else:
                print(f"WARNING: SVGO failed (exit {r.returncode})", file=sys.stderr)
            return False
    return True


def finalize_vector_xml_bytes(out_bytes: bytes) -> bytes:
    """
    Some converters omit viewportWidth/viewportHeight; without them Compose scales pathData
    incorrectly and icons render blank. Also fixes stroke-only paths where converters emit
    fillColor #000000 (opaque fill hides the stroke).
    """
    text = out_bytes.decode("utf-8")
    if "android:viewportWidth" not in text:
        w_m = re.search(r'android:width="([\d.]+)dp"', text)
        h_m = re.search(r'android:height="([\d.]+)dp"', text)
        if w_m and h_m:
            vw, vh = w_m.group(1), h_m.group(1)
            text = re.sub(
                r"<vector\s+",
                f'<vector android:viewportWidth="{vw}" android:viewportHeight="{vh}" ',
                text,
                count=1,
            )

    def _fix_stroke_path_tag(m: re.Match) -> str:
        tag = m.group(0)
        if "android:strokeColor" not in tag:
            return tag
        return re.sub(
            r'android:fillColor="#000000"',
            'android:fillColor="#00000000"',
            tag,
            count=1,
        )

    text = re.sub(r"<path\b[^/]*/>", _fix_stroke_path_tag, text)
    return text.encode("utf-8")


def convert_with_vd_tool(repo_root: Path, svg: Path, out_xml: Path) -> bool:
    """
    Android Studio-compatible conversion via npm ``vd-tool`` (requires Java 8+).
    vd-tool writes ``<stem>.xml`` for ``<stem>.svg``; we stage a copy named ``out_xml.stem``.
    """
    try:
        out_xml.parent.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"vd-tool: cannot create output dir {out_xml.parent}: {e}", file=sys.stderr)
        return False

    stem = out_xml.stem
    try:
        with tempfile.TemporaryDirectory(prefix="vd-tool-") as tmp:
            tmp_path = Path(tmp)
            staged_svg = tmp_path / f"{stem}.svg"
            shutil.copy2(svg, staged_svg)
            cmd = [
                "npx",
                "--yes",
                "vd-tool",
                "-c",
                "-in",
                str(staged_svg.resolve()),
                "-out",
                str(tmp_path.resolve()),
            ]
            r = subprocess.run(
                cmd,
                cwd=str(repo_root),
                capture_output=True,
                text=True,
                check=False,
            )
            if r.returncode != 0:
                tail = (r.stderr or r.stdout or "").strip()
                if tail:
                    print(f"vd-tool stderr: {tail[:800]}", file=sys.stderr)
                return False
            generated = tmp_path / f"{stem}.xml"
            if not generated.is_file():
                print(f"vd-tool: expected output missing: {generated}", file=sys.stderr)
                return False
            out_bytes = generated.read_bytes()
    except OSError as e:
        print(f"vd-tool: {e}", file=sys.stderr)
        return False

    _bom = b"\xef\xbb\xbf"
    head = out_bytes.lstrip(_bom + b" \t\r\n")[:8192]
    if b"<vector" not in head:
        print(
            "vd-tool: output did not contain an Android <vector> drawable "
            f"(first bytes: {head[:120]!r})",
            file=sys.stderr,
        )
        return False
    try:
        out_xml.write_bytes(finalize_vector_xml_bytes(out_bytes))
        if out_xml.stat().st_size == 0:
            return False
    except OSError as e:
        print(f"vd-tool: cannot write {out_xml}: {e}", file=sys.stderr)
        return False
    return True


def allocate_xml_archive_run_dir(converted_xml_root: Path) -> Path:
    """
    One directory per script invocation: icons-src/converted-xml/icon_<date>_<time>/.
    If two runs start in the same clock second, use icon_<stamp>_1, _2, …
    """
    converted_xml_root.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    primary = converted_xml_root / f"icon_{stamp}"
    if not primary.exists():
        primary.mkdir(parents=False, exist_ok=True)
        return primary
    n = 1
    while True:
        candidate = converted_xml_root / f"icon_{stamp}_{n}"
        if not candidate.exists():
            candidate.mkdir(parents=False, exist_ok=True)
            return candidate
        n += 1


def unique_dest_in_converted(converted_dir: Path, svg_path: Path) -> Path:
    name = svg_path.name
    dest = converted_dir / name
    if not dest.exists():
        return dest
    stem = svg_path.stem
    suffix = svg_path.suffix
    n = 1
    while True:
        candidate = converted_dir / f"{stem}_{n}{suffix}"
        if not candidate.exists():
            return candidate
        n += 1


def _peek_config_path(argv: list[str]) -> Path | None:
    for i, a in enumerate(argv):
        if a == "--config" and i + 1 < len(argv):
            return Path(argv[i + 1])
        if a.startswith("--config="):
            return Path(a.split("=", 1)[1])
    return None


def _load_json_config(repo_root: Path, argv: list[str]) -> dict:
    cfg_path = _peek_config_path(argv)
    if cfg_path is None:
        return {}
    if not cfg_path.is_absolute():
        cfg_path = (repo_root / cfg_path).resolve()
    if not cfg_path.is_file():
        print(f"ERROR: --config file not found: {cfg_path}", file=sys.stderr)
        raise SystemExit(2)
    return json.loads(cfg_path.read_text(encoding="utf-8"))


def _path_or_none(val: object, base: Path) -> Path | None:
    if val is None or val == "":
        return None
    p = Path(str(val))
    return p.resolve() if p.is_absolute() else (base / p).resolve()


def _argv_has_flag(argv: list[str], flag: str) -> bool:
    if flag in argv:
        return True
    prefix = flag + "="
    return any(a.startswith(prefix) for a in argv)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[1:]
    provisional_root = resolve_repo_root(None)
    cfg = _load_json_config(provisional_root, argv)

    p = argparse.ArgumentParser(
        description=(
            "SVGO + VectorDrawable: SVG folder → Android vector XML (Compose drawable). "
            "Default: repo icons-src → composeResources/drawable. "
            "Converter: npx --yes vd-tool (Java required)."
        ),
        epilog=(
            "Examples:\n"
            "  python3 svg_icons_to_compose_resources.py\n"
            "  python3 svg_icons_to_compose_resources.py --input-dir ./svgs --output-dir ./out\n"
            "  python3 svg_icons_to_compose_resources.py --config ci-svg2xml.json\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--force",
        action="store_true",
        help="Overwrite target XML if it exists (no _1/_2 suffix on drawable name).",
    )
    p.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Repository root (default: parent of scripts/ containing this file, else cwd).",
    )
    p.add_argument(
        "--input-dir",
        type=Path,
        default=None,
        help="Folder of top-level *.svg files (default: <repo-root>/icons-src).",
    )
    p.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Folder for *.xml drawables (default: composeApp/.../composeResources/drawable).",
    )
    p.add_argument(
        "--no-svgo",
        action="store_true",
        help="Skip SVGO (useful when default optimization damages paths before vd-tool).",
    )
    p.add_argument(
        "--svgo-config",
        type=Path,
        default=None,
        help="Custom SVGO config file (.mjs/.js/.yaml). Default: scripts/svgo-icons.config.mjs",
    )
    p.add_argument(
        "--move-after-success",
        action="store_true",
        help="After each successful conversion, move the source SVG to <input-dir>/converted/.",
    )
    p.add_argument(
        "--archive-xml-dir",
        type=Path,
        default=None,
        help="If set, copy each finalized XML into icon_<timestamp>/ under this directory.",
    )
    p.add_argument(
        "--repair-dir",
        type=Path,
        default=None,
        help="With --repair-drawables: directory of *.xml to repair (default: compose drawable dir).",
    )
    p.add_argument(
        "--config",
        type=Path,
        default=None,
        help=(
            "JSON driver (optional): keys input_dir, output_dir, no_svgo, force, "
            "move_after_success, archive_xml_dir, repair_dir, svgo_config. "
            "CLI flags override JSON when both are set. Relative paths resolve against --repo-root."
        ),
    )
    p.add_argument(
        "--repair-drawables",
        action="store_true",
        help="Re-run finalize_vector_xml_bytes on all <vector> XML in the repair dir and exit.",
    )
    args = p.parse_args(argv)
    repo_root = resolve_repo_root(args.repo_root)

    if cfg:
        if args.input_dir is None and cfg.get("input_dir") is not None:
            args.input_dir = _path_or_none(cfg["input_dir"], repo_root)
        if args.output_dir is None and cfg.get("output_dir") is not None:
            args.output_dir = _path_or_none(cfg["output_dir"], repo_root)
        if args.svgo_config is None and cfg.get("svgo_config") is not None:
            args.svgo_config = _path_or_none(cfg["svgo_config"], repo_root)
        if args.archive_xml_dir is None and cfg.get("archive_xml_dir") is not None:
            args.archive_xml_dir = _path_or_none(cfg["archive_xml_dir"], repo_root)
        if args.repair_dir is None and cfg.get("repair_dir") is not None:
            args.repair_dir = _path_or_none(cfg["repair_dir"], repo_root)
        if "force" in cfg and not _argv_has_flag(argv, "--force"):
            args.force = bool(cfg["force"])
        if "no_svgo" in cfg and not _argv_has_flag(argv, "--no-svgo"):
            args.no_svgo = bool(cfg["no_svgo"])
        if "move_after_success" in cfg and not _argv_has_flag(argv, "--move-after-success"):
            args.move_after_success = bool(cfg["move_after_success"])

    return args


def repair_compose_drawables(d: Path) -> int:
    if not d.is_dir():
        print(f"ERROR: drawable dir missing: {d}", file=sys.stderr)
        return 1
    n = 0
    for p in sorted(d.glob("*.xml")):
        try:
            raw = p.read_bytes()
        except OSError as e:
            print(f"WARNING: skip {p.name}: {e}", file=sys.stderr)
            continue
        if b"<vector" not in raw:
            continue
        fixed = finalize_vector_xml_bytes(raw)
        if fixed != raw:
            p.write_bytes(fixed)
            n += 1
            print(f"repaired: {p.name}")
    print(f"Summary: repaired={n} drawable XML file(s)")
    return 0


def main() -> int:
    args = parse_args()
    repo_root = resolve_repo_root(args.repo_root)
    if args.repair_drawables:
        repair_dir = args.repair_dir or (repo_root / DRAWABLE_REL)
        return repair_compose_drawables(repair_dir)

    icons_src = (args.input_dir or (repo_root / ICONS_SRC_REL)).resolve()
    drawable = (args.output_dir or (repo_root / DRAWABLE_REL)).resolve()
    converted_dir = icons_src / "converted"

    if not icons_src.is_dir():
        print(f"ERROR: input SVG directory missing: {icons_src}", file=sys.stderr)
        return 1

    drawable.mkdir(parents=True, exist_ok=True)
    if args.move_after_success:
        converted_dir.mkdir(parents=True, exist_ok=True)

    svg_paths = list_svg_files(icons_src)
    total_found = len(svg_paths)

    if not svg_paths:
        print(f"No top-level .svg files in {icons_src} (0 found).")
        print("Summary: found=0 converted=0 moved=0 collision_suffix=0 failed=0 skipped_invalid=0")
        return 0

    if not run_svgo(
        repo_root,
        svg_paths,
        no_svgo=args.no_svgo,
        svgo_config=args.svgo_config,
    ):
        print("WARNING: continuing with conversions after SVGO failure.", file=sys.stderr)

    xml_archive_run_dir: Path | None = None

    converted = 0
    moved = 0
    collision_suffix = 0
    failed = 0
    skipped_invalid = 0

    for svg in svg_paths:
        stem_lower = svg.stem.lower()
        ok, reason = is_valid_svg(svg)
        if not ok:
            print(f"skipped (invalid): {svg.name} — {reason}")
            skipped_invalid += 1
            continue

        out_xml, alloc_err, used_suffix = allocate_output_xml(
            drawable, stem_lower, force=args.force
        )
        if out_xml is None:
            print(f"failed: {svg.name} — {alloc_err}")
            failed += 1
            continue

        if convert_with_vd_tool(repo_root, svg, out_xml):
            if used_suffix:
                collision_suffix += 1
                print(f"Output exists; writing {out_xml.name} (source {svg.name})")
            print(f"converted: {svg.name} → {out_xml.name}")
            if args.archive_xml_dir is not None:
                archive_root = args.archive_xml_dir.resolve()
                archive_root.mkdir(parents=True, exist_ok=True)
                if xml_archive_run_dir is None:
                    xml_archive_run_dir = allocate_xml_archive_run_dir(archive_root)
                    try:
                        rel = xml_archive_run_dir.relative_to(repo_root)
                    except ValueError:
                        rel = xml_archive_run_dir
                    print(f"XML archive (this run): {rel}")
                try:
                    shutil.copy2(out_xml, xml_archive_run_dir / out_xml.name)
                except OSError as e:
                    print(
                        f"WARNING: archive copy failed for {out_xml.name} → "
                        f"{xml_archive_run_dir}: {e}",
                        file=sys.stderr,
                    )
            converted += 1
            if args.move_after_success:
                try:
                    dest_svg = unique_dest_in_converted(converted_dir, svg)
                    svg.rename(dest_svg)
                    moved += 1
                except OSError as e:
                    print(f"WARNING: converted {out_xml.name} but move failed: {e}", file=sys.stderr)
        else:
            print(f"Conversion failed for {svg}")
            failed += 1
            try:
                if out_xml.exists():
                    out_xml.unlink()
            except OSError:
                pass

    print(
        "Summary: "
        f"found={total_found} "
        f"converted={converted} "
        f"moved={moved} "
        f"collision_suffix={collision_suffix} "
        f"failed={failed} "
        f"skipped_invalid={skipped_invalid}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
