"""적벽 간이 시뮬레이터 v2 (밸런스 탐색용, scratchpad 전용).
원본 tools/scenario/sim_red_cliffs_208.py를 고쳤다. 추가:
 - Q46 진영 공유 탐지(선택), 일제사격 주기 파라미터
 - Q49 열 냉각 60초당 30 + 생존 척 수 x 2
 - 사기 감소 배율(명중 하한·이탈·거리대 가중), 군 사기 임계 파라미터
 - 전대별 투입 대기 시간(wave release), 초기 거리 오프셋
 - 의미 있는 사건 기록(거리대 전환, 퇴각/붕괴, 화공 기회, 군 사기 위험, 새 전대 교전 진입)
"""
import json, math, random, sys, statistics as st
from collections import Counter, defaultdict

D = r"C:\WorkSpace\Seonghanji\data"
def J(n): return json.load(open(f"{D}\\{n}", encoding="utf-8"))
setup = J("red-cliffs-demo-setup.json"); fx = J("red-cliffs-combat-effects-rules.json")
res = J("red-cliffs-combat-resource-rules.json"); wpn = J("red-cliffs-weapon-allocation-rules.json")
mov = J("red-cliffs-movement-rules.json"); frm = J("red-cliffs-formation-rules.json")
sen = J("red-cliffs-sensor-ew-rules.json")
COST = {s["id"]: s["unit_cost"] for s in setup["ship_types"]}
CHARS = {c["id"]: c for c in J("characters.json")}
INT = {k: c["stats"]["지력"] for k, c in CHARS.items()}
CMD = {k: c["stats"]["통솔"] for k, c in CHARS.items()}
PHASE_W0 = {"contact": 0.8, "barrage": 1.2, "engagement": 2.0, "assault": 1.6, "resolution": 1.0}
DIR_W = {"front": 1.0, "flank": 1.25, "rear": 1.5}
ESCAPE = {"cao": (1600, 300), "alliance": (0, 650)}
SIDE = {"liu_bei": "alliance", "sun_quan": "alliance", "cao_cao": "cao"}
BANDS = ["contact", "barrage", "engagement", "assault"]

def ang(v): return math.degrees(math.atan2(v[1], v[0])) % 360
def wrap(a): return (a + 180) % 360 - 180

