"""Reviewer-facing QA artifacts for the athlete media package.

Reads the built assets back and produces the contact sheets, identity strip,
360dp legibility proof, loop key frames and the GLB round-trip check that a
human reviewer compares before signing docs/media/FORM_REVIEW.md.

Usage (from the repository root):
    python qa/media/tools/qa_report.py
"""

from __future__ import annotations

import json
import math
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_athlete import animation, glb, render  # noqa: E402
from arena_athlete.annotations import CUE_LABEL_BG, CUE_TEXT, font, measure, draw_tracked  # noqa: E402
from arena_athlete.mesh import AthleteMesh, build_mesh  # noqa: E402
from arena_athlete.rig import Pose, bone_index, pose_vertices, solve  # noqa: E402
from arena_athlete.render import Camera  # noqa: E402
from arena_athlete.spec import (  # noqa: E402
    ASSET_ROOT,
    BONE_HEAD,
    BONE_NAMES,
    EXERCISES,
    FRAMES_DIR,
    LOOPS_DIR,
    PALETTE,
    POSTERS_DIR,
    QA_ROOT,
    REPO_ROOT,
)

MARGIN = 26
LABEL_HEIGHT = 62


def _load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def _label_strip(width: int, title: str, subtitle: str) -> Image.Image:
    strip = Image.new("RGB", (width, LABEL_HEIGHT), tuple(int(c * 255) for c in PALETTE.canvas))
    draw = ImageDraw.Draw(strip)
    draw_tracked(draw, (2, 8), title, font("extrabold", 26), CUE_TEXT, 1.0)
    draw_tracked(draw, (2, 38), subtitle, font("medium", 19), CUE_TEXT, 0.6)
    return strip


def build_contact_sheet() -> Path:
    cells: list[tuple[str, str, Image.Image]] = []
    for exercise, config in EXERCISES.items():
        for pose_name in ("start", "mid", "end"):
            cells.append(
                (
                    config["label"].upper(),
                    pose_name.upper(),
                    _load(FRAMES_DIR / f"{config['stem']}_{pose_name}.webp"),
                )
            )
    cell = 512
    width = MARGIN + 3 * (cell + MARGIN)
    height = MARGIN + 2 * (cell + LABEL_HEIGHT + MARGIN)
    sheet = Image.new("RGB", (width, height), (12, 14, 14))
    for index, (title, subtitle, image) in enumerate(cells):
        row, column = divmod(index, 3)
        x = MARGIN + column * (cell + MARGIN)
        y = MARGIN + row * (cell + LABEL_HEIGHT + MARGIN)
        sheet.paste(image, (x, y))
        sheet.paste(_label_strip(cell, title, subtitle), (x, y + cell))
    path = QA_ROOT / "contact_sheet_athlete.png"
    sheet.save(path)
    return path


def build_identity_strip(heads: dict[tuple[str, str], tuple[float, float]]) -> Path:
    crops = []
    for exercise, config in EXERCISES.items():
        for pose_name in ("start", "end"):
            image = _load(FRAMES_DIR / f"{config['stem']}_{pose_name}.webp")
            head_x, head_y = heads[(exercise, pose_name)]
            box = (
                int(max(0, head_x - 170)),
                int(max(0, head_y - 96)),
                int(min(512, head_x + 170)),
                int(min(512, head_y + 104)),
            )
            crop = image.crop(box).resize((340, 200))
            crops.append((f"{config['label'].upper()} {pose_name.upper()}", crop))
    width = MARGIN + len(crops) * (340 + MARGIN)
    height = MARGIN + 200 + LABEL_HEIGHT + MARGIN
    strip = Image.new("RGB", (width, height), (12, 14, 14))
    for index, (title, image) in enumerate(crops):
        x = MARGIN + index * (340 + MARGIN)
        strip.paste(image, (x, MARGIN))
        strip.paste(_label_strip(340, title, "same athlete check"), (x, MARGIN + 200))
    path = QA_ROOT / "identity_strip.png"
    strip.save(path)
    return path


def build_poster_sheet() -> Path:
    size = 512
    width = MARGIN + 2 * (size + MARGIN)
    height = MARGIN + 2 * (size + LABEL_HEIGHT + MARGIN)
    sheet = Image.new("RGB", (width, height), (12, 14, 14))
    order = [
        ("pushups", "start"),
        ("pushups", "end"),
        ("squats", "start"),
        ("squats", "end"),
    ]
    for index, (exercise, pose_name) in enumerate(order):
        stem = EXERCISES[exercise]["stem"]
        image = _load(POSTERS_DIR / f"{stem}_{pose_name}.webp")
        row, column = divmod(index, 2)
        x = MARGIN + column * (size + MARGIN)
        y = MARGIN + row * (size + LABEL_HEIGHT + MARGIN)
        sheet.paste(image, (x, y))
        sheet.paste(
            _label_strip(size, f"{EXERCISES[exercise]['label'].upper()} {pose_name.upper()}", "fallback poster"),
            (x, y + size),
        )
    path = QA_ROOT / "contact_sheet_posters.png"
    sheet.save(path)
    return path


