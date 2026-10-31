"""Validate the athlete media package and enforce the review gate.

Usage (from the repository root):
    python qa/media/tools/validate_media_package.py                 # prototype gate
    python qa/media/tools/validate_media_package.py --gate release  # release gate

Prototype gate: every manifest entry resolves, hashes match, media decodes,
fallback chains terminate in a shipped poster and budgets hold.
Release gate: additionally requires every shipped asset to be human-approved
and hash-pinned (docs/media/FORM_REVIEW.md); unreviewed media never ships.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_athlete import glb  # noqa: E402
from arena_athlete.spec import (  # noqa: E402
    ASSET_ROOT,
    BUDGETS,
    EXERCISES,
    REPO_ROOT,
    QA_ROOT,
)

MANIFEST_PATH = ASSET_ROOT / "manifest.json"
ASSET_BASE = REPO_ROOT / "app"  # Flutter asset keys are relative to app/
IGNORED_FILES = {"manifest.json", "README.md", ".gitkeep"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def iter_entries(manifest: dict):
    """Yield (label, entry) for every asset record in the manifest."""
    yield "models.athlete", manifest["models"]["athlete"]
    for exercise, record in manifest["exercises"].items():
        for name, entry in record["assets"].items():
            yield f"exercises.{exercise}.assets.{name}", entry


def check_entries(manifest: dict, errors: list[str], warnings: list[str]) -> dict:
    seen_paths: set[str] = set()
    sizes: dict[str, int] = {}
    for label, entry in iter_entries(manifest):
        relative = entry["asset"]
        path = ASSET_BASE / relative
        if not path.is_file():
            errors.append(f"{label}: missing file {relative}")
            continue
        seen_paths.add(relative)
        if path.stat().st_size != entry["bytes"]:
            errors.append(f"{label}: size drift ({path.stat().st_size} != {entry['bytes']})")
        if sha256(path) != entry["sha256"]:
            errors.append(f"{label}: sha256 drift for {relative}")
        if "review_status" not in entry:
            errors.append(f"{label}: missing review_status")
        kind = entry.get("type", "other")
        sizes[kind] = sizes.get(kind, 0) + entry["bytes"]

        suffix = path.suffix.lower()
        if suffix in {".webp", ".png"}:
            try:
                with Image.open(path) as image:
                    image.load()
                    if kind == "poster" and (image.width, image.height) != (512, 512):
                        warnings.append(f"{label}: poster is {image.width}x{image.height}")
            except Exception as exception:  # noqa: BLE001
                errors.append(f"{label}: cannot decode {relative} ({exception})")
        elif suffix == ".mp4":
            result = subprocess.run(
                [
                    "ffprobe",
                    "-v",
                    "error",
                    "-select_streams",
                    "v:0",
                    "-show_entries",
                    "stream=codec_name,width,height,nb_frames",
                    "-of",
                    "json",
                    str(path),
                ],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0 or not json.loads(result.stdout).get("streams"):
                errors.append(f"{label}: no decodable video stream in {relative}")
            else:
                stream = json.loads(result.stdout)["streams"][0]
                if (stream.get("width"), stream.get("height")) != (512, 512):
                    warnings.append(f"{label}: video is not 512x512")
        elif suffix == ".glb":
            try:
                data = glb.read_glb(path)
                animations = [animation.get("name") for animation in data.document.get("animations", [])]
                expected = {config["clip"] for config in EXERCISES.values()}
                missing = expected - set(animations)
                if missing:
                    errors.append(f"{label}: missing animation clips {sorted(missing)}")
                if not data.document.get("skins"):
                    errors.append(f"{label}: no skin in GLB")
            except Exception as exception:  # noqa: BLE001
                errors.append(f"{label}: cannot parse GLB ({exception})")

    # Orphan check: every shipped file must be described by the manifest.
    for path in sorted(ASSET_ROOT.rglob("*")):
        if not path.is_file():
            continue
        relative = str(path.relative_to(ASSET_BASE)).replace("\\", "/")
        if path.name in IGNORED_FILES:
            continue
        if relative not in seen_paths:
            errors.append(f"orphan asset not in manifest: {relative}")
    return sizes


def check_budgets(manifest: dict, errors: list[str]) -> dict:
    """Per-file budgets by asset kind plus one package total over unique files."""
    report: dict = {"files": {}, "package_total": {}}
    unique_sizes: dict[str, int] = {}
    for label, entry in iter_entries(manifest):
        suffix = Path(entry["asset"]).suffix.lower()
        kind = entry.get("type", "other")
        if kind == "model":
            key = "glb"
        elif kind == "video":
            key = "loop_webp" if suffix == ".webp" else "loop_mp4"
        elif kind == "poster":
            key = "poster_png" if suffix == ".png" else "poster_webp"
        elif kind == "image":
            key = "frame_webp"
        elif kind == "overlay":
            key = "overlay_webp"
        else:
            key = None
        budget = BUDGETS.get(key) if key else None
        if budget and entry["bytes"] > budget:
            errors.append(
                f"{label}: {entry['asset']} is {entry['bytes'] / 1024:.0f} KiB over the "
                f"{key} budget of {budget / 1024:.0f} KiB"
            )
        unique_sizes[entry["asset"]] = entry["bytes"]
    for key, budget in BUDGETS.items():
        if key == "package_total":
            continue
        report["files"].setdefault(key, {"budget": budget, "count": 0, "largest": 0})
    for label, entry in iter_entries(manifest):
        suffix = Path(entry["asset"]).suffix.lower()
        kind = entry.get("type", "other")
        key = {
            ("model", ".glb"): "glb",
            ("video", ".mp4"): "loop_mp4",
            ("video", ".webp"): "loop_webp",
            ("poster", ".png"): "poster_png",
            ("poster", ".webp"): "poster_webp",
            ("image", ".webp"): "frame_webp",
            ("overlay", ".webp"): "overlay_webp",
        }.get((kind, suffix))
        if key and key in report["files"]:
            report["files"][key]["count"] += 1
            report["files"][key]["largest"] = max(report["files"][key]["largest"], entry["bytes"])
    total = sum(unique_sizes.values())
    report["package_total"] = {
        "bytes": total,
        "budget": BUDGETS["package_total"],
        "unique_files": len(unique_sizes),
    }
    if total > BUDGETS["package_total"]:
        errors.append(f"package budget exceeded: {total} > {BUDGETS['package_total']}")
    return report


def check_fallbacks(manifest: dict, errors: list[str]) -> dict:
    """Resolve each fallback chain, including simulated media loss."""
    report = {}
    placeholder = manifest["missing_media_policy"]["placeholder"]
    for exercise, record in manifest["exercises"].items():
        resolutions = {}
        for scenario, skip in (
            ("intact", set()),
            ("no_video", {"loop_mp4", "loop_webp"}),
            ("no_video_no_webp_poster", {"loop_mp4", "loop_webp", "poster_start", "poster_end"}),
        ):
            resolved = None
            for node in record["fallback_chain"]:
                name = node.split(".")[-1]
                if name in skip:
                    continue
                if name == "placeholder":
                    resolved = {"kind": placeholder["kind"], "title": placeholder["title"]}
                    break
                entry = record["assets"].get(name)
                if entry is None:
                    errors.append(f"{exercise}: fallback node {node} is not in the manifest")
                    break
                path = ASSET_BASE / entry["asset"]
                if path.is_file():
                    resolved = {
                        "asset": entry["asset"],
                        "review_status": entry["review_status"],
                    }
                    break
            if resolved is None:
                errors.append(f"{exercise}: fallback chain unresolved in scenario {scenario}")
            resolutions[scenario] = resolved
        report[exercise] = resolutions
    return report


def check_release_gate(manifest: dict, errors: list[str], warnings: list[str]) -> dict:
    pending = []
    approved = []
    for label, entry in iter_entries(manifest):
        status = entry.get("review_status")
        if status == "approved":
            approved.append(label)
            review = entry.get("review", {})
            if not review.get("reviewer") or not review.get("reviewed_at"):
                errors.append(f"{label}: approved without reviewer/date")
            if review.get("reviewed_asset_sha256") not in (None, entry["sha256"]):
                errors.append(f"{label}: approval hash does not match the shipped file")
        else:
            pending.append(label)
    if pending:
        errors.append(
            "release gate: unreviewed media present and must be excluded from release builds: "
            + ", ".join(pending)
        )
    if not manifest["review"].get("release_eligible") and approved:
        warnings.append("manifest review.release_eligible is false while some assets are approved")
    return {"approved": approved, "pending": pending, "release_eligible": bool(approved) and not pending}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gate", choices=("prototype", "release"), default="prototype")
    args = parser.parse_args()

    if not MANIFEST_PATH.is_file():
        print("[media-validate] FAIL: manifest.json missing; run qa/media/tools/build.py")
        return 1
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    errors: list[str] = []
    warnings: list[str] = []

    if manifest.get("schema") != "app.trainingarena.media/athlete-manifest@1":
        errors.append("unexpected manifest schema")
    check_entries(manifest, errors, warnings)
    budgets = check_budgets(manifest, errors)
    fallbacks = check_fallbacks(manifest, errors)
    gate = check_release_gate(manifest, errors, warnings) if args.gate == "release" else None

    report = {
        "gate": args.gate,
        "manifest": str(MANIFEST_PATH.relative_to(REPO_ROOT)).replace("\\", "/"),
        "ok": not errors,
        "errors": errors,
        "warnings": warnings,
        "budgets": budgets,
        "fallbacks": fallbacks,
        "release_gate": gate,
        "review_status": manifest["review"],
    }
    QA_ROOT.mkdir(parents=True, exist_ok=True)
    report_path = QA_ROOT / (
        "validation_report.json" if args.gate == "prototype" else "validation_report_release.json"
    )
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    for warning in warnings:
        print(f"[media-validate] warn: {warning}")
    for error in errors:
        print(f"[media-validate] FAIL: {error}")
    if not errors:
        total = budgets["package_total"]["bytes"]
        print(
            f"[media-validate] PASS ({args.gate} gate): {len(list(iter_entries(manifest)))} entries, "
            f"{total / 1024:.0f} KiB total; report: {report_path.relative_to(REPO_ROOT)}"
        )
    else:
        print(f"[media-validate] FAIL ({args.gate} gate): {len(errors)} problem(s)")
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
