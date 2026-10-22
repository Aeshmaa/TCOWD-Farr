#!/usr/bin/env python3
"""Downloads CC0 textures + sky HDRIs from Poly Haven (polyhaven.com) into res://assets/.
Re-run safely; existing files are skipped. All Poly Haven assets are CC0."""
import json, os, sys, urllib.request
ROOT = os.path.join(os.path.dirname(__file__), "..", "assets")
TEXTURES = ["concrete_floor_worn_001", "metal_plate", "snow_02", "large_sandstone_blocks_01",
    "red_sandstone_pavement", "aerial_sand", "dry_ground_01", "burned_ground_01", "dark_rock",
    "dark_rock_02", "cliff_side", "aerial_ground_rock", "quarry_wall", "mossy_brick_floor",
    "old_stone_wall_02", "aerial_grass_rock", "marble_cliff_01", "brown_mud_rocks_01",
    "rusty_metal_02", "dry_ground_rocks", "medieval_blocks_02", "gray_rocks"]
SKIES = ["kloofendal_overcast_puresky", "qwantani_late_afternoon_puresky", "wasteland_clouds_puresky",
    "qwantani_dusk_2_puresky", "qwantani_night_puresky", "kloofendal_48d_partly_cloudy_puresky",
    "snow_field_puresky", "scythian_tombs_puresky", "kloofendal_misty_morning_puresky",
    "industrial_sunset_02_puresky"]
def get(url, dest):
    if os.path.exists(dest) and os.path.getsize(dest) > 1000: return
    req = urllib.request.Request(url, headers={"User-Agent": "farr-asset-fetch"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f: f.write(r.read())
def files(asset):
    with urllib.request.urlopen(urllib.request.Request(f"https://api.polyhaven.com/files/{asset}", headers={"User-Agent": "farr-asset-fetch"}), timeout=30) as r:
        return json.load(r)
for t in TEXTURES:
    try:
        f = files(t)
        get(f["Diffuse"]["1k"]["jpg"]["url"], f"{ROOT}/textures/{t}_diff.jpg")
        get(f["nor_gl"]["1k"]["jpg"]["url"], f"{ROOT}/textures/{t}_nor.jpg")
        print("tex ok", t)
    except Exception as e: print("tex FAIL", t, e)
for s in SKIES:
    try:
        f = files(s)
        get(f["hdri"]["1k"]["hdr"]["url"], f"{ROOT}/sky/{s}.hdr")
        print("sky ok", s)
    except Exception as e: print("sky FAIL", s, e)
