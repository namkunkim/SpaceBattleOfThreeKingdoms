
FLEET = "scripts/FleetBattle3D.gd"
AUTO = "scripts/world/auto_resolver.gd"
ADAPTER = "core/battle/operation_runtime_adapter.gd"

def replace(content, old, new):
    newline = "\r\n" if b"\r\n" in content else "\n"
    old, new = [s.replace("\n", newline).encode() for s in (old, new)]
    if content.count(old) != 1:
        raise ValueError(f"nonunique overlay anchor {old!r}")
    return content.replace(old, new)

def overlays(project, lane, case):
    changes = {}

    def edit(path, old, new):
        changes[path] = replace(changes.get(path, (project / path).read_bytes()), old, new)

    if case == "guard-initial":
        edit(FLEET, "\tinput_node.setup(self, cmds)\n", """\tinput_node.setup(self, cmds)
\tif OS.get_environment("P02_K6_INITIAL_GUARD") == "1":
\t\tprofile_patch = func(p: Dictionary): p.foe = false
""")
    if case == "native":
        edit(AUTO, "func _prepare() -> bool:", "var k6_effective: Dictionary\n\nfunc _prepare() -> bool:")
        edit(AUTO, '\tvar p := brief.profile()', '\tvar p := brief.profile()\n\tk6_effective = p.duplicate(true)')
    return changes

