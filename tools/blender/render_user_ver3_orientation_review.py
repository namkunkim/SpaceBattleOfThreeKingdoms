import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


MODELS = [
    "전열함",
    "화력함",
    "항모",
    "공성함",
    "전자전함",
    "보급_수리함",
    "호위함",
]


def script_args():
    args = sys.argv
    args = args[args.index("--") + 1 :] if "--" in args else []
    if len(args) != 2:
        raise SystemExit("usage: blender --background --python SCRIPT -- SOURCE_DIR OUTPUT_DIR")
    return Path(args[0]), Path(args[1])


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1000
    scene.render.resolution_y = 560
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("OrientationWorld")
    world.color = (0.004, 0.009, 0.018)
    scene.world = world
    return scene


def mesh_bounds():
    points = []
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if not points:
        raise RuntimeError("No mesh objects imported")
    low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return low, high


def add_area(name, location, energy, size, color):
    data = bpy.data.lights.new(name, type="AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (0.0, 0.0, 0.0)


def add_axis_marker(x, y, z, label, color):
    text_data = bpy.data.curves.new(label, type="FONT")
    text_data.body = label
    text_data.align_x = "CENTER"
    text_data.align_y = "CENTER"
    text_data.size = 0.11
    text_data.extrude = 0.003
    mat = bpy.data.materials.new(label + "_material")
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
    bsdf.inputs["Emission Strength"].default_value = 2.0
    text_data.materials.append(mat)
    obj = bpy.data.objects.new(label, text_data)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, y, z)


def render_model(source, output):
    scene = reset_scene()
    bpy.ops.import_scene.gltf(filepath=str(source))
    low, high = mesh_bounds()
    center = (low + high) * 0.5
    size = high - low
    span = max(size.x, size.y, size.z)

    camera_data = bpy.data.cameras.new("TopCamera")
    camera = bpy.data.objects.new("TopCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = (center.x, center.y, high.z + span * 2.4)
    camera.rotation_euler = (0.0, 0.0, 0.0)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(size.y * 1.75, size.x / (1000 / 560) * 1.35)
    scene.camera = camera

    add_area("Key", (center.x - span * 0.25, center.y - span * 0.15, high.z + span), 1200, span * 2.0, (0.72, 0.84, 1.0))
    add_area("Fill", (center.x + span * 0.4, center.y + span * 0.25, high.z + span * 0.55), 800, span * 1.3, (1.0, 0.68, 0.42))

    marker_y = low.y - max(size.y * 0.28, span * 0.07)
    marker_z = high.z + span * 0.015
    add_axis_marker(low.x + size.x * 0.08, marker_y, marker_z, "-X", (1.0, 0.3, 0.25))
    add_axis_marker(high.x - size.x * 0.08, marker_y, marker_z, "+X", (0.25, 0.85, 1.0))

    scene.render.filepath = str(output)
    scene.view_settings.look = "AgX - Medium High Contrast"
    bpy.ops.render.render(write_still=True)
    print(f"ORIENTATION_RENDER {source.name} -> {output}")


def main():
    source_dir, output_dir = script_args()
    output_dir.mkdir(parents=True, exist_ok=True)
    for name in MODELS:
        render_model(source_dir / f"{name}.glb", output_dir / f"{name}.png")


if __name__ == "__main__":
    main()