class Sq:
    def __init__(s, d, P):
        s.id = d["id"]; s.faction = d["faction_id"]; s.side = SIDE[s.faction]
        s.flagship = d["flagship"]; s.pos = list(map(float, d["initial_position"])); s.facing = 0.0
        if s.side == "cao": s.pos[0] += P.get("cao_dx", 0)
        s.comp = [[c["ship_type_id"], c["count"], c.get("mission_equipment_id", "")] for c in d["composition"]]
        s.formation = d["formation_id"]; s.cost_decl = d["declared_total_cost"]
        s.ships0 = sum(c[1] for c in s.comp)
        s.maxhull = sum(c[1] * COST[c[0]] * 10 for c in s.comp); s.hull = s.maxhull
        s.morale = d.get("start_morale_bp", 10000); s.state = "active"; s.lost = 0
        rec = 40 + CMD[d["commander"]["id"]] * 2
        ratio = max(0, (s.cost_decl - rec) / rec)
        s.tier = min(math.ceil(ratio / 0.25), 4) if ratio > 0 else 0
        s.acc_bp = 10000 - s.tier * 400
        slow = min(mov["base_speed_by_ship_type"][c[0]] for c in s.comp)
        s.speed = max(1, math.floor(slow * (100 - 5 * s.tier) / 100)) / 60.0
        s.weapons = {}
        for wid, w in wpn["weapons"].items():
            best = None; plat = 0
            for t, n, eq in s.comp:
                cap = w["platforms"].get(t) or (w["fast_equipment"].get(eq) if eq else None)
                if cap:
                    plat += n
                    if best is None or cap["range"] > best[1]["range"] or (cap["range"] == best[1]["range"] and t < best[0]): best = (t, cap)
            if best:
                ini = res["weapon_initial_per_platform"][wid]
                carriers = sum(n for t, n, _ in s.comp if t == "SHP-01") * 4 if wid == "line_fire" else 0
                s.weapons[wid] = dict(range=best[1]["range"], arc=best[1]["arc_deg"], platform=best[0],
                                      ammo=plat * ini["ammo"], special=plat * ini["special"], carrier=carriers, carrier_cap=carriers, cd=0.0)
        s.ecap = 80 + 12 * s.ships0; s.energy = s.ecap; s.hcap = 100 + 8 * s.ships0; s.heat = 0.0
        s.sensor = sum(n * sen["ship_sensor_points"][t] + (n * sen["fast_equipment_sensor_points"][eq] if eq else 0) for t, n, eq in s.comp)
        s.ew = sum(n * sen["ship_ew_points"][t] + (n * sen["fast_equipment_ew_points"][eq] if eq else 0) for t, n, eq in s.comp)
        iq = INT[d["commander"]["id"]]
        s.iq_pts = next(b["sensor_points"] for b in sen["intelligence_bands"] if b["min"] <= iq <= b["max"])
        s.release = P.get("release", {}).get(s.id, 0)
        s.engaged_at = None; s.target = None; s._rt = -1e9; s._ret = False
        s.mgroup = d.get("morale_group"); s.halve_until = -1
    @property
    def fire(s): return frm["formations"][s.formation]["fire_percent"]
    @property
    def defense(s): return frm["formations"][s.formation]["defense_percent"]
    def alive(s): return s.state in ("active", "retreating")
    def can_attack(s): return s.state == "active"
    def ships_now(s): return s.ships0 - s.lost
    def composition_now(s):
        rem = s.lost; out = []
        for t, n, eq in sorted(s.comp, key=lambda c: c[0]):
            l = min(rem, n); rem -= l; out.append([t, n - l, eq])
        return out
    def cost_now(s): return sum(n * COST[t] for t, n, _ in s.composition_now())
    def cost0(s): return sum(n * COST[t] for t, n, _ in s.comp)
    def alive_platforms(s, wid):
        w = wpn["weapons"][wid]
        return sum(n for t, n, eq in s.composition_now() if t in w["platforms"] or (eq and eq in w["fast_equipment"]))

DP = {}
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
    return adj + o.iq_pts - t._ew - math.floor(dist / 25) - t._conceal

def sector(shooter, target):
    v = (shooter.pos[0] - target.pos[0], shooter.pos[1] - target.pos[1])
    if math.hypot(*v) < 1e-3: return "front"
    d = abs(wrap(ang(v) - target.facing))
    return "rear" if d >= 120 else ("flank" if d > 60 else "front")

def phase_of(dist):
    if dist <= 100: return "assault"
    if dist <= 190: return "engagement"
    if dist <= 260: return "barrage"
    return "contact"

EMIN = {"sun_quan": 6500, "cao_cao": 4500, "liu_bei": 0}
HOST = None; DENSE = ("FRM-02", "FRM-03", "FRM-04"); FLAG = {}; AI = {}

