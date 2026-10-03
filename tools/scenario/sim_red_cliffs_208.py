"""적벽 시나리오(data/scenarios/red_cliffs_208_realtime.json)의 난이도별 간이 실시간 시뮬레이션.

본편 data/의 규칙 수치를 직접 읽는다. 1턴 = 60초, dt = 1초. 실제 코어가 아니라 밸런스 경향을 보는 근사 모델이다:
무기 범주마다 60초 일제사격, 피해 √(플랫폼 수) 배율, 국면·방향 사기 가중, 군 사기 3000 미만 즉시 종료,
조조 AI는 반응 지연·실수율, 화공 간파는 평균 시간 기반 확률. 플레이어 개입·진형 전환·보급·선회는 없다.
실행: python sim_red_cliffs_208.py [시드 수] [count_factor 목록, 예: 0.6,0.8,1.0]
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
EQCOST = {e["id"]: e["unit_cost"] for e in setup["ship_types"][7]["mission_equipment"]}
CHARS = {c["id"]: c for c in J("characters.json")}
INT = {k: c["stats"]["지력"] for k, c in CHARS.items()}
CMD = {k: c["stats"]["통솔"] for k, c in CHARS.items()}
PHASE_W = {"contact": 0.8, "barrage": 1.2, "engagement": 2.0, "assault": 1.6, "resolution": 1.0}
DIR_W = {"front": 1.0, "flank": 1.25, "rear": 1.5}
ESCAPE = {"cao": (1600, 300), "alliance": (0, 650)}
SIDE = {"liu_bei": "alliance", "sun_quan": "alliance", "cao_cao": "cao"}

def ang(v): return math.degrees(math.atan2(v[1], v[0])) % 360
def wrap(a): return (a + 180) % 360 - 180

class Sq:
    def __init__(s, d, formation_override=None):
        s.id = d["id"]; s.faction = d["faction_id"]; s.side = SIDE[s.faction]
        s.flagship = d["flagship"]; s.pos = list(map(float, d["initial_position"])); s.facing = 0.0
        s.home = tuple(s.pos)
        s.comp = []  # [type, count, equip]
        for c in d["composition"]: s.comp.append([c["ship_type_id"], c["count"], c.get("mission_equipment_id", "")])
        s.formation = formation_override or d["formation_id"]
        s.cost_decl = d["declared_total_cost"]
        s.ships0 = sum(c[1] for c in s.comp)
        s.maxhull = sum(c[1] * COST[c[0]] * 10 for c in s.comp); s.hull = s.maxhull
        s.morale = d.get("start_morale_bp", 10000); s.state = "active"  # active/retreating/surrendered/destroyed/escaped
        s.lost = 0
        # command limit penalty (formation_draft.gd): ceil(over/0.25), max 4
        rec = 40 + CMD[d["commander"]["id"]] * 2
        ratio = max(0, (s.cost_decl - rec) / rec)
        s.tier = min(math.ceil(ratio / 0.25), 4) if ratio > 0 else 0
        s.acc_bp = 10000 - s.tier * 400
        slow = min(mov["base_speed_by_ship_type"][c[0]] for c in s.comp)
        s.speed_turn = max(1, math.floor(slow * (100 - 5 * s.tier) / 100))
        s.speed = s.speed_turn / 60.0
        # weapons: best-range platform per category (weapon_allocation.gd)
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
                s.weapons[wid] = dict(range=best[1]["range"], arc=best[1]["arc_deg"], platform=best[0], plat0=plat,
                                      ammo=plat * ini["ammo"], special=plat * ini["special"], carrier=carriers, carrier_cap=carriers,
                                      cd=0.0)
        s.ecap = 80 + 12 * s.ships0; s.energy = s.ecap; s.hcap = 100 + 8 * s.ships0; s.heat = 0.0
        s.sensor = sum(n * sen["ship_sensor_points"][t] + (n * sen["fast_equipment_sensor_points"][eq] if eq else 0) for t, n, eq in s.comp)
        s.ew = sum(n * sen["ship_ew_points"][t] + (n * sen["fast_equipment_ew_points"][eq] if eq else 0) for t, n, eq in s.comp)
        iq = INT[d["commander"]["id"]]
        s.iq_pts = next(b["sensor_points"] for b in sen["intelligence_bands"] if b["min"] <= iq <= b["max"])
        s.supp = Counter(); s.shots = Counter(); s.hits = 0; s.first_ammo_out = {}
    @property
    def fire(s): return frm["formations"][s.formation]["fire_percent"]
    @property
    def defense(s): return frm["formations"][s.formation]["defense_percent"]
    def alive(s): return s.state in ("active", "retreating")
    def can_attack(s): return s.state == "active"
    def composition_now(s, proportional):
        # code: losses allocated by ship_type_id ascending
        rem = s.lost; out = []
        if proportional:
            frac = s.lost / s.ships0
            return [[t, n - round(n * frac), eq] for t, n, eq in s.comp]
        for t, n, eq in sorted(s.comp, key=lambda c: c[0]):
            l = min(rem, n); rem -= l; out.append([t, n - l, eq])
        return out
    def cost_now(s, proportional):  # victory cost excludes mission equipment (combat_effects.gd)
        return sum(n * COST[t] for t, n, _ in s.composition_now(proportional))
    def cost0(s): return sum(n * COST[t] for t, n, _ in s.comp)
    def alive_platforms(s, wid, proportional):
        w = wpn["weapons"][wid]; tot = 0
        for t, n, eq in s.composition_now(proportional):
            if t in w["platforms"] or (eq and eq in w["fast_equipment"]): tot += n
        return tot

def det_score(o, t, dist):
    adj = math.floor((o.sensor * (100 + frm["formations"][o.formation]["detection_percent"]) + 50) / 100)
    return adj + o.iq_pts - t.ew - math.floor(dist / 25)

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

def run(variant, seed):
    rng = random.Random(seed)
    V = variant
    fo = V.get("formations", {})
    sqs = [Sq(d, fo.get(d["id"])) for d in setup["squadrons"]]
    by = {s.id: s for s in sqs}
    events = defaultdict(int)  # army morale event penalties per side
    t = 0.0; dt = 1.0; log = []
    first_hit = None; first_retreat = None; chain_done = False
    prop = V.get("proportional_losses", False)
    result = None
    while t < 1200:
        t += dt
        live = [s for s in sqs if s.alive()]
        # ---------- recovery (from turn 2 => t>60), continuous ----------
        if t > 60:
            for s in live:
                s.energy = min(s.ecap, s.energy + s.ecap * 0.20 / 60 * dt)
                s.heat = max(0.0, s.heat - 30 / 60 * dt)
                for w in s.weapons.values():
                    if w["carrier_cap"]:
                        w["carrier"] = min(w["carrier_cap"], w["carrier"] + math.ceil(w["carrier_cap"] * 0.25) / 60 * dt)
        # ---------- targeting + movement ----------
        for s in live:
            enemies = [e for e in sqs if e.side != s.side and e.alive()]
            if not enemies: continue
            if s.state == "retreating":
                goal = ESCAPE[s.side]; v = (goal[0] - s.pos[0], goal[1] - s.pos[1]); d = math.hypot(*v)
                if d <= 60: s.state = "escaped"; continue
                step = min(d, s.speed * dt); s.pos[0] += v[0] / d * step; s.pos[1] += v[1] / d * step; s.facing = ang(v); continue
            if V.get("detection"):
                vis = [e for e in enemies if det_score(s, e, math.dist(s.pos, e.pos)) >= 15]
                # faction-level sharing for movement only (AI viewer merges own faction observers)
                fac_vis = [e for e in enemies if any(det_score(o, e, math.dist(o.pos, e.pos)) >= (37 if s.faction == "sun_quan" else 15)
                                                     for o in sqs if o.faction == s.faction and o.alive())]
            else:
                vis = enemies; fac_vis = enemies
            if s.side == "cao" and AI["reaction_s"] > 0 and getattr(s, "target", None) is not None and s.target.alive() and t - getattr(s, "_rt", -1e9) < AI["reaction_s"]:
                tgt = s.target
            else:
                tgt = min(fac_vis or [None], key=lambda e: math.dist(s.pos, e.pos) if e else 0)
                if s.side == "cao" and fac_vis and rng.randrange(10000) < AI["mistake_bp"]:
                    tgt = fac_vis[rng.randrange(len(fac_vis))]
                s._rt = t
            s.target = tgt
            mode = V.get("sq_ai", {}).get(s.id) or ("hold" if all(c[0] == "SHP-08" for c in s.comp) and s.side == "alliance" else ("fireship" if s.id == HOST else V["ai"].get(s.faction, "advance")))
            goal = None
            if tgt is not None:
                d = math.dist(s.pos, tgt.pos)
                if mode == "advance":
                    standoff = V.get("standoff", {}).get(s.faction, 100)
                    if d > standoff: goal = tgt.pos
                elif mode == "defend":
                    if d <= V.get("defend_trigger", 400) and d > 150: goal = tgt.pos
                elif mode == "flank":
                    # move to a point 150 behind the target's facing
                    fr = math.radians(tgt.facing)
                    goal = [tgt.pos[0] - 150 * math.cos(fr), tgt.pos[1] - 150 * math.sin(fr)]
                    if math.dist(s.pos, goal) < 5: goal = None
                elif mode == "hold":
                    goal = None
                elif mode == "fireship":
                    dense = [e for e in enemies if e.formation in DENSE]
                    if dense:
                        tg = min(dense, key=lambda e: math.dist(s.pos, e.pos))
                        goal = [tg.pos[0] - 200, tg.pos[1]]
                        if math.dist(s.pos, goal) < 5: goal = None
                        tgt = tg
                s.facing = ang((tgt.pos[0] - s.pos[0], tgt.pos[1] - s.pos[1]))
            elif mode == "advance" and s.faction == "cao_cao":
                goal = [s.pos[0] - 60, s.pos[1] + 40]  # patrol offset
            if goal is not None:
                v = (goal[0] - s.pos[0], goal[1] - s.pos[1]); d = math.hypot(*v)
                if d > 1e-6:
                    step = min(d, s.speed * dt); s.pos[0] += v[0] / d * step; s.pos[1] += v[1] / d * step
                    if tgt is None: s.facing = ang(v)
        # ---------- chain explosion variant ----------
        if V.get("chain") and not chain_done and HOST in by:
            host = by[HOST]
            if AI["chain_risk_response"]:
                for e in sqs:
                    if e.side == "cao" and e.alive() and e.formation in DENSE and host.alive() and math.dist(host.pos, e.pos) <= 300:
                        if rng.random() < dt / AI["chain_detect_mean_s"]:
                            e.formation = "FRM-05"; log.append((t, f"{e.id} disperse"))
            if host.can_attack():
                for e in sqs:
                    if e.side != "cao" or not e.alive() or e.formation not in DENSE: continue
                    v = (e.pos[0] - host.pos[0], e.pos[1] - host.pos[1])
                    if math.hypot(*v) <= 240 and abs(wrap(ang(v))) <= 60:
                        chain_done = True
                        dmg = max(1, math.floor(e.maxhull * 0.4)); apply_damage(e, dmg, 3500, prop)
                        events["cao"] += 2500; log.append((t, f"chain {e.id}"))
                        break
        # ---------- fire: each weapon category once per 60 s ----------
        hits_this_tick = []
        for s in live:
            if not s.can_attack(): continue
            for wid, w in s.weapons.items():
                w["cd"] = max(0.0, w["cd"] - dt)
                if w["cd"] > 0: continue
                cands = []
                for e in sqs:
                    if e.side == s.side or not e.alive(): continue
                    d = math.dist(s.pos, e.pos)
                    if d > w["range"]: continue
                    rel = abs(wrap(ang((e.pos[0] - s.pos[0], e.pos[1] - s.pos[1])) - s.facing)) if d > 1e-3 else 0
                    if rel > w["arc"] / 2 + 1e-6 and not V.get("ignore_arc"): continue
                    conf = 10000
                    if V.get("detection"):
                        sc = det_score(s, e, d)
                        if sc >= 37: conf = 10000
                        elif sc >= 15 and s.faction != "sun_quan": conf = 5000   # Sun AI requires >=6500
                        else: continue
                    cands.append((d, e, conf))
                if not cands: continue
                d, e, conf = min(cands, key=lambda c: c[0])
                cost = res["shot_cost"][wid]
                csort = 1 if (wid == "line_fire" and w["platform"] == "SHP-01") else 0
                n_plat = s.alive_platforms(wid, prop) if (V.get("platform_scaled") or V.get("platform_sqrt")) else 1
                if n_plat <= 0: continue
                if V.get("platform_sqrt"):
                    ammo_need = cost["ammo"]; spec_need = cost["special"]; n_plat = math.sqrt(n_plat)
                else:
                    ammo_need = cost["ammo"] * n_plat; spec_need = cost["special"] * n_plat
                reason = None
                if w["ammo"] < ammo_need: reason = "ammo"
                elif s.energy < cost["energy"]: reason = "energy"
                elif s.heat + cost["heat"] > s.hcap: reason = "overheat"
                elif w["carrier"] < csort: reason = "carrier"
                elif w["special"] < spec_need: reason = "special"
                if reason:
                    s.supp[reason] += 1
                    if reason in ("ammo", "special") and wid not in s.first_ammo_out: s.first_ammo_out[wid] = t
                    w["cd"] = V.get("retry", 5.0)
                    continue
                w["ammo"] -= ammo_need; w["special"] -= spec_need; s.energy -= cost["energy"]; s.heat += cost["heat"]; w["carrier"] -= csort
                w["cd"] = 60.0; s.shots[wid] += 1
                sec = sector(s, e)
                chance = max(1000, min(9500, fx["hit"]["base_accuracy_basis_points"][wid] + (s.fire - (e.defense + frm["sector_defense_percent"][sec])) * 100))
                chance = (chance * s.acc_bp + 5000) // 10000
                if conf < 10000: chance = (chance * conf + 5000) // 10000
                if rng.randrange(10000) < chance:
                    dmg = round(fx["damage_points"][wid] * n_plat)
                    hits_this_tick.append((s, e, dmg, phase_of(d), sec))
        # atomic per-tick aggregate (pre-damage snapshot like G8-00)
        agg = defaultdict(lambda: [0, 0.0])
        for s, e, dmg, ph, sec in hits_this_tick:
            base = max(300, math.ceil(dmg * 10000 / (e.maxhull * 5)))
            w = (PHASE_W[ph] if V.get("phase_w", True) else 1) * (DIR_W[sec] if V.get("dir_w", True) else 1)
            agg[e.id][0] += dmg; agg[e.id][1] += base * w
            s.hits += 1
            if first_hit is None: first_hit = t
        for eid, (dmg, mor) in agg.items():
            apply_damage(by[eid], 0 if V.get("no_damage") else dmg, 0 if V.get("no_damage") else mor, prop, ship_w=V.get("ship_loss_w", 1.0))
        # ---------- state transitions ----------
        for s in sqs:
            if s.state in ("active", "retreating"):
                if s.hull <= 0: s.state = "destroyed"; events[s.side] += 500; log.append((t, f"{s.id} destroyed"))
                elif s.morale <= 0: s.state = "surrendered"; events[s.side] += 500 if not getattr(s, "_ret", False) else 0; log.append((t, f"{s.id} surrendered"))
                elif s.morale < 3000 and s.state == "active":
                    s.state = "retreating"; s._ret = True; events[s.side] += 500; log.append((t, f"{s.id} retreat"))
                    if first_retreat is None: first_retreat = t
        # ---------- end checks ----------
        r = end_check(sqs, events, t, prop, V)
        if r: result = r; break
    if result is None:
        result = time_limit(sqs, prop)
    am = {side: army_morale(sqs, events, side) for side in ("alliance", "cao")}
    out = dict(result, t=t, first_hit=first_hit, first_retreat=first_retreat, army=am, log=log,
               cao_hull=sum(s.hull for s in sqs if s.side == "cao") / sum(s.maxhull for s in sqs if s.side == "cao"),
               sqs={s.id: dict(state=s.state, morale=s.morale, hull=round(s.hull / s.maxhull, 3), shots=dict(s.shots),
                               supp=dict(s.supp), ammo_out=dict(s.first_ammo_out),
                               ammo_left={k: w["ammo"] for k, w in s.weapons.items()}) for s in sqs})
    return out

def apply_damage(e, dmg, morale_loss, prop, ship_w=1.0):
    dmg = min(e.hull, dmg); e.hull -= dmg
    losses = math.floor(e.ships0 * (e.maxhull - e.hull) / e.maxhull)
    if e.hull == 0: losses = e.ships0
    delta = max(0, losses - e.lost); e.lost = losses
    e.morale = max(0, e.morale - round(morale_loss + delta * 200 * ship_w))
    if e.hull == 0: e.morale = 0

def army_morale(sqs, events, side):
    mem = [s for s in sqs if s.side == side]
    tot = sum(s.cost_decl for s in mem)
    keep = ARMY_KEEP[0]
    m = sum((s.morale if (s.state == "active" or (keep and s.state == "retreating")) else 0) * s.cost_decl for s in mem) / tot
    return m - events[side]

def end_check(sqs, events, t, prop, V):
    by = {s.id: s for s in sqs}
    liu = by[FLAG["liu_bei"]]; cao = by[FLAG["cao_cao"]]
    if liu.hull <= 0: return dict(reason="liu_flagship_destroyed", winner="cao")
    if cao.hull <= 0: return dict(reason="cao_flagship_destroyed", winner="alliance")
    def loss(fs):
        o = sum(s.cost0() for s in sqs if s.faction in fs); r = sum(s.cost_now(prop) for s in sqs if s.faction in fs)
        return (o - r) / o
    if loss(["cao_cao"]) >= 0.7: return dict(reason="cao_cost_loss70", winner="alliance")
    if loss(["liu_bei"]) >= 0.7: return dict(reason="liu_cost_loss70", winner="cao")
    if loss(["liu_bei", "sun_quan"]) >= 0.7: return dict(reason="alliance_cost_loss70", winner="cao")
    if V.get("army_end", True):
        a = army_morale(sqs, events, "alliance"); c = army_morale(sqs, events, "cao")
        if a < 3000 and c < 3000: return dict(reason="army_morale_both", winner="cao")
        if a < 3000: return dict(reason="army_morale_alliance", winner="cao")
        if c < 3000: return dict(reason="army_morale_cao", winner="alliance")
    for side in ("alliance", "cao"):
        if all(not s.alive() for s in sqs if s.side == side):
            return dict(reason=f"{side}_all_gone", winner="cao" if side == "alliance" else "alliance")
    return None

def time_limit(sqs, prop):
    a0 = sum(s.cost0() for s in sqs if s.side == "alliance"); ar = sum(s.cost_now(prop) for s in sqs if s.side == "alliance")
    c0 = sum(s.cost0() for s in sqs if s.side == "cao"); cr = sum(s.cost_now(prop) for s in sqs if s.side == "cao")
    return dict(reason="time_limit", winner="alliance" if ar * c0 > cr * a0 else "cao")

BASE_AI = {"cao_cao": "advance", "sun_quan": "defend", "liu_bei": "defend"}
ARMY_KEEP=[True]
import make_red_cliffs_208 as MS
SC = json.load(open(r"C:\WorkSpace\SpaceBattleOfThreeKingdoms\data\scenarios\red_cliffs_208_realtime.json", encoding="utf-8"))
HOST = SC["chain_explosion_override"]["host_squadron_id"]
DENSE = ("FRM-02", "FRM-03", "FRM-04")
FLAG = {}
AI = {}
BASE = dict(ai={"cao_cao": "advance", "sun_quan": "defend", "liu_bei": "defend"}, standoff={"cao_cao": 100}, platform_sqrt=True, keep=True)

if __name__ == "__main__":
    N = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    print("| 난이도 | 연쇄 폭발 | 길이 중앙값 | 조조 승률 | 종료 조건 | 조조 선체 잔존 |")
    print("|---|---|---|---|---|---|")
    import itertools
    factors = [float(x) for x in sys.argv[2].split(",")] if len(sys.argv) > 2 else [None]
    for diff, fac in itertools.product(SC["difficulty_order"], factors):
        if fac is not None: MS.DIFF[diff]["count_factor"] = fac
        setup["squadrons"] = MS.apply_difficulty(SC["squadrons"], diff)
        ratio = sum(q["declared_total_cost"] for q in setup["squadrons"] if q["faction_id"] == "cao_cao") / sum(q["declared_total_cost"] for q in setup["squadrons"] if q["faction_id"] != "cao_cao")
        FLAG.clear(); FLAG.update({s["faction_id"]: s["id"] for s in setup["squadrons"] if s["flagship"] and s["faction_id"] in ("liu_bei", "cao_cao")})
        AI.clear(); AI.update(MS.DIFF[diff]["ai"])
        for chain in (False, True):
            V = dict(BASE, chain=chain)
            rs = [run(V, seed) for seed in range(N)]
            T = sorted(r["t"] for r in rs); win = Counter(r["winner"] for r in rs); reasons = Counter(r["reason"] for r in rs)
            m = st.median(T)
            print(f"| {diff} x{ratio:.2f} | {'켬' if chain else '끔'} | {int(m//60)}분 {int(m%60):02d}초 | {100*win['cao']//N}% | {dict(reasons)} | {st.median(r['cao_hull'] for r in rs):.2f} |")
