# Store graphics builder for Training Arena.
#
# Generates the two mandatory Play listing graphics from the project's own
# brand assets (design/arena/arena-mark-1024.png and the bundled Inter fonts):
#
#   design/arena/store/icon-512.png             512x512  32-bit PNG, alpha
#   design/arena/store/feature-graphic-1024x500.png  1024x500 24-bit PNG, no alpha
#
# Deterministic: fixed layout, fixed colors from design/arena/tokens.json, no
# randomness and no network. Re-run to regenerate identical bytes.
#
#   python tools/store/build_store_assets.py
#
# Play requirements enforced here (checked 2026-09-20,
# support.google.com/googleplay/android-developer/answer/9866151):
#   icon: 512x512, 32-bit PNG with alpha, <= 1024 KB
#   feature graphic: 1024x500, JPEG or 24-bit PNG without alpha
import hashlib
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
MARK = ROOT / "design" / "arena" / "arena-mark-1024.png"
OUT_DIR = ROOT / "design" / "arena" / "store"
FONT_DIR = ROOT / "app" / "assets" / "fonts"

CHARCOAL = (0x17, 0x19, 0x1A)
GRAPHITE = (0x24, 0x27, 0x29)
RAISED = (0x30, 0x35, 0x37)
LIME = (0xD6, 0xFF, 0x3F)
SOFT_WHITE = (0xF6, 0xF7, 0xF2)
SECONDARY = (0xB6, 0xBD, 0xB9)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def build_icon() -> Path:
    mark = Image.open(MARK).convert("RGBA")
    if mark.size != (1024, 1024):
        raise SystemExit(f"unexpected mark size {mark.size}")
    icon = mark.resize((512, 512), Image.LANCZOS)
    if icon.mode != "RGBA":
        raise SystemExit("icon must keep the alpha channel")
    path = OUT_DIR / "icon-512.png"
    icon.save(path, format="PNG", optimize=True)
    return path


def build_feature_graphic() -> Path:
    canvas = Image.new("RGB", (1024, 500), CHARCOAL)
    draw = ImageDraw.Draw(canvas)

    # Graphite diagonal band keeps the graphic from blending into Play's dark
    # surface while staying inside the brand palette.
    draw.polygon([(0, 500), (430, 500), (700, 0), (270, 0)], fill=GRAPHITE)
    draw.rectangle([(0, 470), (1024, 500)], fill=RAISED)

    mark = Image.open(MARK).convert("RGBA").resize((280, 280), Image.LANCZOS)
    canvas.paste(mark, (86, 110), mark)

    draw.rectangle([(432, 132), (452, 148)], fill=LIME)
    title = font("Inter-ExtraBold.ttf", 62)
    subtitle = font("Inter-Medium.ttf", 30)
    caption = font("Inter-Regular.ttf", 24)

    draw.text((432, 160), "TRAINING", font=title, fill=SOFT_WHITE)
    draw.text((432, 228), "ARENA", font=title, fill=LIME)
    draw.text((434, 316), "60-second push-up and squat battles", font=subtitle,
              fill=SECONDARY)
    draw.text((434, 360), "Challenge a friend by link. Live, one on one.",
              font=caption, fill=SECONDARY)

    if canvas.mode != "RGB":
        raise SystemExit("feature graphic must have no alpha channel")
    path = OUT_DIR / "feature-graphic-1024x500.png"
    canvas.save(path, format="PNG", optimize=True)
    return path


def verify(icon: Path, graphic: Path) -> None:
    with Image.open(icon) as image:
        assert image.size == (512, 512), image.size
        assert image.mode == "RGBA", image.mode
        assert icon.stat().st_size <= 1024 * 1024, "icon exceeds 1 MB"
    with Image.open(graphic) as image:
        assert image.size == (1024, 500), image.size
        assert image.mode == "RGB", image.mode
    print(f"icon-512.png              {icon.stat().st_size} bytes "
          f"sha256={hashlib.sha256(icon.read_bytes()).hexdigest()}")
    print(f"feature-graphic-1024x500.png {graphic.stat().st_size} bytes "
          f"sha256={hashlib.sha256(graphic.read_bytes()).hexdigest()}")


def main() -> int:
    if not MARK.exists():
        print(f"missing brand mark: {MARK}", file=sys.stderr)
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    graphic = build_feature_graphic()
    verify(icon, graphic)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