def legibility() -> dict:
    """Measure rendered type at the 360dp screen width and at the 328dp media card."""
    widths = {"screen_360dp": 360.0, "media_card_328dp": 328.0}
    rows = [
        ("label START/BOTTOM", 30, 2.5),
        ("cue body", 26, 0.0),
        ("micro caption", 22, 1.4),
        ("micro body", 22, 0.0),
        ("header title", 26, 1.2),
    ]
    measurements = []
    for name, px, tracking in rows:
        entry = {"text": name, "px_at_512": px}
        for label, width in widths.items():
            effective = (px + tracking) * (width / 512.0)
            entry[label] = round(effective, 1)
            entry[f"{label}_meets_14dp"] = effective >= 14.0
        measurements.append(entry)

    poster = _load(POSTERS_DIR / "pushup_end.webp")
    scaled = poster.resize((360, 360), Image.LANCZOS)
    canvas = Image.new("RGB", (MARGIN + 512 + MARGIN + 360 + MARGIN, 512 + MARGIN + LABEL_HEIGHT), (12, 14, 14))
    canvas.paste(poster, (MARGIN, MARGIN))
    canvas.paste(scaled, (MARGIN + 512 + MARGIN, MARGIN))
    canvas.paste(_label_strip(512, "512 PX ASSET", "review copy"), (MARGIN, MARGIN + 512))
    canvas.paste(
        _label_strip(360, "SIMULATED 360 dp", "smallest cue 14+ dp"),
        (MARGIN + 512 + MARGIN, MARGIN + 512),
    )
    path = QA_ROOT / "legibility_360dp.png"
    canvas.save(path)
    measurements.append({"image": str(path.relative_to(REPO_ROOT)).replace("\\", "/")})
    return {"widths_px": widths, "text": measurements}


def identity_pose() -> Pose:
    heads = {name: np.array(BONE_HEAD[name], dtype=float) for name in BONE_NAMES}
    rotations = {name: np.eye(3) for name in BONE_NAMES}
    return Pose(heads=heads, rotations=rotations)


