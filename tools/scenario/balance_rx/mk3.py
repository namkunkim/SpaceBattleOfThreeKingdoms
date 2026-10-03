s = open("sim2.py", encoding="utf-8").read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (a[:60], s.count(a))
    s = s.replace(a, b)
rep('''        s.engaged_at = None; s.target = None; s._rt = -1e9; s._ret = False''',
    '''        s.engaged_at = None; s.target = None; s._rt = -1e9; s._ret = False
        s.mgroup = d.get("morale_group"); s.halve_until = -1''')
rep('''    chain_done = False; chain_open = False; danger = set()''',
    '''    chain_done = False; chain_open = False; danger = set()
    XR = P.get("xr", False); rng2 = random.Random(seed * 7919 + 17)
    win_off = rng2.uniform(*P.get("win_range", (360, 600))); win_start = None
    hs = dict(state="wait", susp=0.0, charges=2, target=None)  # host fire program
    burnt = set(); spreads = []; rallied = False
    def feigning(q): return XR and P.get("chain") and q.id == HOST and hs["state"] == "feign" and hs["susp"] < 100
    def burn(e, power, kind):
        dmg = max(1, math.floor(e.maxhull * power * P.get("chain_hull_mul", 1.0))); k = power / 0.40
        if P.get("chain_null"): ev.append((t, kind, e.id)); burnt.add(e.id); return
        apply_damage(e, dmg, 3500 * k * P.get("chain_mor_mul", 1.0), P, raw=True); events["cao"] += 2500 * k * P.get("chain_army_mul", 1.0); burnt.add(e.id)
        ev.append((t, kind, f"{e.id}:{power:.3f}"))''')
rep('''            else:
                fac_vis = enemies
            if s.side == "cao" and AI["reaction_s"]''', '''            else:
                fac_vis = enemies
            if s.side == "cao": fac_vis = [e for e in fac_vis if not feigning(e)]
            if s.side == "cao" and AI["reaction_s"]''')
rep('''            mode = ("hold" if all(c[0] == "SHP-08" for c in s.comp) and s.side == "alliance" else
                    ("fireship" if s.id == HOST else P["ai"].get(s.faction, "advance")))''',
    '''            mode = ("hold" if all(c[0] == "SHP-08" for c in s.comp) and s.side == "alliance" else
                    ("fireship" if s.id == HOST else P["ai"].get(s.faction, "advance")))
            if XR and s.id == HOST:
                mode = "xfire" if (P.get("chain") and hs["state"] in ("wait", "feign", "exposed")) else "defend"''')
rep('''                elif mode == "fireship":''', '''                elif mode == "xfire":
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
                elif mode == "fireship":''')
old_chain_start = '''        # chain explosion (화공)
        if P.get("chain") and not chain_done and HOST in by:'''
i = s.index(old_chain_start); j = s.index('''        hits = []''')
old = s[i:j]
new = '''        # chain explosion (화공)
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
''' + "        elif" + old.split("\n", 2)[1].strip()[2:] + "\n" + old.split("\n", 2)[2]
s = s[:i] + new + s[j:]
rep('''                    if e.side == s.side or not e.alive(): continue
                    d = math.dist(s.pos, e.pos)
                    if d > w["range"]: continue''', '''                    if e.side == s.side or not e.alive(): continue
                    if feigning(e) or feigning(s): continue
                    d = math.dist(s.pos, e.pos)
                    if d > w["range"]: continue''')
rep('''        for eid, (dmg, mor) in agg.items():
            apply_damage(by[eid], round(dmg), mor, P)''', '''        for eid, (dmg, mor) in agg.items():
            q = by[eid]; fac = 1.0
            if XR and q.side == "cao" and hs["state"] == "feign":
                hs["susp"] += P.get("susp_per_hit", 0) * sum(1 for hh in hits if hh[1] is q)
            if XR:
                if q.side == "cao" and q.formation in DENSE: fac *= P.get("dense_mul", 0.8)
                if t < q.halve_until: fac *= 0.5
            apply_damage(q, round(dmg), mor, P, fac=fac)''')
rep('''def apply_damage(e, dmg, morale_loss, P, raw=False):''', '''def apply_damage(e, dmg, morale_loss, P, raw=False, fac=1.0):''')
rep('''    e.morale = max(0, e.morale - round(morale_loss + delta * sb))''', '''    e.morale = max(0, e.morale - round((morale_loss + delta * sb) * fac))''')
rep('''                elif s.morale <= 0: s.state = "surrendered"; events[s.side] += 0 if s._ret else P.get("ev_bp", 500); ev.append((t, "surrender", s.id))
                elif s.morale < 3000 and s.state == "active":
                    s.state = "retreating"; s._ret = True; events[s.side] += P.get("ev_bp", 500); ev.append((t, "retreat", s.id))''',
'''                elif s.morale <= 0:
                    s.state = "surrendered"; events[s.side] += 0 if s._ret else P.get("ev_bp", 500); ev.append((t, "surrender", s.id))
                    if XR and not s._ret: events["cao" if s.side == "alliance" else "alliance"] -= P.get("recover_bp", 300)
                elif s.morale < 3000 and s.state == "active":
                    s.state = "retreating"; s._ret = True; events[s.side] += P.get("ev_bp", 500); ev.append((t, "retreat", s.id))
                    if XR: events["cao" if s.side == "alliance" else "alliance"] -= P.get("recover_bp", 300)''')
rep('''        for side in ("alliance", "cao"):
            if side not in danger''', '''        if XR and not rallied and P.get("rally", True) and army_morale(sqs, events, "alliance") < 4500:
            rallied = True; fl = by[FLAG["liu_bei"]]
            if fl.can_attack():
                for q in sqs:
                    if q.side == "alliance" and q.can_attack() and math.dist(q.pos, fl.pos) <= 200:
                        q.morale = min(10000, q.morale + 1200); q.halve_until = t + 30
                ev.append((t, "rally", "liu"))
        for side in ("alliance", "cao"):
            if side not in danger''')
rep('''    return m - events[side]''', '''    return min(10000, m - events[side])''')
rep('''    return dict(result, t=t, first_hit=first_hit, ev=ev)''', '''    return dict(result, t=t, first_hit=first_hit, ev=ev, win_start=win_start)''')
rep('''def setup_diff(diff, P):''', '''SUSP = {"입문": 0.4, "표준": 0.8, "상급": 1.5, "극한": 2.0}
def setup_diff(diff, P):''')
rep('''            Q = dict(BASE, **P, chain=chain)''', '''            Q = dict(BASE, **P, chain=chain); Q.setdefault("susp_rate", SUSP[diff])''')
rep('''                       opened=sum(''', '''                       spread=sum(any(k == "spread" for _, k, _ in r["ev"]) for r in rs) / N,
                       detected=sum(any(k == "detected" for _, k, _ in r["ev"]) for r in rs) / N,
                       opened=sum(''')
rep('''MEANINGFUL = ("band", "retreat", "surrender", "destroyed", "fire_open", "chain", "danger", "engage")''',
    '''MEANINGFUL = ("band", "retreat", "surrender", "destroyed", "fire_open", "chain", "danger", "engage", "feign", "detected", "rally")''')
open("sim3.py", "w", encoding="utf-8").write(s)
