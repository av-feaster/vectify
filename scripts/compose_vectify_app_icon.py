#!/usr/bin/env python3
"""
Compose the macOS App Icon from:
  - vectify.png     : detailed "V" + motion + code (transparent outside the mark)
  - vectify_1.png   : squircle reference; TL→BR colors drive the background gradient

Writes icon_*.png into Vectify/Vectify/Assets.xcassets/AppIcon.appiconset/ at all
required macOS sizes (same layout as Xcode expects).

Requires: pip install pillow numpy (see repo .venv-icon or use your own venv).
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parents[1]
SRC_MAIN = REPO / "vectify.png"
SRC_GRAD = REPO / "vectify_1.png"
OUT_DIR = REPO / "Vectify" / "Vectify" / "Assets.xcassets" / "AppIcon.appiconset"
MASTER = 1024
EXPONENT = 5.0  # superellipse sharpness (macOS-ish tile)


def squircle_mask(w: int, h: int, exponent: float = EXPONENT) -> np.ndarray:
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    nx = 2.0 * np.abs(xs / max(w - 1, 1) - 0.5)
    ny = 2.0 * np.abs(ys / max(h - 1, 1) - 0.5)
    inside = (nx**exponent + ny**exponent) <= 1.0
    return (inside.astype(np.float32) * 255.0).astype(np.uint8)


def diagonal_gradient(w: int, h: int, c_tl: np.ndarray, c_br: np.ndarray) -> np.ndarray:
    """RGB float32 (h,w,3), diagonal mix using normalized x+y."""
    t = (np.linspace(0.0, 1.0, w, dtype=np.float64)[None, :] * 0.55 + np.linspace(0.0, 1.0, h, dtype=np.float64)[:, None] * 0.45)
    t = np.clip(t, 0.0, 1.0)[..., None]
    return c_tl.astype(np.float64) * (1.0 - t) + c_br.astype(np.float64) * t


def rgba_to_pil(arr: np.ndarray) -> Image.Image:
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGBA")


def straight_over(dst: np.ndarray, src: np.ndarray) -> np.ndarray:
    """Porter-Duff 'src over dst', straight RGBA, channels in 0–1."""
    d = dst.astype(np.float64)
    s = src.astype(np.float64)
    dr, dg, db, da = d[..., 0], d[..., 1], d[..., 2], d[..., 3]
    sr, sg, sb, sa = s[..., 0], s[..., 1], s[..., 2], s[..., 3]
    out_a = sa + da * (1.0 - sa)
    inv = np.clip(out_a, 1e-9, 1.0)
    or_ = (sr * sa + dr * da * (1.0 - sa)) / inv
    og = (sg * sa + dg * da * (1.0 - sa)) / inv
    ob = (sb * sa + db * da * (1.0 - sa)) / inv
    return np.stack([or_, og, ob, out_a], axis=-1)


def compose_master() -> Image.Image:
    main = Image.open(SRC_MAIN).convert("RGBA")
    ref = Image.open(SRC_GRAD).convert("RGB")

    ref_s = ref.resize((MASTER, MASTER), Image.Resampling.LANCZOS)
    rs = np.array(ref_s).astype(np.float64)
    h, w = rs.shape[:2]
    c_tl = rs[48, 48]
    c_tr = rs[48, w - 49]
    c_bl = rs[h - 49, 48]
    c_br = rs[h - 49, w - 49]
    c_start = (c_tl + c_bl) / 2.0
    c_end = (c_tr + c_br) / 2.0
    grad = diagonal_gradient(w, h, c_start, c_end)

    mask_tile = squircle_mask(w, h).astype(np.float64) / 255.0

    mw, mh = main.size
    scale = min((MASTER * 0.78) / mw, (MASTER * 0.78) / mh)
    nw, nh = max(1, int(mw * scale)), max(1, int(mh * scale))
    fg = main.resize((nw, nh), Image.Resampling.LANCZOS)
    fga = np.array(fg).astype(np.float64) / 255.0
    ox = (MASTER - nw) // 2
    oy = (MASTER - nh) // 2

    under = np.zeros((MASTER, MASTER, 4), dtype=np.float64)
    under[..., 0] = np.clip(grad[..., 0], 0, 255) / 255.0
    under[..., 1] = np.clip(grad[..., 1], 0, 255) / 255.0
    under[..., 2] = np.clip(grad[..., 2], 0, 255) / 255.0
    under[..., 3] = mask_tile

    over = np.zeros_like(under)
    m_slice = mask_tile[oy : oy + nh, ox : ox + nw]
    over[oy : oy + nh, ox : ox + nw, 0] = fga[..., 0]
    over[oy : oy + nh, ox : ox + nw, 1] = fga[..., 1]
    over[oy : oy + nh, ox : ox + nw, 2] = fga[..., 2]
    over[oy : oy + nh, ox : ox + nw, 3] = np.clip(fga[..., 3] * m_slice, 0.0, 1.0)

    comp = straight_over(under, over) * 255.0
    out = rgba_to_pil(comp)
    a_ch = out.split()[3]
    a_soft = a_ch.filter(ImageFilter.GaussianBlur(radius=1.0))
    out.putalpha(a_soft)
    return out


def export_mac_icons(master: Image.Image, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, side in specs:
        im = master.resize((side, side), Image.Resampling.LANCZOS)
        im.save(dest / name, format="PNG")


def main() -> int:
    if not SRC_MAIN.is_file() or not SRC_GRAD.is_file():
        print("Missing vectify.png or vectify_1.png at repo root.", file=sys.stderr)
        return 1
    master = compose_master()
    export_mac_icons(master, OUT_DIR)
    print(f"Wrote macOS AppIcon PNGs to {OUT_DIR}")
    # Optional: sips sanity check
    r = subprocess.run(
        ["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(OUT_DIR / "icon_512x512@2x.png")],
        check=False,
        capture_output=True,
        text=True,
    )
    if r.returncode == 0:
        print(r.stdout.strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
