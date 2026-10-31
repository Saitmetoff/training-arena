"""Print the joint measurements used by docs/media/FORM_REVIEW.md.

Usage (from the repository root):
    python qa/media/tools/measure_poses.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_athlete import animation  # noqa: E402
from arena_athlete.rig import solve  # noqa: E402


def joint_angle(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
    first = a - b
    second = c - b
    cosine = float(np.dot(first, second) / (np.linalg.norm(first) * np.linalg.norm(second)))
    return float(np.degrees(np.arccos(np.clip(cosine, -1.0, 1.0))))


def torso_lean(pose) -> float:
    shoulder = pose.heads["upperarm_r"]
    hip = pose.heads["thigh_r"]
    return float(np.degrees(np.arctan2(shoulder[0] - hip[0], shoulder[1] - hip[1])))


def main() -> int:
    phases = {
        "pushups": (("start", 0.04), ("mid", 0.25), ("end", 0.485)),
        "squats": (("start", 0.05), ("mid", 0.28), ("end", 0.53)),
    }
    for exercise, entries in phases.items():
        for name, time in entries:
            pose = solve(animation.POSE_FUNCTIONS[exercise](time))
            print(
                f"{exercise:8s} {name:5s} "
                f"elbow={joint_angle(pose.heads['upperarm_r'], pose.heads['forearm_r'], pose.heads['hand_r']):6.1f}  "
                f"knee={joint_angle(pose.heads['thigh_r'], pose.heads['shin_r'], pose.heads['foot_r']):6.1f}  "
                f"torso_lean={torso_lean(pose):5.1f}  "
                f"shoulder_y={pose.heads['upperarm_r'][1]:.3f}  "
                f"wrist_y={pose.heads['hand_r'][1]:.3f}  "
                f"hip_y={pose.heads['thigh_r'][1]:.3f}  "
                f"knee_y={pose.heads['shin_r'][1]:.3f}  "
                f"knee_x={pose.heads['shin_r'][0]:.3f}  "
                f"ankle_y={pose.heads['foot_r'][1]:.3f}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
