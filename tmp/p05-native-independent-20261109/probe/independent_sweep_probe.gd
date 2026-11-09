extends SceneTree
const Guard = preload("res://guard.gd")
func _initialize():
 var data = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
 var g = Guard.new(data)
 assert(g.start("RC") == "")
 var c: Vector2 = g.node("C")
 var limit: float = g.radii[0] - Guard.TRACK + g._radius("RC-CAO-SQ-04")
 var y: float = c.y + limit - 0.001
 var old := Vector2(c.x - 1.0, y)
 var target := Vector2(c.x + 1.0, y)
 assert(old.distance_to(c) > limit and target.distance_to(c) > limit)
 g.state.positions = [old]
 g.state.plan = old
 var proposal = g.snapshot()
 proposal.positions = [target]
 proposal.plan = target
 var before = g.snapshot()
 var reason = g._swept(proposal, old, target)
 assert(reason == "defender_clearance")
 assert(before == g.snapshot())
 var at_boundary = g._inside_world(Vector2(g.radii[0], 300), g.radii[0])
 var outside = g._inside_world(Vector2(g.radii[0] - 0.01, 300), g.radii[0])
 assert(at_boundary and not outside)
 print("INDEPENDENT_SWEEP_PASS endpoints_clear=true interior_rejected=true state_unchanged=true world_boundary=true")
 quit(0)
