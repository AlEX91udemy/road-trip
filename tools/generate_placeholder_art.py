#!/usr/bin/env python3
"""Generates the placeholder pixel-art sprites for Road Trip.

Run from the project root:  python3 tools/generate_placeholder_art.py
All textures are written to assets/sprites/ and are hand-tuned to tile
horizontally where the game scrolls them (road + parallax layers).
No external dependencies (pure-python PNG writer).

Visual direction (Phase 1.1 — Keep Driving-influenced restyle): a muted,
earthy, desaturated palette (greens/browns/grays, contemplative rather than
vibrant) instead of the more saturated "golden hour" pass before it, plus
irregular ink-weight outlines on foreground objects (car, gas station)
instead of a perfectly uniform 1px rim — Keep Driving's artist has
described deliberately avoiding perfectly even pixel-art lines in favor of
linework that varies in thickness like hand-inked drawing. This is a style
reference, not a clone: no assets, palettes or files from that game are
used or copied — only the general direction (muted colors, irregular
linework, layered parallax, side-view) is followed. Car/road/gas-station
canvases keep their original pixel dimensions exactly: scenes position
wheels, collision shapes and chunk widths against those dimensions, and
this pass is presentation-only.
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


def line_h(buf, x0, x1, y, c, w=1):
    for x in range(x0, x1 + 1):
        for dy in range(w):
            buf[(x, y + dy)] = c


def ink_outline(buf, w, h, color, seed=0):
    """Irregular outline with uneven thickness, evoking varied hand-inked
    line weight rather than a perfectly uniform pixel-art rim: a base 1px
    rim, then roughly a third of it randomly thickened by one more pixel."""
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
    for x, y in edge:
        if hnoise(x, y, seed) > 0.62:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if (nx, ny) not in buf and hnoise(nx, ny, seed + 1) > 0.45:
                    buf[(nx, ny)] = color


# Tiny 5x7 bitmap font, just the glyphs actually used (the gas station's
# "АЗС" sign) — not a general font, so it only defines what's needed.
FONT_5X7 = {
    "А": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "З": ["####.", "....#", "..##.", "....#", "....#", "#...#", ".###."],
    "С": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
}


def draw_text(buf, text, x0, y0, color):
    """Blits `text` (only characters present in FONT_5X7) left to right,
    5px glyphs with 1px spacing. Returns the x just past the last glyph."""
    x = x0
    for ch in text:
        for row, line in enumerate(FONT_5X7.get(ch, [])):
            for col, bit in enumerate(line):
                if bit == "#":
                    buf[(x + col, y0 + row)] = (*color, 255)
        x += 6
    return x


# ---------------------------------------------------------------- sky (static layer)

def gen_sky():
    """Hazy, desaturated gradient — pale blue-gray at the top settling into
    a soft warm gray-beige near the horizon, a diffuse low sun rather than
    a glowing gold orb, and muted three-tier clouds. Contemplative, not
    vibrant."""
    w, h = 320, 180
    buf = {}
    bands = [(0, (108, 124, 142)), (35, (128, 142, 156)), (68, (150, 158, 164)),
             (98, (176, 176, 172)), (124, (196, 188, 172)), (150, (210, 198, 178))]
    for y in range(h):
        color = bands[0][1]
        for start, c in bands:
            if y >= start:
                color = c
        for x in range(w):
            c = color
            for i, (start, bc) in enumerate(bands[1:], 1):
                if start - 4 <= y < start and hnoise(x, y, 3) > (start - y) / 4.0:
                    c = bc
            buf[(x, y)] = (*c, 255)
    # low, diffuse sun — soft light source, not a saturated glowing disc
    sx, sy = 250, 44
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - sx, y - sy)
            if d <= 11:
                buf[(x, y)] = (232, 222, 202, 255)
            elif d <= 15:
                buf[(x, y)] = (218, 210, 194, 255)
            elif d <= 20:
                buf[(x, y)] = (204, 198, 186, 255)
    # softly shaded, muted clouds
    for cx, cy, rx, ry in ((66, 50, 36, 9), (168, 28, 27, 7), (298, 66, 32, 8)):
        for y in range(h):
            for x in range(w):
                t = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if t < 1.0:
                    if y < cy - ry * 0.2:
                        shade = (222, 218, 208, 255)
                    elif y < cy + ry * 0.35:
                        shade = (206, 200, 190, 255)
                    else:
                        shade = (180, 174, 166, 255)
                    buf[(x, y)] = shade
    save_png(OUT_DIR / "sky.png", w, h, buf)


# ---------------------------------------------------------------- mountains (tileable)

def gen_mountains():
    """Distant range, desaturated toward a neutral gray-green haze rather
    than a saturated purple, keeping it feeling far away without fighting
    for attention against anything in front of it."""
    w, h = 320, 120
    buf = {}

    def ridge(x, base, amps, phases):
        v = base
        for (freq, amp), ph in zip(amps, phases):
            v -= amp * math.sin(2 * math.pi * x * freq / w + ph)
        return v

    for x in range(w):
        far = max(6, ridge(x, 40, [(1, 22), (3, 9), (7, 5)], [0.0, 1.7, 0.5]))
        near = max(10, ridge(x, 66, [(2, 18), (5, 8), (9, 4)], [0.9, 2.2, 4.1]))
        for y in range(h):
            if y >= near:
                c = (128, 132, 130)
                if y < near + 2:
                    c = (152, 154, 148)          # lit rim on the near ridge
            elif y >= far:
                c = (152, 154, 150)
                if y < far + 2:
                    c = (176, 176, 168)          # lit rim on the far ridge
            else:
                continue
            if hnoise(x, y, 11) > 0.9:           # sparse rocky texture
                c = tuple(max(0, v - 10) for v in c)
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "mountains.png", w, h, buf)


# ---------------------------------------------------------------- landmarks (tileable, NEW)

def gen_landmarks():
    """Distant skyline accents: a sparse scatter of panel-apartment blocks
    (панельки) and one onion-domed church silhouette, tinted to match the
    mountains' haze so they read as "even further back", not competing
    with anything in front of them."""
    w, h = 320, 90
    buf = {}
    tint = (138, 140, 140)

    for bx, bh, bw in ((40, 46, 20), (150, 38, 16), (260, 50, 22)):
        top = h - bh
        rect(buf, bx, top, bx + bw, h - 1, tint)
        for wy in range(top + 3, h - 2, 5):
            for wx in range(bx + 2, bx + bw - 1, 4):
                buf[(wx, wy)] = (110, 112, 114, 255)          # window grid

    cx = 210
    tower_top = h - 31
    rect(buf, cx - 5, tower_top, cx + 5, h - 1, tint)          # bell tower
    dome_cy = tower_top - 6
    for dy in range(-8, 9):
        for dx in range(-9, 10):
            if (dx / 9.0) ** 2 + (dy / 8.0) ** 2 <= 1.0 and dy <= 8 - abs(dx) * 0.3:
                buf[(cx + dx, dome_cy + dy)] = (*tint, 255)
    rect(buf, cx - 1, dome_cy - 12, cx + 1, dome_cy - 8, tint)  # spire
    rect(buf, cx - 3, dome_cy - 9, cx + 3, dome_cy - 8, tint)   # cross bar
    save_png(OUT_DIR / "landmarks.png", w, h, buf)


# ---------------------------------------------------------------- fields (tileable, NEW)

def gen_fields():
    """Rolling farmland between the mountains and the forest line — muted
    olive/khaki rather than saturated gold, with a weathered fence line and
    a hay bale for a little life."""
    w, h = 320, 100
    buf = {}
    for x in range(w):
        top = 30 - 10 * math.sin(2 * math.pi * x / w * 2 + 0.6) \
                - 4 * math.sin(2 * math.pi * x / w * 5 + 2.1)
        for y in range(h):
            if y < top:
                continue
            depth = (y - top) / (h - top)
            c = (156, 152, 118) if depth < 0.5 else (134, 138, 104)
            if hnoise(x, y, 51) > 0.93:
                c = tuple(max(0, v - 14) for v in c)   # texture flecks
            buf[(x, y)] = (*c, 255)
    # fence line: posts every 40px with a rail between them
    fence_y = int(30 - 10 * math.sin(0.6) - 4 * math.sin(2.1)) + 6
    for x in range(0, w, 40):
        for dy in range(6):
            buf[(x, fence_y - dy)] = (88, 80, 70, 255)
    line_h(buf, 0, w - 1, fence_y - 4, (100, 90, 78))
    # one hay bale, tileable-safe (kept well clear of the seam)
    bx, by, r = 200, fence_y + 22, 9
    for y in range(by - r, by + r):
        for x in range(bx - r, bx + r):
            if (x - bx) ** 2 + (y - by) ** 2 <= r * r:
                buf[(x, y)] = (176, 152, 108, 255)
    save_png(OUT_DIR / "fields.png", w, h, buf)


# ---------------------------------------------------------------- forest (tileable)

def gen_forest():
    """Mid-distance tree line — desaturated, grayer green than a vivid
    postcard forest, matching the hazier, contemplative palette overall."""
    w, h = 320, 96
    buf = {}
    bump_w = 16
    bumps = w // bump_w
    for x in range(w):
        bi = (x // bump_w) % bumps
        u = (x % bump_w) / bump_w
        top_back = 26 - (6 + 12 * hnoise(bi, 0, 21)) * math.sin(math.pi * u)
        bj = ((x + bump_w // 2) // bump_w) % bumps
        v = ((x + bump_w // 2) % bump_w) / bump_w
        top_front = 42 - (6 + 14 * hnoise(bj, 1, 22)) * math.sin(math.pi * v)
        for y in range(h):
            if y >= top_front:
                c = (54, 70, 52)
                if hnoise(x, y, 23) > 0.82:
                    c = (44, 58, 44)
            elif y >= top_back:
                c = (78, 90, 74)
                if hnoise(x, y, 24) > 0.82:
                    c = (64, 76, 62)
            else:
                continue
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "forest.png", w, h, buf)


# ---------------------------------------------------------------- birches (tileable, NEW)

def gen_birches():
    """Birch grove — the single most recognizable silhouette of the Russian
    countryside: slender pale trunks with dark bark flecks under a muted
    rounded canopy. Deliberately sparse (gaps between clusters) so
    individual trunks read instead of blurring into a solid tree wall."""
    w, h = 320, 110
    buf = {}
    cluster_w = 40
    n_clusters = w // cluster_w
    for ci in range(n_clusters):
        if hnoise(ci, 0, 71) < 0.35:
            continue                                    # gap: forest shows through
        trunk_x = ci * cluster_w + int(cluster_w * (0.3 + 0.4 * hnoise(ci, 5, 75)))
        canopy_cy = 28 + int(14 * hnoise(ci, 1, 72))
        canopy_r = 15 + int(6 * hnoise(ci, 2, 73))
        trunk_top = canopy_cy + int(canopy_r * 0.6)
        for dy in range(-canopy_r, canopy_r + 1):
            for dx in range(-canopy_r, canopy_r + 1):
                if dx * dx + dy * dy > canopy_r * canopy_r:
                    continue
                x, y = trunk_x + dx, canopy_cy + dy
                if not (0 <= x < w and 0 <= y < h):
                    continue
                c = (92, 108, 84) if dy < 0 else (76, 90, 70)
                if hnoise(x, y, 76) > 0.85:
                    c = (62, 78, 58)
                buf[(x, y)] = (*c, 255)
        for y in range(trunk_top, h):
            for tx in range(trunk_x - 1, trunk_x + 2):
                if not (0 <= tx < w):
                    continue
                c = (214, 208, 196)
                if hnoise(tx, y, 77) > 0.8 or (tx == trunk_x and y % 9 < 2):
                    c = (48, 46, 44)                    # bark flecks / marks
                buf[(tx, y)] = (*c, 255)
    save_png(OUT_DIR / "birches.png", w, h, buf)


# ------------------------------------------------- roadside vegetation (tileable, NEW)

def gen_roadside_vegetation():
    """Close-in scrub and bush clusters right along the shoulder — muted
    olive, still a touch richer than the forest since it's nearer the
    camera, but never saturated."""
    w, h = 320, 64
    buf = {}
    cluster_w = 40
    for x in range(w):
        ci = (x // cluster_w) % (w // cluster_w)
        u = (x % cluster_w) / cluster_w
        bush = hnoise(ci, 0, 61) > 0.35
        top = h if not bush else h - (10 + 14 * hnoise(ci, 1, 62)) * math.sin(math.pi * u)
        for y in range(h):
            if y < top:
                continue
            c = (62, 76, 54)
            if hnoise(x, y, 63) > 0.85:
                c = (50, 62, 46)
            if hnoise(x, y, 64) > 0.985:
                c = (198, 168, 112)           # tiny wildflower fleck
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "roadside_vegetation.png", w, h, buf)


# ------------------------------------------------- utility poles + wires (tileable, NEW)

def gen_utility_poles():
    """Weathered wooden power poles with a cross-arm and sagging wires
    between them — one pole every 160px so a 320px tile carries exactly
    two, and the wire sag matches height at both tile edges for a seamless
    scroll."""
    w, h = 320, 220
    buf = {}
    span = 160
    pole_top = 60
    ground = h - 1

    for x in range(w):
        u = (x % span) / span
        # parabolic sag between consecutive poles, matching at u=0 and u=1
        d = abs(u - 0.5) * 2
        wire_y = pole_top + 8 + 14 * (1 - d)
        is_pole = (x % span) < 3
        if is_pole:
            for y in range(pole_top, ground + 1):
                c = (92, 80, 68)
                if x % span == 0:
                    c = (112, 98, 82)        # lit face of the post
                buf[(x, y)] = (*c, 255)
            # cross-arm
            for cx in range(-9, 10):
                px = x + cx
                if 0 <= px < w:
                    buf[(px, pole_top)] = (82, 72, 62, 255)
                    buf[(px, pole_top + 1)] = (82, 72, 62, 255)
        # three sagging wire strands
        for k in range(3):
            wy = int(round(wire_y)) + k * 3
            if 0 <= wy < h:
                buf.setdefault((x, wy), (44, 42, 40, 255))
    save_png(OUT_DIR / "utility_poles.png", w, h, buf)


# ---------------------------------------------------------------- foreground grass (tileable)

def gen_foreground():
    """Nearest layer, overlapping the bottom of the frame in front of the
    road — muted green, kept in the same desaturated family as everything
    behind it rather than popping as the brightest thing on screen."""
    w, h = 320, 48
    buf = {}
    for x in range(w):
        top = 12 - int(9 * hnoise((x // 5) % (w // 5), 7, 31))
        for y in range(h):
            if y < top:
                continue
            c = (48, 72, 46)
            if hnoise(x, y, 32) > 0.8:
                c = (38, 58, 40)
            if y > 30:
                c = tuple(max(0, v - 8) for v in c)
            if y > 16 and hnoise(x, y, 33) > 0.988:
                c = (206, 182, 120)
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "foreground.png", w, h, buf)


# ---------------------------------------------------------------- road strip (tileable)

def gen_road():
    """Muted asphalt — still a hint of warmth, but desaturated rather than
    a rich tan — with a visible weathered shoulder, crisp dashed lane
    markings with a shadow for contrast, and subtle AO at every edge."""
    w, h = 256, 48
    buf = {}
    for x in range(w):
        for y in range(h):
            if y <= 3:
                c = (166, 152, 128)              # dirt/gravel shoulder
                if y == 3:
                    c = (128, 116, 98)            # shoulder -> asphalt AO
            elif y >= 44:
                c = (66, 60, 54)                  # shadowed base
                if y == 44:
                    c = (92, 84, 74)              # asphalt -> base AO
            else:
                n = hnoise(x, y, 41)
                v = 80 + int((n - 0.5) * 16)      # asphalt speckle
                c = (v + 4, v, v - 6)
                if hnoise(x // 7, y // 3, 42) > 0.97:
                    c = (64, 58, 54)              # cracks
            # dashed lane separators, with a 1px shadow beneath for pop
            if (17 <= y <= 18 or 30 <= y <= 31) and (x % 32) < 18:
                c = (214, 206, 188)
            elif (19 == y or 32 == y) and (x % 32) < 18:
                c = (104, 92, 80)
            buf[(x, y)] = (*c, 255)
    save_png(OUT_DIR / "road.png", w, h, buf)


# ---------------------------------------------------------------- car body + wheel

def draw_car_body(body, body_dark, body_light):
    """Draws the 56x24 side-view car hull in the given paint colors. Same
    canvas and wheel-arch geometry as before (wheels sit at local x = -14 /
    +14) — player_car.tscn positions its Wheel sprites and PresenceArea
    against those, so this pass only restyles the paint within that fixed
    envelope, never the geometry itself."""
    w, h = 56, 24
    buf = {}
    window = (154, 182, 190)
    window_dark = (118, 152, 166)

    rect(buf, 3, 12, 52, 18, body)                # main hull, slightly lower for a sleeker stance
    rect(buf, 15, 3, 41, 11, body)                 # cabin, taller greenhouse
    rect(buf, 16, 3, 40, 3, body_light)            # roof highlight
    rect(buf, 18, 5, 27, 10, window)               # rear window
    rect(buf, 29, 5, 39, 10, window)               # front window
    rect(buf, 18, 8, 27, 10, window_dark)
    rect(buf, 29, 8, 39, 10, window_dark)
    rect(buf, 24, 5, 25, 10, (58, 48, 42))         # window pillar (cleaner cabin break)
    # sloped hood / trunk, smoother steps than the prototype
    rect(buf, 41, 9, 47, 11, body)
    rect(buf, 48, 11, 52, 12, body)
    rect(buf, 9, 9, 14, 11, body)
    rect(buf, 4, 11, 8, 12, body)
    rect(buf, 3, 13, 52, 13, body_light)           # side highlight stripe
    rect(buf, 3, 17, 52, 18, body_dark)            # lower shading
    rect(buf, 3, 19, 52, 21, (50, 50, 56))         # skirt / bumper band
    rect(buf, 51, 13, 53, 15, (222, 202, 146))     # headlight, rounder
    rect(buf, 2, 13, 3, 15, (172, 78, 66))         # tail light
    rect(buf, 20, 12, 21, 17, body_dark)           # door seam
    rect(buf, 44, 12, 45, 17, body_dark)           # rear door seam (new)
    for cx in (14, 42):
        for y in range(17, 24):
            for x in range(w):
                if (x - cx) ** 2 + (y - 21) ** 2 <= 7 ** 2:
                    buf.pop((x, y), None)
    ink_outline(buf, w, h, (34, 26, 24, 255), seed=201)
    return w, h, buf


def gen_car():
    w, h, buf = draw_car_body((156, 74, 64), (118, 54, 52), (186, 118, 100))
    save_png(OUT_DIR / "car_body.png", w, h, buf)

    # wheel: same 12x12 canvas/radius as before (PlayerCar.wheel_radius_px
    # assumes it) — cleaner hub/spoke read within that fixed size.
    s = 12
    buf = {}
    c = (s - 1) / 2
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - c, y - c)
            if d <= 5.6:
                col = (28, 28, 32)
                if d <= 2.2:
                    col = (188, 188, 192)        # hub
                elif d <= 3.4:
                    col = (140, 140, 146)        # hub rim
                elif d > 4.8:
                    col = (18, 18, 20)           # tire rim
                buf[(x, y)] = (*col, 255)
    for p in ((5, 1), (6, 1), (5, 10), (6, 10), (1, 5), (1, 6), (10, 5), (10, 6)):
        buf[p] = (80, 80, 88, 255)
    save_png(OUT_DIR / "car_wheel.png", s, s, buf)


# ---------------------------------------------------------------- gas station

def gen_gas_station():
    """Roadside gas station, 96x48 — same canvas as before (Building sprite
    scale/position in gas_station.tscn assumes it). Bolder canopy silhouette,
    muted/weathered materials, and a softly lit sign rather than a
    neon-bright one."""
    w, h = 96, 48
    buf = {}
    ground = h - 1

    # shop building (right side)
    wall = (204, 196, 180)
    wall_dark = (180, 172, 156)
    rect(buf, 58, 20, 93, ground, wall)
    for y in range(20, ground + 1, 3):
        rect(buf, 58, y, 93, y, wall_dark)
    rect(buf, 55, 15, 95, 19, (156, 86, 58))        # muted brick roof band
    rect(buf, 62, 28, 74, 38, (142, 168, 176))
    rect(buf, 62, 28, 74, 30, (168, 192, 198))
    rect(buf, 80, 30, 88, ground, (86, 68, 58))
    rect(buf, 86, 38, 87, 39, (196, 182, 138))

    # canopy over the pump island (left side) — deeper overhang, bolder edge
    rect(buf, 1, 6, 53, 13, (166, 92, 58))          # canopy roof, wider/lower
    rect(buf, 1, 11, 53, 13, (128, 68, 46))         # roof shadow edge
    rect(buf, 1, 6, 53, 7, (196, 132, 88))          # sunlit roof highlight
    for px in (5, 47):
        rect(buf, px, 14, px + 2, ground, (120, 116, 120))
        rect(buf, px, 14, px, ground, (154, 148, 154))
    rect(buf, 12, 40, 42, ground, (96, 92, 98))

    # fuel pump
    rect(buf, 22, 24, 32, 42, (168, 94, 64))
    rect(buf, 24, 27, 30, 32, (218, 212, 196))
    rect(buf, 33, 30, 34, 36, (54, 50, 54))
    rect(buf, 22, 24, 32, 25, (134, 70, 50))

    # tall sign on a pole — softly lit board, lettered "АЗС" (the generic
    # Russian abbreviation for a fuel station — deliberately not a real
    # brand's name or colors).
    rect(buf, 53, 6, 54, ground, (110, 104, 108))
    for gx in range(37, 70):
        for gy in range(0, 9):
            if 0 <= gx < w:
                d = math.hypot(gx - 53, gy - 4)
                if d <= 11:
                    buf[(gx, gy)] = (216, 192, 146, 255)   # soft glow halo
    rect(buf, 41, 0, 65, 8, (196, 132, 78))          # sign board
    draw_text(buf, "АЗС", 44, 1, (64, 40, 26))

    ink_outline(buf, w, h, (34, 26, 24, 255), seed=301)
    save_png(OUT_DIR / "gas_station.png", w, h, buf)


if __name__ == "__main__":
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    gen_sky()
    gen_mountains()
    gen_landmarks()
    gen_fields()
    gen_forest()
    gen_birches()
    gen_roadside_vegetation()
    gen_utility_poles()
    gen_foreground()
    gen_road()
    gen_car()
    gen_gas_station()