def run(P, seed):
    rng = random.Random(seed)
    sqs = [Sq(d, P) for d in setup["squadrons"]]
    by = {s.id: s for s in sqs}
    events = defaultdict(int)
    t = 0.0; dt = 1.0
    ev = []  # (t, kind, detail)
    chain_done = False; chain_open = False; danger = set()
    XR = P.get("xr", False); rng2 = random.Random(seed * 7919 + 17)
    win_off = rng2.uniform(*P.get("win_range", (360, 600))); win_start = None
    hs = dict(state="wait", susp=0.0, charges=2, target=None)  # host fire program
    burnt = set(); spreads = []; rallied = False
    est_since = {}; fconf = {}; fest = {}; shots = {"alliance": [0, 0], "cao": [0, 0]}
    def est_ok(q): return DP.get("est_conf", 5000) >= EMIN.get(q.faction, 0)
    def feigning(q): return XR and P.get("chain") and q.id == HOST and hs["state"] == "feign" and hs["susp"] < 100
    def burn(e, power, kind):
        dmg = max(1, math.floor(e.maxhull * power * P.get("chain_hull_mul", 1.0))); k = power / 0.40
        if P.get("chain_null"): ev.append((t, kind, e.id)); burnt.add(e.id); return
        apply_damage(e, dmg, 3500 * k * P.get("chain_mor_mul", 1.0), P, raw=True); events["cao"] += 2500 * k * P.get("chain_army_mul", 1.0); burnt.add(e.id)
        ev.append((t, kind, f"{e.id}:{power:.3f}"))
    band = None; band_cand = None; band_since = 0
    first_hit = None; result = None
    PW = P.get("phase_w", PHASE_W0)
    mul = P.get("mor_mul", 1.0); floor_bp = P.get("floor_bp", 300); ship_bp = P.get("ship_bp", 200)
    period = P.get("period", 60.0); thr = P.get("army_thr", 3000)
    tlimit = P.get("tlimit", 1200)
    while t < tlimit:
        t += dt
        live = [s for s in sqs if s.alive()]
        if t > 60:
            for s in live:
                s.energy = min(s.ecap, s.energy + s.ecap * 0.20 / 60 * dt)
                cool = (30 + 2 * s.ships_now()) if P.get("q49", True) else 30
                s.heat = max(0.0, s.heat - cool / 60 * dt)
                for w in s.weapons.values():
                    if w["carrier_cap"]:
                        w["carrier"] = min(w["carrier_cap"], w["carrier"] + math.ceil(w["carrier_cap"] * 0.25) / 60 * dt)
        # shared detection (Q46): best score per side per enemy
        if P.get("detection"):
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
                        if state == 2 and side not in fconf: fconf[side] = t
        for s in live:
            enemies = [e for e in sqs if e.side != s.side and e.alive()]
            if not enemies: continue
            if s.state == "retreating":
                goal = ESCAPE[s.side]; v = (goal[0] - s.pos[0], goal[1] - s.pos[1]); d = math.hypot(*v)
                if d <= 60: s.state = "escaped"; ev.append((t, "escape", s.id)); continue
                step = min(d, s.speed * dt); s.pos[0] += v[0] / d * step; s.pos[1] += v[1] / d * step; s.facing = ang(v); continue
            if P.get("detection"):
                if DP.get("move_est", True):
                    fac_vis = [e for e in enemies if best[(s.side, e.id)] == 2] or [e for e in enemies if best[(s.side, e.id)] >= 1]
                else:
                    need = 1 if est_ok(s) else 2
                    fac_vis = [e for e in enemies if best[(s.side, e.id)] >= need]
            else:
                fac_vis = enemies
            if s.side == "cao": fac_vis = [e for e in fac_vis if not feigning(e)]
            if s.side == "cao" and AI["reaction_s"] > 0 and s.target is not None and s.target.alive() and t - s._rt < AI["reaction_s"]:
                tgt = s.target
            else:
                tgt = min(fac_vis or [None], key=lambda e: math.dist(s.pos, e.pos) if e else 0)
                if s.side == "cao" and fac_vis and rng.randrange(10000) < AI["mistake_bp"]:
                    tgt = fac_vis[rng.randrange(len(fac_vis))]
                s._rt = t
            s.target = tgt
            mode = ("hold" if all(c[0] == "SHP-08" for c in s.comp) and s.side == "alliance" else
                    ("fireship" if s.id == HOST else P["ai"].get(s.faction, "advance")))
            if XR and s.id == HOST:
                mode = "xfire" if (P.get("chain") and hs["state"] in ("wait", "feign", "exposed")) else "defend"
            relh = P.get("release_hit", {}).get(s.id)
            if relh is not None and (first_hit is None or t < first_hit + relh): held_h = True
            else: held_h = False
            held = (t < s.release or held_h) and s.engaged_at is None and not (P.get("release_on_contact") and tgt is not None and math.dist(s.pos, tgt.pos) <= P.get("release_on_contact"))
            goal = None
            S = 0
            if P.get("stage") and first_hit is not None:
                for t0s, dist_s in P["stage"]:
                    if t - first_hit >= t0s: S = dist_s
            elif P.get("stage"):
                S = P["stage"][0][1]
            if tgt is not None:
                d = math.dist(s.pos, tgt.pos)
                if held:
                    goal = None
                elif mode == "advance":
                    if d > max(P.get("standoff", 100), S): goal = tgt.pos
                elif mode == "defend":
                    sup = P.get("support") if s.faction in P.get("support_factions", ("sun_quan", "liu_bei")) else None
                    if sup and d > P.get("defend_trigger", 400):
                        # 지원: 아군 어느 전대에서든 sup 안에 있는 적 중 가장 가까운 적으로
                        near = [e for e in enemies if any(f.side == s.side and f.can_attack() and f is not s and math.dist(f.pos, e.pos) <= sup for f in sqs)]
                        if near:
                            tgt = min(near, key=lambda e: math.dist(s.pos, e.pos)); d = math.dist(s.pos, tgt.pos)
                            if d > max(150, S): goal = tgt.pos
                    elif d <= P.get("defend_trigger", 400) and d > max(150, S if P.get("stage_ally", True) else 0): goal = tgt.pos
                elif mode == "xfire":
                    dense = [e for e in enemies if e.side == "cao" and e.formation in DENSE]
                    if not dense:
                        hs["state"] = "done"
                    else:
                        if P.get("host_pick") == "healthy":
                            tg = max(dense, key=lambda e: e.hull - 0.5 * math.dist(s.pos, e.pos))
                        elif hs["state"] in ("feign", "exposed") and hs["target"] is not None and hs["target"].alive() and hs["target"].formation in DENSE and P.get("host_lock"):
                            tg = hs["target"]
                        else:
                            tg = min(dense, key=lambda e: math.dist(s.pos, e.pos))
                        dd = math.dist(s.pos, tg.pos)
                        if hs["state"] == "wait":
                            if P.get("host_timed") and win_start is not None and (dd - 120) / max(s.speed, 1e-6) >= win_start - t:
                                hs["state"] = "feign"; hs["susp"] = 0.0; ev.append((t, "feign", tg.id))
                            elif not P.get("host_timed") and win_start is not None and t >= win_start:
                                hs["state"] = "feign"; hs["susp"] = 0.0; ev.append((t, "feign", tg.id))
                            else:
                                ne = min(enemies, key=lambda e: math.dist(s.pos, e.pos)); dn = math.dist(s.pos, ne.pos); safe = P.get("safe_d", 290)
                                if dn < safe - 5:
                                    goal = [s.pos[0] + (s.pos[0] - ne.pos[0]) / dn * 30, s.pos[1] + (s.pos[1] - ne.pos[1]) / dn * 30]
                                elif first_hit is not None and dd > P.get("stage_d", 300) + 5 and dn > safe + 5:
                                    sd = P.get("stage_d", 300); tgt = tg
                                    goal = [tg.pos[0] + (s.pos[0] - tg.pos[0]) * sd / dd, tg.pos[1] + (s.pos[1] - tg.pos[1]) * sd / dd]
                        if hs["state"] in ("feign", "exposed"):
                            hs["target"] = tg; tgt = tg
                            if dd > 120:
                                goal = [tg.pos[0] + (s.pos[0] - tg.pos[0]) * 120 / dd, tg.pos[1] + (s.pos[1] - tg.pos[1]) * 120 / dd]
                elif mode == "fireship":
                    dense = [e for e in enemies if e.formation in DENSE]
                    if dense:
                        tg = min(dense, key=lambda e: math.dist(s.pos, e.pos))
                        goal = [tg.pos[0] - 200, tg.pos[1]]
                        if math.dist(s.pos, goal) < 5: goal = None
                        tgt = tg
                s.facing = ang((tgt.pos[0] - s.pos[0], tgt.pos[1] - s.pos[1]))
            elif mode == "advance" and s.faction == "cao_cao" and not held:
                goal = [s.pos[0] - 60, s.pos[1] + 40]
            if goal is not None:
                v = (goal[0] - s.pos[0], goal[1] - s.pos[1]); d = math.hypot(*v)
                if d > 1e-6:
                    step = min(d, s.speed * dt); s.pos[0] += v[0] / d * step; s.pos[1] += v[1] / d * step
                    if tgt is None: s.facing = ang(v)
        # chain explosion (화공)
        if XR:
            if first_hit is not None and win_start is None: win_start = first_hit + win_off
            if P.get("chain") and HOST in by:
                host = by[HOST]
                if not host.can_attack() and hs["state"] in ("wait", "feign", "exposed"): hs["state"] = "done"
                wopen = win_start is not None and win_start <= t < win_start + 180
                if wopen and not chain_open: chain_open = True; ev.append((t, "fire_open", HOST))
                if hs["state"] == "feign":
                    hs["susp"] += P["susp_rate"] * dt
                    if hs["susp"] >= 100:
                        tg = hs["target"]
                        if tg is not None and tg.alive(): tg.formation = "FRM-05"
                        events["alliance"] += 1500; hs["charges"] -= 1; ev.append((t, "detected", tg.id if tg else ""))
                        hs["state"] = "exposed" if hs["charges"] > 0 else "done"
                if hs["state"] in ("feign", "exposed"):
                    tg = hs["target"]
                    if win_start is not None and t >= win_start + 180: hs["state"] = "done"
                    elif wopen and tg is not None and tg.alive() and tg.formation in DENSE:
                        dd = math.dist(host.pos, tg.pos)
                        panic = P.get("panic") and hs["state"] == "feign" and hs["susp"] >= 100 - P["susp_rate"] * P.get("panic_s", 3) and dd <= P.get("panic_d", 240)
                        if dd <= 122 or (dd <= 240 and t >= win_start + 160) or panic:
                            power = 0.25 if dd >= 240 else (0.25 + (240 - dd) / 120 * 0.15 if dd >= 120 else (0.40 + (120 - max(dd, 60)) / 60 * 0.10))
                            burn(tg, power, "chain"); hs["charges"] -= 1; hs["state"] = "done"; chain_done = True
                            spreads.append([t + 20, tg, power, 0])
            for sp in spreads:
                if sp[3] < 2 and sp[0] is not None and t >= sp[0]:
                    cand = [e for e in sqs if e.side == "cao" and e.alive() and e.formation in DENSE and e.id not in burnt and math.dist(e.pos, sp[1].pos) <= 150]
                    if cand:
                        e = min(cand, key=lambda q: math.dist(q.pos, sp[1].pos)); sp[2] /= 2; sp[3] += 1
                        burn(e, sp[2], "spread"); sp[1] = e; sp[0] = t + 20
                    else:
                        sp[0] = None
            if int(t) % 10 == 0:
                for q in sqs:
                    if q.side == "cao" and q.alive() and q.mgroup == "northern" and q.formation not in DENSE:
                        q.morale = max(0, q.morale - P.get("plague_bp", 40))
        elif P.get("chain") and not chain_done and HOST in by:
            host = by[HOST]
            if not chain_open and host.can_attack() and any(e.side == "cao" and e.alive() and e.formation in DENSE and math.dist(host.pos, e.pos) <= 300 for e in sqs):
                chain_open = True; ev.append((t, "fire_open", HOST))
            if AI["chain_risk_response"]:
                for e in sqs:
                    if e.side == "cao" and e.alive() and e.formation in DENSE and host.alive() and math.dist(host.pos, e.pos) <= 300:
                        if rng.random() < dt / AI["chain_detect_mean_s"]:
                            e.formation = "FRM-05"
            if host.can_attack():
                for e in sqs:
                    if e.side != "cao" or not e.alive() or e.formation not in DENSE: continue
                    v = (e.pos[0] - host.pos[0], e.pos[1] - host.pos[1])
                    if math.hypot(*v) <= 240 and abs(wrap(ang(v))) <= 60:
                        chain_done = True
                        dmg = max(1, math.floor(e.maxhull * 0.4)); apply_damage(e, dmg, 3500 * P.get("chain_mor_mul", 1.0), P, raw=True)
                        events["cao"] += 2500; ev.append((t, "chain", e.id))
                        break
        hits = []
        for s in live:
            if not s.can_attack(): continue
            for wid, w in s.weapons.items():
                w["cd"] = max(0.0, w["cd"] - dt)
                if w["cd"] > 0: continue
                cands = []
                for e in sqs:
                    if e.side == s.side or not e.alive(): continue
                    if feigning(e) or feigning(s): continue
                    d = math.dist(s.pos, e.pos)
                    if d > w["range"]: continue
                    rel = abs(wrap(ang((e.pos[0] - s.pos[0], e.pos[1] - s.pos[1])) - s.facing)) if d > 1e-3 else 0
                    if rel > w["arc"] / 2 + 1e-6: continue
                    conf = 10000
                    if P.get("detection"):
                        sc = best[(s.side, e.id)]
                        if sc == 2: conf = 10000
                        elif sc == 1 and est_ok(s): conf = DP.get("est_conf", 5000)
                        else: continue
                    cands.append((d, e, conf))
                if not cands: continue
                d, e, conf = min(cands, key=lambda c: c[0])
                cost = res["shot_cost"][wid]
                csort = 1 if (wid == "line_fire" and w["platform"] == "SHP-01") else 0
                n_plat = s.alive_platforms(wid)
                if n_plat <= 0: continue
                sq_n = math.sqrt(n_plat)
                reason = None
                if w["ammo"] < cost["ammo"]: reason = "ammo"
                elif s.energy < cost["energy"]: reason = "energy"
                elif s.heat + cost["heat"] > s.hcap: reason = "overheat"
                elif w["carrier"] < csort: reason = "carrier"
                elif w["special"] < cost["special"]: reason = "special"
                if reason:
                    w["cd"] = 5.0; continue
                w["ammo"] -= cost["ammo"]; w["special"] -= cost["special"]; s.energy -= cost["energy"]; s.heat += cost["heat"]; w["carrier"] -= csort
                w["cd"] = period
                shots[s.side][0] += 1; shots[s.side][1] += conf < 10000
                if s.engaged_at is None:
                    s.engaged_at = t; ev.append((t, "engage", s.id))
                sec = sector(s, e)
                chance = max(1000, min(9500, fx["hit"]["base_accuracy_basis_points"][wid] + (s.fire - (e.defense + frm["sector_defense_percent"][sec])) * 100))
                chance = (chance * s.acc_bp + 5000) // 10000
                if conf < 10000: chance = (chance * conf + 5000) // 10000
                if rng.randrange(10000) < chance:
                    dmg = fx["damage_points"][wid] * sq_n * P.get("dmg_mul", 1.0)
                    hits.append((s, e, dmg, phase_of(d), sec))
        agg = defaultdict(lambda: [0, 0.0])
        for s, e, dmg, ph, sec in hits:
            base = max(floor_bp, math.ceil(dmg * 10000 / (e.maxhull * 5)))
            agg[e.id][0] += dmg; agg[e.id][1] += base * PW[ph] * DIR_W[sec] * mul
            if first_hit is None: first_hit = t
        for eid, (dmg, mor) in agg.items():
            q = by[eid]; fac = 1.0
            if XR and q.side == "cao" and hs["state"] == "feign":
                hs["susp"] += P.get("susp_per_hit", 0) * sum(1 for hh in hits if hh[1] is q)
            if XR:
                if q.side == "cao" and q.formation in DENSE: fac *= P.get("dense_mul", 0.8)
                if t < q.halve_until: fac *= 0.5
            apply_damage(q, round(dmg), mor, P, fac=fac)
        for s in sqs:
            if s.state in ("active", "retreating"):
                if s.hull <= 0: s.state = "destroyed"; events[s.side] += P.get("ev_bp", 500); ev.append((t, "destroyed", s.id))
                elif s.morale <= 0:
                    s.state = "surrendered"; events[s.side] += 0 if s._ret else P.get("ev_bp", 500); ev.append((t, "surrender", s.id))
                    if XR and not s._ret: events["cao" if s.side == "alliance" else "alliance"] -= P.get("recover_bp", 300)
                elif s.morale < 3000 and s.state == "active":
                    s.state = "retreating"; s._ret = True; events[s.side] += P.get("ev_bp", 500); ev.append((t, "retreat", s.id))
                    if XR: events["cao" if s.side == "alliance" else "alliance"] -= P.get("recover_bp", 300)
        # global band (closest active opposing pair), 20 s hysteresis
        dmin = min((math.dist(a.pos, b.pos) for a in sqs if a.side == "alliance" and a.can_attack() for b in sqs if b.side == "cao" and b.can_attack()), default=9999)
        nb = phase_of(dmin)
        if nb != band_cand: band_cand = nb; band_since = t
        if band_cand != band and t - band_since >= 20:
            if band is not None: ev.append((band_since, "band", f"{band}->{band_cand}"))
            band = band_cand
        if XR and not rallied and P.get("rally", True) and army_morale(sqs, events, "alliance") < 4500:
            rallied = True; fl = by[FLAG["liu_bei"]]
            if fl.can_attack():
                for q in sqs:
                    if q.side == "alliance" and q.can_attack() and math.dist(q.pos, fl.pos) <= 200:
                        q.morale = min(10000, q.morale + 1200); q.halve_until = t + 30
                ev.append((t, "rally", "liu"))
        for side in ("alliance", "cao"):
            if side not in danger and army_morale(sqs, events, side) < thr + P.get("danger_margin", 1500):
                danger.add(side); ev.append((t, "danger", side))
        if P.get("trace") is not None and int(t) % 30 == 0:
            P["trace"].append((t, round(army_morale(sqs, events, "alliance")), round(army_morale(sqs, events, "cao")), round(dmin),
                               " ".join(f"{q.id[3:]}:{q.state[0]}{q.morale//100}/{int(100*q.hull/q.maxhull)}" for q in sqs if q.alive())))
        r = end_check(sqs, events, P)
        if r: result = r; break
    if result is None:
        result = time_limit(sqs)
    return dict(result, t=t, first_hit=first_hit, ev=ev, win_start=win_start, fconf=fconf, fest=fest, shots=shots)

