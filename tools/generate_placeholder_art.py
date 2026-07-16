#!/usr/bin/env python3
"""Generates the placeholder pixel-art sprites for the Day 1 prototype.

Run from the project root:  python3 tools/generate_placeholder_art.py
All textures are written to assets/sprites/ and are hand-tuned to tile
horizontally where the game scrolls them (road + parallax layers).
No external dependencies (pure-python PNG writer).
"""
import math
import struct
import zlib
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "sprites"

# ---------------------------------------------------------------- PNG writer

def save_png(path: Path, w: int, h: int, buf) -> None:
    """buf is a dict {(x, y): (r, g, b, a)}; missing pixels are transparent."""
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter: none
        for x in range(w):
            p = buf.get((x, y), (0, 0, 0, 0))
            raw.extend(p if len(p) == 4 else (*p, 255))

    def chunk(tag: bytes, data: bytes) -> bytes:
        out = struct.pack(">I", len(data)) + tag + data
        return out + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
           + chunk(b"IEND", b""))
    path.write_bytes(png)
    print(f"wrote {path.relative_to(OUT_DIR.parent.parent)} ({w}x{h})")


# ---------------------------------------------------------------- helpers

def hnoise(x: int, y: int, seed: int = 0) -> float:
    """Deterministic per-pixel hash noise in [0, 1] (tileable by construction)."""
    n = (x * 374761393 + y * 668265263 + seed * 982451653) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFF) / 255.0


def rect(buf, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            buf[(x, y)] = c


def outline(buf, w, h, color):
    """1px dark outline around every opaque region (classic pixel-art rim)."""
    edge = []
    for y in range(h):
        for x in range(w):
            if (x, y) in buf:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) in buf:
                    edge.append((x, y))
                    break
    for p in edge:
        buf[p] = color


# ---------------------------------------------------------------- sky (static layer)

def gen_sky():
    w, h = 320, 180
    buf = {}
    bands = [(0, (96, 150, 214)), (40, (118, 168, 224)), (75, (142, 188, 232)),
             (105, (168, 205, 238)), (130, (196, 222, 244)), (150, (214, 233, 246))]
    for y in range(h):
        color = bands[0][1]
        for start, c in bands:
            if y >= start:
                color = c
        for x in range(w):
            c = color
            # ordered-dither the band edges so the gradient reads as pixel art
            for i, (start, bc) in enumerate(bands[1:], 1):
                if start - 4 <= y < start and hnoise(x, y, 3) > (start - y) / 4.0:
                    c = bc
            buf[(x, y)] = (*c, 255)
    # sun with a soft halo
    sx, sy = 252, 38
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - sx, y - sy)
            if d <= 13:
                buf[(x, y)] = (255, 245, 205, 255)
            elif d <= 16:
                buf[(x, y)] = (236, 226, 214, 255)
    # a few flat clouds
    for cx, cy, rx, ry in ((70, 52, 34, 8), (170, 30, 26, 6), (300, 70, 30, 7)):
        for y in range(h):
            for x in range(w):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 < 1.0:
                    shade = (222, 232, 244, 255) if y > cy + ry * 0.35 else (244, 250, 254, 255)
                    buf[(x, y)] = shade
    save_png(OUT_DIR / "sky.png", w, h, buf)


# ---------------------------------------------------------------- mountains (tileable)

def gen_mountains():
    w, h = 320, 120
    buf = {}

    def ridge(x, base, amps, phases):
        v = base
        for (freq, amp), ph in zip(amps, phases):
            v -= amp * math.sin(2 * math.pi * x * freq / w + ph)
        return v

    for x in range(w):
        far = max(6, ridge(x, 44, [(1, 24), (3, 10), (7, 5)], [0.0, 1.7, 0.5]))
        near = max(10, ridge(x, 72, [(2, 20), (5, 8), (9, 4)], [0.9, 2.2, 4.1]))
        for y in range(h):
            if y >= near:
                c = (95, 105, 140)
                if y < near + 2:
                    c = (120, 130, 162)          # lit rim on the near ridge
            elif y >= far:
                c = (128, 138, 168)
                if y < far + 2:
                    c = (154, 163, 190)          # lit rim on the far ridge
            else:
                continue
            if hnoise(x, y, 11) > 0.9:           # sparse rocky texture
                c = tuple(max(0, v - 10) for v in c)
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "mountains.png", w, h, buf)


# ---------------------------------------------------------------- forest (tileable)

