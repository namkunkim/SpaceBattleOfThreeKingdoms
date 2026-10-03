"""함대 대량 표시용 저폴리 LOD를 만든다.

user_ver3_runtime 모델(척당 3.4만~6만 삼각형)을 Decimate(Collapse)로 줄여
assets/models/fleet_lod/<함종>_lod<n>.glb 로 내보낸다. 재질과 텍스처는 내보내지 않는다.
런타임(FleetRenderer)이 원본 모델의 재질을 그대로 입히므로 UV만 보존하면 된다.

실행:
  blender --background --python tools/blender/build_fleet_lods.py -- <runtime_dir> <output_dir>
"""
import json
import sys
from pathlib import Path

import bpy

MODELS = ["전열함", "화력함", "공성함", "보급_수리함", "전자전함", "호위함", "항모"]
# 단계별 목표 삼각형 수: lod1 = 근접(화면에서 수십 px), lod2 = 원거리 군집
TARGETS = {1: 2400, 2: 480}


def triangle_count(objs):
    total = 0
    for obj in objs:
        obj.data.calc_loop_triangles()
        total += len(obj.data.loop_triangles)
    return total


def build(source_path, output_path, target):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source_path))
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    before = triangle_count(objs)
    ratio = min(1.0, target / max(1, before))
    for obj in objs:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        mod = obj.modifiers.new(name="FleetLOD", type="DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = ratio
        mod.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.select_set(False)
    after = triangle_count(objs)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        export_materials="NONE",
        export_yup=True,
    )
    return {"model": source_path.stem, "lod_file": output_path.name, "before": before, "after": after}


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    source_dir = Path(args[0])
    output_dir = Path(args[1])
    results = []
    for name in MODELS:
        for lod, target in TARGETS.items():
            r = build(source_dir / f"{name}.glb", output_dir / f"{name}_lod{lod}.glb", target)
            results.append(r)
            print("FLEET_LOD " + json.dumps(r, ensure_ascii=False), flush=True)
    print("FLEET_LOD_PASS", flush=True)


if __name__ == "__main__":
    main()
