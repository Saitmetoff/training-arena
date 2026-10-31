"""Specification for the Training Arena 3D athlete media package.

Single source of numbers for the procedural mannequin athlete: proportions,
palette (mirrored from design/arena/tokens.json), camera, lighting, render
size and the file layout consumed by the app.

World convention (documented in docs/media/ATHLETE_SPEC.md):
  +X  = athlete forward (facing direction in the bind pose)
  +Y  = world up
  +Z  = athlete right (right = forward x up in a right-handed frame)
"""

from __future__ import annotations

import json
import math
from pathlib import Path

# --------------------------------------------------------------------------
# Repo layout
# --------------------------------------------------------------------------

ASSET_PACKAGE = Path("app/assets/media/athlete")
QA_PACKAGE = Path("qa/media")
TOKENS_PATH = Path("design/arena/tokens.json")
FONT_DIR = Path("app/assets/fonts")

ATHLETE_ID = "arena-mannequin-v1"
ATHLETE_NAME = "Arena Mannequin Athlete v1"
PACKAGE_VERSION = "1.0.0"


def find_repo_root(start: Path | None = None) -> Path:
    """Walk up from this file until the Training Arena checkout root."""
    candidate = (start or Path(__file__)).resolve()
    for folder in [candidate, *candidate.parents]:
        if (folder / "prompts" / "02_3D_ATHLETE_MEDIA.md").is_file() and (
            folder / "app"
        ).is_dir():
            return folder
    raise RuntimeError("Training Arena repo root not found above " + str(candidate))


REPO_ROOT = find_repo_root()


def load_tokens() -> dict:
    """Design tokens are the single source of the product palette."""
    with (REPO_ROOT / TOKENS_PATH).open("r", encoding="utf-8") as handle:
        return json.load(handle)


TOKENS = load_tokens()


def hex_rgb(value: str) -> tuple[float, float, float]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) / 255.0 for i in (0, 2, 4))  # type: ignore[return-value]


class Palette:
    """UI palette from design tokens plus the few media-only material tones."""

    def __init__(self, tokens: dict) -> None:
        color = tokens["color"]
        self.canvas = hex_rgb(color["canvas"])
        self.surface = hex_rgb(color["surface"])
        self.raised = hex_rgb(color["raised"])
        self.line = hex_rgb(color["line"])
        self.line_strong = hex_rgb(color["lineStrong"])
        self.player = hex_rgb(color["player"])
        self.player_ink = hex_rgb(color["playerInk"])
        self.opponent = hex_rgb(color["opponent"])
        self.text = hex_rgb(color["text"])
        self.text_secondary = hex_rgb(color["textSecondary"])
        self.text_quiet = hex_rgb(color["textQuiet"])
        self.positive = hex_rgb(color["positive"])
        self.warning = hex_rgb(color["warning"])
        self.danger = hex_rgb(color["danger"])
        self.overlay_rgba = (23, 25, 26, 200)

        # Media-only material tones derived from the product palette so the
        # athlete reads on a charcoal background. The lime accent is exact.
        self.skin = hex_rgb("#C9AC8E")
        self.skin_shadow = hex_rgb("#9C8268")
        self.hair = hex_rgb("#1B1E20")
        self.kit_top = hex_rgb("#3A4145")
        self.kit_bottom = hex_rgb("#2B3033")
        self.accent = self.player
        self.glove = hex_rgb("#32383A")
        self.shoe = hex_rgb("#22272A")

        # Floor / backdrop are media-only neutral derivations of charcoal.
        self.backdrop_top = hex_rgb("#131516")
        self.backdrop_bottom = hex_rgb("#1D2022")
        self.floor_shadow = (0, 0, 0, 130)


PALETTE = Palette(TOKENS)

# --------------------------------------------------------------------------
# Athlete proportions (metres). Height 1.75 m, roughly 7.5 heads.
# --------------------------------------------------------------------------

PROPORTIONS = {
    "height": 1.75,
    "head_radius": 0.112,
    "head_center_y": 1.638,
    "neck_radius": 0.048,
    "shoulder_y": 1.42,
    "shoulder_z": 0.19,
    "elbow_y": 1.14,
    "wrist_y": 0.88,
    "hip_y": 0.95,
    "hip_z": 0.105,
    "knee_y": 0.51,
    "ankle_y": 0.095,
    "toe_y": 0.03,
    "toe_x": 0.18,
    "torso_chest_y": 1.22,
    "torso_top_y": 1.44,
    "shoulder_width": 0.44,
}

# --------------------------------------------------------------------------
# Skeleton (bind pose = neutral standing start used by the squat demo)
# --------------------------------------------------------------------------

