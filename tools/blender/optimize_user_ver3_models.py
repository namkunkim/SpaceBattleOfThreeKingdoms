import json
import sys
from pathlib import Path

import bpy


TARGET_TRIANGLES = {
    "전열함": 55_000,
    "화력함": 60_000,
    "항모": 60_000,
    "공성함": 60_000,
    "전자전함": 45_000,
    "보급_수리함": 45_000,
    "호위함": 25_000,
}


def triangle_count(mesh):
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def optimize(source_path, output_path, target_triangles):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    before = sum(triangle_count(obj.data) for obj in mesh_objects)
    ratio = min(1.0, target_triangles / max(1, before))
    if ratio < 0.999:
        for obj in mesh_objects:
            bpy.context.view_layer.objects.active = obj
            obj.select_set(True)
            modifier = obj.modifiers.new(name="Runtime_LOD0_Decimate", type="DECIMATE")
            modifier.decimate_type = "COLLAPSE"
            modifier.ratio = ratio
            modifier.use_collapse_triangulate = True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            obj.select_set(False)
    for image in bpy.data.images:
        width, height = image.size
        if width > 2048 or height > 2048:
            scale = min(2048 / width, 2048 / height)
            image.scale(max(1, round(width * scale)), max(1, round(height * scale)))
    after = sum(triangle_count(obj.data) for obj in mesh_objects)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(output_path), export_format="GLB", export_materials="EXPORT", export_yup=True)
    return {"model": source_path.stem, "triangles_before": before, "triangles_after": after, "ratio": ratio}


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    source_dir = Path(args[0])
    output_dir = Path(args[1])
    results = []
    for model_name, target in TARGET_TRIANGLES.items():
        source_path = source_dir / f"{model_name}.glb"
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        result = optimize(source_path, output_dir / f"{model_name}.glb", target)
        results.append(result)
        print("OPTIMIZED " + json.dumps(result, ensure_ascii=False), flush=True)
    print("OPTIMIZE_USER_VER3_PASS " + json.dumps(results, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
