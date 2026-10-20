# FARR (Codename: TCOWD)

2.5D three-faction extraction & war RPG built in **Godot 4.7.2 (Standard / GDScript)**.

## Phase 1 Foundation (Included)
- **Isometric Orthographic Camera** ([`scripts/camera_rig.gd`](scripts/camera_rig.gd)): 30° pitch, 45° yaw, smooth target follow, mouse-wheel zoom.
- **8-Direction Billboard Sprite** ([`scripts/directional_sprite.gd`](scripts/directional_sprite.gd)): `Sprite3D` with Y-billboard that selects 1 of 8 directional columns relative to the camera angle (generates a procedural 8-direction placeholder sheet until real spritesheets are added).
- **NavMesh Click-to-Move + WASD Controller** ([`scripts/player.gd`](scripts/player.gd)): RF-style left-click/hold pathfinding around 3D obstacles via `NavigationAgent3D`, plus camera-relative WASD movement.
- **Greybox Test Arena** ([`scenes/main.tscn`](scenes/main.tscn)): auto-baked `NavigationRegion3D` with pillars, a ruined wall, and a glowing Farr vein placeholder.

## Syncing Between MacBook and RTX PC
1. Install **Godot 4.7.2 Standard** (NOT the `.NET` version) on both machines.
2. Push this repo to a private GitHub repository and clone it on the RTX PC.
3. `.gitignore` excludes `.godot/` (local cache) and `.gitattributes` keeps line endings consistent between macOS and Windows.