def gen_forest():
    w, h = 320, 96
    buf = {}
    bump_w = 16
    bumps = w // bump_w
    for x in range(w):
        # back tree line: scalloped canopy, one bump per 16px, tiles via modulo
        bi = (x // bump_w) % bumps
        u = (x % bump_w) / bump_w
        top_back = 26 - (6 + 12 * hnoise(bi, 0, 21)) * math.sin(math.pi * u)
        bj = ((x + bump_w // 2) // bump_w) % bumps
        v = ((x + bump_w // 2) % bump_w) / bump_w
        top_front = 42 - (6 + 14 * hnoise(bj, 1, 22)) * math.sin(math.pi * v)
        for y in range(h):
            if y >= top_front:
                c = (40, 74, 50)
                if hnoise(x, y, 23) > 0.82:
                    c = (33, 63, 42)             # leaf clumps
            elif y >= top_back:
                c = (58, 96, 66)
                if hnoise(x, y, 24) > 0.82:
                    c = (48, 82, 58)
            else:
                continue
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "forest.png", w, h, buf)


# ---------------------------------------------------------------- foreground grass (tileable)

def gen_foreground():
    w, h = 320, 48
    buf = {}
    for x in range(w):
        top = 12 - int(9 * hnoise((x // 5) % (w // 5), 7, 31))   # ragged grass tufts
        for y in range(h):
            if y < top:
                continue
            c = (32, 86, 44)
            if hnoise(x, y, 32) > 0.8:
                c = (24, 68, 34)                 # dark blades
            if y > 30:
                c = tuple(max(0, v - 8) for v in c)
            if y > 16 and hnoise(x, y, 33) > 0.988:
                c = (232, 212, 96)               # tiny flowers
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "foreground.png", w, h, buf)


# ---------------------------------------------------------------- road strip (tileable)

def gen_road():
    w, h = 256, 48
    buf = {}
    for x in range(w):
        for y in range(h):
            if y == 0:
                c = (160, 155, 140)              # top edge
            elif y <= 2:
                c = (215, 210, 195)              # pale shoulder line
            elif y >= 44:
                c = (58, 60, 68)                 # shadowed base
            else:
                n = hnoise(x, y, 41)
                v = 78 + int((n - 0.5) * 16)     # asphalt speckle
                c = (v, v + 2, v + 12)
                if hnoise(x // 7, y // 3, 42) > 0.97:
                    c = (60, 62, 72)             # cracks
            # dashed lane separators: 3 driving lanes between the shoulder
            # (rows 0-2) and the shadowed base (rows 44+). Boundaries sit at
            # source rows 16-17 and 29-30 -> world y 292-296 / 318-322 when the
            # chunk is drawn 2x from y=260. Period 32 divides 256 -> tiles cleanly.
            if (16 <= y <= 17 or 29 <= y <= 30) and (x % 32) < 18:
                c = (208, 202, 186)
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "road.png", w, h, buf)


# ---------------------------------------------------------------- car body + wheel

def draw_car_body(body, body_dark, body_light):
    """Draws the shared 56x24 side-view car hull in the given paint colors.
    Used for the player body and every traffic color variant, so all cars
    stay pixel-identical in silhouette."""
    w, h = 56, 24
    buf = {}
    window = (150, 205, 230)
    window_dark = (112, 170, 205)

    rect(buf, 3, 11, 52, 18, body)               # main hull
    rect(buf, 16, 3, 40, 10, body)               # cabin
    rect(buf, 17, 3, 39, 3, body_light)          # roof highlight
    rect(buf, 19, 5, 27, 9, window)              # rear window
    rect(buf, 30, 5, 38, 9, window)              # front window
    rect(buf, 19, 8, 27, 9, window_dark)
    rect(buf, 30, 8, 38, 9, window_dark)
    # sloped hood / trunk steps
    rect(buf, 41, 8, 46, 10, body)
    rect(buf, 47, 10, 52, 11, body)
    rect(buf, 10, 8, 15, 10, body)
    rect(buf, 4, 10, 9, 11, body)
    rect(buf, 3, 12, 52, 12, body_light)         # side highlight stripe
    rect(buf, 3, 17, 52, 18, body_dark)          # lower shading
    rect(buf, 3, 19, 52, 20, (70, 70, 80))       # skirt / bumper band
    rect(buf, 52, 13, 53, 14, (250, 220, 120))   # headlight
    rect(buf, 2, 13, 3, 14, (232, 64, 52))       # tail light
    rect(buf, 21, 11, 22, 16, body_dark)         # door seam
    # wheel arches: carve so the separate wheel sprites read as attached
    for cx in (14, 42):
        for y in range(17, 24):
            for x in range(w):
                if (x - cx) ** 2 + (y - 21) ** 2 <= 7 ** 2:
                    buf.pop((x, y), None)
    outline(buf, w, h, (40, 24, 32, 255))
    return w, h, buf


# Traffic paint jobs: (name, body, body_dark, body_light). Distinct hues so
# oncoming cars read instantly as "not the player" (player stays red).
TRAFFIC_PAINTS = [
    ("blue", (64, 108, 190), (44, 78, 148), (108, 148, 224)),
    ("green", (74, 148, 92), (52, 110, 66), (112, 182, 124)),
    ("sand", (206, 176, 96), (166, 136, 64), (228, 204, 136)),
]


def gen_car():
    w, h, buf = draw_car_body((198, 58, 66), (152, 40, 54), (226, 96, 96))
    save_png(OUT_DIR / "car_body.png", w, h, buf)
    for name, body, dark, light in TRAFFIC_PAINTS:
        w, h, buf = draw_car_body(body, dark, light)
        save_png(OUT_DIR / f"traffic_body_{name}.png", w, h, buf)

    # wheel: 12x12, small tread marks make the spin animation visible
    s = 12
    buf = {}
    c = (s - 1) / 2
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - c, y - c)
            if d <= 5.6:
                col = (32, 32, 40)
                if d <= 2.4:
                    col = (190, 190, 200)        # hub
                elif d > 4.7:
                    col = (18, 18, 24)           # tire rim
                buf[(x, y)] = (*col, 255)
    for p in ((5, 1), (6, 1), (5, 10), (6, 10)):
        buf[p] = (92, 92, 106, 255)
    save_png(OUT_DIR / "car_wheel.png", s, s, buf)


# ---------------------------------------------------------------- gas station

def gen_gas_station():
    """Roadside gas station, 96x48: canopy over a pump island on the left,
    a small shop building on the right, and a tall FUEL price sign. Drawn
    with its base on the bottom row so the sprite sits on the road shoulder."""
    w, h = 96, 48
    buf = {}
    ground = h - 1

    # shop building (right side)
    wall = (214, 208, 196)
    wall_dark = (182, 174, 160)
    rect(buf, 58, 20, 93, ground, wall)
    for y in range(20, ground + 1, 3):                      # siding stripes
        rect(buf, 58, y, 93, y, wall_dark)
    rect(buf, 56, 16, 95, 19, (172, 60, 54))                # flat roof band
    rect(buf, 62, 28, 74, 38, (139, 196, 222))              # window
    rect(buf, 62, 28, 74, 30, (170, 216, 234))              # window glare
    rect(buf, 80, 30, 88, ground, (74, 62, 58))             # door
    rect(buf, 86, 38, 87, 39, (200, 190, 120))              # door handle

    # canopy over the pump island (left side)
    rect(buf, 2, 8, 52, 13, (198, 64, 58))                  # canopy roof
    rect(buf, 2, 12, 52, 13, (150, 44, 44))                 # roof shadow edge
    for px in (6, 46):                                      # support pillars
        rect(buf, px, 14, px + 2, ground, (120, 120, 132))
        rect(buf, px, 14, px, ground, (156, 156, 168))      # lit side
    rect(buf, 14, 40, 40, ground, (96, 96, 108))            # pump island base

    # fuel pump on the island
    rect(buf, 22, 24, 32, 42, (204, 84, 60))                # pump body
    rect(buf, 24, 27, 30, 32, (232, 230, 220))              # display
    rect(buf, 33, 30, 34, 36, (60, 56, 60))                 # hose
    rect(buf, 22, 24, 32, 25, (160, 56, 44))                # pump top shade

    # tall sign on a pole between canopy and shop
    rect(buf, 53, 6, 54, ground, (110, 110, 122))           # pole
    rect(buf, 48, 0, 60, 5, (198, 64, 58))                  # sign board
    rect(buf, 50, 2, 58, 3, (240, 236, 228))                # "text" stripe

    outline(buf, w, h, (40, 24, 32, 255))
    save_png(OUT_DIR / "gas_station.png", w, h, buf)


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    gen_sky()
    gen_mountains()
    gen_forest()
    gen_foreground()
    gen_road()
    gen_car()
    gen_gas_station()
