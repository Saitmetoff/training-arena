"""Authored animation for the two reviewed demonstrations.

Each demo is a deterministic function of loop time t in [0, 1) returning a
PoseSpec. Poses are built from body landmarks (shoulder centre, hand targets,
ankle targets) plus two-bone IK, so ground contact and limb lengths always
hold. Both exercises share the athlete's bind pose (standing) as the neutral
start / return pose.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np

from . import geom
from .rig import PoseSpec
from .spec import (
    BONE_HEAD,
    BONE_TAIL,
    FOOT_LENGTH,
    LEG_LENGTH,
    PELVIS_OFFSET,
    TORSO_LENGTH,
)

FORWARD = np.array([1.0, 0.0, 0.0])
UP = np.array([0.0, 1.0, 0.0])

# Bind foot rotation relative to the shin (sagittal plane, +Z axis).
_BIND_SHIN = geom.normalize(np.array(BONE_TAIL["shin_r"]) - np.array(BONE_HEAD["shin_r"]))
_BIND_FOOT = geom.normalize(np.array(BONE_TAIL["foot_r"]) - np.array(BONE_HEAD["foot_r"]))
BIND_FOOT_ANGLE = math.atan2(
    float(np.cross(_BIND_SHIN, _BIND_FOOT)[2]), float(np.dot(_BIND_SHIN, _BIND_FOOT))
)
PLANTAR_FLEX_PUSHUP = math.radians(8.0)


def _rz(vector: np.ndarray, angle: float) -> np.ndarray:
    cos_a = math.cos(angle)
    sin_a = math.sin(angle)
    return np.array(
        [
            vector[0] * cos_a - vector[1] * sin_a,
            vector[0] * sin_a + vector[1] * cos_a,
            vector[2],
        ]
    )


def smoothstep(value: float) -> float:
    value = float(np.clip(value, 0.0, 1.0))
    return value * value * (3.0 - 2.0 * value)


def _lerp(a: np.ndarray | float, b: np.ndarray | float, amount: float):
    return a + (b - a) * amount


@dataclass(frozen=True)
class Segment:
    start: float
    end: float
    from_value: float
    to_value: float


def phase_from_segments(t: float, segments: list[Segment], eased: bool = True) -> float:
    t = t % 1.0
    for segment in segments:
        if segment.start <= t <= segment.end:
            span = max(segment.end - segment.start, 1e-9)
            local = (t - segment.start) / span
            if eased:
                local = smoothstep(local)
            return segment.from_value + (segment.to_value - segment.from_value) * local
    return segments[-1].to_value


PUSHUP_SEGMENTS = [
    Segment(0.00, 0.08, 0.0, 0.0),
    Segment(0.08, 0.42, 0.0, 1.0),
    Segment(0.42, 0.55, 1.0, 1.0),
    Segment(0.55, 0.95, 1.0, 0.0),
    Segment(0.95, 1.00, 0.0, 0.0),
]

SQUAT_SEGMENTS = [
    Segment(0.00, 0.10, 0.0, 0.0),
    Segment(0.10, 0.46, 0.0, 1.0),
    Segment(0.46, 0.60, 1.0, 1.0),
    Segment(0.60, 0.97, 1.0, 0.0),
    Segment(0.97, 1.00, 0.0, 0.0),
]

# --------------------------------------------------------------------------
# Push-up landmarks
# --------------------------------------------------------------------------

PUSHUP_HAND = np.array([1.30, 0.055, 0.235])  # right side; left mirrors z
PUSHUP_SHOULDER_TOP = np.array([0.10, 0.53, 0.0])  # added to the hand target
PUSHUP_SHOULDER_BOTTOM = np.array([0.25, 0.31, 0.0])
PUSHUP_ANKLE_Z = 0.13
PUSHUP_TOE_HEIGHT = 0.03


def _pushup_body_angle(shoulder_center: np.ndarray) -> float:
    """Solve the plank angle so the ball of the foot rests on the floor."""
    target_height = PUSHUP_TOE_HEIGHT

    def toe_height(theta: float) -> float:
        direction = np.array([math.sin(theta), math.cos(theta), 0.0])
        pelvis = shoulder_center - direction * TORSO_LENGTH
        hip = pelvis.copy()
        ankle = hip - direction * LEG_LENGTH
        shin_direction = -direction
        foot_direction = _rz(shin_direction, BIND_FOOT_ANGLE + PLANTAR_FLEX_PUSHUP)
        toe = ankle + foot_direction * FOOT_LENGTH
        return float(toe[1])

    low, high = math.radians(35.0), math.radians(95.0)
    low_valid = toe_height(low) - target_height
    high_valid = toe_height(high) - target_height
    if low_valid * high_valid > 0.0:
        # Fall back to the closest achievable angle.
        return low if abs(low_valid) < abs(high_valid) else high
    for _ in range(60):
        middle = 0.5 * (low + high)
        if (toe_height(middle) - target_height) * low_valid <= 0.0:
            high = middle
        else:
            low = middle
    return 0.5 * (low + high)


def pushup_spec(t: float) -> PoseSpec:
    amount = phase_from_segments(t, PUSHUP_SEGMENTS)
    offset = _lerp(PUSHUP_SHOULDER_TOP, PUSHUP_SHOULDER_BOTTOM, amount)

    wrist = {}
    elbow_pole = {}
    hand_dir = {}
    ankle_target = {}
    knee_pole = {}
    foot_dir = {}
    for suffix, sign in (("r", 1.0), ("l", -1.0)):
        wrist[suffix] = PUSHUP_HAND * np.array([1.0, 1.0, sign])
        elbow_pole[suffix] = geom.normalize(np.array([-0.62, -0.18, sign * 1.0]))
        hand_dir[suffix] = geom.normalize(np.array([0.95, -0.10, sign * 0.12]))

    hand = PUSHUP_HAND
    shoulder_center = np.array([hand[0] + offset[0], hand[1] + offset[1], 0.0])
    theta = _pushup_body_angle(shoulder_center)
    direction = np.array([math.sin(theta), math.cos(theta), 0.0])
    pelvis = shoulder_center - direction * TORSO_LENGTH
    foot_direction = _rz(-direction, BIND_FOOT_ANGLE + PLANTAR_FLEX_PUSHUP)

    for suffix, sign in (("r", 1.0), ("l", -1.0)):
        hip = np.array([pelvis[0], pelvis[1], sign * 0.105])
        ankle = hip - direction * LEG_LENGTH + np.array([0.0, 0.0, sign * (PUSHUP_ANKLE_Z - 0.105)])
        ankle_target[suffix] = ankle
        knee_pole[suffix] = np.array([0.0, -1.0, sign * 0.05])
        foot_dir[suffix] = geom.normalize(np.array([foot_direction[0], foot_direction[1], sign * 0.03]))

    return PoseSpec(
        root_head=pelvis + direction * PELVIS_OFFSET,
        torso_dir=direction,
        head_dir=geom.normalize(direction + UP * 0.45),
        wrist_target=wrist,
        elbow_pole=elbow_pole,
        hand_dir=hand_dir,
        hand_pole={suffix: UP for suffix in ("r", "l")},
        ankle_target=ankle_target,
        knee_pole=knee_pole,
        foot_dir=foot_dir,
    )


# --------------------------------------------------------------------------
# Squat landmarks
# --------------------------------------------------------------------------

SQUAT_ANKLE = np.array([0.0, 0.095, 0.16])
SQUAT_HIPS_TOP = np.array([0.0, 0.98, 0.0])
SQUAT_HIPS_BOTTOM = np.array([-0.205, 0.626, 0.0])
SQUAT_LEAN_BOTTOM = math.radians(30.0)
SQUAT_WRIST_TOP = np.array([0.0, 0.88, 0.225])
SQUAT_WRIST_BOTTOM = np.array([0.52, 1.02, 0.17])


def squat_spec(t: float) -> PoseSpec:
    amount = phase_from_segments(t, SQUAT_SEGMENTS)
    lean = SQUAT_LEAN_BOTTOM * amount
    torso_dir = np.array([math.sin(lean), math.cos(lean), 0.0])
    hips_head = _lerp(SQUAT_HIPS_TOP, SQUAT_HIPS_BOTTOM, amount)

    wrist = {}
    elbow_pole = {}
    hand_pole = {}
    hand_dir = {}
    ankle_target = {}
    knee_pole = {}
    foot_dir = {}
    bind_hand_dir = geom.normalize(np.array(BONE_TAIL["hand_r"]) - np.array(BONE_HEAD["hand_r"]))
    forward_hand_dir = geom.normalize(np.array([0.86, -0.05, 0.0]))
    for suffix, sign in (("r", 1.0), ("l", -1.0)):
        wrist[suffix] = _lerp(
            SQUAT_WRIST_TOP * np.array([1.0, 1.0, sign]),
            SQUAT_WRIST_BOTTOM * np.array([1.0, 1.0, sign]),
            amount,
        )
        elbow_pole[suffix] = geom.normalize(
            np.array([1.0, 0.0, sign * 0.4]) * (1.0 - amount)
            + np.array([0.0, -0.5, sign * 1.0]) * amount
        )
        hand_pole[suffix] = geom.normalize(
            np.array([1.0, 0.0, sign * 0.2]) * (1.0 - amount) + UP * amount
        )
        hand_dir[suffix] = geom.normalize(bind_hand_dir * (1.0 - amount) + forward_hand_dir * amount)
        ankle_target[suffix] = SQUAT_ANKLE * np.array([1.0, 1.0, sign])
        knee_pole[suffix] = np.array([1.0, -0.08, sign * 0.18])
        foot_dir[suffix] = geom.normalize(
            np.array(BONE_TAIL["foot_r"]) - np.array(BONE_HEAD["foot_r"])
        ) * np.array([1.0, 1.0, sign])

    head_dir = geom.normalize(_lerp(torso_dir, UP, 0.55))
    return PoseSpec(
        root_head=hips_head,
        torso_dir=torso_dir,
        head_dir=head_dir,
        wrist_target=wrist,
        elbow_pole=elbow_pole,
        hand_dir=hand_dir,
        hand_pole=hand_pole,
        ankle_target=ankle_target,
        knee_pole=knee_pole,
        foot_dir=foot_dir,
    )


POSE_FUNCTIONS = {
    "pushups": pushup_spec,
    "squats": squat_spec,
}

KEY_PHASES = {
    "pushups": {"start": 0.04, "mid": 0.25, "end": 0.485},
    "squats": {"start": 0.05, "mid": 0.28, "end": 0.53},
}


def key_phase_time(exercise: str, name: str) -> float:
    return KEY_PHASES[exercise][name]
