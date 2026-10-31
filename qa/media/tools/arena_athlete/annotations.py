"""High-contrast annotation overlays and poster composition.

Overlays are exported separately (with alpha) so the app can composite form
cues over the loop, and baked into poster fallbacks so a still frame is always
self-explanatory. All cue copy is instructional, never a score or a claim of
computer-vision verification.
"""

from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont

from .geom import normalize
from .rig import Pose
from .spec import FONTS, PALETTE, REPO_ROOT

_FONT_CACHE: dict[tuple[str, int], ImageFont.FreeTypeFont] = {}

LAYOUT_TOP = 108  # keeps cue plates clear of the poster header strip
LAYOUT_MARGIN = 24


def font(weight: str, size: int) -> ImageFont.FreeTypeFont:
    key = (weight, size)
    if key not in _FONT_CACHE:
        _FONT_CACHE[key] = ImageFont.truetype(str(REPO_ROOT / FONTS[weight]), size)
    return _FONT_CACHE[key]


def measure(text: str, text_font: ImageFont.FreeTypeFont, tracking: float = 0.0) -> float:
    if not text:
        return 0.0
    return text_font.getlength(text) + tracking * (len(text) - 1)


def draw_tracked(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    text_font: ImageFont.FreeTypeFont,
    fill,
    tracking: float = 0.0,
) -> float:
    x, y = xy
    for char in text:
        draw.text((x, y), char, font=text_font, fill=fill)
        x += text_font.getlength(char) + tracking
    return x - xy[0]


CUE_TEXT = (*[int(channel * 255) for channel in PALETTE.text], 255)
CUE_LABEL_INK = (*[int(channel * 255) for channel in PALETTE.player_ink], 255)
CUE_LABEL_BG = (*[int(channel * 255) for channel in PALETTE.player], 255)
CUE_PLATE = PALETTE.overlay_rgba
CUE_DARK = (12, 14, 14, 215)
CUE_QUIET = (*[int(channel * 255) for channel in PALETTE.text_quiet], 255)


def plate(
    draw: ImageDraw.ImageDraw,
    anchor: tuple[float, float],
    lines: list[tuple[str, ImageFont.FreeTypeFont, tuple[int, int, int, int], float]],
    align: str = "top-left",
    padding: tuple[int, int] = (16, 12),
    line_gap: int = 6,
) -> tuple[float, float, float, float]:
    widths = [measure(text, text_font, tracking) for text, text_font, _, tracking in lines]
    heights = [text_font.size + 6 for _, text_font, _, _ in lines]
    box_width = max(widths) + padding[0] * 2
    box_height = sum(heights) + line_gap * (len(lines) - 1) + padding[1] * 2
    x, y = anchor
    if align.endswith("center"):
        x -= box_width / 2
    elif align.endswith("right"):
        x -= box_width
    if align.startswith("bottom"):
        y -= box_height
    draw.rounded_rectangle(
        (x, y, x + box_width, y + box_height),
        radius=13,
        fill=CUE_PLATE,
        outline=CUE_LABEL_BG,
        width=3,
    )
    cursor = y + padding[1]
    for (text, text_font, color, tracking), height in zip(lines, heights):
        text_x = x + padding[0]
        if align.endswith("center"):
            text_x = x + (box_width - measure(text, text_font, tracking)) / 2
        draw_tracked(draw, (text_x, cursor), text, text_font, color, tracking)
        cursor += height + line_gap
    return (x, y, x + box_width, y + box_height)


def _plate_box(
    lines: list[tuple[str, ImageFont.FreeTypeFont, tuple[int, int, int, int], float]],
    padding: tuple[int, int],
    line_gap: int,
) -> tuple[float, float]:
    widths = [measure(text, text_font, tracking) for text, text_font, _, tracking in lines]
    heights = [text_font.size + 6 for _, text_font, _, _ in lines]
    return (
        max(widths) + padding[0] * 2,
        sum(heights) + line_gap * (len(lines) - 1) + padding[1] * 2,
    )


def place_plate(
    draw: ImageDraw.ImageDraw,
    lines: list[tuple[str, ImageFont.FreeTypeFont, tuple[int, int, int, int], float]],
    occupancy: np.ndarray | None,
    size: int,
    prefer: str = "top",
    margin: int = 22,
    top_margin: int | None = None,
    padding: tuple[int, int] = (16, 12),
    line_gap: int = 6,
) -> tuple[float, float, float, float]:
    """Draw a plate in whichever corner covers the fewest athlete pixels."""
    box_width, box_height = _plate_box(lines, padding, line_gap)
    resolved_top = top_margin if top_margin is not None else margin
    if prefer == "top":
        candidates = [
            ("top-left", (margin, resolved_top)),
            ("top-right", (size - margin, resolved_top)),
        ]
    else:
        candidates = [
            ("bottom-left", (margin, size - margin)),
            ("bottom-right", (size - margin, size - margin)),
        ]
    best_name, best_anchor, best_score = candidates[0][0], candidates[0][1], None
    if occupancy is not None and len(occupancy):
        for name, anchor in candidates:
            x, y = anchor
            left = x if name.endswith("left") else x - box_width
            top = y if name.startswith("top") else y - box_height
            inside = (
                (occupancy[:, 0] >= left - 6)
                & (occupancy[:, 0] <= left + box_width + 6)
                & (occupancy[:, 1] >= top - 6)
                & (occupancy[:, 1] <= top + box_height + 6)
            )
            score = int(inside.sum())
            if best_score is None or score < best_score:
                best_name, best_anchor, best_score = name, anchor, score
    return plate(draw, best_anchor, lines, align=best_name, padding=padding, line_gap=line_gap)


