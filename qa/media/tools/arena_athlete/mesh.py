"""Procedural mesh for the Arena Mannequin Athlete.

Every part is authored in the bind pose (neutral standing start of the squat
demo) and rigidly bound to exactly one bone. Parts are grouped by material so
the GLB exports one primitive per material.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

from . import geom
from .spec import (
    BONE_HEAD,
    BONE_TAIL,
    FOOT_LENGTH,
    PALETTE,
    PROPORTIONS,
)

MATERIALS = ["skin", "hair", "accent", "kit_top", "kit_bottom", "glove", "shoe"]

MATERIAL_COLORS = {
    "skin": PALETTE.skin,
    "hair": PALETTE.hair,
    "accent": PALETTE.accent,
    "kit_top": PALETTE.kit_top,
    "kit_bottom": PALETTE.kit_bottom,
    "glove": PALETTE.glove,
    "shoe": PALETTE.shoe,
}


@dataclass
class Part:
    verts: np.ndarray
    faces: np.ndarray
    bone: str
    material: str
    smooth: bool = True


@dataclass
class AthleteMesh:
    vertices: np.ndarray  # (N, 3) float64 bind-pose positions
    normals: np.ndarray  # (N, 3) float64
    joints: np.ndarray  # (N,) int bone indices
    triangles: np.ndarray  # (M, 3) int
    triangle_materials: np.ndarray  # (M,) int material indices
    material_names: list[str] = field(default_factory=list)


def _segment_frame(p0: np.ndarray, p1: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    direction = geom.normalize(p1 - p0)
    helper = np.array([0.0, 1.0, 0.0]) if abs(direction[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    side = geom.normalize(np.cross(helper, direction))
    normal = geom.normalize(np.cross(direction, side))
    return side, direction, normal


def tapered_cylinder(
    p0: np.ndarray,
    p1: np.ndarray,
    radius0: float,
    radius1: float,
    segments: int = 12,
    caps: bool = True,
) -> tuple[np.ndarray, np.ndarray]:
    side, direction, normal = _segment_frame(p0, p1)
    rings: list[list[int]] = []
    verts: list[np.ndarray] = []
    for center, radius in ((p0, radius0), (p1, radius1)):
        ring = []
        for index in range(segments):
            angle = 2.0 * math.pi * index / segments
            offset = side * (math.cos(angle) * radius) + normal * (math.sin(angle) * radius)
            ring.append(len(verts))
            verts.append(center + offset)
        rings.append(ring)

    faces: list[tuple[int, int, int]] = []
    for index in range(segments):
        nxt = (index + 1) % segments
        a, b = rings[0][index], rings[0][nxt]
        c, d = rings[1][nxt], rings[1][index]
        faces.append((a, b, c))
        faces.append((a, c, d))
    if caps:
        start_center = len(verts)
        verts.append(p0)
        end_center = len(verts)
        verts.append(p1)
        for index in range(segments):
            nxt = (index + 1) % segments
            faces.append((start_center, rings[0][nxt], rings[0][index]))
            faces.append((end_center, rings[1][index], rings[1][nxt]))
    return np.array(verts), np.array(faces, dtype=int)


def sphere(
    center: np.ndarray,
    radius: float,
    segments_u: int = 18,
    segments_v: int = 12,
    scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
    keep=None,
) -> tuple[np.ndarray, np.ndarray]:
    verts: list[np.ndarray] = []
    grid: list[list[int]] = []
    scale_arr = np.array(scale)
    for v_index in range(segments_v + 1):
        phi = math.pi * v_index / segments_v
        row = []
        for u_index in range(segments_u):
            theta = 2.0 * math.pi * u_index / segments_u
            offset = np.array(
                [
                    math.sin(phi) * math.cos(theta),
                    math.cos(phi),
                    math.sin(phi) * math.sin(theta),
                ]
            )
            point = center + (offset * scale_arr) * radius
            row.append(len(verts))
            verts.append(point)
        grid.append(row)
    faces: list[tuple[int, int, int]] = []
    for v_index in range(segments_v):
        for u_index in range(segments_u):
            nxt = (u_index + 1) % segments_u
            a = grid[v_index][u_index]
            b = grid[v_index][nxt]
            c = grid[v_index + 1][nxt]
            d = grid[v_index + 1][u_index]
            if v_index != 0:
                faces.append((a, b, c))
            if v_index != segments_v - 1:
                faces.append((a, c, d))
    if keep is not None:
        kept = []
        for face in faces:
            centroid = np.mean([verts[i] for i in face], axis=0)
            if keep(centroid):
                kept.append(face)
        faces = kept
    return np.array(verts), np.array(faces, dtype=int)


def loft(
    sections: list[tuple[float, float, float, float]],
    segments: int = 14,
    cap_bottom: bool = True,
    cap_top: bool = True,
    center_x: float = 0.0,
    center_z: float = 0.0,
) -> tuple[np.ndarray, np.ndarray]:
    """Loft superellipse sections. Each section is (y, half_depth_x, half_width_z, exponent)."""
    verts: list[np.ndarray] = []
    rings: list[list[int]] = []
    for y, half_depth, half_width, exponent in sections:
        ring = []
        for index in range(segments):
            angle = 2.0 * math.pi * (index + 0.5) / segments
            cos_a = math.cos(angle)
            sin_a = math.sin(angle)
            x = math.copysign(abs(cos_a) ** (2.0 / exponent), cos_a) * half_depth
            z = math.copysign(abs(sin_a) ** (2.0 / exponent), sin_a) * half_width
            ring.append(len(verts))
            verts.append(np.array([center_x + x, y, center_z + z]))
        rings.append(ring)

    faces: list[tuple[int, int, int]] = []
    for index in range(len(sections) - 1):
        lower, upper = rings[index], rings[index + 1]
        for seg in range(segments):
            nxt = (seg + 1) % segments
            faces.append((lower[seg], lower[nxt], upper[nxt]))
            faces.append((lower[seg], upper[nxt], upper[seg]))
    if cap_bottom:
        center = len(verts)
        verts.append(np.array([center_x, sections[0][0], center_z]))
        for seg in range(segments):
            nxt = (seg + 1) % segments
            faces.append((center, rings[0][nxt], rings[0][seg]))
    if cap_top:
        center = len(verts)
        verts.append(np.array([center_x, sections[-1][0], center_z]))
        for seg in range(segments):
            nxt = (seg + 1) % segments
            faces.append((center, rings[-1][seg], rings[-1][nxt]))
    return np.array(verts), np.array(faces, dtype=int)


def oriented_box(
    origin: np.ndarray,
    axis_x: np.ndarray,
    axis_y: np.ndarray,
    axis_z: np.ndarray,
    min_corner: tuple[float, float, float],
    max_corner: tuple[float, float, float],
) -> tuple[np.ndarray, np.ndarray]:
    corners = []
    for sx in (min_corner[0], max_corner[0]):
        for sy in (min_corner[1], max_corner[1]):
            for sz in (min_corner[2], max_corner[2]):
                corners.append(origin + axis_x * sx + axis_y * sy + axis_z * sz)
    verts = np.array(corners)
    # index order follows the (sx, sy, sz) loops
    faces = np.array(
        [
            (0, 1, 3), (0, 3, 2),  # -x
            (4, 6, 7), (4, 7, 5),  # +x
            (0, 4, 5), (0, 5, 1),  # -y
            (2, 3, 7), (2, 7, 6),  # +y
            (0, 2, 6), (0, 6, 4),  # -z
            (1, 5, 7), (1, 7, 3),  # +z
        ],
        dtype=int,
    )
    return verts, faces


def build_parts() -> list[Part]:
    parts: list[Part] = []
    head_center = np.array([0.0, PROPORTIONS["head_center_y"], 0.0])
    head_radius = PROPORTIONS["head_radius"]

    # --- head, hair cap, lime visor -------------------------------------
    verts, faces = sphere(head_center, head_radius, 22, 14, scale=(1.04, 1.0, 0.94))
    parts.append(Part(verts, faces, "head", "skin", smooth=True))

    verts, faces = sphere(
        head_center + np.array([-0.008, 0.006, 0.0]),
        head_radius * 1.02,
        20,
        12,
        scale=(1.03, 1.0, 0.94),
        keep=lambda c: (c[0] < -0.03 and c[1] > 1.615) or c[1] > 1.722,
    )
    parts.append(Part(verts, faces, "head", "hair", smooth=True))

    verts, faces = sphere(
        head_center + np.array([0.0, 0.004, 0.0]),
        head_radius * 1.045,
        24,
        16,
        scale=(1.04, 1.0, 0.94),
        keep=lambda c: c[0] > 0.05 and 1.628 < c[1] < 1.672,
    )
    parts.append(Part(verts, faces, "head", "accent", smooth=True))

    verts, faces = tapered_cylinder(
        np.array([0.0, 1.445, 0.0]), np.array([0.0, 1.575, 0.0]), 0.056, 0.05, 12
    )
    parts.append(Part(verts, faces, "neck", "skin", smooth=True))

    # --- torso (training top) -------------------------------------------
    verts, faces = loft(
        [
            (1.00, 0.160, 0.163, 2.6),
            (1.08, 0.152, 0.155, 2.6),
            (1.17, 0.150, 0.152, 2.5),
            (1.29, 0.185, 0.198, 2.4),
            (1.40, 0.194, 0.212, 2.4),
            (1.462, 0.170, 0.188, 2.4),
        ]
    )
    parts.append(Part(verts, faces, "chest", "kit_top", smooth=True))
    # split the hem of the top between hips and chest ownership
    verts, faces = loft(
        [
            (0.995, 0.163, 0.166, 2.6),
            (1.02, 0.166, 0.169, 2.6),
        ],
        segments=14,
        cap_bottom=False,
        cap_top=False,
    )
    parts.append(Part(verts, faces, "hips", "kit_top", smooth=True))

    verts, faces = oriented_box(
        np.zeros(3),
        np.array([1.0, 0.0, 0.0]),
        np.array([0.0, 1.0, 0.0]),
        np.array([0.0, 0.0, 1.0]),
        (0.148, 1.285, -0.052),
        (0.196, 1.34, 0.052),
    )
    parts.append(Part(verts, faces, "chest", "accent", smooth=False))

    # --- shorts ----------------------------------------------------------
    verts, faces = loft(
        [
            (0.655, 0.183, 0.186, 2.4),
            (0.74, 0.176, 0.180, 2.45),
            (0.84, 0.166, 0.172, 2.5),
            (0.91, 0.170, 0.178, 2.5),
            (0.97, 0.176, 0.183, 2.6),
            (1.045, 0.166, 0.172, 2.6),
        ]
    )
    parts.append(Part(verts, faces, "hips", "kit_bottom", smooth=True))

    verts, faces = loft(
        [
            (1.012, 0.176, 0.181, 2.6),
            (1.05, 0.174, 0.179, 2.6),
        ],
        segments=14,
        cap_bottom=False,
        cap_top=False,
    )
    parts.append(Part(verts, faces, "hips", "accent", smooth=True))

    # --- arms -------------------------------------------------------------
    for suffix, sign in (("r", 1.0), ("l", -1.0)):
        shoulder = np.array([0.0, 1.42, sign * 0.19])
        elbow = np.array([0.0, 1.14, sign * 0.215])
        wrist = np.array([0.0, 0.88, sign * 0.225])
        hand_tip = np.array([0.02, 0.79, sign * 0.225])

        verts, faces = sphere(shoulder, 0.068, 16, 10)
        parts.append(Part(verts, faces, f"clavicle_{suffix}", "kit_top", smooth=True))

        verts, faces = tapered_cylinder(shoulder, elbow, 0.056, 0.046, 12)
        parts.append(Part(verts, faces, f"upperarm_{suffix}", "skin", smooth=True))

        sleeve_end = shoulder + (elbow - shoulder) * 0.42
        verts, faces = tapered_cylinder(shoulder + (elbow - shoulder) * 0.02, sleeve_end, 0.063, 0.058, 12)
        parts.append(Part(verts, faces, f"upperarm_{suffix}", "kit_top", smooth=True))

        cuff_start = shoulder + (elbow - shoulder) * 0.40
        cuff_end = shoulder + (elbow - shoulder) * 0.46
        verts, faces = tapered_cylinder(cuff_start, cuff_end, 0.0605, 0.0605, 12)
        parts.append(Part(verts, faces, f"upperarm_{suffix}", "accent", smooth=True))

        verts, faces = sphere(elbow, 0.05, 14, 9)
        parts.append(Part(verts, faces, f"forearm_{suffix}", "skin", smooth=True))

        verts, faces = tapered_cylinder(elbow, wrist, 0.046, 0.035, 12)
        parts.append(Part(verts, faces, f"forearm_{suffix}", "skin", smooth=True))

        band_a = elbow + (wrist - elbow) * 0.74
        band_b = elbow + (wrist - elbow) * 0.92
        verts, faces = tapered_cylinder(band_a, band_b, 0.047, 0.043, 12)
        parts.append(Part(verts, faces, f"forearm_{suffix}", "accent", smooth=True))

        hand_dir = geom.normalize(hand_tip - wrist)
        side, _, normal = _segment_frame(wrist, hand_tip)
        verts, faces = oriented_box(
            wrist,
            side,
            hand_dir,
            normal,
            (-0.038, -0.01, -0.02),
            (0.038, 0.105, 0.02),
        )
        parts.append(Part(verts, faces, f"hand_{suffix}", "glove", smooth=False))

    # --- legs -------------------------------------------------------------
    for suffix, sign in (("r", 1.0), ("l", -1.0)):
        hip = np.array(BONE_HEAD[f"thigh_{suffix}"])
        knee = np.array(BONE_TAIL[f"thigh_{suffix}"])
        ankle = np.array(BONE_HEAD[f"foot_{suffix}"])
        toe = np.array(BONE_TAIL[f"foot_{suffix}"])

        verts, faces = tapered_cylinder(hip, knee, 0.089, 0.065, 14)
        parts.append(Part(verts, faces, f"thigh_{suffix}", "skin", smooth=True))

        verts, faces = sphere(knee, 0.066, 16, 10)
        parts.append(Part(verts, faces, f"shin_{suffix}", "skin", smooth=True))

        verts, faces = tapered_cylinder(knee, ankle, 0.064, 0.045, 14)
        parts.append(Part(verts, faces, f"shin_{suffix}", "skin", smooth=True))

        foot_dir = geom.normalize(toe - ankle)
        side, _, normal = _segment_frame(ankle, toe)
        verts, faces = oriented_box(
            ankle,
            side,
            foot_dir,
            normal,
            (-0.055, -0.035, -0.012),
            (0.055, FOOT_LENGTH + 0.06, 0.082),
        )
        parts.append(Part(verts, faces, f"foot_{suffix}", "shoe", smooth=False))

        verts, faces = oriented_box(
            ankle,
            side,
            foot_dir,
            normal,
            (-0.058, -0.048, -0.03),
            (0.058, FOOT_LENGTH + 0.066, -0.006),
        )
        parts.append(Part(verts, faces, f"foot_{suffix}", "accent", smooth=False))

    return parts


def _vertex_normals(verts: np.ndarray, faces: np.ndarray) -> np.ndarray:
    normals = np.zeros_like(verts)
    for face in faces:
        a, b, c = verts[face[0]], verts[face[1]], verts[face[2]]
        normal = np.cross(b - a, c - a)
        normals[face[0]] += normal
        normals[face[1]] += normal
        normals[face[2]] += normal
    lengths = np.linalg.norm(normals, axis=1)
    lengths[lengths < 1e-9] = 1.0
    return normals / lengths[:, None]


def build_mesh(bone_index: dict[str, int]) -> AthleteMesh:
    parts = build_parts()
    vertices: list[np.ndarray] = []
    normals: list[np.ndarray] = []
    joints: list[int] = []
    triangles: list[tuple[int, int, int]] = []
    triangle_materials: list[int] = []

    for part in parts:
        if part.smooth:
            base = len(vertices)
            vertex_normals = _vertex_normals(part.verts, part.faces)
            vertices.extend(part.verts)
            normals.extend(vertex_normals)
            joints.extend([bone_index[part.bone]] * len(part.verts))
            material_index = MATERIALS.index(part.material)
            for face in part.faces:
                triangles.append((base + face[0], base + face[1], base + face[2]))
                triangle_materials.append(material_index)
        else:
            material_index = MATERIALS.index(part.material)
            for face in part.faces:
                a, b, c = part.verts[face[0]], part.verts[face[1]], part.verts[face[2]]
                normal = geom.normalize(np.cross(b - a, c - a))
                base = len(vertices)
                vertices.extend([a, b, c])
                normals.extend([normal, normal, normal])
                joints.extend([bone_index[part.bone]] * 3)
                triangles.append((base, base + 1, base + 2))
                triangle_materials.append(material_index)

    return AthleteMesh(
        vertices=np.array(vertices),
        normals=np.array(normals),
        joints=np.array(joints, dtype=int),
        triangles=np.array(triangles, dtype=int),
        triangle_materials=np.array(triangle_materials, dtype=int),
        material_names=list(MATERIALS),
    )