# name, parent, head position, tail position. `_r` is the athlete's right (+Z),
# `_l` is the athlete's left (-Z).
SKELETON: list[tuple[str, str | None, tuple[float, float, float], tuple[float, float, float]]] = [
    ("hips", None, (0.0, 0.98, 0.0), (0.0, 1.08, 0.0)),
    ("spine", "hips", (0.0, 1.08, 0.0), (0.0, 1.22, 0.0)),
    ("chest", "spine", (0.0, 1.22, 0.0), (0.0, 1.44, 0.0)),
    ("neck", "chest", (0.0, 1.44, 0.0), (0.0, 1.55, 0.0)),
    ("head", "neck", (0.0, 1.55, 0.0), (0.0, 1.75, 0.0)),
    ("clavicle_r", "chest", (0.0, 1.42, 0.05), (0.0, 1.42, 0.19)),
    ("upperarm_r", "clavicle_r", (0.0, 1.42, 0.19), (0.0, 1.14, 0.215)),
    ("forearm_r", "upperarm_r", (0.0, 1.14, 0.215), (0.0, 0.88, 0.225)),
    ("hand_r", "forearm_r", (0.0, 0.88, 0.225), (0.02, 0.79, 0.225)),
    ("clavicle_l", "chest", (0.0, 1.42, -0.05), (0.0, 1.42, -0.19)),
    ("upperarm_l", "clavicle_l", (0.0, 1.42, -0.19), (0.0, 1.14, -0.215)),
    ("forearm_l", "upperarm_l", (0.0, 1.14, -0.215), (0.0, 0.88, -0.225)),
    ("hand_l", "forearm_l", (0.0, 0.88, -0.225), (0.02, 0.79, -0.225)),
    ("thigh_r", "hips", (0.0, 0.95, 0.105), (0.0, 0.51, 0.15)),
    ("shin_r", "thigh_r", (0.0, 0.51, 0.15), (0.0, 0.095, 0.16)),
    ("foot_r", "shin_r", (0.0, 0.095, 0.16), (0.18, 0.03, 0.162)),
    ("thigh_l", "hips", (0.0, 0.95, -0.105), (0.0, 0.51, -0.15)),
    ("shin_l", "thigh_l", (0.0, 0.51, -0.15), (0.0, 0.095, -0.16)),
    ("foot_l", "shin_l", (0.0, 0.095, -0.16), (0.18, 0.03, -0.162)),
]

BONE_NAMES = [bone[0] for bone in SKELETON]
BONE_PARENT = {bone[0]: bone[1] for bone in SKELETON}
BONE_HEAD = {bone[0]: bone[2] for bone in SKELETON}
BONE_TAIL = {bone[0]: bone[3] for bone in SKELETON}

PELVIS_POINT = (0.0, 0.95, 0.0)  # midpoint between hip joints
SHOULDER_CENTER = BONE_TAIL["chest"]  # (0, 1.44, 0)
PELVIS_OFFSET = BONE_HEAD["hips"][1] - PELVIS_POINT[1]  # pelvis point -> hips bone head

TORSO_LENGTH = math.dist(PELVIS_POINT, SHOULDER_CENTER)
THIGH_LENGTH = math.dist(BONE_HEAD["thigh_r"], BONE_TAIL["thigh_r"])
SHIN_LENGTH = math.dist(BONE_HEAD["shin_r"], BONE_TAIL["shin_r"])
FOOT_LENGTH = math.dist(BONE_HEAD["foot_r"], BONE_TAIL["foot_r"])
LEG_LENGTH = THIGH_LENGTH + SHIN_LENGTH
UPPERARM_LENGTH = math.dist(BONE_HEAD["upperarm_r"], BONE_TAIL["upperarm_r"])
FOREARM_LENGTH = math.dist(BONE_HEAD["forearm_r"], BONE_TAIL["forearm_r"])
HAND_LENGTH = math.dist(BONE_HEAD["hand_r"], BONE_TAIL["hand_r"])

# --------------------------------------------------------------------------
# Camera: one camera for both exercises so the athlete never changes size or
# angle between push-up and squat. Azimuth is measured from the athlete's
# forward (+X) toward their right (+Z); the camera therefore sits front-right
# of the athlete and shows a three-quarter side view.
# --------------------------------------------------------------------------

CAMERA = {
    "azimuth_deg": 70.0,
    "elevation_deg": 9.0,
    "fov_deg": 30.0,
    "target": (0.72, 0.55, 0.0),
    "distance": 6.0,  # solved during build; recorded in ATHLETE_SPEC.md
    "safe_area": 0.84,  # fraction of the frame the silhouette may fill
    # Lateral nudge (metres along the screen-right axis) that keeps a clean
    # gutter for annotation plates without changing angle, lens or scale.
    "target_shift_screen": {"pushups": 0.0, "squats": 0.26},
}