def _evaluate_glb(
    data: glb.GlbData, track_index: int, time: float, normals: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    document = data.document
    skin = document["skins"][0]
    world = data.node_world_matrices(track_index, time)
    inverse_bind = np.transpose(
        data.accessor(skin["inverseBindMatrices"]).astype(float).reshape(-1, 4, 4), (0, 2, 1)
    )
    primitive = document["meshes"][0]["primitives"][0]
    positions = data.accessor(primitive["attributes"]["POSITION"]).astype(float)
    joints = data.accessor(primitive["attributes"]["JOINTS_0"]).astype(int)[:, 0]
    output = np.zeros_like(positions)
    output_normals = np.zeros_like(normals)
    for joint_index in np.unique(joints):
        selection = joints == joint_index
        matrix = world[skin["joints"][joint_index]] @ inverse_bind[joint_index]
        output[selection] = positions[selection] @ matrix[:3, :3].T + matrix[:3, 3]
        output_normals[selection] = normals[selection] @ matrix[:3, :3].T
    lengths = np.linalg.norm(output_normals, axis=1)
    lengths[lengths < 1e-9] = 1.0
    return output, output_normals / lengths[:, None]


def glb_roundtrip(mesh: AthleteMesh, camera: Camera, renderer: render.Renderer) -> dict:
    data = glb.read_glb(ASSET_ROOT / "models" / "athlete_mannequin_v1.glb")
    results = []
    panels = []
    identity = identity_pose()
    for track_index, (exercise, config) in enumerate(EXERCISES.items()):
        for pose_name in ("start", "end"):
            frac = animation.key_phase_time(exercise, pose_name)
            time = frac * float(config["duration_s"])
            pipeline_pose = solve(animation.POSE_FUNCTIONS[exercise](frac))
            pipeline_vertices = pose_vertices(mesh, pipeline_pose)
            glb_vertices, glb_normals = _evaluate_glb(data, track_index, time, mesh.normals)
            error = float(np.abs(glb_vertices - pipeline_vertices).max())
            results.append({"clip": config["clip"], "pose": pose_name, "max_vertex_error_m": error})
            glb_mesh = AthleteMesh(
                vertices=glb_vertices,
                normals=glb_normals,
                joints=mesh.joints,
                triangles=mesh.triangles,
                triangle_materials=mesh.triangle_materials,
                material_names=mesh.material_names,
            )
            panels.append(
                (
                    f"{config['label'].upper()} {pose_name.upper()}",
                    renderer.draw(pipeline_pose, camera),
                    render.Renderer(glb_mesh).draw(identity, camera),
                )
            )
    cell = 512
    width = MARGIN + len(panels) * (cell + MARGIN)
    height = MARGIN + 2 * (cell + LABEL_HEIGHT + MARGIN)
    sheet = Image.new("RGB", (width, height), (12, 14, 14))
    for index, (title, pipeline_image, glb_image) in enumerate(panels):
        x = MARGIN + index * (cell + MARGIN)
        sheet.paste(pipeline_image, (x, MARGIN))
        sheet.paste(glb_image, (x, MARGIN + cell + LABEL_HEIGHT + MARGIN))
        sheet.paste(_label_strip(cell, title, "pipeline render (top) / GLB skinning (bottom)"), (x, MARGIN + cell))
    path = QA_ROOT / "glb_roundtrip_check.png"
    sheet.save(path)
    worst = max(entry["max_vertex_error_m"] for entry in results)
    return {"worst_error_m": worst, "samples": results, "image": str(path.relative_to(REPO_ROOT))}


def loop_keyframes() -> list[Path]:
    paths = []
    for exercise, config in EXERCISES.items():
        source = LOOPS_DIR / f"{config['stem']}_loop.mp4"
        with tempfile.TemporaryDirectory() as folder:
            pattern = str(Path(folder) / "frame_%02d.png")
            duration = float(config["duration_s"])
            subprocess.run(
                [
                    "ffmpeg",
                    "-y",
                    "-hide_banner",
                    "-loglevel",
                    "error",
                    "-i",
                    str(source),
                    "-vf",
                    "select='not(mod(n\\,5))',scale=256:256",
                    "-vsync",
                    "0",
                    "-frames:v",
                    "6",
                    pattern,
                ],
                check=True,
            )
            frames = sorted(Path(folder).glob("frame_*.png"))
            sheet = Image.new("RGB", (6 * 256, 256 + LABEL_HEIGHT), (12, 14, 14))
            for index, frame_path in enumerate(frames[:6]):
                sheet.paste(Image.open(frame_path).convert("RGB"), (index * 256, 0))
            sheet.paste(
                _label_strip(6 * 256, f"{config['label'].upper()} LOOP KEY FRAMES", f"{duration:.1f}s loop, 25 fps"),
                (0, 256),
            )
            path = QA_ROOT / f"loop_keyframes_{config['stem']}.png"
            sheet.save(path)
            paths.append(path)
    return paths


def main() -> int:
    QA_ROOT.mkdir(parents=True, exist_ok=True)
    mesh = build_mesh(bone_index())
    manifest = json.loads((ASSET_ROOT / "manifest.json").read_text(encoding="utf-8"))
    camera_config = manifest["camera"]
    renderer = render.Renderer(mesh)

    # Rebuild the shared cameras exactly as build.py did.
    subjects = {}
    for exercise in EXERCISES:
        duration = float(EXERCISES[exercise]["duration_s"])
        count = int(round(duration * 25))
        subjects[exercise] = [
            pose_vertices(mesh, solve(animation.POSE_FUNCTIONS[exercise](index / count)))
            for index in range(count)
        ]
    from arena_athlete.spec import CAMERA, RENDER

    cameras, _ = Camera.fit_grouped(
        list(subjects.values()),
        fov_deg=float(camera_config["fov_deg"]),
        size=int(RENDER["size"]),
        safe_area=float(CAMERA["safe_area"]),
        azimuth_deg=float(camera_config["azimuth_deg"]),
        elevation_deg=float(camera_config["elevation_deg"]),
    )
    camera_by_exercise = dict(zip(subjects.keys(), cameras))

    head_anchors: dict[tuple[str, str], tuple[float, float]] = {}
    for exercise in EXERCISES:
        for pose_name in ("start", "end"):
            pose = solve(animation.POSE_FUNCTIONS[exercise](animation.key_phase_time(exercise, pose_name)))
            head = pose.heads["head"] + pose.rotations["head"] @ np.array([0.0, 0.11, 0.0])
            screen, _ = camera_by_exercise[exercise].project(np.array([head]))
            head_anchors[(exercise, pose_name)] = (float(screen[0][0]), float(screen[0][1]))

    artifacts = {
        "contact_sheet": str(build_contact_sheet().relative_to(REPO_ROOT)),
        "identity_strip": str(build_identity_strip(head_anchors).relative_to(REPO_ROOT)),
        "poster_sheet": str(build_poster_sheet().relative_to(REPO_ROOT)),
        "legibility": legibility(),
        "glb_roundtrip": glb_roundtrip(mesh, camera_by_exercise["pushups"], renderer),
        "loop_keyframes": [str(path.relative_to(REPO_ROOT)) for path in loop_keyframes()],
    }
    report_path = QA_ROOT / "qa_report.json"
    report_path.write_text(json.dumps(artifacts, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: v for k, v in artifacts.items() if k != "legibility"}, indent=2))
    print(f"[qa] report: {report_path.relative_to(REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
