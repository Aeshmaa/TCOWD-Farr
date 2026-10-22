# FARR (TCOWD) — Master Developer & AI Onboarding Guide

> [!NOTE]
> **To any new Antigravity AI Agent or Developer:**
> This repository contains **FARR (Codename: TCOWD)**, a 2.5D/3D three-faction extraction and territorial war RPG built in **Godot 4 Standard (GDScript)**.
> When starting a new conversation or working on a new machine, **read this document first**. It contains everything required to understand the architecture, design philosophy, mechanics, and file structure without needing access to prior chat logs.

---

## 1. Executive Concept & Influences
- **Concept**: A dark sci-fi / dark fantasy three-faction persistent war RPG. Three asymmetric civilizations fight for control over the sealed shelter-world of the **Var**, mining divine glowing amber crystal ore (**Farr**) beneath a cracked celestial dome.
- **Tone**: Ancient Persian / Zoroastrian mythology fused with high-tech sci-fi (akin to *RF Online* meets *Dune* meets *Dark Souls*). Serious, atmospheric, non-cartoony.
- **Engine**: **Godot 4.3+ / 4.7 Standard** (GDScript, Forward+ / Compatibility renderer, cross-platform).

---

## 2. The Three Playable Factions

| Faction | Visual Identity | Ideology & Power | Signature Stance `[4]` |
| :--- | :--- | :--- | :--- |
| **Order of the Oracle** | Layered ivory, weathered white silk, burnished gold, sacred fire (*Atar*), bronze spears | Preserving Asha (Truth/Cosmic Order); attempting to stitch shut the sky fracture | **Royal Fravashi Summon**: Manifests a white-gold winged spirit that fights alongside the player |
| **Legion of the Druj** | Blackened bronze, obsidian plate, spiked chains, crimson-violet fire, curved shamshirs | Servants of the Serpent Tyrant (*Azii Dzahhakka*); worshipping Wrath and Chaos | **Dread-Titan Stance**: +35% Attack power, dark shadow flames, increased stagger |
| **Sveleitre Colony Ark** | Porcelain-white hulls, brushed carbon, glowing cyan data-filaments, robotic frames | Sentient AI machine race from a crashed colony ark (*Instance Zero*); logical conquest | **Siege Artillery Mode**: Locks down into a high-powered plasma cannon platform |

---

## 3. World Architecture: 30-Map Atlas
All 30 maps are defined in `scripts/game_data.gd` (`GameData.MAPS` and `GameData.MAP_ORDER`) and instantiated from `maps/<map_id>.tscn`.

1. **Safe Headquarters (Lv.1-12)**:
   - `order_hq` (Sovereign Sanctum)
   - `legion_hq` (Druj Obsidian Citadel)
   - `svel_hq` (Colony Ark Bridge)
2. **Outpost Waypoints (Lv.10-20)**:
   - `order_outpost`, `legion_outpost`, `svel_outpost`
3. **Core Mining & Crater Grounds (Lv.20-45)**:
   - `farr_mining_ground`, `mining_breach_ridge`, `mining_lower_crater`
4. **Borderlands & Contested Wilderness (Lv.15-35)**:
   - `border_sette`, `border_glacier`, `beast_plateau`, `steppes_highlands`
5. **Farming Niches & Resource Vaults (Lv.25-45)**:
   - `farm_caldera_magma`, `farm_deep_aquifer`, `farm_ether_sky`, `farm_relic_catacombs`
6. **Ancient Vaults & Deep Dungeons (Lv.35-50)**:
   - `dungeon_ark_core`, `dungeon_daeva_crypt`, `dungeon_sky_sanctum`, `dungeon_var_roots`
7. **Contested Battlegrounds & War Fronts (Lv.30-50)**:
   - `contested_cauldron`, `contested_steppes`, `cauldron_abyss`, `outcast_wasteland`, `sky_fracture_ridge`
8. **Basic Field Training Zones**:
   - `order_basic`, `legion_basic`, `svel_basic`

> [!TIP]
> **Sky & Environment Styling**:
> All maps feature starry night HDRIs (`assets/sky/*.hdr`) or custom 360° celestial panoramas (`celestial_stars_crack.png`, `cosmic_nebula_violet.png`, `cosmic_aurora_cyan.png`). In all map scenes and `scripts/map_scene.gd`, `fog_sky_affect = 0.05` ensures atmospheric fog never washes out the starry skies.

---

## 4. In-Game HUD Layout

The UI was restructured into an authentic, uncluttered MMORPG layout:

```
+---------------------------------------------------------------------------------------------------------------+
| [ TOP-LEFT: UNIT FRAME ]                                                         [ TOP-RIGHT: ZONE & NAV ]    |
| +-------------------------------------------------+                              +--------------------------+ |
| | Lv.4 Wrathborn (Frontline) <Legion of the Druj> |                              | 🧭 Druj Obsidian Citadel | |
| | HP [==============================] 535 / 535    |                              | Safe HQ / Lv.1-12        | |
| | FP [==============================] 200 / 200    |                              | [🛡️ Safe Sanctuary]      | |
| | SP [==============================] 296 / 296    |                              | Coords: X: 4.5  Z: -20.3 | |
| | 💰 2,230 SGL  | Debt: 12,368 SGL | Ammo: 120    |                              | [🗺️ World Map (30) [M]]  | |
| | Buffs: RF +15% [58s] | Stance: Native (2.7m)    |                              +--------------------------+ |
| +-------------------------------------------------+                              | [Bags][Story][HQ][Dev ▾] | |
|                                                                                  +--------------------------+ |
|                                                                                                               |
|                                       [ TOP-CENTER: TARGET FRAME ]                                            |
|                                       +--------------------------+                                            |
|                                       | Lv.10 Feral Servo-Hound  |                                            |
|                                       | HP: 260 / 260 (100%)     |                                            |
|                                       +--------------------------+                                            |
|                                                                                                               |
| [ BOTTOM-LEFT: LOG ]                        [ BOTTOM-CENTER: RF QUICKBAR ]                                    |
| > Defeated Servo-Hound!                     [1][2][3][4] | [5][6][7][8] | [9][Z]                              |
| > Ready.                                    (50x50 Boxy Quickslots with Icons & Badges)                       |
+---------------------------------------------------------------------------------------------------------------+
```