def apply_damage(e, dmg, morale_loss, P, raw=False, fac=1.0):
    dmg = min(e.hull, dmg); e.hull -= dmg
    losses = math.floor(e.ships0 * (e.maxhull - e.hull) / e.maxhull)
    if e.hull == 0: losses = e.ships0
    delta = max(0, losses - e.lost); e.lost = losses
    sb = P.get("ship_bp", 200) * (1 if raw else P.get("mor_mul_ship", P.get("mor_mul", 1.0)))
    e.morale = max(0, e.morale - round((morale_loss + delta * sb) * fac))
    if e.hull == 0: e.morale = 0

def army_morale(sqs, events, side):
    mem = [s for s in sqs if s.side == side]
    tot = sum(s.cost_decl for s in mem)
    m = sum((s.morale if s.state in ("active", "retreating") else 0) * s.cost_decl for s in mem) / tot
    return min(10000, m - events[side])

def end_check(sqs, events, P):
    by = {s.id: s for s in sqs}
    liu = by[FLAG["liu_bei"]]; cao = by[FLAG["cao_cao"]]
    if liu.hull <= 0: return dict(reason="liu_flag", winner="cao")
    if cao.hull <= 0: return dict(reason="cao_flag", winner="alliance")
    def loss(fs):
        o = sum(s.cost0() for s in sqs if s.faction in fs); r = sum(s.cost_now() for s in sqs if s.faction in fs)
        return (o - r) / o
    if loss(["cao_cao"]) >= 0.7: return dict(reason="cao_loss70", winner="alliance")
    if loss(["liu_bei"]) >= 0.7: return dict(reason="liu_loss70", winner="cao")
    if loss(["liu_bei", "sun_quan"]) >= 0.7: return dict(reason="ally_loss70", winner="cao")
    thr = P.get("army_thr", 3000)
    a = army_morale(sqs, events, "alliance"); c = army_morale(sqs, events, "cao")
    if a < thr and c < thr: return dict(reason="am_both", winner="cao")
    if a < thr: return dict(reason="am_ally", winner="cao")
    if c < thr: return dict(reason="am_cao", winner="alliance")
    for side in ("alliance", "cao"):
        if all(not s.alive() for s in sqs if s.side == side):
            return dict(reason=f"{side}_gone", winner="cao" if side == "alliance" else "alliance")
    return None

