# FARR (Codename: TCOWD)

A 2.5D / 3D three-faction extraction and territorial war RPG built in **Godot 4 Standard (GDScript)**.

Inspired by *RF Online*, ancient Persian (Zoroastrian) mythology, and classic MMORPG combat systems.

---

## Quick Start & Cross-Platform Setup

### 1. Requirements
- **Godot 4.3+ or 4.7 Standard** (NOT the `.NET / C#` build — standard GDScript edition).
- Windows, macOS, or Linux.

### 2. Launching the Game
- Launch Godot -> click **Import** -> select `project.godot` inside this directory -> click **Import & Edit**.
- Press **F5** (or the Play button) to run the game immediately.
- Alternatively via command line:
  ```bash
  godot --path . scenes/main.tscn
  ```

---

## Documentation & AI Onboarding

All design, lore, and technical architecture specifications are tracked directly inside this repository:

| Document | Description |
| :--- | :--- |
| **[`docs/AI_DEVELOPER_GUIDE.md`](docs/AI_DEVELOPER_GUIDE.md)** | **Master Developer & AI Agent Guide**: Essential reading when starting a new session or onboarding on another PC. |
| **[`docs/lore_bible.md`](docs/lore_bible.md)** | **Lore Bible**: Zoroastrian myth roots, the 3 Factions, Leaders, World Bosses, and the Var shelter-world. |
| **[`docs/gamedata_reference.md`](docs/gamedata_reference.md)** | **Systems & Database**: 30 World Zones, 12 Base Classes, 24 Lv.30 Advanced Jobs, Weapon Stances, and Talics. |
| **[`docs/hud_layout_spec.md`](docs/hud_layout_spec.md)** | **HUD Layout Specification**: Top-Left Unit Frame, Top-Right Zone Navigation & Dev Drawer, Target Frame. |
| **[`docs/rf_quickskill_and_sky_showcase.md`](docs/rf_quickskill_and_sky_showcase.md)** | **Quickbar & Sky Overhaul**: 50x50 boxy quickskill bar mapping and 30-map starry sky system. |
| **[`docs/concepts/`](docs/concepts/)** | High-resolution concept art for all 3 World Bosses and 3 Faction Leaders. |

---

## Core Game Features
- **3 Asymmetric Factions**: Order of the Oracle (Holy/Asha), Legion of the Druj (Demonic/Chaos), and Sveleitre Colony Ark (Cybernetic AI).
- **30-Map World Network**: Safe HQs, Outposts, Borderlands, Resource Mining Craters, Dungeons, and Contested War Fronts.
- **RF Online-Style Quickskill Bar**: 10 square slots with custom picture icons, hotkey badges `[1-9, Z]`, consumable counters, cooldown overlays, and glowing active borders.
- **Dynamic Camera System**: Isometric projection `[V]`, 360° orbit (`[Space+Drag]` or `[Q]/[E]`), over-the-shoulder, and free-cam.
- **Inventory & Progression**: 5-bag inventory system `[I]`, auto-potion chargers, item upgrades with Talic crystals, and mining nodes.
