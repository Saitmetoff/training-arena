"""Build the Training Arena athlete media package.

Usage (from the repository root):
    python qa/media/tools/build.py [--quick]

Produces:
    app/assets/media/athlete/...   optimized assets + manifest.json
    qa/media/...                   reviewer contact sheets and checks
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_athlete import animation, glb, mesh as mesh_module, render  # noqa: E402
from arena_athlete.annotations import draw_annotations, poster_header  # noqa: E402
from arena_athlete.render import Camera  # noqa: E402
from arena_athlete.rig import bone_index, pose_vertices, solve  # noqa: E402
from arena_athlete.spec import (  # noqa: E402
    ASSET_ROOT,
    ATHLETE_ID,
    ATHLETE_NAME,
    BUDGETS,
    CAMERA,
    EXERCISES,
    FRAMES_DIR,
    LOOPS_DIR,
    MODELS_DIR,
    OVERLAYS_DIR,
    PACKAGE_VERSION,
    PALETTE,
    POSTERS_DIR,
    QA_PACKAGE,
    RENDER,
    REPO_ROOT,
)

GENERATED_AT = os.environ.get("ARENA_MEDIA_TIMESTAMP", "2026-09-17T00:00:00Z")
GLB_NAME = "athlete_mannequin_v1.glb"


def log(message: str) -> None:
    print(f"[media] {message}", flush=True)


def rgb_hex(rgb: tuple[float, float, float]) -> str:
    return "#" + "".join(f"{round(channel * 255):02X}" for channel in rgb)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_mesh():
    indices = bone_index()
    athlete = mesh_module.build_mesh(indices)
    log(
        f"mesh: {len(athlete.vertices)} vertices, {len(athlete.triangles)} triangles, "
        f"{len(athlete.material_names)} materials"
    )
    return athlete


def frame_times(exercise: str) -> np.ndarray:
    duration = float(EXERCISES[exercise]["duration_s"])
    count = int(round(duration * RENDER["fps"]))
    return np.arange(count) / count


def build_frames(athlete, exercise: str):
    pose_function = animation.POSE_FUNCTIONS[exercise]
    frames = []
    for t in frame_times(exercise):
        frames.append(solve(pose_function(float(t))))
    return frames


def fit_cameras(athlete, exercise_frames: dict[str, list]) -> tuple[dict[str, Camera], float]:
    subjects = []
    shifts = []
    for exercise, frames in exercise_frames.items():
        subjects.append([pose_vertices(athlete, pose) for pose in frames])
        shifts.append(float(CAMERA.get("target_shift_screen", {}).get(exercise, 0.0)))
    cameras, distance = Camera.fit_grouped(
        subjects,
        fov_deg=float(CAMERA["fov_deg"]),
        size=int(RENDER["size"]),
        safe_area=float(CAMERA["safe_area"]),
        azimuth_deg=float(CAMERA["azimuth_deg"]),
        elevation_deg=float(CAMERA["elevation_deg"]),
        screen_shifts=shifts,
    )
    result = {exercise: camera for exercise, camera in zip(exercise_frames.keys(), cameras)}
    for exercise, camera in result.items():
        log(
            f"camera[{exercise}]: target=({camera.target[0]:.2f}, {camera.target[1]:.2f}, "
            f"{camera.target[2]:.2f}) distance={distance:.2f} m"
        )
    log(
        f"camera shared: azimuth={CAMERA['azimuth_deg']} elevation={CAMERA['elevation_deg']} "
        f"fov={CAMERA['fov_deg']} distance={distance:.2f} m"
    )
    return result, distance


def save_webp(image: Image.Image, path: Path, quality: int | None = None, lossless: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if lossless:
        image.save(path, "WEBP", lossless=True, quality=100, method=6)
    else:
        image.save(path, "WEBP", quality=quality or RENDER["webp_quality"], method=6)


def encode_loops(png_dir: Path, stem: str) -> None:
    LOOPS_DIR.mkdir(parents=True, exist_ok=True)
    pattern = str(png_dir / "%04d.png")
    mp4 = LOOPS_DIR / f"{stem}_loop.mp4"
    webp = LOOPS_DIR / f"{stem}_loop.webp"
    common = [
        "ffmpeg",
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-framerate",
        str(RENDER["fps"]),
        "-i",
        pattern,
        "-an",
        "-fflags",
        "+bitexact",
    ]
    subprocess.run(
        common
        + [
            "-c:v",
            "libx264",
            "-profile:v",
            "high",
            "-pix_fmt",
            "yuv420p",
            "-crf",
            "26",
            "-preset",
            "slow",
            "-movflags",
            "+faststart",
            "-map_metadata",
            "-1",
            str(mp4),
        ],
        check=True,
    )
    subprocess.run(
        common
        + [
            "-c:v",
            "libwebp",
            "-lossless",
            "0",
            "-q:v",
            "70",
            "-loop",
            "0",
            "-map_metadata",
            "-1",
            str(webp),
        ],
        check=True,
    )


def render_key_stills(renderer: render.Renderer, athlete, exercise: str, pose_frames, camera: Camera):
    stills: dict[str, Image.Image] = {}
    for pose_name in ("start", "mid", "end"):
        t = animation.key_phase_time(exercise, pose_name)
        pose = solve(animation.POSE_FUNCTIONS[exercise](t))
        stills[pose_name] = renderer.draw(pose, camera)
    return stills


def build_asset_entry(path: Path, kind: str, extra: dict | None = None) -> dict:
    entry = {
        "asset": str(path.relative_to(REPO_ROOT / "app")).replace("\\", "/"),
        "type": kind,
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
        "review_status": "pending_human_review",
    }
    if extra:
        entry.update(extra)
    return entry


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--quick", action="store_true", help="key stills only, skip loops")
    args = parser.parse_args()

    started = time.time()
    for folder in (MODELS_DIR, LOOPS_DIR, POSTERS_DIR, FRAMES_DIR, OVERLAYS_DIR):
        folder.mkdir(parents=True, exist_ok=True)
    (REPO_ROOT / QA_PACKAGE).mkdir(parents=True, exist_ok=True)
    tmp_root = REPO_ROOT / QA_PACKAGE / ".tmp"
    if tmp_root.exists():
        shutil.rmtree(tmp_root)
    tmp_root.mkdir(parents=True)

    athlete = build_mesh()
    exercise_frames = {}
    for exercise in EXERCISES:
        frames = build_frames(athlete, exercise)
        exercise_frames[exercise] = frames
        log(f"{exercise}: {len(frames)} frames @ {RENDER['fps']} fps")
    cameras, camera_distance = fit_cameras(athlete, exercise_frames)
    render_cameras = {
        exercise: Camera(
            eye=camera.eye,
            target=camera.target,
            fov_deg=camera.fov_deg,
            size=int(RENDER["size"]) * int(RENDER["supersample"]),
        )
        for exercise, camera in cameras.items()
    }
    renderer = render.Renderer(athlete)

    # --- GLB -------------------------------------------------------------
    tracks = []
    for exercise, config in EXERCISES.items():
        pose_frames = exercise_frames[exercise]
        samples = pose_frames + [pose_frames[0]]
        tracks.append(glb.build_track(config["clip"], samples, float(RENDER["fps"])))
    glb_path = MODELS_DIR / GLB_NAME
    glb.export_glb(athlete, tracks, glb_path, generated_at=GENERATED_AT)
    log(f"glb: {glb_path.relative_to(REPO_ROOT)} ({glb_path.stat().st_size / 1024:.0f} KiB)")

    manifest = {
        "schema": "app.trainingarena.media/athlete-manifest@1",
        "package_version": PACKAGE_VERSION,
        "generated_at": GENERATED_AT,
        "generator": "qa/media/tools/build.py",
        "athlete": {
            "id": ATHLETE_ID,
            "name": ATHLETE_NAME,
            "description": "Single rigged mannequin athlete shared by every demonstration.",
            "height_m": 1.75,
        },
        "review": {
            "status": "pending_human_review",
            "release_eligible": False,
            "checklist": "docs/media/FORM_REVIEW.md",
            "provenance": "docs/media/PROVENANCE.md",
        },
        "identity": {
            "palette_source": "design/arena/tokens.json",
            "canvas": rgb_hex(PALETTE.canvas),
            "kit_top": rgb_hex(PALETTE.kit_top),
            "kit_bottom": rgb_hex(PALETTE.kit_bottom),
            "accent": rgb_hex(PALETTE.accent),
            "note": "violet (#BEA1FF) is reserved for the opponent and is never used in athlete media",
        },
        "camera": {
            "view": "three_quarter_right",
            "azimuth_deg": CAMERA["azimuth_deg"],
            "elevation_deg": CAMERA["elevation_deg"],
            "fov_deg": CAMERA["fov_deg"],
            "distance_m": round(camera_distance, 3),
            "frame_px": int(RENDER["size"]),
            "shared_across_exercises": True,
            "policy": (
                "identical azimuth, elevation, lens, distance and scale in both exercises; "
                "the aim point is recentred per exercise so neither pose is pushed into a corner"
            ),
            "targets": {
                exercise: {
                    "target": [round(float(value), 3) for value in cameras[exercise].target],
                }
                for exercise in EXERCISES
            },
        },
        "models": {
            "athlete": build_asset_entry(glb_path, "model", {"format": "glb", "clips": [config["clip"] for config in EXERCISES.values()]}),
        },
        "exercises": {},
    }

    for exercise, config in EXERCISES.items():
        stem = config["stem"]
        pose_frames = exercise_frames[exercise]
        camera = cameras[exercise]
        render_camera = render_cameras[exercise]
        stills = render_key_stills(renderer, athlete, exercise, pose_frames, render_camera)
        for pose_name, image in stills.items():
            save_webp(image, FRAMES_DIR / f"{stem}_{pose_name}.webp")

        for pose_name in ("start", "end"):
            pose = solve(animation.POSE_FUNCTIONS[exercise](animation.key_phase_time(exercise, pose_name)))
            occupancy, _ = camera.project(pose_vertices(athlete, pose))
            overlay = draw_annotations(exercise, pose_name, pose, camera, int(RENDER["size"]), occupancy)
            save_webp(overlay, OVERLAYS_DIR / f"{stem}_{pose_name}.webp", lossless=True)
            poster_overlay = draw_annotations(
                exercise,
                pose_name,
                pose,
                camera,
                int(RENDER["size"]),
                occupancy,
                top_margin=88,
            )
            poster = Image.alpha_composite(stills[pose_name].convert("RGBA"), poster_overlay).convert("RGB")
            poster = poster_header(poster, exercise, pose_name)
            save_webp(poster, POSTERS_DIR / f"{stem}_{pose_name}.webp")
            poster.convert("RGB").save(
                POSTERS_DIR / f"{stem}_{pose_name}.png",
                "PNG",
                optimize=True,
            )

        if not args.quick:
            png_dir = tmp_root / stem
            png_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(pose_frames):
                renderer.draw(frame, render_camera).save(png_dir / f"{index:04d}.png")
            encode_loops(png_dir, stem)
            shutil.rmtree(png_dir)
            log(f"{exercise}: loops encoded")

            assets = {
                "glb": manifest["models"]["athlete"],
                "loop_mp4": build_asset_entry(LOOPS_DIR / f"{stem}_loop.mp4", "video"),
                "loop_webp": build_asset_entry(LOOPS_DIR / f"{stem}_loop.webp", "video"),
                "frame_start": build_asset_entry(FRAMES_DIR / f"{stem}_start.webp", "image"),
                "frame_mid": build_asset_entry(FRAMES_DIR / f"{stem}_mid.webp", "image"),
                "frame_end": build_asset_entry(FRAMES_DIR / f"{stem}_end.webp", "image"),
                "overlay_start": build_asset_entry(OVERLAYS_DIR / f"{stem}_start.webp", "overlay"),
                "overlay_end": build_asset_entry(OVERLAYS_DIR / f"{stem}_end.webp", "overlay"),
                "poster_start": build_asset_entry(POSTERS_DIR / f"{stem}_start.webp", "poster"),
                "poster_end": build_asset_entry(POSTERS_DIR / f"{stem}_end.webp", "poster"),
                "poster_start_png": build_asset_entry(
                    POSTERS_DIR / f"{stem}_start.png", "poster", {"role": "guaranteed_decode"}
                ),
                "poster_end_png": build_asset_entry(
                    POSTERS_DIR / f"{stem}_end.png", "poster", {"role": "guaranteed_decode"}
                ),
            }
            manifest["exercises"][exercise] = {
                "wire": config["wire"],
                "label": config["label"],
                "clip": config["clip"],
                "duration_s": config["duration_s"],
                "loops": True,
                "pose_names": ["start", "mid", "end"],
                "assets": assets,
                "fallback_chain": [
                    f"exercises.{exercise}.assets.loop_mp4",
                    f"exercises.{exercise}.assets.loop_webp",
                    f"exercises.{exercise}.assets.poster_start",
                    f"exercises.{exercise}.assets.poster_start_png",
                    "placeholder",
                ],
                "review": {
                    "status": "pending_human_review",
                    "reviewer": None,
                    "reviewed_at": None,
                    "form_review": f"docs/media/FORM_REVIEW.md#{exercise}",
                    "asset_sha256": {
                        "poster_start": assets["poster_start"]["sha256"],
                        "poster_end": assets["poster_end"]["sha256"],
                        "glb": assets["glb"]["sha256"],
                        "loop_mp4": assets["loop_mp4"]["sha256"],
                    },
                },
            }

    if args.quick:
        shutil.rmtree(tmp_root, ignore_errors=True)
        log("quick mode: stills and posters written, loops and manifest skipped")
        return 0

    manifest["always_present"] = [
        e["assets"]["poster_start_png"]["asset"] for e in manifest["exercises"].values()
    ]
    manifest["missing_media_policy"] = {
        "rule": "resolve in fallback_chain order; never render a blank frame",
        "placeholder": {
            "kind": "ui",
            "title": "Form guide pending review",
            "body": "Demonstration media ships only after a human form review (docs/media/FORM_REVIEW.md).",
        },
        "release_builds": "omit any asset whose review_status is not approved",
    }
    manifest["budgets"] = BUDGETS
    manifest_path = ASSET_ROOT / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    log(f"manifest: {manifest_path.relative_to(REPO_ROOT)}")

    shutil.rmtree(tmp_root, ignore_errors=True)
    log(f"done in {time.time() - started:.1f}s")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