def time_limit(sqs):
    a0 = sum(s.cost0() for s in sqs if s.side == "alliance"); ar = sum(s.cost_now() for s in sqs if s.side == "alliance")
    c0 = sum(s.cost0() for s in sqs if s.side == "cao"); cr = sum(s.cost_now() for s in sqs if s.side == "cao")
    return dict(reason="time", winner="alliance" if ar * c0 > cr * a0 else "cao")

import make_red_cliffs_208 as MS
SC = json.load(open(r"C:\WorkSpace\SpaceBattleOfThreeKingdoms\data\scenarios\red_cliffs_208_realtime.json", encoding="utf-8"))
HOST = SC["chain_explosion_override"]["host_squadron_id"]
BASE = dict(ai={"cao_cao": "advance", "sun_quan": "defend", "liu_bei": "defend"}, standoff=100)

MEANINGFUL = ("band", "retreat", "surrender", "destroyed", "fire_open", "chain", "danger", "engage", "feign", "detected", "rally")

def metrics(r, merge=30, wave_gap=90):
    """사건 → 결정 지점(merge초 안 사건은 하나로), 파도(교전 진입 사건 군집, wave_gap초 이상 떨어지면 새 파도)."""
    if r["first_hit"] is None: return dict(dp=0, gap=None, waves=0, wgap=None, span=0)
    t0 = r["first_hit"]
    evs = sorted((t, k, x) for t, k, x in r["ev"] if k in MEANINGFUL and t >= t0 - 5)
    # 첫 교전 진입 사건 자체(교전 시작)는 결정 지점에서 뺀다
    pts = []
    for t, k, x in evs:
        if t <= t0 + 5 and k == "engage": continue
        if pts and t - pts[-1] < merge: continue
        pts.append(t)
    gaps = [b - a for a, b in zip([t0] + pts, pts)]
    # 파도: 교전 진입(engage) + 전대 이탈(retreat/surrender/destroyed) 기준 전투 강도 변곡 → 여기서는 engage 군집과 이탈 군집을 함께 본다
    wav = []
    for t, k, x in evs:
        if k not in ("engage", "retreat", "surrender", "destroyed", "chain"): continue
        if not wav or t - wav[-1][-1] >= wave_gap: wav.append([t])
        else: wav[-1].append(t)
    starts = [w[0] for w in wav]
    wg = [b - a for a, b in zip(starts, starts[1:])]
    return dict(dp=len(pts), gap=st.median(gaps) if gaps else None, waves=len(wav), wgap=st.median(wg) if wg else None, span=r["t"] - t0)

