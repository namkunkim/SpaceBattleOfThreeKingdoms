"""Bake Red Cliffs' normalized movement grid and matching terrain overlay."""
import json
import math
from pathlib import Path
import random
import struct
import sys
import zlib

ROOT = Path(__file__).resolve().parents[2]
COLS, ROWS = 49, 29
WIDTH, HEIGHT = 1536, 864
RNG = random.Random(208)

def read_material(path):
    """Load the 24-bit or 32-bit BMP exported from the source plate."""
    raw = Path(path).read_bytes()
    if raw[:2] != b"BM":
        raise ValueError("Expected a BMP material plate")
    start = struct.unpack_from("<I", raw, 10)[0]
    width, signed_height, planes, bits, compression = struct.unpack_from("<iiHHI", raw, 18)
    if planes != 1 or bits not in (24, 32) or compression != 0:
        raise ValueError("Expected an uncompressed 24/32-bit BMP")
    height = abs(signed_height)
    step = bits // 8
    stride = (width * step + 3) & ~3
    def pixel(x, y):
        px = min(int(x * width), width - 1)
        py = min(int(y * height), height - 1)
        if signed_height > 0:
            py = height - py - 1
        at = start + py * stride + px * step
        return raw[at+2], raw[at+1], raw[at]
    return pixel

material_pixel = read_material(sys.argv[1]) if len(sys.argv) == 2 else None

def band(x, y, cx, cy, span, thickness, slope, wave):
    offset = x - cx
    ridge = y - cy - slope * offset - wave * math.sin(offset * 15)
    return math.exp(-((offset / span) ** 2 + (ridge / thickness) ** 2) * 1.5)

def channels(x, y):
    rock = max(
        band(x, y, .45, .18, .19, .072, -.18, .021),
        .92 * band(x, y, .60, .67, .27, .050, -.46, .033),
        .76 * band(x, y, .17, .44, .10, .064, .51, .022),
    )
    gas = max(
        band(x, y, .36, .14, .22, .10, .21, .04),
        .90 * band(x, y, .78, .48, .25, .10, -.52, .036),
    )
    dust = max(
        .90 * band(x, y, .33, .73, .29, .10, .30, .054),
        .83 * band(x, y, .70, .91, .34, .09, -.22, .028),
        .77 * band(x, y, .81, .28, .14, .09, .22, .029),
    )
    return rock, gas, dust

grid = [[channels(x / (COLS - 1), y / (ROWS - 1)) for x in range(COLS)] for y in range(ROWS)]
costs = [round(10150 + min(6500, rock * 4700 + gas * 2500 + dust * 1700))
         for row in grid for rock, gas, dust in row]
navigation = json.loads((ROOT / "data/scenarios/base/red-cliffs-navigation.json").read_bytes())
polygons = navigation["blocked"]
data = {"navigation": navigation, "map_id": "red-cliffs-208-orbital-terrain-v1", "columns": COLS, "rows": ROWS,
        "move_cost_bp": costs, "overlay": "res://assets/world_atlas/red-cliffs-terrain.png"}
data_path = ROOT / "data/scenarios/base/red-cliffs-movement-field.json"
data_path.write_text(json.dumps(data, separators=(",", ":")) + "\n", encoding="utf-8")

def inside(x, y, polygon):
    result = False
    for (ax, ay), (bx, by) in zip(polygon, polygon[1:] + polygon[:1]):
        if (ay > y) != (by > y) and x < ax + (y-ay) * (bx-ax) / (by-ay):
            result = not result
    return result

def blocked(x, y):
    return .35 < x < .68 and any(inside(x, y, polygon) for polygon in polygons)