### Bottom Quickskill Bar (`SkillBarPanel`)
- **Geometry**: Compact 50×50px metallic square slots with dark steel borders, centered at the bottom of the screen.
- **Icons**: Dedicated pixel/vector picture icons in `assets/icons/skills/`:
  - `[1]` **Auto-Attack** (`attack.png`): Toggle weapon auto-attack. (Orange active border + `ON`).
  - `[2]` **Primary Burst / Cleave** (`cleave.png`): Single-target high burst. (Cooldown veil + `%.1fs`).
  - `[3]` **AoE Stomp** (`stomp.png`): Radial ground shockwave stagger. (Cooldown veil + `%.1fs`).
  - `[4]` **Signature Ability** (`signature.png`): Faction Siege/Fravashi/Titan stance. (Gold border + `ON`).
  - `[5]` **HP Potion** (`potion_hp.png`): Restores +350 HP. (Stack count badge + shared 2.0s CD).
  - `[6]` **FP Potion** (`potion_fp.png`): Restores +250 FP. (Stack count badge + shared 2.0s CD).
  - `[7]` **SP Potion** (`potion_sp.png`): Restores +300 SP. (Stack count badge + shared 2.0s CD).
  - `[8]` **Recall Scroll** (`scroll.png`): Instant warp to Safe HQ. (Stack count badge).
  - `[9 / B]` **RF Buff Suite** (`buff_suite.png`): +15% Dmg/Def, +25% Speed. (Green border + duration badge).
  - `[Z]` **Weapon Stance** (`weapon_stance.png`): Cycle Native / Fast (+25% Atk Spd) / Power (+30% Dmg).

---

## 5. Key Scripts & Architecture Reference

| File | Purpose & Responsibilities |
| :--- | :--- |
| [`scripts/game_data.gd`](file:///scripts/game_data.gd) | **Master Database**: 3 Factions, 12 Base Classes, 24 Lv.30 Advanced Jobs, 30 World Zones, Item definitions, Talic upgrades, Weapon Stances, Story Chapters. |
| [`scripts/player.gd`](file:///scripts/player.gd) | **Player Controller & Systems**: Click-to-move pathfinding, WASD movement, targeting, combat telemetry, bag management, auto-potion logic, mining logic. |
| [`scripts/hud.gd`](file:///scripts/hud.gd) | **HUD & UI Controller**: Manages all HUD panels, unit frame, quickslots, bags `[I]`, world map atlas `[M]`, settings `[Esc]`, story window `[N]`, dev drawer. |
| [`scripts/camera_rig.gd`](file:///scripts/camera_rig.gd) | **Camera Controller**: 360° orbit (`[Space+Drag]` or `[Q]/[E]`), camera modes (Isometric, Free Orbit, Over-the-Shoulder, Drone), projection toggle `[V]`. |
| [`scripts/world.gd`](file:///scripts/world.gd) | **World Loader**: Dynamically loads and switches active map scenes (`maps/<id>.tscn`), sets spawn points, handles environmental transitions. |
| [`scripts/map_scene.gd`](file:///scripts/map_scene.gd) | **Map Base**: Base script for all 30 map scenes. Configures environment sky, WorldEnvironment, lighting, fog settings, and mining nodes. |
| [`scripts/combat_vfx.gd`](file:///scripts/combat_vfx.gd) | **Combat Visual FX**: Generates floating hit sparks, AoE shockwaves, buff rings, and impact flashes. |
| [`scripts/sfx_manager.gd`](file:///scripts/sfx_manager.gd) | **Sound Effects Manager**: Synthesizes and plays retro-sci-fi audio previews with support for external `.wav` overrides in `assets/sfx/`. |

---

## 6. Development & Testing Commands

### Run the Game
Open the project in Godot 4 and press **F5**, or launch via CLI:
```bash
godot --path . scenes/main.tscn
```

### Validate Compilation (Headless Check)
```bash
godot --headless --editor --quit
```

### Capture In-Game Screenshot with HUD
```bash
godot --path . -s tools/shot.gd -- <map_id> <output_path.png> --hud
```
*Example:*
```bash
godot --path . -s tools/shot.gd -- svel_hq /tmp/test_hud.png 0 4 18 0 16 -10 --hud
```

---

## 7. How to Continue Development on a New Machine / New Chat

When opening this project on another computer:
1. `git clone https://github.com/Aeshmaa/TCOWD-Farr.git`
2. Open in Godot 4 Standard -> click **Import & Edit**.
3. In Antigravity (new chat), you can simply tell the assistant:
   > *"I am working on the FARR project in this workspace. Please read `docs/AI_DEVELOPER_GUIDE.md` to get up to speed on the lore, systems, HUD, and architecture, then help me with [your task]."*
4. The assistant will immediately understand the entire project context, architecture, code standards, and conventions.
