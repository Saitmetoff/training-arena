"""Deterministic software renderer for the athlete fallback assets.

Painter's-algorithm rasteriser on Pillow with a fixed three-light rig. It is
intentionally simple and reproducible: no GPU, no textures, no randomness.
The GLB is the interactive path; these frames are the packaged fallback.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from . import geom
from .mesh import AthleteMesh, MATERIAL_COLORS, MATERIALS
from .rig import Pose, pose_normals, pose_vertices
from .spec import CAMERA, LIGHTING, PALETTE


@dataclass
class Camera:
    eye: np.ndarray
    target: np.ndarray
    fov_deg: float
    size: int

    @property
    def view(self) -> np.ndarray:
        return geom.look_at(self.eye, self.target)

    def project(self, points: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
        return geom.project(points, self.view, self.fov_deg, self.size)

    @classmethod
    def fit(
        cls,
        vertex_frames: list[np.ndarray],
        fov_deg: float,
        size: int,
        safe_area: float,
        azimuth_deg: float,
        elevation_deg: float,
    ) -> "Camera":
        cameras, _ = cls.fit_grouped(
            [vertex_frames], fov_deg, size, safe_area, azimuth_deg, elevation_deg
        )
        return cameras[0]

    @classmethod
    def fit_grouped(
        cls,
        subjects: list[list[np.ndarray]],
        fov_deg: float,
        size: int,
        safe_area: float,
        azimuth_deg: float,
        elevation_deg: float,
        screen_shifts: list[float] | None = None,
    ) -> tuple[list["Camera"], float]:
        """Fit several subjects with one camera distance.

        All returned cameras share the same azimuth, elevation, focal length
        and distance (identical perspective and scale), but each is aimed at
        its own subject centre so no pose is pushed into a corner. An optional
        `screen_shifts` offset in metres nudges a subject sideways to leave a
        clean gutter for annotation plates.
        """
        view = geom.camera_eye(1.0, np.zeros(3), azimuth_deg, elevation_deg)
        screen_right = geom.normalize(np.cross(view, np.array([0.0, 1.0, 0.0])))
        targets = []
        for index, vertex_frames in enumerate(subjects):
            points = np.concatenate(vertex_frames, axis=0)
            target = (points.min(axis=0) + points.max(axis=0)) / 2.0
            if screen_shifts:
                target = target + screen_right * screen_shifts[index]
            targets.append(target)
        distance = 6.0
        half = size * safe_area / 2.0
        for _ in range(8):
            worst = 0.0
            for vertex_frames, target in zip(subjects, targets):
                camera = cls(
                    eye=geom.camera_eye(distance, target, azimuth_deg, elevation_deg),
                    target=target,
                    fov_deg=fov_deg,
                    size=size,
                )
                for frame in vertex_frames:
                    screen, _ = camera.project(frame)
                    worst = max(
                        worst,
                        float(np.abs(screen[:, 0] - size / 2.0).max()),
                        float(np.abs(screen[:, 1] - size / 2.0).max()),
                    )
            if worst < 1e-6:
                break
            distance *= worst / half
        cameras = [
            cls(
                eye=geom.camera_eye(distance, target, azimuth_deg, elevation_deg),
                target=target,
                fov_deg=fov_deg,
                size=size,
            )
            for target in targets
        ]
        return cameras, distance


def _light_vectors() -> list[tuple[np.ndarray, np.ndarray, float]]:
    lights = []
    for name in ("key", "fill", "rim"):
        entry = LIGHTING[name]
        lights.append(
            (
                geom.normalize(np.array(entry["dir"])),
                np.array(entry["color"]),
                float(entry["intensity"]),
            )
        )
    return lights


def _shade(
    normals: np.ndarray,
    base_colors: np.ndarray,
    materials: np.ndarray,
    lights: list[tuple[np.ndarray, np.ndarray, float]],
    view_dir: np.ndarray,
) -> np.ndarray:
    """Lambert + ambient + a little specular for every triangle."""
    ambient = np.array(LIGHTING["ambient"]["color"]) * float(LIGHTING["ambient"]["intensity"])
    result = base_colors * ambient
    key_light = lights[0]
    half_vector = geom.normalize(key_light[0] + view_dir)
    specular_shininess = float(LIGHTING["specular"]["shininess"])
    for direction, color, intensity in lights:
        lambert = np.clip(normals @ direction, 0.0, None)
        result += base_colors * lambert[:, None] * (color * intensity)
    specular_weight = np.array(
        [float(LIGHTING["specular"].get(MATERIALS[index], LIGHTING["specular"]["default"])) for index in materials]
    )
    specular = np.clip(normals @ half_vector, 0.0, None) ** specular_shininess
    result += (specular * specular_weight)[:, None] * np.array(LIGHTING["key"]["color"])
    return np.clip(result, 0.0, 1.0)


def _background(size: int) -> Image.Image:
    top = np.array(PALETTE.backdrop_top) * 255.0
    bottom = np.array(PALETTE.backdrop_bottom) * 255.0
    gradient = np.linspace(0.0, 1.0, size)[:, None, None]
    rows = top[None, None, :] * (1.0 - gradient) + bottom[None, None, :] * gradient
    array = np.repeat(rows, size, axis=1).astype(np.uint8)
    return Image.fromarray(array, mode="RGB")


def _shadow_layer(camera: Camera, vertices: np.ndarray, size: int) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    low = vertices.min(axis=0)
    high = vertices.max(axis=0)
    center = np.array([(low[0] + high[0]) / 2.0, 0.004, (low[2] + high[2]) / 2.0])
    radius_x = (high[0] - low[0]) / 2.0 + 0.16
    radius_z = max((high[2] - low[2]) / 2.0 + 0.18, 0.30)
    angles = np.linspace(0.0, 2.0 * math.pi, 48, endpoint=False)
    points = np.array(
        [
            [
                center[0] + math.cos(angle) * radius_x,
                0.004,
                center[2] + math.sin(angle) * radius_z,
            ]
            for angle in angles
        ]
    )
    screen, _ = camera.project(points)
    draw = ImageDraw.Draw(layer)
    draw.polygon([tuple(point) for point in screen], fill=(0, 0, 0, 96))
    return layer.filter(ImageFilter.GaussianBlur(size * 0.022))


def _vignette(image: Image.Image) -> Image.Image:
    size = image.size[0]
    coords = np.linspace(-1.0, 1.0, size)
    xx, yy = np.meshgrid(coords, coords)
    radius = np.sqrt(xx**2 + yy**2)
    alpha = np.clip((radius - 0.62) / 0.75, 0.0, 1.0) * 0.30
    array = np.asarray(image).astype(float)
    array *= (1.0 - alpha)[:, :, None]
    return Image.fromarray(array.astype(np.uint8), mode="RGB")


class Renderer:
    def __init__(self, mesh: AthleteMesh, size: int | None = None, supersample: int | None = None):
        from .spec import RENDER

        self.mesh = mesh
        self.size = size or RENDER["size"]
        self.supersample = supersample or RENDER["supersample"]
        self.lights = _light_vectors()

    def draw(self, pose: Pose, camera: Camera, background: Image.Image | None = None) -> Image.Image:
        ss = self.supersample
        canvas = background if background is not None else _background(camera.size)
        vertices = pose_vertices(self.mesh, pose)
        normals = pose_normals(self.mesh, pose)
        screen, depth = camera.project(vertices)

        shadow = _shadow_layer(camera, vertices, camera.size)
        canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

        triangle_depth = depth[self.mesh.triangles].mean(axis=1)
        order = np.argsort(-triangle_depth)
        triangle_normals = normals[self.mesh.triangles].mean(axis=1)
        lengths = np.linalg.norm(triangle_normals, axis=1)
        lengths[lengths < 1e-9] = 1.0
        triangle_normals = triangle_normals / lengths[:, None]
        base = np.array([MATERIAL_COLORS[MATERIALS[index]] for index in self.mesh.triangle_materials])
        view_dir = geom.normalize(camera.eye - camera.target)
        colors = (_shade(triangle_normals, base, self.mesh.triangle_materials, self.lights, view_dir) * 255.0).astype(
            np.uint8
        )

        draw = ImageDraw.Draw(canvas)
        triangles = self.mesh.triangles
        for index in order:
            face = triangles[index]
            points = screen[face]
            draw.polygon(
                [tuple(points[0]), tuple(points[1]), tuple(points[2])],
                fill=tuple(int(channel) for channel in colors[index]),
            )

        if ss > 1:
            canvas = canvas.resize((self.size, self.size), Image.LANCZOS)
        return _vignette(canvas.convert("RGB"))