def barrier_density(x, y):
    if not .35 < x < .68:
        return 0.0
    for polygon in polygons:
        if not inside(x, y, polygon):
            continue
        nearest = 1.0
        for (ax, ay), (bx, by) in zip(polygon, polygon[1:] + polygon[:1]):
            dx, dy = bx-ax, by-ay
            t = max(0.0, min(1.0, ((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy)))
            nearest = min(nearest, (x-ax-t*dx)**2+(y-ay-t*dy)**2)
        u = min(1.0, math.sqrt(nearest) / .045)
        return u*u*(3-2*u)
    return 0.0

def sample(x, y):
    gx, gy = x * (COLS - 1), y * (ROWS - 1)
    i, j = min(int(gx), COLS - 2), min(int(gy), ROWS - 2)
    u, v = gx - i, gy - j
    return tuple((grid[j][i][k] * (1-u) + grid[j][i+1][k] * u) * (1-v)
                 + (grid[j+1][i][k] * (1-u) + grid[j+1][i+1][k] * u) * v for k in range(3))

def noise_table(size):
    return [[RNG.random() for _ in range(size+1)] for _ in range(size+1)]

noise = [noise_table(n) for n in (12, 31, 80, 176)]

def noise_at(table, x, y):
    n = len(table)-1
    px, py = x*n, y*n
    ix, iy = min(int(px),n-1), min(int(py),n-1)
    fx, fy = px-ix, py-iy
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    return (table[iy][ix]*(1-fx)+table[iy][ix+1]*fx)*(1-fy) + (table[iy+1][ix]*(1-fx)+table[iy+1][ix+1]*fx)*fy

pixels = bytearray(WIDTH * HEIGHT * 4)
for py in range(HEIGHT):
    y = py / (HEIGHT - 1)
    for px in range(WIDTH):
        x = px / (WIDTH - 1)
        rock, gas, dust = sample(x, y)
        dense = barrier_density(x, y)
        rock = max(rock, dense * .70)
        dust = max(dust, dense * .38)
        if max(rock, gas, dust) < .008:
            continue
        if material_pixel is not None:
            # Repeat a mirrored part of the material so rock-scale stays independent of the field.
            u = (x * 1.42 + 0.17) % 2
            v = (y * 1.31 + 0.28) % 2
            red, green, blue = material_pixel(1 - abs(1-u), 1 - abs(1-v))
            light = max(red, green, blue) / 255
            strength = min(1.0, max(dense * 0.98, rock * .76, gas * .76, dust * .47))
            # Remove the material's dark background instead of painting an opaque slab.
            opacity = min(.94, strength * max(0.0, light - .025) ** .62 * 1.74)
            if opacity > .004:
                rgb = (min(255, round(red * 1.08)), min(255, round(green * 1.12)), min(255, round(blue * 1.18)))
                index = (py * WIDTH + px) * 4
                pixels[index:index+4] = bytes((*rgb, round(opacity * 255)))
            continue
        coarse, mid, fine, detail = (noise_at(table, x, y) for table in noise)
        filament = (0.54 + .46 * math.sin(26 * x + 56 * y + coarse * 7 + mid * 2)) ** 2
        fog = gas * (.23 + .53 * filament) * (.33 + .7 * mid)
        rubble = rock * (.16 + .20 * coarse) * (.4 + .6 * detail)
        powder = dust * (.19 + .44 * fine) * (.47 + .65 * mid)
        rubble += dense * (.035 + mid * fine * .18)
        alpha = fog + rubble + powder
        weights = (fog, rubble, powder)
        colors = ((112, 84, 139) if y < .4 else (57, 111, 136), (100, 91, 81), (133, 104, 79))
        rgb = tuple(round(sum(weight * color[k] for weight, color in zip(weights, colors)) / alpha) for k in range(3))
        index = (py * WIDTH + px) * 4
        pixels[index:index+4] = bytes((*rgb, min(225, round(alpha * 198))))

def paint(px, py, color, alpha):
    if not (0 <= px < WIDTH and 0 <= py < HEIGHT):
        return
    index = (py * WIDTH + px) * 4
    old = pixels[index:index+4]
    old_weight = old[3] / 255 * (1-alpha)
    total = old_weight + alpha
    values = [round((old[i]*old_weight + color[i]*alpha) / total) for i in range(3)]
    pixels[index:index+4] = bytes((*values, round(total*255)))

def asteroid(cx, cy, radius, density):
    ratio = RNG.uniform(.55, .95)
    phase = RNG.uniform(0, math.tau)
    facets = [RNG.uniform(.64, 1.22) for _ in range(9)]
    hue = RNG.uniform(.75, 1.20)
    for py in range(cy-radius-1, cy+radius+2):
        for px in range(cx-radius-1, cx+radius+2):
            rx, ry = (px-cx)/radius, (py-cy)/(radius*ratio)
            angle = ((math.atan2(ry,rx)+phase) % math.tau) / math.tau * len(facets)
            slot = int(angle)
            outline = facets[slot] + (facets[(slot+1)%len(facets)]-facets[slot]) * (angle-slot)
            length = math.hypot(rx,ry)
            if length > outline:
                continue
            rim = max(0, 1-(outline-length)*7)
            sun = max(0, -.65*rx - .68*ry)
            grain = RNG.random() * .26
            light = (.16 + sun * .63 + rim * sun * .5 + grain) * hue
            rgb = tuple(min(220, round(c*light)) for c in (177, 158, 136))
            paint(px, py, rgb, min(.96, (.56 + density*.39) * (.83 + grain)))

for _ in range(0 if material_pixel is not None else 23400):
    x, y = RNG.random(), RNG.random()
    rock, _, dust = sample(x, y)
    px, py = int(x*WIDTH), int(y*HEIGHT)
    if blocked(x, y):
        rock = max(rock, .96)
    if RNG.random() < rock ** 1.8 * .40:
        radius = 1 + int(RNG.random() ** 5 * RNG.uniform(3, 15) * (.45 + rock))
        asteroid(px, py, radius, rock)
    elif RNG.random() < dust * .12:
        paint(px, py, (147, 113, 86), RNG.uniform(.15, .52))

def png_chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))

def save_png(path, width, height, rgba):
    scanlines = b"".join(b"\0" + rgba[y*width*4:(y+1)*width*4] for y in range(height))
    output = b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 6, 0, 0, 0))
    output += png_chunk(b"IDAT", zlib.compress(scanlines, 8)) + png_chunk(b"IEND", b"")
    path.write_bytes(output)
    return len(output)

assets = ROOT / "assets/world_atlas"
size = save_png(assets / "red-cliffs-terrain.png", WIDTH, HEIGHT, pixels)
overview_width, overview_height = 1280, 720
overview = bytearray(overview_width * overview_height * 4)
for py in range(overview_height):
    y = (py + .5) / overview_height
    for px in range(int(overview_width * .35), int(overview_width * .68) + 1):
        x = (px + .5) / overview_width
        if not blocked(x, y):
            continue
        density = barrier_density(x, y)
        at = (int(y*HEIGHT) * WIDTH + int(x*WIDTH)) * 4
        material = pixels[at:at+4]
        brightness = max(material[:3]) / 255 * (material[3] / 255)
        bands = noise_at(noise[1], x, y)
        edge = (1 - density) ** 4
        tint = (round(18 + 50 * brightness + 17 * edge),
                round(48 + 114 * brightness + 56 * bands + 44 * edge),
                round(83 + 127 * brightness + 48 * bands + 50 * edge),
                round(171 + 48 * density + 21 * bands))
        index = (py*overview_width + px) * 4
        overview[index:index+4] = bytes(min(255, component) for component in tint)
save_png(assets / "red-cliffs-navigation-overview.png", overview_width, overview_height, overview)
print(f"{COLS}x{ROWS} samples, movement cost {min(costs)}..{max(costs)} bp, {size:,} bytes")