SUSP = {"입문": 0.4, "표준": 0.8, "상급": 1.5, "극한": 2.0}
def setup_diff(diff, P):
    setup["squadrons"] = MS.apply_difficulty(SC["squadrons"], diff)
    FLAG.clear(); FLAG.update({s["faction_id"]: s["id"] for s in setup["squadrons"] if s["flagship"] and s["faction_id"] in ("liu_bei", "cao_cao")})
    AI.clear(); AI.update(MS.DIFF[diff]["ai"])

def evaluate(P, diffs=("표준", "상급"), N=30, verbose=True, label=""):
    rows = {}
    for diff in diffs:
        setup_diff(diff, P)
        for chain in (False, True):
            Q = dict(BASE, **P, chain=chain); Q.setdefault("susp_rate", SUSP[diff])
            rs = [run(Q, seed) for seed in range(N)]
            ms = [metrics(r) for r in rs]
            T = [r["t"] for r in rs]
            win = sum(r["winner"] == "cao" for r in rs) / N
            row = dict(len=st.median(T), win=win, dp=st.median(m["dp"] for m in ms),
                       gap=st.median([m["gap"] for m in ms if m["gap"]] or [0]), waves=st.median(m["waves"] for m in ms),
                       wgap=st.median([m["wgap"] for m in ms if m["wgap"]] or [0]),
                       fh=st.median(r["first_hit"] or 0 for r in rs), span=st.median(m["span"] for m in ms),
                       reasons=Counter(r["reason"] for r in rs), chain=sum(any(k == "chain" for _, k, _ in r["ev"]) for r in rs) / N,
                       spread=sum(any(k == "spread" for _, k, _ in r["ev"]) for r in rs) / N,
                       detected=sum(any(k == "detected" for _, k, _ in r["ev"]) for r in rs) / N,
                       opened=sum(any(k == "fire_open" for _, k, _ in r["ev"]) for r in rs) / N,
                       len_q=(sorted(T)[N // 4], sorted(T)[3 * N // 4]),
                       timeouts=sum(r["reason"] == "time" for r in rs))
            rows[(diff, chain)] = row
            if verbose:
                print(f"{label}|{diff}|{'화공' if chain else '없음'}|len {row['len']/60:5.1f}m|cao {row['win']*100:3.0f}%|1st hit {row['fh']/60:4.1f}m span {row['span']/60:4.1f}m"
                      f"|dp {row['dp']:.1f} gap {row['gap']:.0f}s|waves {row['waves']:.1f} wgap {row['wgap']:.0f}s|{dict(row['reasons'])}", flush=True)
    return rows

if __name__ == "__main__":
    N = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    evaluate({}, diffs=("입문", "표준", "상급", "극한"), N=N, label="v2 기준")