def label_plate(
    draw: ImageDraw.ImageDraw,
    anchor: tuple[float, float],
    label: str,
    body: list[str],
    align: str = "top-left",
) -> tuple[float, float, float, float]:
    lines: list[tuple[str, ImageFont.FreeTypeFont, tuple[int, int, int, int], float]] = [
        (label, font("extrabold", 30), CUE_LABEL_BG, 2.5)
    ]
    for text in body:
        lines.append((text, font("semibold", 26), CUE_TEXT, 0.0))
    return plate(draw, anchor, lines, align=align)


def micro_plate(
    draw: ImageDraw.ImageDraw,
    anchor: tuple[float, float],
    caption: str,
    body: str,
    align: str = "top-left",
) -> tuple[float, float, float, float]:
    return plate(
        draw,
        anchor,
        [
            (caption, font("bold", 20), CUE_LABEL_BG, 1.4),
            (body, font("medium", 22), CUE_TEXT, 0.0),
        ],
        align=align,
    )


def outline_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    color,
    width: int = 5,
    outline: int = 9,
) -> None:
    draw.line(points, fill=CUE_DARK, width=outline, joint="curve")
    draw.line(points, fill=color, width=width, joint="curve")


def cap(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, fill) -> None:
    draw.ellipse(
        (center[0] - radius - 2, center[1] - radius - 2, center[0] + radius + 2, center[1] + radius + 2),
        fill=CUE_DARK,
    )
    draw.ellipse(
        (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
        fill=fill,
    )


def double_arrow(
    draw: ImageDraw.ImageDraw,
    start: tuple[float, float],
    end: tuple[float, float],
    color,
    width: int = 4,
    head: int = 16,
    outline: int = 8,
) -> None:
    outline_line(draw, [start, end], color, width=width, outline=outline)
    for tip, tail in ((start, end), (end, start)):
        direction = normalize(np.array([tip[0] - tail[0], tip[1] - tail[1], 0.0]))[:2]
        perpendicular = np.array([-direction[1], direction[0]])
        base = np.array(tip) - direction * head
        left = base + perpendicular * head * 0.55
        right = base - perpendicular * head * 0.55
        draw.polygon([tuple(tip), tuple(left), tuple(right)], fill=CUE_DARK)
        inner_tip = np.array(tip) - direction * 3
        inner_base = base - direction * 2
        inner_left = inner_base + perpendicular * head * 0.36
        inner_right = inner_base - perpendicular * head * 0.36
        draw.polygon([tuple(inner_tip), tuple(inner_left), tuple(inner_right)], fill=color)


def angle_arc(
    draw: ImageDraw.ImageDraw,
    center: tuple[float, float],
    start: tuple[float, float],
    end: tuple[float, float],
    radius: float,
    color,
    width: int = 5,
) -> float:
    start_angle = math.degrees(math.atan2(start[1] - center[1], start[0] - center[0]))
    end_angle = math.degrees(math.atan2(end[1] - center[1], end[0] - center[0]))
    delta = (end_angle - start_angle + 360.0) % 360.0
    if delta > 180.0:
        start_angle, end_angle = end_angle, start_angle
        delta = 360.0 - delta
    draw.arc(
        (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
        start_angle,
        start_angle + delta,
        fill=CUE_DARK,
        width=width + 4,
    )
    draw.arc(
        (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
        start_angle,
        start_angle + delta,
        fill=color,
        width=width,
    )
    return delta


def _anchors(pose: Pose, camera) -> dict[str, tuple[float, float]]:
    shoulder_center = pose.heads["chest"] + pose.rotations["chest"] @ np.array([0.0, 0.22, 0.0])
    right_ankle = pose.heads["foot_r"]
    names = {
        "shoulder": pose.heads["upperarm_r"],
        "elbow": pose.heads["forearm_r"],
        "wrist": pose.heads["hand_r"],
        "hip": pose.heads["thigh_r"],
        "knee": pose.heads["shin_r"],
        "ankle": right_ankle,
        "ankle_l": pose.heads["foot_l"],
        "shoulder_center": shoulder_center,
        "pelvis": pose.heads["hips"],
        "head": pose.heads["head"],
        "foot_r_out": right_ankle + np.array([0.0, 0.03, 0.0]),
        "foot_l_out": pose.heads["foot_l"] + np.array([0.0, 0.03, 0.0]),
    }
    keys = list(names.keys())
    screen, _ = camera.project(np.array([names[key] for key in keys]))
    return {key: (float(screen[i][0]), float(screen[i][1])) for i, key in enumerate(keys)}


def draw_annotations(
    exercise: str,
    pose_name: str,
    pose: Pose,
    camera,
    size: int,
    occupancy: np.ndarray | None = None,
    top_margin: int = 22,
) -> Image.Image:
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    lime = CUE_LABEL_BG
    anchors = _anchors(pose, camera)

    def label_lines(label: str, body: list[str]):
        lines = [(label, font("extrabold", 30), CUE_LABEL_BG, 2.5)]
        for text in body:
            lines.append((text, font("semibold", 26), CUE_TEXT, 0.0))
        return lines

    def micro_lines(caption: str, body: str):
        return [
            (caption, font("bold", 22), CUE_LABEL_BG, 1.4),
            (body, font("medium", 22), CUE_TEXT, 0.0),
        ]

    top_plate: list = []
    bottom_plate: list = []

    if exercise == "pushups" and pose_name == "start":
        outline_line(draw, [anchors["shoulder_center"], anchors["pelvis"], anchors["ankle"]], lime)
        cap(draw, anchors["shoulder_center"], 7, lime)
        cap(draw, anchors["ankle"], 7, lime)
        outline_line(
            draw,
            [anchors["wrist"], (anchors["wrist"][0] + 22, anchors["wrist"][1] - 40)],
            lime,
            width=4,
        )
        top_plate = label_lines("START", ["Head to heels in one line"])
        bottom_plate = micro_lines("HANDS UNDER SHOULDERS", "elbows track back, not out")
    elif exercise == "pushups" and pose_name == "end":
        angle_arc(draw, anchors["elbow"], anchors["shoulder"], anchors["wrist"], 56, lime, width=6)
        cap(draw, anchors["elbow"], 6, lime)
        top_plate = label_lines("BOTTOM", ["Elbows about 90°", "Chest near the floor"])
        bottom_plate = micro_lines("ONE STRAIGHT LINE", "hips never sag or pike")
    elif exercise == "squats" and pose_name == "start":
        outline_line(draw, [anchors["shoulder_center"], anchors["ankle"]], lime, width=3)
        foot_left = anchors["foot_l_out"]
        foot_right = anchors["foot_r_out"]
        double_arrow(draw, foot_left, foot_right, lime, width=4)
        mid = ((foot_left[0] + foot_right[0]) / 2, (foot_left[1] + foot_right[1]) / 2)
        outline_line(draw, [mid, (mid[0], mid[1] + 34)], lime, width=3)
        top_plate = label_lines("START", ["Stand tall, chest up"])
        bottom_plate = micro_lines("FEET SHOULDER-WIDTH", "weight through mid-foot")
    elif exercise == "squats" and pose_name == "end":
        knee = anchors["knee"]
        hip = anchors["hip"]
        axis = hip[0] + 62
        outline_line(draw, [(axis, knee[1]), (axis, hip[1])], lime, width=5)
        cap(draw, (axis, knee[1]), 6, lime)
        cap(draw, (axis, hip[1]), 6, lime)
        outline_line(draw, [anchors["shoulder_center"], anchors["pelvis"], anchors["ankle"]], lime, width=3)
        top_plate = label_lines("BOTTOM", ["Hips below knees", "Knees track over toes"])
        bottom_plate = micro_lines("HIP BELOW KNEE", "heels stay down")

    if top_plate:
        place_plate(draw, top_plate, occupancy, size, prefer="top", margin=22, top_margin=top_margin)
    if bottom_plate:
        place_plate(draw, bottom_plate, occupancy, size, prefer="bottom", margin=22)
    return overlay


def poster_header(image: Image.Image, exercise: str, pose_name: str) -> Image.Image:
    """Bake a self-describing header strip into a poster fallback."""
    size = image.size[0]
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, size, 76), fill=(23, 25, 26, 236))
    tag = "FORM GUIDE"
    tag_font = font("black", 19)
    tag_width = measure(tag, tag_font, 1.8)
    draw.rounded_rectangle((LAYOUT_MARGIN, 20, LAYOUT_MARGIN + tag_width + 28, 20 + 36), radius=10, fill=CUE_LABEL_BG)
    draw_tracked(draw, (LAYOUT_MARGIN + 14, 27), tag, tag_font, CUE_LABEL_INK, 1.8)
    title = ("PUSH-UP" if exercise == "pushups" else "SQUAT") + (
        " · START" if pose_name == "start" else " · BOTTOM"
    )
    title_font = font("extrabold", 26)
    title_x = LAYOUT_MARGIN + tag_width + 48
    draw_tracked(draw, (title_x, 24), title, title_font, CUE_TEXT, 1.2)
    note = "instructional, not a rep counter"
    note_font = font("medium", 18)
    note_width = measure(note, note_font, 0.4)
    if title_x + measure(title, title_font, 1.2) + 30 < size - LAYOUT_MARGIN - note_width:
        draw_tracked(
            draw, (size - LAYOUT_MARGIN - note_width, 29), note, note_font, CUE_QUIET, 0.4
        )
    return Image.alpha_composite(image.convert("RGBA"), overlay)
