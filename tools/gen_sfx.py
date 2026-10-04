# 전투 효과음 합성기. 표준 라이브러리만 쓴다(외부 자산·라이선스 없음).
# 실행: python tools/gen_sfx.py  → assets/audio/battle/*.wav (44.1kHz 16bit 모노)
# 이름이 ui_sound.gd EVENTS의 file과 같으면 훅이 합성 임시음 대신 이 파일을 쓴다.
# *_loop 파일은 smpl 청크에 루프 구간을 넣는다(Godot 임포트 "Detect From WAV").
import math, os, random, struct

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "battle")


def n(d):
    return int(SR * d)


def osc(dur, f, shape="sine", ph=0.0):
    out = []
    for i in range(n(dur)):
        ph += (f(i / SR) if callable(f) else f) / SR
        p = ph % 1.0
        if shape == "sine":
            v = math.sin(2 * math.pi * p)
        elif shape == "saw":
            v = 2 * p - 1
        elif shape == "square":
            v = 1.0 if p < 0.5 else -1.0
        else:  # tri
            v = 4 * abs(p - 0.5) - 1
        out.append(v)
    return out


def noise(dur, seed):
    r = random.Random(seed)
    return [r.uniform(-1, 1) for _ in range(n(dur))]


def brown(dur, seed):
    r, y, out = random.Random(seed), 0.0, []
    for _ in range(n(dur)):
        y = (y + r.uniform(-1, 1) * 0.05) * 0.995
        out.append(y * 8)
    return out


def lp(x, cut, poles=1):
    for _ in range(poles):
        y, out = 0.0, []
        for i, v in enumerate(x):
            fc = cut(i / SR) if callable(cut) else cut
            y += (1 - math.exp(-2 * math.pi * fc / SR)) * (v - y)
            out.append(y)
        x = out
    return x


def hp(x, cut):
    return [a - b for a, b in zip(x, lp(x, cut))]


def env(x, f):
    return [v * f(i / SR) for i, v in enumerate(x)]


def ad(a, d):  # 선형 상승 a초, 지수 감쇠 d초
    return lambda t: t / a if t < a else math.exp(-(t - a) / d)


def sweep(f0, f1, dur):  # 지수 미끄럼
    return lambda t: f0 * (f1 / f0) ** min(t / dur, 1.0)


def mix(*layers):  # (신호, 이득, 시작초)
    total = max(n(s) + len(x) for x, _, s in layers)
    out = [0.0] * total
    for x, g, s in layers:
        o = n(s)
        for i, v in enumerate(x):
            out[o + i] += v * g
    return out


def echo(x, d=0.11, fb=0.35, taps=4):
    return mix(*[(x, fb ** k, d * k) for k in range(taps + 1)])


def finish(x, peak=0.89, drive=1.4):
    x = [math.tanh(v * drive) for v in x]
    m = max(abs(v) for v in x) or 1.0
    fade = min(n(0.01), len(x))
    for i in range(fade):
        x[-1 - i] *= i / fade
    return [v * peak / m for v in x]


def loopify(x, xf):  # 꼬리를 머리에 교차 페이드해 이음매를 없앤다
    body, tail = x[:-xf], x[-xf:]
    for i in range(xf):
        k = i / xf
        body[i] = body[i] * k + tail[i] * (1 - k)
    return body


