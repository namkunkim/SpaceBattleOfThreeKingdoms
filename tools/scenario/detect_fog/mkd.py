s = open("sim3.py", encoding="utf-8").read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (a[:70], s.count(a))
    s = s.replace(a, b)
# 1. detection score with options
rep('''def det_score(o, t, dist):
    adj = math.floor((o.sensor * (100 + frm["formations"][o.formation]["detection_percent"]) + 50) / 100)
    return adj + o.iq_pts - t.ew - math.floor(dist / 25)''',
'''DP = {}
TER = json.load(open(D + "/red-cliffs-terrain-rules.json", encoding="utf-8"))["zones"]
def zones_at(p):
    out = []
    for z in TER:
        sh = z["shape"]
        if sh["x"] - 1e-3 <= p[0] <= sh["x"] + sh["width"] + 1e-3 and sh["y"] - 1e-3 <= p[1] <= sh["y"] + sh["height"] + 1e-3: out.append(z)
    return out
def raw_pts(o, table, eqtable):
    comp = o.composition_now() if DP.get("cur", True) else o.comp
    return sum(n * table[t] + (n * eqtable[eq] if eq else 0) for t, n, eq in comp if n > 0)
def refresh_det(sqs):
    for o in sqs:
        raw = raw_pts(o, sen["ship_sensor_points"], sen["fast_equipment_sensor_points"])
        if o.id in DP.get("no_sensor", ()): raw = 0
        m = DP.get("sens", "orig")
        if m == "orig": v = raw
        elif m == "sqrt": v = DP["base"] + DP["k"] * math.sqrt(raw)
        elif m == "cap": v = DP["base"] + min(raw, DP["cap"])
        o._sens = v
        o._ew = 0 if DP.get("no_ew") else raw_pts(o, sen["ship_ew_points"], sen["fast_equipment_ew_points"])
        if DP.get("terrain", True):
            zs = zones_at(o.pos)
            o._tpct = max(-60, min(30, sum(z["effects"]["observer_sensor_percent"] for z in zs)))
            o._conceal = sum(z["effects"]["target_concealment_points"] for z in zs)
        else:
            o._tpct = 0; o._conceal = 0
def det_score(o, t, dist):
    pct = 100 + frm["formations"][o.formation]["detection_percent"] + o._tpct
    adj = math.floor((o._sens * pct + 50) / 100)
    return adj + o.iq_pts - t._ew - math.floor(dist / 25) - t._conceal''')
# 2. detection block: thresholds, promotion, first-confirm tracking
rep('''        if P.get("detection"):
            best = {}
            for side in ("alliance", "cao"):
                obs = [o for o in sqs if o.side == side and o.alive()]
                for e in sqs:
                    if e.side != side and e.alive():
                        best[(side, e.id)] = max((det_score(o, e, math.dist(o.pos, e.pos)) for o in obs), default=-999)''',
'''        if P.get("detection"):
            best = {}; refresh_det(sqs); CT = DP.get("conf", 37); ET = DP.get("est", 15); PR = DP.get("promo")
            for side in ("alliance", "cao"):
                obs = [o for o in sqs if o.side == side and o.alive()]
                for e in sqs:
                    if e.side != side and e.alive():
                        sc = max((det_score(o, e, math.dist(o.pos, e.pos)) for o in obs), default=-999)
                        k = (side, e.id)
                        if sc >= ET:
                            est_since.setdefault(k, t)
                            if side not in fest: fest[side] = t
                        else: est_since.pop(k, None)
                        if sc >= CT: state = 2
                        elif sc >= ET: state = 2 if (PR is not None and t - est_since[k] >= PR) else 1
                        else: state = 0
                        best[k] = state
                        if state == 2 and side not in fconf: fconf[side] = t''')
rep('''            if P.get("detection"):
                need = 37 if s.faction == "sun_quan" else 15
                fac_vis = [e for e in enemies if best[(s.side, e.id)] >= need]''',
'''            if P.get("detection"):
                if DP.get("move_est", True):
                    fac_vis = [e for e in enemies if best[(s.side, e.id)] == 2] or [e for e in enemies if best[(s.side, e.id)] >= 1]
                else:
                    need = 1 if est_ok(s) else 2
                    fac_vis = [e for e in enemies if best[(s.side, e.id)] >= need]''')
rep('''                    if P.get("detection"):
                        sc = best[(s.side, e.id)]
                        if sc >= 37: conf = 10000
                        elif sc >= 15 and s.faction != "sun_quan": conf = 5000
                        else: continue''',
'''                    if P.get("detection"):
                        sc = best[(s.side, e.id)]
                        if sc == 2: conf = 10000
                        elif sc == 1 and est_ok(s): conf = DP.get("est_conf", 5000)
                        else: continue''')
rep('''    burnt = set(); spreads = []; rallied = False''',
'''    burnt = set(); spreads = []; rallied = False
    est_since = {}; fconf = {}; fest = {}; shots = {"alliance": [0, 0], "cao": [0, 0]}
    def est_ok(q): return DP.get("est_conf", 5000) >= EMIN.get(q.faction, 0)''')
rep('''                w["cd"] = period
''', '''                w["cd"] = period
                shots[s.side][0] += 1; shots[s.side][1] += conf < 10000
''')
rep('''    return dict(result, t=t, first_hit=first_hit, ev=ev, win_start=win_start)''',
'''    return dict(result, t=t, first_hit=first_hit, ev=ev, win_start=win_start, fconf=fconf, fest=fest, shots=shots)''')
rep('''HOST = None; DENSE''', '''EMIN = {"sun_quan": 6500, "cao_cao": 4500, "liu_bei": 0}
HOST = None; DENSE''')
open("simd.py", "w", encoding="utf-8").write(s)
print("ok")
