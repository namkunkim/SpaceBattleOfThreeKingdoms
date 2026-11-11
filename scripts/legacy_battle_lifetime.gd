extends RefCounted

# The owner calls this only when no further simulation work can occur.
static func release(sim: BattleSim) -> void:
	if sim == null:
		return
	for system in [sim.salvo, sim.detect, sim.supply, sim.morale, sim.victory,
			sim.cmd, sim.chain, sim.assault, sim.skills, sim.decisions]:
		if system != null:
			system.sim = null