def write(name, x, loop=False):
    if loop:  # 루프는 끝 페이드·과구동 없이 정규화만
        m = max(abs(v) for v in x) or 1.0
        x = [v * 0.8 / m for v in x]
    pcm = struct.pack("<%dh" % len(x), *(int(max(-1, min(1, v)) * 32767) for v in x))
    chunks = b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16)
    chunks += b"data" + struct.pack("<I", len(pcm)) + pcm
    if loop:
        smpl = struct.pack("<9I", 0, 0, 10**9 // SR, 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, len(x) - 1, 0, 0)
        chunks += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    with open(os.path.join(OUT, name + ".wav"), "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + len(chunks)) + b"WAVE" + chunks)
    print("%-18s %.2fs" % (name, len(x) / SR))


# ── 공통 부품 ──────────────────────────────────────────

def blast(dur, seed, bright=4000, low=180, sub=55):
    nz = lp(noise(dur, seed), lambda t: low + bright * math.exp(-t * 6), 2)
    crack = [v if random.Random(seed + i).random() < 0.004 else 0.0 for i, v in enumerate(noise(dur, seed + 1))]
    return mix(
        (env(nz, ad(0.004, dur * 0.3)), 1.0, 0),
        (env(osc(dur, sweep(sub, sub * 0.45, dur)), ad(0.002, dur * 0.25)), 0.9, 0),
        (env(lp(crack, 3000), ad(0.01, dur * 0.4)), 0.6, 0.03),
    )


def clank(dur, seed, base=1.0):
    parts = [(523, 0.12), (1187, 0.08), (1873, 0.05), (2711, 0.035)]
    layers = [(env(osc(dur, f * base), ad(0.001, d)), 1.0, 0) for f, d in parts]
    layers.append((env(hp(noise(0.03, seed), 1500), ad(0.001, 0.008)), 0.8, 0))
    return mix(*layers)


def cannon(seed):
    return mix(
        (env(lp(noise(0.5, seed), lambda t: 150 + 1800 * math.exp(-t * 18), 2), ad(0.002, 0.12)), 1.0, 0),
        (env(osc(0.5, sweep(80, 38, 0.3)), ad(0.002, 0.1)), 1.0, 0),
    )


# ── 효과음 ─────────────────────────────────────────────

def laser_light():
    zap = env(osc(0.22, sweep(2400, 320, 0.16), "square"), ad(0.002, 0.05))
    body = env(osc(0.22, sweep(1200, 160, 0.18), "saw"), ad(0.002, 0.06))
    return finish(echo(lp(mix((zap, 0.5, 0), (body, 0.6, 0)), 5000), 0.07, 0.25, 2))


def laser_heavy():
    charge = env(osc(0.3, sweep(180, 1400, 0.3)), lambda t: (t / 0.3) ** 2 * 0.35)
    shot = mix(
        (env(osc(0.8, sweep(900, 70, 0.5), "saw"), ad(0.003, 0.18)), 0.7, 0),
        (env(osc(0.8, sweep(60, 30, 0.6)), ad(0.003, 0.25)), 0.9, 0),
        (env(lp(noise(0.8, 11), lambda t: 300 + 6000 * math.exp(-t * 10)), ad(0.002, 0.12)), 0.6, 0),
    )
    return finish(echo(mix((charge, 1.0, 0), (shot, 1.0, 0.28)), 0.13, 0.3, 3))


def beam_loop():
    d = 2.2
    hum = mix(*[(osc(d, f, "saw"), 0.35, 0) for f in (98, 98.6, 147.2, 196.9)])
    hum = lp(hum, 1100, 2)
    fizz = hp(lp(noise(d, 21), 4500), 1800)
    x = mix((hum, 1.0, 0), (fizz, 0.18, 0))
    return loopify(env(x, lambda t: 1 + 0.12 * math.sin(2 * math.pi * 7 * t)), n(0.2))


def volley():  # 근접 방어포 짧은 2연발 (사건 간격 0.09초라 짧게)
    shot = lambda s: mix(
        (env(lp(noise(0.08, s), 3200), ad(0.001, 0.018)), 1.0, 0),
        (env(osc(0.08, sweep(320, 90, 0.05)), ad(0.001, 0.02)), 0.8, 0),
    )
    return finish(mix((shot(31), 1.0, 0), (shot(32), 0.8, 0.055)))


def salvo():  # 주포 일제사격: 묵직한 3연발
    return finish(echo(mix((cannon(41), 1.0, 0), (cannon(42), 0.9, 0.09), (cannon(43), 0.85, 0.2)), 0.16, 0.3, 3), drive=2.0)


def missile_launch():
    d = 1.5
    hiss = hp(lp(noise(d, 51), lambda t: 900 + 5000 * min(t / 0.25, 1) * math.exp(-t * 0.8)), 250)
    hiss = env(hiss, lambda t: min(t / 0.05, 1) * math.exp(-t * 2.2))
    whistle = env(osc(d, sweep(500, 1700, 1.0)), lambda t: min(t / 0.2, 1) * math.exp(-t * 2.8))
    thump = env(osc(0.3, sweep(110, 40, 0.15)), ad(0.002, 0.07))
    return finish(mix((thump, 1.0, 0), (clank(0.2, 52, 0.7), 0.3, 0), (hiss, 0.9, 0.02), (whistle, 0.12, 0.05)))


def missile_hit():
    return finish(echo(blast(1.0, 61, bright=5000, low=220, sub=70), 0.15, 0.25, 2), drive=2.2)


def fighter_launch():
    d = 1.9
    doppler = lambda t: 1.0 if t < 1.0 else 1.0 - 0.35 * (t - 1.0) / 0.9
    jet = osc(d, lambda t: (220 + 700 * min(t / 0.6, 1)) * doppler(t), "saw")
    jet = lp(jet, lambda t: 2600 * doppler(t), 2)
    hiss = hp(lp(noise(d, 71), 6000), 1200)
    shape = lambda t: min(t / 0.35, 1) * (1.0 if t < 0.9 else math.exp(-(t - 0.9) * 2.6))
    return finish(mix((clank(0.4, 72, 0.8), 0.8, 0), (env(jet, shape), 0.6, 0.08), (env(hiss, shape), 0.4, 0.08)))


def fighter_guns():
    shots = [(env(hp(lp(noise(0.05, 80 + k), 4500), 400), ad(0.001, 0.012)), 1.0 - k * 0.03, k * 0.042) for k in range(12)]
    return finish(mix(*shots))


def fighter_dock():
    hyd = env(hp(lp(noise(0.7, 91), 3500), 800), lambda t: min(t / 0.05, 1) * math.exp(-t * 4))
    return finish(mix((hyd, 0.5, 0), (clank(0.5, 92, 0.6), 0.9, 0.3), (env(osc(0.3, sweep(90, 45, 0.2)), ad(0.002, 0.08)), 0.7, 0.3)))


def engine_loop():
    d = 3.3
    rumble = lp(brown(d, 101), 160, 2)
    hum = mix((osc(d, 42), 0.5, 0), (osc(d, 84.3), 0.2, 0), (osc(d, 126.5, "tri"), 0.08, 0))
    x = mix((rumble, 1.0, 0), (hum, 1.0, 0))
    return loopify(env(x, lambda t: 1 + 0.15 * math.sin(2 * math.pi * t / 1.5)), n(0.3))


def engine_boost():
    d = 1.8
    roar = lp(noise(d, 111), lambda t: 250 + 2800 * min(t / 0.5, 1) * math.exp(-max(t - 0.6, 0) * 1.2), 2)
    whine = osc(d, sweep(120, 420, 0.8), "saw")
    shape = lambda t: min(t / 0.25, 1) * (1.0 if t < 0.7 else math.exp(-(t - 0.7) * 1.8))
    return finish(mix((env(roar, shape), 1.0, 0), (env(lp(whine, 1500), shape), 0.3, 0), (env(osc(0.4, sweep(70, 35, 0.3)), ad(0.005, 0.12)), 0.8, 0)))


def shield_hit():
    d = 0.7
    ring = mix((osc(d, sweep(1500, 900, d)), 0.6, 0), (osc(d, sweep(2250, 1350, d)), 0.35, 0))
    ring = [v * math.sin(2 * math.pi * 37 * i / SR) for i, v in enumerate(ring)]
    zap = env(hp(noise(0.06, 121), 3000), ad(0.001, 0.015))
    return finish(echo(mix((env(ring, ad(0.003, 0.16)), 1.0, 0), (zap, 0.6, 0)), 0.09, 0.3, 3))


def armor_hit():
    return finish(mix((clank(0.45, 131), 1.0, 0), (env(lp(noise(0.3, 132), 1200), ad(0.002, 0.06)), 0.7, 0)))


def ship_kill():
    return finish(echo(blast(1.4, 141), 0.18, 0.25, 2), drive=2.0)


def fleet_destroyed():
    return finish(echo(mix(
        (blast(3.0, 151, bright=3000, low=120, sub=45), 1.0, 0),
        (blast(1.2, 152), 0.6, 0.45),
        (blast(1.0, 153, bright=5000), 0.5, 0.95),
        (blast(1.6, 154, sub=40), 0.7, 1.5),
    ), 0.22, 0.3, 3), drive=1.8)


def chain_explosion():
    r = random.Random(161)
    return finish(mix(*[(blast(0.9, 162 + k, bright=r.uniform(2500, 6000), sub=r.uniform(45, 80)), r.uniform(0.6, 1.0), k * 0.32 + r.uniform(0, 0.12)) for k in range(6)]), drive=1.8)


def fire_ignite():  # 화공 발동: 불길이 확 일어나는 소리
    d = 1.6
    whoosh = lp(noise(d, 171), lambda t: 300 + 4500 * min(t / 0.4, 1) * math.exp(-max(t - 0.4, 0) * 1.5), 2)
    whoosh = env(whoosh, lambda t: min(t / 0.35, 1) ** 2 * math.exp(-max(t - 0.4, 0) * 1.6))
    return finish(mix((whoosh, 1.0, 0), (blast(1.0, 172, bright=2000, sub=50), 0.7, 0.3)))


def fire_loop():  # 번지는 불: 저음 굉음 + 타닥임
    d = 3.3
    r = random.Random(181)
    roar = lp(noise(d, 182), 500, 2)
    crackle = [r.uniform(0.3, 1) * (1 if r.random() < 0.5 else -1) if r.random() < 0.0025 else 0.0 for _ in range(n(d))]
    crackle = hp(lp(crackle, 5000), 900)
    x = mix((env(roar, lambda t: 1 + 0.25 * math.sin(2 * math.pi * t / 1.1)), 1.0, 0), (crackle, 2.5, 0))
    return loopify(x, n(0.3))


SOUNDS = [laser_light, laser_heavy, volley, salvo, missile_launch, missile_hit, fighter_launch, fighter_guns,
          fighter_dock, engine_boost, shield_hit, armor_hit, ship_kill, fleet_destroyed, chain_explosion, fire_ignite]
LOOPS = [beam_loop, engine_loop, fire_loop]

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for f in SOUNDS:
        write(f.__name__, f())
    for f in LOOPS:
        write(f.__name__, f(), loop=True)
