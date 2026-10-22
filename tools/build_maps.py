#!/usr/bin/env python3
"""
Builds all 30 editable FARR map scenes (res://maps/<map_id>.tscn) and their
257x257 grayscale heightmap PNGs (res://assets/heightmaps/<map_id>.png).

Every generated .tscn is a standard, clean Godot 4 scene with root `MapScene`
(scripts/map_scene.gd) and children:
  - Environment (WorldEnvironment)
  - Sun (DirectionalLight3D)
  - Terrain (MapTerrain -> scripts/map_terrain.gd)
  - BossPit (Node3D: arena platform, Kenney columns/braziers, glowing rune ring, 3D label)
  - Landmarks (Node3D: themed Kenney 3D .glb buildings, towers, hangars, crypts, columns, spires)
  - Props (Node3D: biome rocks, crystals, trees, mushrooms, crates, barrels, perimeter cliff rocks)
  - Lights (Node3D: OmniLight3D accents for altars, crystals, hangars, braziers)
  - PropCollisions (StaticBody3D: simple CollisionShape3D cylinders/boxes for placed landmarks)
"""

import math
import os
import re
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEIGHTMAP_DIR = os.path.join(ROOT, "assets", "heightmaps")
MAPS_DIR = os.path.join(ROOT, "maps")
os.makedirs(HEIGHTMAP_DIR, exist_ok=True)
os.makedirs(MAPS_DIR, exist_ok=True)


