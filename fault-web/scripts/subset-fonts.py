#!/usr/bin/env python3
"""Deterministically subset the six bundled Inter TTF weights to WOFF2.

Run from fault-web/:
    python scripts/subset-fonts.py

Inputs (unchanged TTF sources) and outputs share src/app/fonts/.
Requires fontTools + Brotli (already installed).
"""
import pathlib
import subprocess
import sys

WEIGHTS = ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Black"]

FONT_DIR = pathlib.Path(__file__).resolve().parent.parent / "src" / "app" / "fonts"
SOURCE_DIR = FONT_DIR.parent.parent


def source_unicodes() -> str:
    """English site: ASCII, Latin-1 and every character in shipped source copy.

    Regenerate after copy/localization changes. Other characters use the CSS
    system fallback. The original full TTFs remain available for raster assets.
    """
    points = set(range(0x20, 0x7F)) | set(range(0xA0, 0x100))
    for path in SOURCE_DIR.rglob("*"):
        if path.suffix in {".ts", ".tsx", ".css"}:
            points.update(ord(char) for char in path.read_text(encoding="utf-8"))
    return ",".join(f"U+{point:04X}" for point in sorted(points))


def main() -> int:
    missing = [str(FONT_DIR / f"Inter-{w}.ttf") for w in WEIGHTS
               if not (FONT_DIR / f"Inter-{w}.ttf").exists()]
    if missing:
        for path in missing:
            print(f"missing source: {path}", file=sys.stderr)
        return 1

    for weight in WEIGHTS:
        src = FONT_DIR / f"Inter-{weight}.ttf"
        dst = FONT_DIR / f"Inter-{weight}.woff2"
        cmd = [
            sys.executable, "-m", "fontTools.subset", str(src),
            f"--unicodes={source_unicodes()}",
            "--flavor=woff2",
            "--no-recalc-timestamp",
            f"--output-file={dst}",
        ]
        print(" ".join(cmd))
        subprocess.run(cmd, check=True)
        print(f"  -> {dst.name}: {dst.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