def _camera_basis() -> tuple[tuple[float, float, float], tuple[float, float, float], tuple[float, float, float]]:
    """World-space view direction (target -> eye), screen right and up."""
    azimuth = math.radians(CAMERA["azimuth_deg"])
    elevation = math.radians(CAMERA["elevation_deg"])
    view = (
        math.cos(elevation) * math.cos(azimuth),
        math.sin(elevation),
        math.cos(elevation) * math.sin(azimuth),
    )
    # screen right = normalize(view x world up)
    right = (view[2], 0.0, -view[0])
    length = math.hypot(right[0], right[2])
    right = (right[0] / length, 0.0, right[2] / length)
    return view, right


def _normalized(vector: tuple[float, float, float]) -> tuple[float, float, float]:
    length = math.sqrt(sum(component * component for component in vector))
    return tuple(component / length for component in vector)


_VIEW, _SCREEN_RIGHT = _camera_basis()
_UP = (0.0, 1.0, 0.0)


def _light(mix_view: float, mix_right: float, mix_up: float) -> tuple[float, float, float]:
    """Blend a direction the surface can face to receive this light."""
    return _normalized(
        (
            _VIEW[0] * mix_view + _SCREEN_RIGHT[0] * mix_right + _UP[0] * mix_up,
            _VIEW[1] * mix_view + _SCREEN_RIGHT[1] * mix_right + _UP[1] * mix_up,
            _VIEW[2] * mix_view + _SCREEN_RIGHT[2] * mix_right + _UP[2] * mix_up,
        )
    )


# A fixed three-light studio rig expressed in camera space, so the athlete is
# lit identically in every exercise and from every screen it appears on.
LIGHTING = {
    "key": {"dir": _light(0.85, -0.55, 1.05), "color": (1.0, 0.975, 0.93), "intensity": 0.88},
    "fill": {"dir": _light(0.90, 0.40, 0.15), "color": (0.74, 0.80, 0.84), "intensity": 0.45},
    "rim": {"dir": _light(-0.85, -0.15, 0.45), "color": (0.84, 1.0, 0.30), "intensity": 0.55},
    "ambient": {"color": (0.24, 0.26, 0.28), "intensity": 1.0},
    "specular": {"skin": 0.06, "accent": 0.30, "default": 0.08, "shininess": 24.0},
}

RENDER = {
    "size": 512,
    "supersample": 2,
    "fps": 25,
    "webp_quality": 84,
    "poster_png_optimize": True,
}

FONTS = {
    "black": FONT_DIR / "Inter-Black.ttf",
    "extrabold": FONT_DIR / "Inter-ExtraBold.ttf",
    "bold": FONT_DIR / "Inter-Bold.ttf",
    "semibold": FONT_DIR / "Inter-SemiBold.ttf",
    "medium": FONT_DIR / "Inter-Medium.ttf",
    "regular": FONT_DIR / "Inter-Regular.ttf",
}

# --------------------------------------------------------------------------
# Exercise metadata. Wire names must match ArenaExercise in
# app/lib/domain/arena_types.dart ("pushups", "squats").
# --------------------------------------------------------------------------

EXERCISES = {
    "pushups": {
        "wire": "pushups",
        "label": "Push-up",
        "clip": "PushUp_Demo",
        "stem": "pushup",
        "duration_s": 2.4,
        "loop": True,
    },
    "squats": {
        "wire": "squats",
        "label": "Squat",
        "clip": "Squat_Demo",
        "stem": "squat",
        "duration_s": 3.0,
        "loop": True,
    },
}

# --------------------------------------------------------------------------
# Size budgets (bytes) enforced by qa/media/tools/validate_media_package.py
# --------------------------------------------------------------------------

BUDGETS = {
    "package_total": 3_500_000,
    "glb": 400_000,
    "loop_mp4": 450_000,
    "loop_webp": 900_000,
    "poster_webp": 90_000,
    "poster_png": 220_000,
    "frame_webp": 70_000,
    "overlay_webp": 60_000,
}

# Asset roots (as bundled by Flutter)
ASSET_ROOT = REPO_ROOT / ASSET_PACKAGE
MODELS_DIR = ASSET_ROOT / "models"
LOOPS_DIR = ASSET_ROOT / "loops"
POSTERS_DIR = ASSET_ROOT / "posters"
FRAMES_DIR = ASSET_ROOT / "frames"
OVERLAYS_DIR = ASSET_ROOT / "overlays"
QA_ROOT = REPO_ROOT / QA_PACKAGE
