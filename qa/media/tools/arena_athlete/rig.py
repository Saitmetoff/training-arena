"""Rig solver: turns high-level pose specs into rigid bone transforms.

The skeleton is rigid: every child bone head sits at its parent's tail in the
parent's frame. Poses are authored as world-space directions plus IK targets,
then converted into per-bone world rotations. Skinning is one bone per vertex
with weight 1.0, so a vertex bound to bone B transforms as

    v' = head_world(B) + R_world(B) @ (v - head_bind(B))
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from . import geom
from .mesh import AthleteMesh
from .spec import (
    BONE_HEAD,
    BONE_NAMES,
    BONE_PARENT,
    BONE_TAIL,
    FOREARM_LENGTH,
    LEG_LENGTH,
    SHIN_LENGTH,
    THIGH_LENGTH,
    UPPERARM_LENGTH,
)

FORWARD = np.array([1.0, 0.0, 0.0])
UP = np.array([0.0, 1.0, 0.0])

BIND_DIR = {name: geom.normalize(np.array(BONE_TAIL[name]) - np.array(BONE_HEAD[name])) for name in BONE_NAMES}
BIND_POLE = {name: (UP if name.startswith("foot") else FORWARD) for name in BONE_NAMES}


@dataclass
class PoseSpec:
    """World-space description of one frame."""

    root_head: np.ndarray  # hips head position
    torso_dir: np.ndarray  # direction of hips/spine/chest (pelvis -> shoulder center)
    head_dir: np.ndarray
    wrist_target: dict[str, np.ndarray] = field(default_factory=dict)
    elbow_pole: dict[str, np.ndarray] = field(default_factory=dict)
    hand_dir: dict[str, np.ndarray] = field(default_factory=dict)
    hand_pole: dict[str, np.ndarray] = field(default_factory=dict)
    ankle_target: dict[str, np.ndarray] = field(default_factory=dict)
    knee_pole: dict[str, np.ndarray] = field(default_factory=dict)
    foot_dir: dict[str, np.ndarray] = field(default_factory=dict)


@dataclass
class Pose:
    heads: dict[str, np.ndarray]
    rotations: dict[str, np.ndarray]

    def bone_matrix(self, name: str, vertices: np.ndarray) -> np.ndarray:
        head = self.heads[name]
        rotation = self.rotations[name]
        bind_head = np.array(BONE_HEAD[name])
        return head + (vertices - bind_head) @ rotation.T


def _bone_head(pose_heads: dict[str, np.ndarray], rotations: dict[str, np.ndarray], name: str) -> np.ndarray:
    parent = BONE_PARENT[name]
    if parent is None:
        raise ValueError(f"{name} has no parent")
    offset = np.array(BONE_HEAD[name]) - np.array(BONE_HEAD[parent])
    return pose_heads[parent] + rotations[parent] @ offset


def solve(spec: PoseSpec) -> Pose:
    torso_dir = geom.normalize(spec.torso_dir)
    head_dir = geom.normalize(spec.head_dir)
    heads: dict[str, np.ndarray] = {}
    rotations: dict[str, np.ndarray] = {}

    # --- torso chain ------------------------------------------------------
    heads["hips"] = np.asarray(spec.root_head, dtype=float)
    rotations["hips"] = geom.rotation_from_dirs(BIND_DIR["hips"], BIND_POLE["hips"], torso_dir, FORWARD)
    for name in ("spine", "chest"):
        heads[name] = _bone_head(heads, rotations, name)
        rotations[name] = geom.rotation_from_dirs(BIND_DIR[name], BIND_POLE[name], torso_dir, FORWARD)
    heads["neck"] = _bone_head(heads, rotations, "neck")
    rotations["neck"] = geom.rotation_from_dirs(BIND_DIR["neck"], BIND_POLE["neck"], head_dir, FORWARD)
    heads["head"] = _bone_head(heads, rotations, "head")
    rotations["head"] = geom.rotation_from_dirs(BIND_DIR["head"], BIND_POLE["head"], head_dir, FORWARD)

    # --- arms -------------------------------------------------------------
    for suffix in ("r", "l"):
        clavicle = f"clavicle_{suffix}"
        upperarm = f"upperarm_{suffix}"
        forearm = f"forearm_{suffix}"
        hand = f"hand_{suffix}"
        heads[clavicle] = _bone_head(heads, rotations, clavicle)
        rotations[clavicle] = geom.rotation_from_dirs(
            BIND_DIR[clavicle], BIND_POLE[clavicle], rotations["chest"] @ BIND_DIR[clavicle], FORWARD
        )
        shoulder = heads[clavicle] + rotations[clavicle] @ (
            np.array(BONE_TAIL[clavicle]) - np.array(BONE_HEAD[clavicle])
        )
        heads[upperarm] = shoulder

        target = np.asarray(spec.wrist_target[suffix], dtype=float)
        pole = np.asarray(spec.elbow_pole[suffix], dtype=float)
        elbow, wrist = geom.limb_ik(shoulder, target, UPPERARM_LENGTH, FOREARM_LENGTH, pole)
        rotations[upperarm] = geom.rotation_from_dirs(
            BIND_DIR[upperarm], BIND_POLE[upperarm], geom.normalize(elbow - shoulder), pole
        )
        heads[forearm] = elbow
        rotations[forearm] = geom.rotation_from_dirs(
            BIND_DIR[forearm], BIND_POLE[forearm], geom.normalize(wrist - elbow), pole
        )
        heads[hand] = wrist
        hand_pole = np.asarray(spec.hand_pole.get(suffix, pole), dtype=float)
        rotations[hand] = geom.rotation_from_dirs(
            BIND_DIR[hand], BIND_POLE[hand], geom.normalize(spec.hand_dir[suffix]), hand_pole
        )

    # --- legs -------------------------------------------------------------
    for suffix in ("r", "l"):
        thigh = f"thigh_{suffix}"
        shin = f"shin_{suffix}"
        foot = f"foot_{suffix}"
        heads[thigh] = _bone_head(heads, rotations, thigh)
        hip = heads[thigh]
        target = np.asarray(spec.ankle_target[suffix], dtype=float)
        pole = np.asarray(spec.knee_pole[suffix], dtype=float)
        knee, ankle = geom.limb_ik(hip, target, THIGH_LENGTH, SHIN_LENGTH, pole)
        rotations[thigh] = geom.rotation_from_dirs(
            BIND_DIR[thigh], BIND_POLE[thigh], geom.normalize(knee - hip), pole
        )
        heads[shin] = knee
        rotations[shin] = geom.rotation_from_dirs(
            BIND_DIR[shin], BIND_POLE[shin], geom.normalize(ankle - knee), pole
        )
        heads[foot] = ankle
        rotations[foot] = geom.rotation_from_dirs(
            BIND_DIR[foot], BIND_POLE[foot], geom.normalize(spec.foot_dir[suffix]), UP
        )

    return Pose(heads=heads, rotations=rotations)


def pose_vertices(mesh: AthleteMesh, pose: Pose) -> np.ndarray:
    """Apply rigid skinning; returns posed vertices in world space."""
    output = np.array(mesh.vertices, dtype=float)
    for index, name in enumerate(BONE_NAMES):
        selection = mesh.joints == index
        if not selection.any():
            continue
        output[selection] = pose.bone_matrix(name, mesh.vertices[selection])
    return output


def pose_normals(mesh: AthleteMesh, pose: Pose) -> np.ndarray:
    output = np.array(mesh.normals, dtype=float)
    for index, name in enumerate(BONE_NAMES):
        selection = mesh.joints == index
        if not selection.any():
            continue
        output[selection] = mesh.normals[selection] @ pose.rotations[name].T
    return output


def bone_index() -> dict[str, int]:
    return {name: index for index, name in enumerate(BONE_NAMES)}
