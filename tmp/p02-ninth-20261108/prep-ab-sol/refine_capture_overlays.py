"""Review-only Q/C capture refinements. Writes no product files."""
from difflib import unified_diff
from hashlib import sha256
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
OUT=HERE/"capture-refinement-review"

C_HELPER='''
func _k6_c_fields(rec: Dictionary) -> Dictionary:
	var p: Vector2 = rec.pos
	return {"seen": rec.seen, "state": rec.state, "conf_bp": rec.conf_bp,
		"pos": [p.x, p.y], "err_r": rec.err_r,
		"types": [typeof(rec.seen), typeof(rec.state), typeof(rec.conf_bp), typeof(rec.pos), typeof(rec.err_r)]}
'''

Q_HELPERS='''
func _k6_q_projection(kind: String, policy: String, seed_id: int, projection: Dictionary) -> void:
	var roster: Array = []
	for row in projection.squadrons:
		var p: Vector2 = row.pos
		roster.append({"id": row.id, "side": row.side, "pos": [p.x,p.y],
			"dead": row.get("dead"), "contact": row.get("contact"),
			"types": [typeof(row.id),typeof(row.side),typeof(row.pos),typeof(row.get("dead")),typeof(row.get("contact"))]})
	print("K6_Q_INDEPENDENT ", JSON.stringify({"case":kind+"/"+policy,"seed":seed_id,
		"tick":projection.tick,"hz":projection.hz,"roster":roster}, "", true, true))

func _k6_q_fields(command: Dictionary) -> Dictionary:
	var p: Vector2 = command.point
	return {"tick":command.tick,"side":command.side,"ids":command.ids,"kind":command.kind,
		"target_id":command.target_id,"point":[p.x,p.y],"args":command.args,
		"types":[typeof(command.tick),typeof(command.side),typeof(command.ids),typeof(command.kind),
			typeof(command.target_id),typeof(command.point),typeof(command.args)]}
'''

def replace(text, old, new):
    if text.count(old)!=1:
        raise ValueError(f"unexpected source occurrence: {old}")
    return text.replace(old,new,1)

def c(text):
    text=replace(text,'\t_k6_c_stream("c-target-restore", b, label)',
      '\tif a.detect != null:\n\t\tprint("K6_C_RESTORE ", JSON.stringify({"seed":a.st.seed_id,"phase":label,"ok":answer.get("ok",false)}))\n\t\tif answer.get("ok", false):\n\t\t\t_k6_c_stream("c-target-restore", b, label)')
    text=replace(text,'rows.append({"id": id, "typed_payload": var_to_bytes(sim.detect.contacts[side][id]).hex_encode()})',
      'var rec: Dictionary = sim.detect.contacts[side][id]\n\t\t\trows.append({"id": id, "typed_payload": var_to_bytes(rec).hex_encode(), "fields":_k6_c_fields(rec)})')
    return text+C_HELPER

def q(text):
    text=replace(text,'\t\tvar k6_native_commands := reference_commands(policy, public_raw)',
      '\t\t_k6_q_projection(kind, policy, seed_id, public_raw)\n\t\tvar k6_native_commands := reference_commands(policy, public_raw)')
    text=replace(text,'rows.append({"ordinal": rows.size(), "typed_tuple": var_to_bytes(command).hex_encode()})',
      'rows.append({"ordinal": rows.size(), "typed_tuple": var_to_bytes(command).hex_encode(), "fields":_k6_q_fields(command)})')
    return text+Q_HELPERS

if __name__=="__main__":
    OUT.mkdir(exist_ok=False)
    entries={}
    for path,fn in (("p02_headless_adapter.gd",q),("i01b_service_state.gd",c)):
        raw=(HERE/"capture-overlays-review"/path).read_bytes()
        old=raw.decode("utf-8")
        new=fn(old)
        delta="".join(unified_diff(old.splitlines(keepends=True),new.splitlines(keepends=True),f"v1/{path}",f"v2/{path}"))
        dest=OUT/path
        dest.write_bytes(new.encode("utf-8"))
        diff=dest.with_suffix(".diff")
        diff.write_bytes(delta.encode("utf-8"))
        entries[path]={k:sha256(v).hexdigest() for k,v in (("parent_sha256",raw),("overlay_sha256",dest.read_bytes()),("delta_sha256",diff.read_bytes()))}
    (OUT/"SHA.json").write_bytes((json.dumps(entries,indent=2)+"\n").encode("utf-8"))