# ------------------------------------------------------------------------------
# 1. MINIMAL PURE-PYTHON 8-BIT GRAYSCALE PNG WRITER
# ------------------------------------------------------------------------------
def write_grayscale_png(path: str, width: int, height: int, pixels_0_255: list[int]) -> None:
    raw_rows = bytearray()
    for y in range(height):
        raw_rows.append(0)  # Filter type 0 (None)
        row_start = y * width
        raw_rows.extend(pixels_0_255[row_start : row_start + width])

    def make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + chunk_type + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0)
    compressed = zlib.compress(bytes(raw_rows), 9)
    png_bytes = (
        b"\x89PNG\r\n\x1a\n"
        + make_chunk(b"IHDR", ihdr)
        + make_chunk(b"IDAT", compressed)
        + make_chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(png_bytes)


# ------------------------------------------------------------------------------
# 2. PARSE ALL 30 MAPS FROM scripts/game_data.gd
# ------------------------------------------------------------------------------
def parse_game_data_maps() -> dict:
    gd_path = os.path.join(ROOT, "scripts", "game_data.gd")
    txt = open(gd_path, "r", encoding="utf-8").read()
    maps_sec = txt.split("const MAPS := {")[1].split("\nconst ")[0]
    chunks = re.split(r'\n\t"([a-z0-9_]+)": \{', maps_sec)
    out = {}
    for i in range(1, len(chunks), 2):
        mid = chunks[i]
        body = chunks[i + 1]
        theme_m = re.search(r'"terrain_theme":\s*"([A-Z_]+)"', body)
        theme = theme_m.group(1) if theme_m else "TECH_ARK"

        # Parse boss_pit dict
        bp = {"pos": (0.0, 0.0, -26.0), "radius": 9.5, "name": "Zone Boss Pit"}
        bp_line = re.search(r'"boss_pit":\s*\{([^\n}]+)\}', body)
        if bp_line:
            btxt = bp_line.group(1)
            nm = re.search(r'"name":\s*"([^"]+)"', btxt)
            rd = re.search(r'"radius":\s*([0-9.]+)', btxt)
            ps = re.search(r'Vector3\(\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*\)', btxt)
            if nm:
                bp["name"] = nm.group(1)
            if rd:
                bp["radius"] = float(rd.group(1))
            if ps:
                bp["pos"] = (float(ps.group(1)), float(ps.group(2)), float(ps.group(3)))

        # Collect all entity Vector3 positions so we keep flat pads & avoid blocking them
        vecs = []
        for ax, ay, az in re.findall(
            r'Vector3\(\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*,\s*([-0-9.]+)\s*\)', body
        ):
            vecs.append((float(ax), float(az)))

        out[mid] = {
            "id": mid,
            "theme": theme,
            "boss_pit": bp,
            "entity_xz": vecs,
        }
    return out


# ------------------------------------------------------------------------------
# 3. HEIGHTMAP GENERATOR + EXACT GDSCRIPT-MATCHING HEIGHT SAMPLER
# ------------------------------------------------------------------------------
def smoothstep(edge0: float, edge1: float, x: float) -> float:
    t = max(0.0, min(1.0, (x - edge0) / max(1e-6, edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def generate_heightmap_and_sampler(map_id: str, mdata: dict, height_scale: float):
    """
    Generates a 257x257 grayscale PNG in assets/heightmaps/<map_id>.png
    and returns a callable `height_at(x, z)` that matches `MapTerrain.height_at(x, z)`
    (169x169 mesh grid with 2 passes of 3x3 box blur).
    """
    iw = 257
    ih = 257
    size = 250.0
    theme = mdata["theme"]
    bp_x, _, bp_z = mdata["boss_pit"]["pos"]
    bp_rad = mdata["boss_pit"]["radius"]
    entity_xz = mdata["entity_xz"]

    # Deterministic seed per map_id
    seed = sum((idx + 1) * ord(ch) for idx, ch in enumerate(map_id))
    p1 = (seed % 17) * 0.37
    p2 = (seed % 23) * 0.51
    p3 = (seed % 31) * 0.29

    pixels = [0] * (iw * ih)

    for j in range(ih):
        z = (j / float(ih - 1) - 0.5) * size
        for i in range(iw):
            x = (i / float(iw - 1) - 0.5) * size
            r = math.hypot(x, z)
            box_d = max(abs(x), abs(z))
            ang = math.atan2(z, x)

            # Base multi-octave rolling terrain (in metres)
            n_low = (
                math.sin(x * 0.045 + p1) * math.cos(z * 0.045 + p2)
                + 0.5 * math.sin((x + z) * 0.07 - p3)
                + 0.25 * math.cos((x - z) * 0.11 + p1)
            )  # in [-1.75, +1.75]

            h = 1.6 + n_low * 0.65

            # Mid-field biome topography (r from 32m to 96m)
            mid_mask = smoothstep(28.0, 52.0, r) * (1.0 - smoothstep(88.0, 108.0, box_d))

            if theme in ("TECH_ARK", "HOLY_TEMPLE", "OBSIDIAN_CITADEL"):
                # Grand Bastion Terraces on East & West flanks (+4.5m) with N/S approach valleys
                flank = max(0.0, abs(x) - 34.0) / 36.0
                flank_terrace = smoothstep(0.1, 0.7, flank) * (1.0 - smoothstep(32.0, 58.0, abs(z)))
                north_dais = smoothstep(-35.0, -68.0, z) * (1.0 - smoothstep(18.0, 42.0, abs(x)))
                h += mid_mask * (flank_terrace * 4.6 + north_dais * 3.8 + n_low * 0.8)

            elif theme in ("CRACK_MINING", "LOWER_CRATER", "BREACH_RIDGE"):
                # Open-Pit Strip Mine Crater: sunken glowing fissures in the floor + stepped haulage rim
                crater_ring = smoothstep(38.0, 62.0, r) * (1.0 - abs( math.sin(ang * 2.0 + 0.4) ) * 0.45)
                fissure_trench = math.exp(-((x - math.sin(z * 0.06) * 14.0) ** 2) / 55.0) * smoothstep(8.0, 26.0, r)
                h += mid_mask * (crater_ring * 6.2 + n_low * 1.1) - fissure_trench * 1.35

            elif theme in ("MAGMA_CALDERA", "SCORCHED_CAULDRON", "VOLCANIC_BASIN"):
                # Volcanic Caldera with sunken molten lava channels (y < 1.1m glows!) & jagged basalt ridges
                lava_river = math.exp(-((abs(x) - 20.0 + math.sin(z * 0.07) * 6.0) ** 2) / 32.0) * (1.0 - smoothstep(45.0, 75.0, abs(z)))
                ridge = smoothstep(40.0, 68.0, r) * (0.65 + 0.35 * math.cos(ang * 3.0 + p1))
                h += mid_mask * (ridge * 6.8 + n_low * 1.2) - lava_river * 1.45

            elif theme in ("AETHER_SKY", "SKY_FRACTURE", "SKY_SANCTUM"):
                # Stepped Celestial/Aether Terraces with radial causeways
                step_r = smoothstep(36.0, 46.0, r) * 2.8 + smoothstep(58.0, 68.0, r) * 3.2
                causeway = math.exp(-(min(abs(x), abs(z)) ** 2) / 70.0)
                h += mid_mask * (step_r * (1.0 - 0.35 * causeway) + n_low * 0.5)

            elif theme in ("BORDER_TRENCHES", "OUTCAST_WASTELAND"):
                # Sunken War Trenches + Raised Sandbag/Artillery Embankments
                trench = math.exp(-((z + 6.0 - math.sin(x * 0.08) * 7.0) ** 2) / 42.0)
                parapet = math.exp(-((abs(z + 6.0) - 14.0) ** 2) / 38.0)
                h += mid_mask * (parapet * 3.8 + abs(n_low) * 1.6) - trench * 1.1

            elif theme in ("DESERT_RUINS", "PERSEPOLIS_STEPPES", "BEAST_HIGHLAND"):
                # Sweeping Diagonal Dunes & Highland Bluffs
                dune = math.sin(x * 0.055 + z * 0.038 + p2) * 0.5 + 0.5
                bluff = smoothstep(38.0, 64.0, r) * (0.5 + 0.5 * math.sin(ang * 2.0 + p1))
                h += mid_mask * (dune * 3.4 + bluff * 4.5)

            elif theme in ("CATACOMB_CRYPT", "DAEVA_CRYPT", "LUMINESCENT_AQUIFER", "ARK_SUPERCORE", "VAR_ROOTS", "FROZEN_SCRAP"):
                # 4 Corner Raised Galleries (+4.2m) separated by cardinal corridors
                corner = smoothstep(22.0, 44.0, abs(x)) * smoothstep(22.0, 44.0, abs(z))
                channel = math.exp(-(x * x) / 65.0) * smoothstep(14.0, 38.0, abs(z))
                h += mid_mask * (corner * 4.8 + n_low * 0.9) - channel * 1.15

            # Flatten pads around Boss Pit and interactive entities so nothing floats or tilts
            pad_weight = 0.0
            d_bp = math.hypot(x - bp_x, z - bp_z)
            if d_bp < bp_rad + 6.0:
                pad_weight = max(pad_weight, 1.0 - smoothstep(bp_rad, bp_rad + 6.0, d_bp))

            # Central HQ / Refinery plaza pad
            if r < 22.0:
                pad_weight = max(pad_weight, 1.0 - smoothstep(12.0, 22.0, r))

            for ex, ez in entity_xz:
                de = math.hypot(x - ex, z - ez)
                if de < 7.5:
                    pad_weight = max(pad_weight, 1.0 - smoothstep(3.2, 7.5, de))

            h = h * (1.0 - pad_weight) + 1.45 * pad_weight

            # Outer Perimeter Mountain Rim (box_d from 92m to 125m)
            rim_t = smoothstep(90.0, 118.0, box_d)
            if rim_t > 0.0:
                jag = (
                    0.65
                    + 0.25 * math.sin(ang * 7.0 + p1)
                    + 0.15 * math.cos(ang * 13.0 - p2)
                )
                h += rim_t * height_scale * 0.78 * jag

            h = max(0.0, min(height_scale, h))
            px = int(round((h / height_scale) * 255.0))
            pixels[j * iw + i] = max(0, min(255, px))

    png_path = os.path.join(HEIGHTMAP_DIR, f"{map_id}.png")
    write_grayscale_png(png_path, iw, ih, pixels)

    # Replicate MapTerrain._sample_heightmap() (res=169, smooth_passes=2) for exact Y snapping
    res = 169
    grid = [0.0] * (res * res)
    for j in range(res):
        v = j / float(res - 1) * float(ih - 1)
        y0 = int(math.floor(v))
        y1 = min(y0 + 1, ih - 1)
        fy = v - y0
        for i in range(res):
            u = i / float(res - 1) * float(iw - 1)
            x0 = int(math.floor(u))
            x1 = min(x0 + 1, iw - 1)
            fx = u - x0
            a = (pixels[y0 * iw + x0] * (1.0 - fx) + pixels[y0 * iw + x1] * fx) / 255.0
            b = (pixels[y1 * iw + x0] * (1.0 - fx) + pixels[y1 * iw + x1] * fx) / 255.0
            grid[j * res + i] = (a * (1.0 - fy) + b * fy) * height_scale

    for _ in range(2):
        nxt = list(grid)
        for j in range(1, res - 1):
            for i in range(1, res - 1):
                s = 0.0
                for dj in (-1, 0, 1):
                    for di in (-1, 0, 1):
                        s += grid[(j + dj) * res + (i + di)]
                nxt[j * res + i] = s / 9.0
        grid = nxt

    def height_at(x: float, z: float) -> float:
        gx = (x / size + 0.5) * float(res - 1)
        gz = (z / size + 0.5) * float(res - 1)
        if gx < 0.0 or gz < 0.0 or gx > res - 1 or gz > res - 1:
            return 0.0
        x0 = int(math.floor(gx))
        z0 = int(math.floor(gz))
        x1 = min(x0 + 1, res - 1)
        z1 = min(z0 + 1, res - 1)
        fx = gx - x0
        fz = gz - z0
        h00 = grid[z0 * res + x0]
        h10 = grid[z0 * res + x1]
        h01 = grid[z1 * res + x0]
        h11 = grid[z1 * res + x1]
        top = h00 * (1.0 - fx) + h10 * fx
        bot = h01 * (1.0 - fx) + h11 * fx
        return top * (1.0 - fz) + bot * fz

    return height_at


# ------------------------------------------------------------------------------
# 4. BIOME VISUAL PRESETS (POLY HAVEN PBR TEXTURES + HDRI SKIES + KENNEY KITS)
# ------------------------------------------------------------------------------
BIOME_PRESETS = {
    "TECH_ARK": {
        "sky": "kloofendal_overcast_puresky.hdr",
        "sky_energy": 1.05,
        "sky_tint": (0.78, 0.90, 1.0),
        "fog_color": (0.36, 0.48, 0.62),
        "fog_density": 0.0038,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.42,
        "sun_color": (0.90, 0.96, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -46.0,
        "sun_yaw": -35.0,
        "ground": "concrete_floor_worn_001",
        "accent": "metal_plate",
        "cliff": "quarry_wall",
        "ground_tint": (0.76, 0.84, 0.94),
        "accent_tint": (0.70, 0.82, 0.96),
        "cliff_tint": (0.55, 0.64, 0.75),
        "accent_amount": 0.42,
        "roughness": 0.72,
        "height_scale": 20.0,
        "glow_color": (0.25, 0.90, 1.0),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.6,
        "landmarks": [
            ("space/hangar_roundB.glb", (-28.0, -14.0), 4.5, 25.0, 6.0),
            ("space/hangar_largeA.glb", (28.0, -14.0), 4.5, -25.0, 5.5),
            ("space/satelliteDish_large.glb", (-26.0, 22.0), 6.0, 45.0, 3.0),
            ("space/satelliteDish_large.glb", (26.0, 22.0), 6.0, -45.0, 3.0),
            ("space/machine_generatorLarge.glb", (-18.0, -2.0), 4.5, 90.0, 2.8),
            ("space/machine_generatorLarge.glb", (18.0, -2.0), 4.5, -90.0, 2.8),
            ("space/craft_cargoA.glb", (-34.0, 6.0), 3.8, 15.0, 3.5),
            ("space/craft_speederA.glb", (34.0, 6.0), 3.8, -15.0, 3.0),
            ("space/turret_double.glb", (-16.0, 26.0), 4.2, 0.0, 2.2),
            ("space/turret_double.glb", (16.0, 26.0), 4.2, 0.0, 2.2),
            ("space/structure_detailed.glb", (-48.0, -36.0), 6.5, 30.0, 4.0),
            ("space/structure_detailed.glb", (48.0, -36.0), 6.5, -30.0, 4.0),
        ],
        "scatter": [
            ("space/rock_crystalsLargeA.glb", 4.5),
            ("space/machine_barrelLarge.glb", 3.5),
            ("space/barrels_rail.glb", 3.8),
            ("space/rock_largeA.glb", 5.0),
            ("space/satelliteDish.glb", 4.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "ARK_SUPERCORE": {
        "sky": "qwantani_night_puresky.hdr",
        "sky_energy": 1.35,
        "sky_tint": (0.55, 0.88, 1.0),
        "fog_color": (0.12, 0.24, 0.36),
        "fog_density": 0.0055,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.55,
        "sun_color": (0.65, 0.92, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -52.0,
        "sun_yaw": -25.0,
        "ground": "metal_plate",
        "accent": "concrete_floor_worn_001",
        "cliff": "dark_rock",
        "ground_tint": (0.62, 0.78, 0.92),
        "accent_tint": (0.48, 0.68, 0.85),
        "cliff_tint": (0.35, 0.48, 0.62),
        "accent_amount": 0.38,
        "roughness": 0.58,
        "height_scale": 20.0,
        "glow_color": (0.15, 0.95, 0.88),
        "glow_below": 0.85,
        "glow_strength": 3.2,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.8,
        "landmarks": [
            ("space/hangar_roundGlass.glb", (-26.0, -14.0), 4.5, 35.0, 6.0),
            ("space/hangar_roundGlass.glb", (26.0, -14.0), 4.5, -35.0, 6.0),
            ("space/machine_wirelessCable.glb", (-20.0, 16.0), 5.0, 20.0, 2.5),
            ("space/machine_wirelessCable.glb", (20.0, 16.0), 5.0, -20.0, 2.5),
            ("space/machine_generatorLarge.glb", (-32.0, 4.0), 5.0, 90.0, 3.2),
            ("space/machine_generatorLarge.glb", (32.0, 4.0), 5.0, -90.0, 3.2),
            ("space/rocket_baseA.glb", (-44.0, -34.0), 4.5, 0.0, 4.5),
            ("space/rocket_baseB.glb", (44.0, -34.0), 4.5, 0.0, 4.5),
            ("space/satelliteDish_detailed.glb", (-26.0, 28.0), 5.5, 15.0, 2.8),
            ("space/satelliteDish_detailed.glb", (26.0, 28.0), 5.5, -15.0, 2.8),
        ],
        "scatter": [
            ("space/rock_crystalsLargeB.glb", 4.8),
            ("space/machine_generator.glb", 3.8),
            ("space/pipe_ring.glb", 4.2),
            ("space/machine_barrel.glb", 3.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "FROZEN_SCRAP": {
        "sky": "snow_field_puresky.hdr",
        "sky_energy": 1.05,
        "sky_tint": (0.82, 0.92, 1.0),
        "fog_color": (0.58, 0.72, 0.86),
        "fog_density": 0.0048,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.38,
        "sun_color": (0.92, 0.96, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -42.0,
        "sun_yaw": -40.0,
        "ground": "snow_02",
        "accent": "aerial_ground_rock",
        "cliff": "cliff_side",
        "ground_tint": (0.88, 0.95, 1.0),
        "accent_tint": (0.68, 0.78, 0.88),
        "cliff_tint": (0.58, 0.70, 0.84),
        "accent_amount": 0.36,
        "roughness": 0.78,
        "height_scale": 22.0,
        "glow_color": (0.35, 0.88, 1.0),
        "glow_below": 0.7,
        "glow_strength": 1.8,
        "pillar_glb": "nature/statue_obelisk.glb",
        "pillar_scale": 5.8,
        "landmarks": [
            ("space/hangar_smallB.glb", (-26.0, -12.0), 4.5, 28.0, 4.5),
            ("space/craft_miner.glb", (26.0, -14.0), 4.2, -35.0, 4.0),
            ("space/rock_crystalsLargeA.glb", (-22.0, 18.0), 6.8, 15.0, 3.2),
            ("space/rock_crystalsLargeB.glb", (22.0, 18.0), 6.8, -25.0, 3.2),
            ("nature/tree_pineRoundA.glb", (-34.0, 8.0), 5.5, 0.0, 2.0),
            ("nature/tree_pineRoundA.glb", (34.0, 8.0), 5.5, 40.0, 2.0),
            ("nature/tree_pineRoundA.glb", (-38.0, -26.0), 5.5, 20.0, 2.0),
            ("nature/tree_pineRoundA.glb", (38.0, -26.0), 5.5, -20.0, 2.0),
            ("space/satelliteDish.glb", (0.0, 30.0), 5.0, 0.0, 2.5),
        ],
        "scatter": [
            ("space/rock_crystals.glb", 4.8),
            ("nature/rock_tallA.glb", 5.2),
            ("nature/tree_pineGroundA.glb", 4.5),
            ("survival/barrel.glb", 2.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "HOLY_TEMPLE": {
        "sky": "qwantani_late_afternoon_puresky.hdr",
        "sky_energy": 1.15,
        "sky_tint": (1.0, 0.95, 0.84),
        "fog_color": (0.76, 0.68, 0.54),
        "fog_density": 0.0035,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.42,
        "sun_color": (1.0, 0.92, 0.76),
        "sun_energy": 1.05,
        "sun_pitch": -44.0,
        "sun_yaw": -30.0,
        "ground": "large_sandstone_blocks_01",
        "accent": "red_sandstone_pavement",
        "cliff": "marble_cliff_01",
        "ground_tint": (0.98, 0.92, 0.80),
        "accent_tint": (0.92, 0.82, 0.68),
        "cliff_tint": (0.86, 0.78, 0.66),
        "accent_amount": 0.35,
        "roughness": 0.76,
        "height_scale": 20.0,
        "glow_color": (1.0, 0.85, 0.35),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "nature/statue_column.glb",
        "pillar_scale": 5.2,
        "landmarks": [
            ("castle/tower-square-roof.glb", (-28.0, -16.0), 5.5, 0.0, 3.5),
            ("castle/tower-square-roof.glb", (28.0, -16.0), 5.5, 0.0, 3.5),
            ("castle/tower-hexagon-base.glb", (-28.0, 18.0), 5.5, 0.0, 3.2),
            ("castle/tower-hexagon-base.glb", (28.0, 18.0), 5.5, 0.0, 3.2),
            ("nature/statue_column.glb", (-14.0, 6.0), 7.2, 0.0, 1.5),
            ("nature/statue_column.glb", (14.0, 6.0), 7.2, 0.0, 1.5),
            ("nature/statue_column.glb", (-14.0, -12.0), 7.2, 0.0, 1.5),
            ("nature/statue_column.glb", (14.0, -12.0), 7.2, 0.0, 1.5),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.5, 0.0, 2.5),
            ("castle/flag-banner-long.glb", (-10.0, 18.0), 3.8, 0.0, 0.8),
            ("castle/flag-banner-long.glb", (10.0, 18.0), 3.8, 0.0, 0.8),
            ("nature/statue_obelisk.glb", (-38.0, 0.0), 8.5, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (38.0, 0.0), 8.5, 0.0, 2.0),
        ],
        "scatter": [
            ("nature/statue_columnDamaged.glb", 5.5),
            ("nature/tree_palmTall.glb", 4.8),
            ("graveyard/urn-round.glb", 4.0),
            ("nature/rock_largeA.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "SKY_SANCTUM": {
        "sky": "kloofendal_48d_partly_cloudy_puresky.hdr",
        "sky_energy": 1.2,
        "sky_tint": (1.0, 0.96, 0.88),
        "fog_color": (0.78, 0.82, 0.90),
        "fog_density": 0.0032,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.50,
        "sun_color": (1.0, 0.95, 0.82),
        "sun_energy": 1.05,
        "sun_pitch": -48.0,
        "sun_yaw": -25.0,
        "ground": "large_sandstone_blocks_01",
        "accent": "marble_cliff_01",
        "cliff": "marble_cliff_01",
        "ground_tint": (1.0, 0.97, 0.90),
        "accent_tint": (0.92, 0.90, 0.85),
        "cliff_tint": (0.85, 0.82, 0.76),
        "accent_amount": 0.4,
        "roughness": 0.65,
        "height_scale": 21.0,
        "glow_color": (1.0, 0.88, 0.42),
        "glow_below": 0.75,
        "glow_strength": 2.4,
        "pillar_glb": "nature/statue_column.glb",
        "pillar_scale": 5.8,
        "has_celestial_halo": True,
        "halo_color": (1.0, 0.88, 0.40),
        "landmarks": [
            ("castle/tower-slant-roof.glb", (-28.0, -16.0), 5.0, 20.0, 3.5),
            ("castle/tower-slant-roof.glb", (28.0, -16.0), 5.0, -20.0, 3.5),
            ("nature/statue_column.glb", (-18.0, 8.0), 8.2, 0.0, 1.6),
            ("nature/statue_column.glb", (18.0, 8.0), 8.2, 0.0, 1.6),
            ("nature/statue_column.glb", (-18.0, -14.0), 8.2, 0.0, 1.6),
            ("nature/statue_column.glb", (18.0, -14.0), 8.2, 0.0, 1.6),
            ("nature/statue_ring.glb", (-26.0, 22.0), 6.5, 30.0, 2.5),
            ("nature/statue_ring.glb", (26.0, 22.0), 6.5, -30.0, 2.5),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 5.0, 0.0, 2.5),
            ("nature/statue_obelisk.glb", (-36.0, 4.0), 9.0, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (36.0, 4.0), 9.0, 0.0, 2.0),
        ],
        "scatter": [
            ("nature/statue_columnDamaged.glb", 5.5),
            ("space/rock_crystalsLargeA.glb", 4.5),
            ("graveyard/fire-basket.glb", 4.0),
            ("nature/statue_block.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "DESERT_RUINS": {
        "sky": "wasteland_clouds_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.88, 0.72),
        "fog_color": (0.76, 0.58, 0.40),
        "fog_density": 0.0045,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.36,
        "sun_color": (1.0, 0.88, 0.68),
        "sun_energy": 1.05,
        "sun_pitch": -40.0,
        "sun_yaw": -45.0,
        "ground": "aerial_sand",
        "accent": "red_sandstone_pavement",
        "cliff": "cliff_side",
        "ground_tint": (0.98, 0.84, 0.64),
        "accent_tint": (0.88, 0.68, 0.48),
        "cliff_tint": (0.78, 0.58, 0.40),
        "accent_amount": 0.38,
        "roughness": 0.88,
        "height_scale": 20.0,
        "glow_color": (1.0, 0.65, 0.2),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "nature/statue_obelisk.glb",
        "pillar_scale": 5.5,
        "landmarks": [
            ("nature/statue_obelisk.glb", (-24.0, -12.0), 8.5, 10.0, 2.0),
            ("nature/statue_obelisk.glb", (24.0, -12.0), 8.5, -10.0, 2.0),
            ("nature/statue_obelisk.glb", (-20.0, 24.0), 7.8, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (20.0, 24.0), 7.8, 0.0, 2.0),
            ("nature/statue_head.glb", (-30.0, 6.0), 6.0, 45.0, 3.0),
            ("nature/statue_head.glb", (30.0, 6.0), 6.0, -45.0, 3.0),
            ("nature/statue_columnDamaged.glb", (-14.0, 10.0), 6.5, 0.0, 1.5),
            ("nature/statue_columnDamaged.glb", (14.0, 10.0), 6.5, 0.0, 1.5),
            ("nature/tent_detailedOpen.glb", (-28.0, -28.0), 5.5, 25.0, 3.0),
            ("nature/tent_detailedClosed.glb", (28.0, -28.0), 5.5, -25.0, 3.0),
        ],
        "scatter": [
            ("nature/cactus_tall.glb", 5.5),
            ("nature/tree_palmBend.glb", 4.8),
            ("survival/rock-sand-b.glb", 5.0),
            ("nature/statue_block.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "CATACOMB_CRYPT": {
        "sky": "scythian_tombs_puresky.hdr",
        "sky_energy": 0.95,
        "sky_tint": (0.72, 0.92, 0.82),
        "fog_color": (0.18, 0.28, 0.24),
        "fog_density": 0.0065,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.48,
        "sun_color": (0.75, 0.95, 0.85),
        "sun_energy": 1.05,
        "sun_pitch": -50.0,
        "sun_yaw": -20.0,
        "ground": "mossy_brick_floor",
        "accent": "old_stone_wall_02",
        "cliff": "dark_rock_02",
        "ground_tint": (0.75, 0.82, 0.76),
        "accent_tint": (0.65, 0.72, 0.68),
        "cliff_tint": (0.48, 0.54, 0.50),
        "accent_amount": 0.42,
        "roughness": 0.86,
        "height_scale": 20.0,
        "glow_color": (0.30, 0.95, 0.68),
        "glow_below": 0.85,
        "glow_strength": 2.6,
        "pillar_glb": "graveyard/column-large.glb",
        "pillar_scale": 4.2,
        "landmarks": [
            ("graveyard/crypt-large.glb", (-24.0, -12.0), 4.2, 20.0, 4.5),
            ("graveyard/crypt-large.glb", (24.0, -12.0), 4.2, -20.0, 4.5),
            ("graveyard/crypt-small.glb", (-24.0, 20.0), 4.0, 15.0, 3.2),
            ("graveyard/crypt-small.glb", (24.0, 20.0), 4.0, -15.0, 3.2),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.5, 0.0, 2.5),
            ("graveyard/pillar-obelisk.glb", (-15.0, 14.0), 5.0, 0.0, 1.5),
            ("graveyard/pillar-obelisk.glb", (15.0, 14.0), 5.0, 0.0, 1.5),
            ("graveyard/column-large.glb", (-15.0, -6.0), 5.0, 0.0, 1.5),
            ("graveyard/column-large.glb", (15.0, -6.0), 5.0, 0.0, 1.5),
            ("graveyard/coffin.glb", (-18.0, 4.0), 4.2, 35.0, 2.0),
            ("graveyard/coffin-old.glb", (18.0, 4.0), 4.2, -35.0, 2.0),
        ],
        "scatter": [
            ("graveyard/gravestone-cross-large.glb", 4.0),
            ("graveyard/iron-fence-border.glb", 3.8),
            ("graveyard/fire-basket.glb", 4.2),
            ("graveyard/pine-crooked.glb", 3.2),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "OBSIDIAN_CITADEL": {
        "sky": "qwantani_dusk_2_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (0.95, 0.62, 0.72),
        "fog_color": (0.34, 0.16, 0.24),
        "fog_density": 0.0052,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.50,
        "sun_color": (1.0, 0.58, 0.48),
        "sun_energy": 1.05,
        "sun_pitch": -38.0,
        "sun_yaw": -35.0,
        "ground": "dark_rock",
        "accent": "medieval_blocks_02",
        "cliff": "dark_rock_02",
        "ground_tint": (0.68, 0.56, 0.66),
        "accent_tint": (0.58, 0.44, 0.54),
        "cliff_tint": (0.42, 0.34, 0.44),
        "accent_amount": 0.40,
        "roughness": 0.78,
        "height_scale": 21.0,
        "glow_color": (0.95, 0.20, 0.38),
        "glow_below": 0.78,
        "glow_strength": 2.5,
        "pillar_glb": "graveyard/pillar-obelisk.glb",
        "pillar_scale": 4.8,
        "landmarks": [
            ("castle/tower-square.glb", (-28.0, -16.0), 6.0, 0.0, 3.8),
            ("castle/tower-square.glb", (28.0, -16.0), 6.0, 0.0, 3.8),
            ("castle/wall-corner-half-tower.glb", (-28.0, 18.0), 5.0, 45.0, 3.5),
            ("castle/wall-corner-half-tower.glb", (28.0, 18.0), 5.0, -45.0, 3.5),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.8, 0.0, 2.5),
            ("graveyard/pillar-obelisk.glb", (-18.0, 6.0), 6.5, 0.0, 1.8),
            ("graveyard/pillar-obelisk.glb", (18.0, 6.0), 6.5, 0.0, 1.8),
            ("graveyard/pillar-obelisk.glb", (-18.0, -12.0), 6.5, 0.0, 1.8),
            ("graveyard/pillar-obelisk.glb", (18.0, -12.0), 6.5, 0.0, 1.8),
            ("castle/siege-catapult.glb", (-34.0, 2.0), 3.2, 30.0, 3.0),
            ("castle/siege-ballista.glb", (34.0, 2.0), 3.2, -30.0, 2.8),
        ],
        "scatter": [
            ("nature/rock_tallB.glb", 5.8),
            ("graveyard/fire-basket.glb", 4.5),
            ("castle/flag-banner-long.glb", 3.5),
            ("graveyard/iron-fence-damaged.glb", 3.8),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "VOLCANIC_BASIN": {
        "sky": "industrial_sunset_02_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.68, 0.48),
        "fog_color": (0.44, 0.20, 0.14),
        "fog_density": 0.0055,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.48,
        "sun_color": (1.0, 0.65, 0.38),
        "sun_energy": 1.05,
        "sun_pitch": -36.0,
        "sun_yaw": -40.0,
        "ground": "burned_ground_01",
        "accent": "dark_rock",
        "cliff": "dark_rock_02",
        "ground_tint": (0.85, 0.64, 0.56),
        "accent_tint": (0.65, 0.48, 0.44),
        "cliff_tint": (0.50, 0.36, 0.32),
        "accent_amount": 0.42,
        "roughness": 0.88,
        "height_scale": 22.0,
        "glow_color": (1.0, 0.35, 0.08),
        "glow_below": 0.95,
        "glow_strength": 3.4,
        "pillar_glb": "nature/rock_tallA.glb",
        "pillar_scale": 4.8,
        "landmarks": [
            ("nature/rock_tallA.glb", (-24.0, 12.0), 7.5, 20.0, 3.5),
            ("nature/rock_tallB.glb", (24.0, 12.0), 7.5, -20.0, 3.5),
            ("nature/rock_tallC.glb", (-26.0, -14.0), 8.0, 45.0, 3.0),
            ("nature/rock_tallD.glb", (26.0, -14.0), 8.0, -45.0, 3.0),
            ("castle/siege-tower-demolished.glb", (-32.0, -2.0), 3.2, 25.0, 3.5),
            ("castle/siege-trebuchet.glb", (32.0, -2.0), 3.2, -25.0, 3.5),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.5, 0.0, 2.5),
            ("space/meteor_detailed.glb", (-18.0, 24.0), 5.5, 0.0, 2.8),
            ("space/meteor_detailed.glb", (18.0, 24.0), 5.5, 40.0, 2.8),
        ],
        "scatter": [
            ("space/craterLarge.glb", 5.5),
            ("nature/rock_largeD.glb", 5.0),
            ("graveyard/pine-fall-crooked.glb", 3.5),
            ("graveyard/fire-basket.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "MAGMA_CALDERA": {
        "sky": "industrial_sunset_02_puresky.hdr",
        "sky_energy": 1.15,
        "sky_tint": (1.0, 0.58, 0.36),
        "fog_color": (0.48, 0.18, 0.10),
        "fog_density": 0.006,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.58,
        "sun_color": (1.0, 0.58, 0.30),
        "sun_energy": 1.05,
        "sun_pitch": -35.0,
        "sun_yaw": -30.0,
        "ground": "burned_ground_01",
        "accent": "dark_rock_02",
        "cliff": "dark_rock",
        "ground_tint": (0.82, 0.56, 0.48),
        "accent_tint": (0.58, 0.38, 0.34),
        "cliff_tint": (0.45, 0.30, 0.26),
        "accent_amount": 0.45,
        "roughness": 0.90,
        "height_scale": 23.0,
        "glow_color": (1.0, 0.32, 0.05),
        "glow_below": 1.15,
        "glow_strength": 4.2,
        "pillar_glb": "nature/rock_tallC.glb",
        "pillar_scale": 5.5,
        "landmarks": [
            ("nature/rock_tallA.glb", (-26.0, 10.0), 8.2, 15.0, 3.8),
            ("nature/rock_tallA.glb", (26.0, 10.0), 8.2, -15.0, 3.8),
            ("space/meteor_detailed.glb", (-22.0, -14.0), 6.5, 30.0, 3.2),
            ("space/meteor_detailed.glb", (22.0, -14.0), 6.5, -30.0, 3.2),
            ("space/rock_crystalsLargeA.glb", (-16.0, 22.0), 6.0, 10.0, 3.0),
            ("space/rock_crystalsLargeB.glb", (16.0, 22.0), 6.0, -10.0, 3.0),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.8, 0.0, 2.5),
            ("space/bones.glb", (-32.0, -4.0), 6.5, 45.0, 3.0),
            ("space/bones.glb", (32.0, -4.0), 6.5, -45.0, 3.0),
        ],
        "scatter": [
            ("space/craterLarge.glb", 6.0),
            ("nature/rock_tallF.glb", 5.5),
            ("space/meteor_half.glb", 4.8),
            ("graveyard/fire-basket.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "SCORCHED_CAULDRON": {
        "sky": "qwantani_dusk_2_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.55, 0.45),
        "fog_color": (0.42, 0.16, 0.16),
        "fog_density": 0.006,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.55,
        "sun_color": (1.0, 0.52, 0.38),
        "sun_energy": 1.05,
        "sun_pitch": -38.0,
        "sun_yaw": -28.0,
        "ground": "burned_ground_01",
        "accent": "brown_mud_rocks_01",
        "cliff": "dark_rock",
        "ground_tint": (0.80, 0.55, 0.52),
        "accent_tint": (0.62, 0.42, 0.40),
        "cliff_tint": (0.46, 0.32, 0.34),
        "accent_amount": 0.42,
        "roughness": 0.88,
        "height_scale": 22.0,
        "glow_color": (1.0, 0.28, 0.12),
        "glow_below": 1.1,
        "glow_strength": 3.8,
        "pillar_glb": "graveyard/pillar-obelisk.glb",
        "pillar_scale": 5.0,
        "landmarks": [
            ("castle/siege-tower-demolished.glb", (-26.0, -12.0), 3.6, 25.0, 3.5),
            ("castle/siege-trebuchet-demolished.glb", (26.0, -12.0), 3.6, -25.0, 3.5),
            ("nature/rock_tallB.glb", (-24.0, 14.0), 7.8, 10.0, 3.5),
            ("nature/rock_tallB.glb", (24.0, 14.0), 7.8, -10.0, 3.5),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 4.8, 0.0, 2.5),
            ("space/meteor_detailed.glb", (-18.0, -22.0), 6.0, 0.0, 3.0),
            ("space/meteor_detailed.glb", (18.0, -22.0), 6.0, 45.0, 3.0),
            ("space/bones.glb", (-32.0, 2.0), 7.0, 20.0, 3.2),
            ("space/bones.glb", (32.0, 2.0), 7.0, -20.0, 3.2),
        ],
        "scatter": [
            ("space/craterLarge.glb", 5.5),
            ("castle/siege-catapult-demolished.glb", 2.8),
            ("nature/rock_tallG.glb", 5.2),
            ("graveyard/fire-basket.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "DAEVA_CRYPT": {
        "sky": "qwantani_night_puresky.hdr",
        "sky_energy": 1.25,
        "sky_tint": (0.88, 0.55, 1.0),
        "fog_color": (0.24, 0.12, 0.32),
        "fog_density": 0.0065,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.55,
        "sun_color": (0.90, 0.58, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -48.0,
        "sun_yaw": -20.0,
        "ground": "medieval_blocks_02",
        "accent": "dark_rock",
        "cliff": "dark_rock_02",
        "ground_tint": (0.72, 0.58, 0.78),
        "accent_tint": (0.55, 0.42, 0.64),
        "cliff_tint": (0.42, 0.30, 0.50),
        "accent_amount": 0.42,
        "roughness": 0.82,
        "height_scale": 21.0,
        "glow_color": (0.85, 0.22, 1.0),
        "glow_below": 0.88,
        "glow_strength": 3.2,
        "pillar_glb": "graveyard/pillar-obelisk.glb",
        "pillar_scale": 5.0,
        "landmarks": [
            ("graveyard/crypt-large.glb", (-24.0, -14.0), 4.5, 25.0, 4.5),
            ("graveyard/crypt-large.glb", (24.0, -14.0), 4.5, -25.0, 4.5),
            ("graveyard/pillar-obelisk.glb", (-22.0, 10.0), 7.5, 0.0, 2.0),
            ("graveyard/pillar-obelisk.glb", (22.0, 10.0), 7.5, 0.0, 2.0),
            ("graveyard/altar-stone.glb", (0.0, 22.0), 5.0, 0.0, 2.5),
            ("dungeon/gate.glb", (-16.0, 22.0), 5.0, 20.0, 2.5),
            ("dungeon/gate.glb", (16.0, 22.0), 5.0, -20.0, 2.5),
            ("graveyard/coffin.glb", (-16.0, -4.0), 4.5, 30.0, 2.0),
            ("graveyard/coffin.glb", (16.0, -4.0), 4.5, -30.0, 2.0),
        ],
        "scatter": [
            ("graveyard/gravestone-cross-large.glb", 4.2),
            ("dungeon/column.glb", 4.5),
            ("graveyard/fire-basket.glb", 4.5),
            ("graveyard/pine-crooked.glb", 3.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "PERSEPOLIS_STEPPES": {
        "sky": "qwantani_late_afternoon_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.90, 0.74),
        "fog_color": (0.72, 0.58, 0.44),
        "fog_density": 0.0042,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.38,
        "sun_color": (1.0, 0.88, 0.68),
        "sun_energy": 1.05,
        "sun_pitch": -42.0,
        "sun_yaw": -35.0,
        "ground": "dry_ground_rocks",
        "accent": "large_sandstone_blocks_01",
        "cliff": "cliff_side",
        "ground_tint": (0.94, 0.82, 0.66),
        "accent_tint": (0.88, 0.76, 0.60),
        "cliff_tint": (0.76, 0.62, 0.48),
        "accent_amount": 0.40,
        "roughness": 0.86,
        "height_scale": 21.0,
        "glow_color": (1.0, 0.75, 0.25),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "nature/statue_column.glb",
        "pillar_scale": 5.2,
        "landmarks": [
            ("nature/statue_column.glb", (-22.0, 6.0), 7.8, 0.0, 1.6),
            ("nature/statue_column.glb", (22.0, 6.0), 7.8, 0.0, 1.6),
            ("nature/statue_column.glb", (-22.0, -14.0), 7.8, 0.0, 1.6),
            ("nature/statue_column.glb", (22.0, -14.0), 7.8, 0.0, 1.6),
            ("nature/statue_obelisk.glb", (-28.0, 22.0), 8.0, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (28.0, 22.0), 8.0, 0.0, 2.0),
            ("castle/tower-square-arch.glb", (-32.0, -4.0), 5.0, 90.0, 3.2),
            ("castle/tower-square-arch.glb", (32.0, -4.0), 5.0, 90.0, 3.2),
            ("nature/statue_head.glb", (0.0, 24.0), 6.0, 0.0, 2.8),
        ],
        "scatter": [
            ("nature/statue_columnDamaged.glb", 5.5),
            ("nature/tree_palmShort.glb", 4.5),
            ("nature/rock_largeB.glb", 5.0),
            ("nature/statue_block.glb", 4.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "VAR_ROOTS": {
        "sky": "kloofendal_misty_morning_puresky.hdr",
        "sky_energy": 1.0,
        "sky_tint": (0.85, 0.95, 0.78),
        "fog_color": (0.36, 0.44, 0.32),
        "fog_density": 0.0055,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.42,
        "sun_color": (0.95, 0.92, 0.74),
        "sun_energy": 1.05,
        "sun_pitch": -46.0,
        "sun_yaw": -30.0,
        "ground": "aerial_grass_rock",
        "accent": "mossy_brick_floor",
        "cliff": "cliff_side",
        "ground_tint": (0.82, 0.88, 0.72),
        "accent_tint": (0.74, 0.82, 0.68),
        "cliff_tint": (0.64, 0.60, 0.50),
        "accent_amount": 0.42,
        "roughness": 0.88,
        "height_scale": 21.0,
        "glow_color": (0.55, 0.95, 0.35),
        "glow_below": 0.75,
        "glow_strength": 2.0,
        "pillar_glb": "nature/statue_column.glb",
        "pillar_scale": 5.0,
        "landmarks": [
            ("castle/tree-large.glb", (-22.0, -10.0), 5.5, 0.0, 2.8),
            ("castle/tree-large.glb", (22.0, -10.0), 5.5, 45.0, 2.8),
            ("castle/tree-large.glb", (-26.0, 16.0), 5.0, 20.0, 2.6),
            ("castle/tree-large.glb", (26.0, 16.0), 5.0, -20.0, 2.6),
            ("nature/statue_column.glb", (-16.0, 8.0), 7.0, 0.0, 1.5),
            ("nature/statue_column.glb", (16.0, 8.0), 7.0, 0.0, 1.5),
            ("nature/statue_ring.glb", (0.0, 22.0), 6.5, 0.0, 2.5),
            ("nature/log_large.glb", (-18.0, -20.0), 6.0, 35.0, 2.5),
            ("nature/log_large.glb", (18.0, -20.0), 6.0, -35.0, 2.5),
        ],
        "scatter": [
            ("nature/mushroom_tanGroup.glb", 6.5),
            ("nature/stump_oldTall.glb", 5.5),
            ("nature/plant_bushDetailed.glb", 5.0),
            ("nature/rock_largeC.glb", 4.8),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "CRACK_MINING": {
        "sky": "wasteland_clouds_puresky.hdr",
        "sky_energy": 1.08,
        "sky_tint": (1.0, 0.86, 0.64),
        "fog_color": (0.58, 0.46, 0.32),
        "fog_density": 0.0048,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.52,
        "sun_color": (1.0, 0.85, 0.60),
        "sun_energy": 1.05,
        "sun_pitch": -44.0,
        "sun_yaw": -35.0,
        "ground": "dry_ground_rocks",
        "accent": "quarry_wall",
        "cliff": "quarry_wall",
        "ground_tint": (0.86, 0.76, 0.62),
        "accent_tint": (0.74, 0.64, 0.52),
        "cliff_tint": (0.62, 0.52, 0.42),
        "accent_amount": 0.45,
        "roughness": 0.88,
        "height_scale": 22.0,
        "glow_color": (1.0, 0.72, 0.16),
        "glow_below": 1.05,
        "glow_strength": 3.6,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.6,
        "has_farr_megaspire": True,
        "landmarks": [
            ("space/chimney_detailed.glb", (-28.0, 2.0), 5.0, 0.0, 2.5),
            ("space/chimney_detailed.glb", (28.0, 2.0), 5.0, 0.0, 2.5),
            ("space/chimney_detailed.glb", (0.0, -34.0), 5.0, 0.0, 2.5),
            ("space/chimney_detailed.glb", (0.0, 34.0), 5.0, 0.0, 2.5),
            ("space/craft_miner.glb", (-24.0, -16.0), 4.2, 30.0, 3.8),
            ("space/craft_miner.glb", (24.0, -16.0), 4.2, -30.0, 3.8),
            ("space/rock_crystalsLargeA.glb", (-18.0, 16.0), 6.8, 15.0, 3.0),
            ("space/rock_crystalsLargeB.glb", (18.0, 16.0), 6.8, -15.0, 3.0),
            ("space/machine_generatorLarge.glb", (-26.0, 22.0), 4.5, 25.0, 2.8),
            ("space/machine_generatorLarge.glb", (26.0, 22.0), 4.5, -25.0, 2.8),
        ],
        "scatter": [
            ("space/rock_crystals.glb", 5.5),
            ("space/barrels_rail.glb", 4.0),
            ("nature/rock_tallE.glb", 5.5),
            ("space/rover.glb", 5.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "LOWER_CRATER": {
        "sky": "industrial_sunset_02_puresky.hdr",
        "sky_energy": 1.05,
        "sky_tint": (1.0, 0.78, 0.52),
        "fog_color": (0.48, 0.34, 0.24),
        "fog_density": 0.0055,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.52,
        "sun_color": (1.0, 0.76, 0.48),
        "sun_energy": 1.05,
        "sun_pitch": -40.0,
        "sun_yaw": -30.0,
        "ground": "brown_mud_rocks_01",
        "accent": "quarry_wall",
        "cliff": "dark_rock",
        "ground_tint": (0.82, 0.68, 0.56),
        "accent_tint": (0.68, 0.56, 0.46),
        "cliff_tint": (0.52, 0.42, 0.34),
        "accent_amount": 0.45,
        "roughness": 0.90,
        "height_scale": 23.0,
        "glow_color": (1.0, 0.68, 0.14),
        "glow_below": 1.15,
        "glow_strength": 3.8,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.6,
        "has_farr_megaspire": True,
        "landmarks": [
            ("space/chimney_detailed.glb", (-26.0, 4.0), 5.2, 0.0, 2.5),
            ("space/chimney_detailed.glb", (26.0, 4.0), 5.2, 0.0, 2.5),
            ("space/craft_miner.glb", (-22.0, -14.0), 4.5, 25.0, 4.0),
            ("space/craft_cargoB.glb", (22.0, -14.0), 4.5, -25.0, 4.0),
            ("space/rock_crystalsLargeA.glb", (-16.0, 20.0), 7.2, 10.0, 3.2),
            ("space/rock_crystalsLargeB.glb", (16.0, 20.0), 7.2, -10.0, 3.2),
            ("space/pipe_entrance.glb", (-32.0, -24.0), 5.5, 40.0, 3.0),
            ("space/pipe_entrance.glb", (32.0, -24.0), 5.5, -40.0, 3.0),
        ],
        "scatter": [
            ("space/rock_crystalsLargeA.glb", 5.0),
            ("space/craterLarge.glb", 5.5),
            ("space/machine_barrelLarge.glb", 3.8),
            ("nature/rock_tallH.glb", 5.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "BREACH_RIDGE": {
        "sky": "wasteland_clouds_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.84, 0.62),
        "fog_color": (0.54, 0.42, 0.30),
        "fog_density": 0.0048,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.50,
        "sun_color": (1.0, 0.82, 0.58),
        "sun_energy": 1.05,
        "sun_pitch": -42.0,
        "sun_yaw": -35.0,
        "ground": "aerial_ground_rock",
        "accent": "rusty_metal_02",
        "cliff": "quarry_wall",
        "ground_tint": (0.84, 0.74, 0.62),
        "accent_tint": (0.76, 0.62, 0.50),
        "cliff_tint": (0.60, 0.50, 0.42),
        "accent_amount": 0.40,
        "roughness": 0.86,
        "height_scale": 22.0,
        "glow_color": (1.0, 0.70, 0.18),
        "glow_below": 1.0,
        "glow_strength": 3.4,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.6,
        "has_farr_megaspire": True,
        "landmarks": [
            ("space/turret_double.glb", (-24.0, -12.0), 5.0, 20.0, 2.5),
            ("space/turret_double.glb", (24.0, -12.0), 5.0, -20.0, 2.5),
            ("space/hangar_smallA.glb", (-28.0, 14.0), 4.5, 15.0, 4.5),
            ("space/hangar_smallA.glb", (28.0, 14.0), 4.5, -15.0, 4.5),
            ("space/chimney_detailed.glb", (-20.0, -24.0), 5.0, 0.0, 2.5),
            ("space/chimney_detailed.glb", (20.0, -24.0), 5.0, 0.0, 2.5),
            ("space/rock_crystalsLargeA.glb", (-16.0, 22.0), 6.5, 0.0, 3.0),
            ("space/rock_crystalsLargeB.glb", (16.0, 22.0), 6.5, 0.0, 3.0),
        ],
        "scatter": [
            ("space/rock_crystals.glb", 5.2),
            ("survival/fence-fortified.glb", 3.5),
            ("space/barrels.glb", 4.0),
            ("nature/rock_tallD.glb", 5.2),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "AETHER_SKY": {
        "sky": "kloofendal_48d_partly_cloudy_puresky.hdr",
        "sky_energy": 1.2,
        "sky_tint": (0.78, 0.95, 1.0),
        "fog_color": (0.48, 0.72, 0.90),
        "fog_density": 0.0035,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.50,
        "sun_color": (0.95, 0.98, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -48.0,
        "sun_yaw": -30.0,
        "ground": "marble_cliff_01",
        "accent": "metal_plate",
        "cliff": "marble_cliff_01",
        "ground_tint": (0.84, 0.94, 1.0),
        "accent_tint": (0.72, 0.88, 1.0),
        "cliff_tint": (0.68, 0.82, 0.95),
        "accent_amount": 0.38,
        "roughness": 0.62,
        "height_scale": 20.0,
        "glow_color": (0.30, 0.92, 1.0),
        "glow_below": 0.82,
        "glow_strength": 3.0,
        "pillar_glb": "space/chimney_detailed.glb",
        "pillar_scale": 2.6,
        "has_celestial_halo": True,
        "halo_color": (0.35, 0.92, 1.0),
        "landmarks": [
            ("space/hangar_roundA.glb", (-28.0, -12.0), 4.2, 25.0, 5.5),
            ("space/hangar_roundA.glb", (28.0, -12.0), 4.2, -25.0, 5.5),
            ("space/satelliteDish_large.glb", (-22.0, 18.0), 6.0, 20.0, 3.0),
            ("space/satelliteDish_large.glb", (22.0, 18.0), 6.0, -20.0, 3.0),
            ("space/craft_speederC.glb", (-18.0, -4.0), 3.8, 35.0, 3.0),
            ("space/craft_speederD.glb", (18.0, -4.0), 3.8, -35.0, 3.0),
            ("space/rock_crystalsLargeA.glb", (-30.0, 8.0), 6.5, 0.0, 3.0),
            ("space/rock_crystalsLargeB.glb", (30.0, 8.0), 6.5, 0.0, 3.0),
        ],
        "scatter": [
            ("space/rock_crystals.glb", 5.0),
            ("space/satelliteDish.glb", 4.2),
            ("space/machine_wireless.glb", 4.0),
            ("nature/statue_column.glb", 5.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "LUMINESCENT_AQUIFER": {
        "sky": "kloofendal_misty_morning_puresky.hdr",
        "sky_energy": 0.95,
        "sky_tint": (0.55, 0.95, 0.88),
        "fog_color": (0.14, 0.32, 0.34),
        "fog_density": 0.006,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.52,
        "sun_color": (0.68, 0.96, 0.90),
        "sun_energy": 1.05,
        "sun_pitch": -48.0,
        "sun_yaw": -25.0,
        "ground": "mossy_brick_floor",
        "accent": "gray_rocks",
        "cliff": "cliff_side",
        "ground_tint": (0.68, 0.88, 0.84),
        "accent_tint": (0.56, 0.78, 0.76),
        "cliff_tint": (0.44, 0.62, 0.62),
        "accent_amount": 0.42,
        "roughness": 0.74,
        "height_scale": 20.0,
        "glow_color": (0.20, 0.96, 0.84),
        "glow_below": 0.92,
        "glow_strength": 3.4,
        "pillar_glb": "nature/statue_column.glb",
        "pillar_scale": 5.0,
        "landmarks": [
            ("nature/mushroom_redGroup.glb", (-22.0, -10.0), 16.0, 15.0, 2.5),
            ("nature/mushroom_redGroup.glb", (22.0, -10.0), 18.0, -15.0, 2.5),
            ("nature/mushroom_redTall.glb", (-16.0, 16.0), 18.0, 0.0, 2.0),
            ("nature/mushroom_redTall.glb", (16.0, 16.0), 18.0, 35.0, 2.0),
            ("space/rock_crystalsLargeA.glb", (-28.0, 6.0), 6.5, 20.0, 3.0),
            ("space/rock_crystalsLargeB.glb", (28.0, 6.0), 6.5, -20.0, 3.0),
            ("nature/statue_ring.glb", (0.0, 22.0), 6.0, 0.0, 2.5),
            ("castle/bridge-straight-pillar.glb", (-18.0, -22.0), 4.2, 0.0, 2.5),
            ("castle/bridge-straight-pillar.glb", (18.0, -22.0), 4.2, 0.0, 2.5),
        ],
        "scatter": [
            ("nature/mushroom_tanGroup.glb", 10.0),
            ("space/rock_crystals.glb", 5.0),
            ("nature/rock_largeE.glb", 4.8),
            ("nature/plant_bushLarge.glb", 5.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "BEAST_HIGHLAND": {
        "sky": "kloofendal_48d_partly_cloudy_puresky.hdr",
        "sky_energy": 1.1,
        "sky_tint": (1.0, 0.90, 0.76),
        "fog_color": (0.64, 0.54, 0.42),
        "fog_density": 0.0042,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.38,
        "sun_color": (1.0, 0.90, 0.72),
        "sun_energy": 1.05,
        "sun_pitch": -44.0,
        "sun_yaw": -35.0,
        "ground": "aerial_grass_rock",
        "accent": "dry_ground_rocks",
        "cliff": "cliff_side",
        "ground_tint": (0.90, 0.82, 0.68),
        "accent_tint": (0.80, 0.68, 0.54),
        "cliff_tint": (0.68, 0.56, 0.44),
        "accent_amount": 0.40,
        "roughness": 0.88,
        "height_scale": 22.0,
        "glow_color": (1.0, 0.75, 0.25),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "nature/statue_obelisk.glb",
        "pillar_scale": 5.5,
        "landmarks": [
            ("space/bones.glb", (-14.0, -8.0), 9.5, 20.0, 3.8),
            ("space/bones.glb", (14.0, -8.0), 9.5, -20.0, 3.8),
            ("space/bones.glb", (-22.0, 12.0), 8.0, 45.0, 3.2),
            ("space/bones.glb", (22.0, 12.0), 8.0, -45.0, 3.2),
            ("nature/statue_obelisk.glb", (-26.0, -16.0), 8.0, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (26.0, -16.0), 8.0, 0.0, 2.0),
            ("nature/rock_tallA.glb", (-32.0, 4.0), 7.5, 15.0, 3.5),
            ("nature/rock_tallB.glb", (32.0, 4.0), 7.5, -15.0, 3.5),
            ("nature/tent_detailedOpen.glb", (0.0, 24.0), 5.5, 0.0, 2.8),
        ],
        "scatter": [
            ("space/bones.glb", 5.5),
            ("nature/tree_pineRoundA.glb", 4.8),
            ("nature/rock_largeF.glb", 5.0),
            ("survival/campfire-pit.glb", 3.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "OUTCAST_WASTELAND": {
        "sky": "wasteland_clouds_puresky.hdr",
        "sky_energy": 1.05,
        "sky_tint": (1.0, 0.84, 0.66),
        "fog_color": (0.62, 0.48, 0.34),
        "fog_density": 0.0048,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.38,
        "sun_color": (1.0, 0.84, 0.62),
        "sun_energy": 1.05,
        "sun_pitch": -40.0,
        "sun_yaw": -35.0,
        "ground": "dry_ground_01",
        "accent": "rusty_metal_02",
        "cliff": "quarry_wall",
        "ground_tint": (0.88, 0.74, 0.58),
        "accent_tint": (0.76, 0.58, 0.44),
        "cliff_tint": (0.64, 0.50, 0.38),
        "accent_amount": 0.38,
        "roughness": 0.90,
        "height_scale": 21.0,
        "glow_color": (1.0, 0.65, 0.20),
        "glow_below": -999.0,
        "glow_strength": 0.0,
        "pillar_glb": "survival/structure-metal.glb",
        "pillar_scale": 4.5,
        "landmarks": [
            ("survival/structure-metal.glb", (-22.0, -14.0), 7.5, 20.0, 3.2),
            ("survival/structure-metal.glb", (22.0, -14.0), 7.5, -20.0, 3.2),
            ("survival/tent-canvas.glb", (-26.0, 12.0), 6.5, 30.0, 3.0),
            ("survival/tent-canvas.glb", (26.0, 12.0), 6.5, -30.0, 3.0),
            ("survival/fence-fortified.glb", (-14.0, 16.0), 5.5, 10.0, 2.5),
            ("survival/fence-fortified.glb", (14.0, 16.0), 5.5, -10.0, 2.5),
            ("castle/siege-ballista.glb", (-18.0, -4.0), 3.2, 15.0, 2.5),
            ("castle/siege-ballista.glb", (18.0, -4.0), 3.2, -15.0, 2.5),
            ("survival/campfire-stand.glb", (0.0, 22.0), 4.5, 0.0, 2.0),
        ],
        "scatter": [
            ("survival/barrel.glb", 2.4),
            ("survival/box-large.glb", 4.0),
            ("nature/cactus_short.glb", 5.5),
            ("nature/rock_tallE.glb", 5.2),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "SKY_FRACTURE": {
        "sky": "qwantani_night_puresky.hdr",
        "sky_energy": 1.35,
        "sky_tint": (0.78, 0.68, 1.0),
        "fog_color": (0.28, 0.22, 0.46),
        "fog_density": 0.005,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.58,
        "sun_color": (0.85, 0.72, 1.0),
        "sun_energy": 1.05,
        "sun_pitch": -48.0,
        "sun_yaw": -25.0,
        "ground": "marble_cliff_01",
        "accent": "dark_rock",
        "cliff": "marble_cliff_01",
        "ground_tint": (0.78, 0.74, 0.94),
        "accent_tint": (0.62, 0.54, 0.84),
        "cliff_tint": (0.52, 0.46, 0.74),
        "accent_amount": 0.42,
        "roughness": 0.68,
        "height_scale": 22.0,
        "glow_color": (0.68, 0.42, 1.0),
        "glow_below": 0.95,
        "glow_strength": 3.6,
        "pillar_glb": "nature/statue_obelisk.glb",
        "pillar_scale": 5.8,
        "has_celestial_halo": True,
        "halo_color": (0.72, 0.45, 1.0),
        "landmarks": [
            ("space/rock_crystalsLargeA.glb", (-24.0, -12.0), 7.8, 20.0, 3.5),
            ("space/rock_crystalsLargeB.glb", (24.0, -12.0), 7.8, -20.0, 3.5),
            ("space/meteor_detailed.glb", (-20.0, 14.0), 6.5, 0.0, 3.0),
            ("space/meteor_detailed.glb", (20.0, 14.0), 6.5, 45.0, 3.0),
            ("nature/statue_ring.glb", (-28.0, 4.0), 7.0, 30.0, 2.8),
            ("nature/statue_ring.glb", (28.0, 4.0), 7.0, -30.0, 2.8),
            ("nature/statue_obelisk.glb", (-16.0, 22.0), 8.5, 0.0, 2.0),
            ("nature/statue_obelisk.glb", (16.0, 22.0), 8.5, 0.0, 2.0),
        ],
        "scatter": [
            ("space/rock_crystals.glb", 5.5),
            ("space/meteor.glb", 4.5),
            ("nature/statue_columnDamaged.glb", 5.5),
            ("nature/rock_tallI.glb", 5.5),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
    "BORDER_TRENCHES": {
        "sky": "qwantani_dusk_2_puresky.hdr",
        "sky_energy": 1.05,
        "sky_tint": (0.95, 0.68, 0.62),
        "fog_color": (0.42, 0.24, 0.24),
        "fog_density": 0.0055,
        "ambient_energy": 0.58,
        "exposure": 0.95,
        "glow_intensity": 0.45,
        "sun_color": (1.0, 0.68, 0.52),
        "sun_energy": 1.05,
        "sun_pitch": -38.0,
        "sun_yaw": -35.0,
        "ground": "brown_mud_rocks_01",
        "accent": "burned_ground_01",
        "cliff": "dark_rock",
        "ground_tint": (0.78, 0.62, 0.58),
        "accent_tint": (0.62, 0.46, 0.44),
        "cliff_tint": (0.48, 0.36, 0.36),
        "accent_amount": 0.42,
        "roughness": 0.90,
        "height_scale": 21.0,
        "glow_color": (0.95, 0.25, 0.35),
        "glow_below": 0.72,
        "glow_strength": 2.4,
        "pillar_glb": "castle/wall-pillar.glb",
        "pillar_scale": 3.5,
        "landmarks": [
            ("castle/siege-trebuchet.glb", (-24.0, -10.0), 3.4, 25.0, 3.2),
            ("castle/siege-trebuchet.glb", (24.0, -10.0), 3.4, -25.0, 3.2),
            ("castle/siege-catapult.glb", (-20.0, 14.0), 3.4, 15.0, 3.0),
            ("castle/siege-catapult.glb", (20.0, 14.0), 3.4, -15.0, 3.0),
            ("survival/fence-fortified.glb", (-14.0, -4.0), 5.5, 0.0, 2.5),
            ("survival/fence-fortified.glb", (14.0, -4.0), 5.5, 0.0, 2.5),
            ("castle/tower-square-base.glb", (0.0, 24.0), 5.0, 0.0, 3.2),
            ("space/turret_double.glb", (-28.0, 4.0), 4.5, 45.0, 2.5),
            ("space/turret_double.glb", (28.0, 4.0), 4.5, -45.0, 2.5),
        ],
        "scatter": [
            ("space/craterLarge.glb", 5.5),
            ("castle/siege-ram-demolished.glb", 2.8),
            ("survival/barrel.glb", 2.2),
            ("nature/rock_tallG.glb", 5.0),
        ],
        "cliff_glb": "nature/cliff_block_rock.glb",
    },
}


# ------------------------------------------------------------------------------
# 5. HELPER TO FORMAT GODOT .TSCN TRANSFORM3D & RESOURCES
# ------------------------------------------------------------------------------
def fmt_transform(x: float, y: float, z: float, scale: float = 1.0, yaw_deg: float = 0.0) -> str:
    rad = math.radians(yaw_deg)
    c = math.cos(rad) * scale
    s = math.sin(rad) * scale
    return f"Transform3D({c:.4f}, 0, {s:.4f}, 0, {scale:.4f}, 0, {-s:.4f}, 0, {c:.4f}, {x:.3f}, {y:.3f}, {z:.3f})"


def find_safe_xz(x: float, z: float, keep_clear: list[tuple[float, float, float]]) -> tuple[float, float]:
    """Nudges (x, z) outward if it overlaps any interactive gameplay entity."""
    for _ in range(12):
        conflict = False
        for kx, kz, kr in keep_clear:
            dx = x - kx
            dz = z - kz
            dist = math.hypot(dx, dz)
            if dist < kr:
                conflict = True
                ang = math.atan2(dz, dx) if dist > 0.01 else 0.7
                x = kx + math.cos(ang) * (kr + 1.5)
                z = kz + math.sin(ang) * (kr + 1.5)
        if not conflict:
            break
    return x, z


def build_map_tscn(map_id: str, mdata: dict, height_at) -> None:
    theme = mdata["theme"]
    preset = BIOME_PRESETS.get(theme, BIOME_PRESETS["TECH_ARK"])
    bp = mdata["boss_pit"]
    bp_x, _, bp_z = bp["pos"]
    bp_rad = bp["radius"]
    bp_name = bp["name"]

    # Build keep-clear list around interactive gameplay entities & boss pit center
    keep_clear = [(bp_x, bp_z, bp_rad + 2.5), (0.0, 0.0, 6.5)]
    for ex, ez in mdata["entity_xz"]:
        keep_clear.append((ex, ez, 4.8))

    # Track external resources (path -> (type, id))
    ext_res = {}
    ext_list = []

    def add_ext(res_path: str, res_type: str) -> str:
        if res_path not in ext_res:
            rid = f"{len(ext_list) + 1}_res"
            ext_res[res_path] = rid
            ext_list.append((res_type, res_path, rid))
        return ext_res[res_path]

    id_map_scene = add_ext("res://scripts/map_scene.gd", "Script")
    id_map_terrain = add_ext("res://scripts/map_terrain.gd", "Script")
    id_sky = add_ext(f"res://assets/sky/{preset['sky']}", "Texture2D")
    id_hmap = add_ext(f"res://assets/heightmaps/{map_id}.png", "Texture2D")

    g_tex = preset["ground"]
    a_tex = preset["accent"]
    c_tex = preset["cliff"]
    id_g_diff = add_ext(f"res://assets/textures/{g_tex}_diff.jpg", "Texture2D")
    id_g_nor = add_ext(f"res://assets/textures/{g_tex}_nor.jpg", "Texture2D")
    id_a_diff = add_ext(f"res://assets/textures/{a_tex}_diff.jpg", "Texture2D")
    id_c_diff = add_ext(f"res://assets/textures/{c_tex}_diff.jpg", "Texture2D")

    id_pillar_glb = add_ext(f"res://assets/props/kenney/{preset['pillar_glb']}", "PackedScene")
    id_brazier_glb = add_ext("res://assets/props/kenney/graveyard/fire-basket.glb", "PackedScene")
    id_cliff_glb = add_ext(f"res://assets/props/kenney/{preset['cliff_glb']}", "PackedScene")

    for glb_rel, _, _, _, _ in preset["landmarks"]:
        add_ext(f"res://assets/props/kenney/{glb_rel}", "PackedScene")
    for glb_rel, _ in preset["scatter"]:
        add_ext(f"res://assets/props/kenney/{glb_rel}", "PackedScene")

    # Sub-resources for Boss Pit floor, glowing rune disk, and optional Megaspire / Halo
    sub_list = []

    def add_sub(s_type: str, body_lines: list[str]) -> str:
        sid = f"SubResource_{len(sub_list) + 1}"
        sub_list.append((s_type, sid, body_lines))
        return sid

    glow_r, glow_g, glow_b = preset["glow_color"]
    if preset["glow_strength"] <= 0.0:
        glow_r, glow_g, glow_b = preset["sun_color"]

    sub_pit_cyl = add_sub(
        "CylinderMesh",
        [
            f"top_radius = {bp_rad:.2f}",
            f"bottom_radius = {bp_rad + 0.8:.2f}",
            "height = 0.3",
        ],
    )
    sub_pit_mat = add_sub(
        "StandardMaterial3D",
        [
            "albedo_color = Color(0.14, 0.15, 0.18, 1)",
            f'albedo_texture = ExtResource("{id_g_diff}")',
            "uv1_scale = Vector3(4, 4, 4)",
            "roughness = 0.82",
        ],
    )
    sub_rune_cyl = add_sub(
        "CylinderMesh",
        [
            f"top_radius = {bp_rad * 0.46:.2f}",
            f"bottom_radius = {bp_rad * 0.49:.2f}",
            "height = 0.08",
        ],
    )
    sub_rune_mat = add_sub(
        "StandardMaterial3D",
        [
            f"albedo_color = Color({glow_r:.3f}, {glow_g:.3f}, {glow_b:.3f}, 1)",
            "emission_enabled = true",
            f"emission = Color({glow_r:.3f}, {glow_g:.3f}, {glow_b:.3f}, 1)",
            "emission_energy_multiplier = 2.2",
        ],
    )

    has_spire = preset.get("has_farr_megaspire", False)
    if has_spire:
        sub_spire_mesh = add_sub("PrismMesh", ["size = Vector3(5.2, 15.0, 5.2)"])
        sub_spire_mat = add_sub(
            "StandardMaterial3D",
            [
                "albedo_color = Color(1.0, 0.72, 0.16, 1)",
                "emission_enabled = true",
                "emission = Color(1.0, 0.68, 0.12, 1)",
                "emission_energy_multiplier = 2.8",
                "roughness = 0.18",
            ],
        )

    has_halo = preset.get("has_celestial_halo", False)
    if has_halo:
        hr, hg, hb = preset.get("halo_color", (1.0, 0.88, 0.4))
        sub_halo_mesh = add_sub(
            "TorusMesh",
            [
                "inner_radius = 6.2",
                "outer_radius = 6.8",
            ],
        )
        sub_halo_mat = add_sub(
            "StandardMaterial3D",
            [
                f"albedo_color = Color({hr:.3f}, {hg:.3f}, {hb:.3f}, 1)",
                "emission_enabled = true",
                f"emission = Color({hr:.3f}, {hg:.3f}, {hb:.3f}, 1)",
                "emission_energy_multiplier = 3.0",
            ],
        )

    nodes = []
    collision_shapes = []

    def add_col_cylinder(cx: float, cy: float, cz: float, radius: float, height: float, label: str):
        sid = add_sub("CylinderShape3D", [f"height = {height:.2f}", f"radius = {radius:.2f}"])
        collision_shapes.append((label, sid, cx, cy + height * 0.5, cz))

    # --- ROOT NODE: MapScene ---
    st_r, st_g, st_b = preset["sky_tint"]
    fc_r, fc_g, fc_b = preset["fog_color"]
    sc_r, sc_g, sc_b = preset["sun_color"]
    nodes.append(
        "\n".join(
            [
                f'[node name="{map_id}" type="Node3D"]',
                f'script = ExtResource("{id_map_scene}")',
                f'map_id = "{map_id}"',
                f'sky_hdri = ExtResource("{id_sky}")',
                f'sky_energy = {preset["sky_energy"]:.2f}',
                f"sky_tint = Color({st_r:.3f}, {st_g:.3f}, {st_b:.3f}, 1)",
                f"fog_color = Color({fc_r:.3f}, {fc_g:.3f}, {fc_b:.3f}, 1)",
                f'fog_density = {preset["fog_density"]:.4f}',
                f'ambient_energy = {preset["ambient_energy"]:.2f}',
                f'exposure = {preset["exposure"]:.2f}',
                f'glow_intensity = {preset["glow_intensity"]:.2f}',
                f"sun_color = Color({sc_r:.3f}, {sc_g:.3f}, {sc_b:.3f}, 1)",
                f'sun_energy = {preset["sun_energy"]:.2f}',
                f'sun_pitch_deg = {preset["sun_pitch"]:.1f}',
                f'sun_yaw_deg = {preset["sun_yaw"]:.1f}',
            ]
        )
    )

    # --- Environment & Sun preview nodes ---
    nodes.append('[node name="Environment" type="WorldEnvironment" parent="."]')
    nodes.append('[node name="Sun" type="DirectionalLight3D" parent="."]\nshadow_enabled = true')

    # --- Terrain (MapTerrain) ---
    gt_r, gt_g, gt_b = preset["ground_tint"]
    at_r, at_g, at_b = preset["accent_tint"]
    ct_r, ct_g, ct_b = preset["cliff_tint"]
    gl_r, gl_g, gl_b = preset["glow_color"]
    nodes.append(
        "\n".join(
            [
                '[node name="Terrain" type="Node3D" parent="."]',
                f'script = ExtResource("{id_map_terrain}")',
                "size = 250.0",
                f'heightmap = ExtResource("{id_hmap}")',
                f'height_scale = {preset["height_scale"]:.1f}',
                "resolution = 169",
                "smooth_passes = 2",
                f'ground_albedo = ExtResource("{id_g_diff}")',
                f'ground_normal = ExtResource("{id_g_nor}")',
                f'accent_albedo = ExtResource("{id_a_diff}")',
                f'cliff_albedo = ExtResource("{id_c_diff}")',
                f"ground_tint = Color({gt_r:.3f}, {gt_g:.3f}, {gt_b:.3f}, 1)",
                f"accent_tint = Color({at_r:.3f}, {at_g:.3f}, {at_b:.3f}, 1)",
                f"cliff_tint = Color({ct_r:.3f}, {ct_g:.3f}, {ct_b:.3f}, 1)",
                f'accent_amount = {preset["accent_amount"]:.2f}',
                "ground_tile_metres = 7.5",
                "cliff_tile_metres = 9.5",
                f'roughness = {preset["roughness"]:.2f}',
                f"glow_color = Color({gl_r:.3f}, {gl_g:.3f}, {gl_b:.3f}, 1)",
                f'glow_below_height = {preset["glow_below"]:.2f}',
                f'glow_strength = {preset["glow_strength"]:.2f}',
            ]
        )
    )

    # --- BossPit Group ---
    nodes.append('[node name="BossPit" type="Node3D" parent="."]')
    bp_y = height_at(bp_x, bp_z)
    nodes.append(
        "\n".join(
            [
                '[node name="ArenaFloor" type="MeshInstance3D" parent="BossPit"]',
                f"transform = {fmt_transform(bp_x, bp_y + 0.05, bp_z)}",
                f'mesh = SubResource("{sub_pit_cyl}")',
                f'material_override = SubResource("{sub_pit_mat}")',
                "metadata/y_offset = 0.05",
            ]
        )
    )
    nodes.append(
        "\n".join(
            [
                '[node name="ArenaRuneDisk" type="MeshInstance3D" parent="BossPit"]',
                f"transform = {fmt_transform(bp_x, bp_y + 0.18, bp_z)}",
                f'mesh = SubResource("{sub_rune_cyl}")',
                f'material_override = SubResource("{sub_rune_mat}")',
                "metadata/y_offset = 0.18",
            ]
        )
    )
    nodes.append(
        "\n".join(
            [
                '[node name="ArenaLabel" type="Label3D" parent="BossPit"]',
                f"transform = {fmt_transform(bp_x, bp_y + 4.5, bp_z)}",
                "billboard = 1",
                "modulate = Color(1, 0.88, 0.42, 1)",
                f'text = "★ {bp_name} ★\\n[Boss Pit Arena]"',
                "font_size = 28",
                "metadata/y_offset = 4.5",
            ]
        )
    )

    p_scale = preset["pillar_scale"]
    for idx in range(8):
        ang = idx * (math.tau / 8.0)
        px = bp_x + math.cos(ang) * (bp_rad - 0.5)
        pz = bp_z + math.sin(ang) * (bp_rad - 0.5)
        py = height_at(px, pz)
        yaw_deg = math.degrees(-ang)
        nodes.append(
            "\n".join(
                [
                    f'[node name="PitPillar_{idx + 1}" parent="BossPit" instance=ExtResource("{id_pillar_glb}")]',
                    f"transform = {fmt_transform(px, py, pz, p_scale, yaw_deg)}",
                    "metadata/y_offset = 0.0",
                ]
            )
        )
        add_col_cylinder(px, py, pz, 0.75, 4.8, f"Col_PitPillar_{idx + 1}")
        if idx % 2 == 0:
            nodes.append(
                "\n".join(
                    [
                        f'[node name="PitBrazier_{idx + 1}" parent="BossPit" instance=ExtResource("{id_brazier_glb}")]',
                        f"transform = {fmt_transform(px, py + 0.1, pz, 3.6, yaw_deg)}",
                        "metadata/y_offset = 0.1",
                    ]
                )
            )

    # --- Landmarks Group (Real Kenney 3D Models + Set Pieces) ---
    nodes.append('[node name="Landmarks" type="Node3D" parent="."]')
    for idx, (glb_rel, (lx, lz), sc, yaw, col_r) in enumerate(preset["landmarks"]):
        sx, sz = find_safe_xz(lx, lz, keep_clear)
        keep_clear.append((sx, sz, col_r + 1.5))
        sy = height_at(sx, sz)
        rid = ext_res[f"res://assets/props/kenney/{glb_rel}"]
        base_name = os.path.splitext(os.path.basename(glb_rel))[0].replace("-", "_")
        nodes.append(
            "\n".join(
                [
                    f'[node name="Landmark_{idx + 1}_{base_name}" parent="Landmarks" instance=ExtResource("{rid}")]',
                    f"transform = {fmt_transform(sx, sy, sz, sc, yaw)}",
                    "metadata/y_offset = 0.0",
                ]
            )
        )
        add_col_cylinder(sx, sy, sz, col_r, 6.0, f"Col_Landmark_{idx + 1}")

    if has_spire:
        spx, spz = find_safe_xz(0.0, 3.5, keep_clear)
        spy = height_at(spx, spz)
        nodes.append(
            "\n".join(
                [
                    '[node name="CentralFarrMegaspire" type="MeshInstance3D" parent="Landmarks"]',
                    f"transform = {fmt_transform(spx, spy + 7.2, spz)}",
                    f'mesh = SubResource("{sub_spire_mesh}")',
                    f'material_override = SubResource("{sub_spire_mat}")',
                    "metadata/y_offset = 7.2",
                ]
            )
        )
        add_col_cylinder(spx, spy, spz, 2.4, 14.0, "Col_CentralFarrMegaspire")

    if has_halo:
        hy = height_at(0.0, 0.0)
        nodes.append(
            "\n".join(
                [
                    '[node name="CelestialHaloRing" type="MeshInstance3D" parent="Landmarks"]',
                    f"transform = Transform3D(1, 0, 0, 0, 0.2588, -0.9659, 0, 0.9659, 0.2588, 0.0, {hy + 9.5:.3f}, 0.0)",
                    f'mesh = SubResource("{sub_halo_mesh}")',
                    f'material_override = SubResource("{sub_halo_mat}")',
                    "metadata/y_offset = 9.5",
                ]
            )
        )

    # --- Props Group (Mid-field Biome Scatter + Perimeter Mountain Rim Rocks) ---
    nodes.append('[node name="Props" type="Node3D" parent="."]')
    scatter_list = preset["scatter"]
    seed = sum((idx + 1) * ord(ch) for idx, ch in enumerate(map_id))

    # 20 Mid-field scatter props (r = 34m .. 86m)
    for i in range(20):
        glb_rel, base_sc = scatter_list[i % len(scatter_list)]
        ang = i * (math.tau / 20.0) + ((seed % 13) * 0.17)
        dist = 36.0 + ((i * 19 + seed) % 48)
        px = math.cos(ang) * dist
        pz = math.sin(ang) * dist
        px, pz = find_safe_xz(px, pz, keep_clear)
        py = height_at(px, pz)
        sc = base_sc * (0.85 + 0.35 * ((i * 7 + seed) % 10) / 10.0)
        yaw = float((i * 53 + seed * 11) % 360)
        rid = ext_res[f"res://assets/props/kenney/{glb_rel}"]
        bname = os.path.splitext(os.path.basename(glb_rel))[0].replace("-", "_")
        nodes.append(
            "\n".join(
                [
                    f'[node name="Prop_{i + 1}_{bname}" parent="Props" instance=ExtResource("{rid}")]',
                    f"transform = {fmt_transform(px, py, pz, sc, yaw)}",
                    "metadata/y_offset = 0.0",
                ]
            )
        )

    # 16 Mountain Ridge Rock Outcrops embedded in the natural mountain slopes (r = 92m .. 104m)
    ridge_rock_glbs = [
        "nature/rock_tallA.glb",
        "nature/rock_tallB.glb",
        "nature/rock_largeD.glb",
        "nature/rock_tallF.glb",
    ]
    for r_glb in ridge_rock_glbs:
        add_ext(f"res://assets/props/kenney/{r_glb}", "PackedScene")

    for i in range(16):
        ang = i * (math.tau / 16.0) + 0.1
        r_dist = 94.0 + (i % 3) * 4.0
        rx = math.cos(ang) * r_dist
        rz = math.sin(ang) * r_dist
        ry = height_at(rx, rz) - 0.5
        sc = 6.0 + (i % 3) * 1.5
        yaw = float((i * 47) % 360)
        glb_choice = ridge_rock_glbs[i % len(ridge_rock_glbs)]
        rid_rock = ext_res[f"res://assets/props/kenney/{glb_choice}"]
        nodes.append(
            "\n".join(
                [
                    f'[node name="RidgeRock_{i + 1}" parent="Props" instance=ExtResource("{rid_rock}")]',
                    f"transform = {fmt_transform(rx, ry, rz, sc, yaw)}",
                    "metadata/y_offset = -0.5",
                ]
            )
        )
        add_col_cylinder(rx, ry, rz, 3.2, 7.0, f"Col_RidgeRock_{i + 1}")

    # --- Lights Group ---
    nodes.append('[node name="Lights" type="Node3D" parent="."]')
    light_coords = [
        (bp_x + bp_rad, bp_z, 3.8, 1.5, 16.0),
        (bp_x - bp_rad, bp_z, 3.8, 1.5, 16.0),
        (bp_x, bp_z + bp_rad, 3.8, 1.5, 16.0),
        (bp_x, bp_z - bp_rad, 3.8, 1.5, 16.0),
        (0.0, 22.0, 2.6, 1.8, 18.0),
        (-22.0, 12.0, 3.2, 1.4, 16.0),
        (22.0, 12.0, 3.2, 1.4, 16.0),
    ]
    for idx, (lx, lz, y_off, nrg, rng) in enumerate(light_coords):
        ly = height_at(lx, lz) + y_off
        nodes.append(
            "\n".join(
                [
                    f'[node name="ZoneLight_{idx + 1}" type="OmniLight3D" parent="Lights"]',
                    f"transform = {fmt_transform(lx, ly, lz)}",
                    f"light_color = Color({glow_r:.3f}, {glow_g:.3f}, {glow_b:.3f}, 1)",
                    f"light_energy = {nrg:.2f}",
                    f"omni_range = {rng:.1f}",
                    f"metadata/y_offset = {y_off:.2f}",
                ]
            )
        )

    # --- PropCollisions StaticBody3D ---
    nodes.append('[node name="PropCollisions" type="StaticBody3D" parent="."]')
    for cname, sid, cx, cy, cz in collision_shapes:
        nodes.append(
            "\n".join(
                [
                    f'[node name="{cname}" type="CollisionShape3D" parent="PropCollisions"]',
                    f"transform = {fmt_transform(cx, cy, cz)}",
                    f'shape = SubResource("{sid}")',
                ]
            )
        )

    # Assemble final .tscn file
    load_steps = 1 + len(ext_list) + len(sub_list)
    lines = [f'[gd_scene load_steps={load_steps} format=3]', ""]
    for rtype, rpath, rid in ext_list:
        lines.append(f'[ext_resource type="{rtype}" path="{rpath}" id="{rid}"]')
    lines.append("")
    for stype, sid, sbody in sub_list:
        lines.append(f'[sub_resource type="{stype}" id="{sid}"]')
        lines.extend(sbody)
        lines.append("")
    for nblock in nodes:
        lines.append(nblock)
        lines.append("")

    tscn_path = os.path.join(MAPS_DIR, f"{map_id}.tscn")
    with open(tscn_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    maps = parse_game_data_maps()
    print(f"Building {len(maps)} heightmaps and editable .tscn map scenes...")
    for idx, (map_id, mdata) in enumerate(maps.items(), 1):
        theme = mdata["theme"]
        preset = BIOME_PRESETS.get(theme, BIOME_PRESETS["TECH_ARK"])
        h_at = generate_heightmap_and_sampler(map_id, mdata, preset["height_scale"])
        build_map_tscn(map_id, mdata, h_at)
        print(f"  [{idx:02d}/{len(maps):02d}] {map_id:24s} ({theme}) -> maps/{map_id}.tscn + assets/heightmaps/{map_id}.png")
    print("All 30 maps built successfully!")


if __name__ == "__main__":
    main()
