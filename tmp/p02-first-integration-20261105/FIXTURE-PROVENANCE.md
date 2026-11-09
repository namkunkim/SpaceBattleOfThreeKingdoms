# Explicit input provenance

POC example: explicitly authored one ally30/foe1 fleet, positions500/550; rules copied unchanged from data/profiles/poc_corridor.json. reinf=[] is authored input, not runtime removal.

Services example: explicitly authored SalvoFixture-style composition SHP-01x1/SHP-03x1/SHP-04x2 versus SHP-02x40, FRM-01, command70; trusted combat_m3 contents with explicit modules morale/victory/command/stratagem/assault/terrain absent at authoring. Detection and Supply present. No runtime default profile or module transformation occurs. Both JSON files are inspectable opt-in inputs, not saves or complete stock profiles.

Timeout POC example (11/7 accepted revision): explicit positions (500,500)/(2500,500), both30 ships/lv1/flag, reinf=[], controls direct/direct, none, max_ticks1. Rules unchanged from poc_corridor. Distance2000 exceeds base range300/missile480/fighter380 and one-tick movement. Controls do not disable PocEnemyAi; T01/T02 raw1step survival is the independent oracle. No runtime module/attack removal.
