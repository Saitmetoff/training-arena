"""Small right-handed vector / rotation helpers used by the athlete rig."""

from __future__ import annotations

import math

import numpy as np

EPS = 1e-9


def vec(*values: float) -> np.ndarray:
    return np.array(values, dtype=float)


def normalize(v: np.ndarray) -> np.ndarray:
    n = float(np.linalg.norm(v))
    if n < EPS:
        raise ValueError("cannot normalize a zero vector")
    return v / n


def rotation_axis_angle(axis: np.ndarray, angle_rad: float) -> np.ndarray:
    axis = normalize(axis)
    x, y, z = axis
    c = math.cos(angle_rad)
    s = math.sin(angle_rad)
    t = 1.0 - c
    return np.array(
        [
            [t * x * x + c, t * x * y - s * z, t * x * z + s * y],
            [t * x * y + s * z, t * y * y + c, t * y * z - s * x],
            [t * x * z - s * y, t * y * z + s * x, t * z * z + c],
        ]
    )


def rotation_between(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Minimal rotation matrix mapping unit vector a onto unit vector b."""
    a = normalize(a)
    b = normalize(b)
    cross = np.cross(a, b)
    dot = float(np.clip(np.dot(a, b), -1.0, 1.0))
    if np.linalg.norm(cross) < 1e-8:
        if dot > 0.0:
            return np.eye(3)
        # Opposite vectors: rotate 180 degrees around any perpendicular axis.
        helper = vec(0.0, 1.0, 0.0) if abs(a[1]) < 0.9 else vec(1.0, 0.0, 0.0)
        axis = normalize(np.cross(a, helper))
        return rotation_axis_angle(axis, math.pi)
    axis = normalize(cross)
    return rotation_axis_angle(axis, math.acos(dot))


def frame_from_dir_and_pole(direction: np.ndarray, pole: np.ndarray) -> np.ndarray:
    """Orthonormal frame [side, direction, normal] whose Y axis is `direction`.

    `pole` selects the side: side = normalize(pole x direction) so that the
    bend plane (direction, normal) contains the pole direction.
    """
    direction = normalize(direction)
    pole = np.asarray(pole, dtype=float)
    side = np.cross(pole, direction)
    if np.linalg.norm(side) < 1e-6:
        helper = vec(0.0, 0.0, 1.0) if abs(direction[2]) < 0.9 else vec(0.0, 1.0, 0.0)
        side = np.cross(direction, helper)
    side = normalize(side)
    normal = normalize(np.cross(direction, side))
    # columns: x = side, y = direction, z = normal
    return np.column_stack((side, direction, normal))


def rotation_from_dirs(
    bind_dir: np.ndarray, bind_pole: np.ndarray, cur_dir: np.ndarray, cur_pole: np.ndarray
) -> np.ndarray:
    """World rotation taking the bind bone direction/pole to the posed one."""
    bind_frame = frame_from_dir_and_pole(bind_dir, bind_pole)
    cur_frame = frame_from_dir_and_pole(cur_dir, cur_pole)
    return cur_frame @ bind_frame.T


def limb_ik(
    root: np.ndarray,
    target: np.ndarray,
    length_a: float,
    length_b: float,
    pole: np.ndarray,
    min_bend_deg: float = 4.0,
) -> tuple[np.ndarray, np.ndarray]:
    """Two-bone IK.

    Returns (joint, tail) where `joint` is the middle joint (elbow/knee) placed
    on the pole side of the root->target line and `tail` is clamped to the
    reachable distance of the chain.
    """
    root = np.asarray(root, dtype=float)
    target = np.asarray(target, dtype=float)
    delta = target - root
    distance = float(np.linalg.norm(delta))
    if distance < EPS:
        raise ValueError("IK target coincides with the chain root")
    direction = delta / distance

    reach = length_a + length_b - 1e-4
    # Keep the joint slightly off the straight line so the bend plane stays
    # numerically stable: the interior angle never exceeds 180 - min_bend_deg,
    # which caps how far the chain may reach.
    straight_bend = math.radians(180.0 - min_bend_deg)
    bend_limit = math.sqrt(
        max(length_a**2 + length_b**2 - 2 * length_a * length_b * math.cos(straight_bend), 1e-8)
    )
    reach = min(reach, bend_limit)
    minimum = abs(length_a - length_b) + 1e-4
    clamped = float(np.clip(distance, minimum, reach))
    tail = root + direction * clamped

    # Standard two-bone solution: distance along the chain to the joint
    # projection plus the perpendicular joint offset.
    along = (length_a**2 - length_b**2 + clamped**2) / (2.0 * clamped)
    height = math.sqrt(max(length_a**2 - along**2, 0.0))

    pole_dir = np.asarray(pole, dtype=float)
    normal = pole_dir - direction * float(np.dot(pole_dir, direction))
    if np.linalg.norm(normal) < 1e-6:
        helper = vec(0.0, 0.0, 1.0) if abs(direction[2]) < 0.9 else vec(1.0, 0.0, 0.0)
        normal = helper - direction * float(np.dot(helper, direction))
    normal = normalize(normal)

    joint = root + direction * along + normal * height
    return joint, tail


def look_at(eye: np.ndarray, target: np.ndarray, up: np.ndarray = vec(0.0, 1.0, 0.0)) -> np.ndarray:
    """Right-handed camera view matrix (camera looks down its -Z axis)."""
    forward = normalize(target - eye)
    right = np.cross(forward, up)
    if np.linalg.norm(right) < 1e-6:
        right = np.cross(forward, vec(0.0, 0.0, 1.0))
    right = normalize(right)
    true_up = np.cross(right, forward)
    view = np.eye(4)
    view[0, :3] = right
    view[1, :3] = true_up
    view[2, :3] = -forward
    view[:3, 3] = -view[:3, :3] @ eye
    return view


def project(points: np.ndarray, view: np.ndarray, fov_deg: float, size: int) -> tuple[np.ndarray, np.ndarray]:
    """Project world points to pixel coordinates.

    Returns (screen_xy, depth) where depth is the positive camera-space
    distance along the view direction.
    """
    points = np.atleast_2d(np.asarray(points, dtype=float))
    homogeneous = np.column_stack((points, np.ones(len(points))))
    camera = (view @ homogeneous.T).T[:, :3]
    depth = -camera[:, 2]
    depth = np.where(np.abs(depth) < 1e-6, 1e-6, depth)
    focal = (size / 2.0) / math.tan(math.radians(fov_deg) / 2.0)
    screen = np.column_stack(
        (size / 2.0 + focal * camera[:, 0] / depth, size / 2.0 - focal * camera[:, 1] / depth)
    )
    return screen, depth


def camera_eye(distance: float, target: np.ndarray, azimuth_deg: float, elevation_deg: float) -> np.ndarray:
    azimuth = math.radians(azimuth_deg)
    elevation = math.radians(elevation_deg)
    direction = vec(
        math.cos(elevation) * math.cos(azimuth),
        math.sin(elevation),
        math.cos(elevation) * math.sin(azimuth),
    )
    return np.asarray(target, dtype=float) + direction * distance
