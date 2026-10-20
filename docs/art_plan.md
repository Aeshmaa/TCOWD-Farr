# FARR: Art and Writing Plan

## 1. Writing: Story Bible, Not a Novel (Yet)

| Write now (small, steady) | Write later (when you build story mode) |
|---|---|
| World timeline (founding of the Var → the Crack) | Full cutscene scripts |
| 1 page per major character (Oracle, Dzahhakka, Aelfwyne, the Forsworn) | Quest dialogue |
| A one‑page outline per faction campaign (beginning, middle, end) | Item descriptions and barks |

**Why not a novel first:** Gameplay will change while you build it (classes, zones, the war). A finished novel would need rewriting. Cutscenes are also the most expensive asset in the game.

> [!TIP]
> If writing keeps you motivated, short **lore stories** (one Forsworn origin each, for example) make great **community and marketing content** later. Just don't let them block the prototype.

---

## 2. The 8‑Direction Problem (Read Before Drawing Anything)

Every animation has to be drawn **8 times**, once per direction.

| Animation | Frames |
|---|---|
| Idle | 4 |
| Walk | 8 |
| Light attack | 6 |
| Heavy attack | 8 |
| Mine (channel) | 6 |
| Hit | 2 |
| Death | 6 |
| **Total per direction** | **40** |

- **× 8 directions = 320 frames for ONE character look.**
- With mirroring (flip left ↔ right): **5 directions = 200 frames.**
- × 12 base classes × gear variations: impossible to draw by hand alone.

### Ways to make it doable
| Technique | How it helps |
|---|---|
| **Paper‑doll layers** | Draw body, armor, weapon and helmet as separate layers that swap independently. New gear means drawing one layer, not a whole character |
| **Mirroring** | Draw 5 directions and flip the other 3 |
| **3D → 2D pre‑render** *(strongly recommended)* | Model a low‑poly 3D character once (Blender) and render all 8 directions automatically. Diablo II and many modern 2.5D games work this way. You draw the **concept art and textures**; the computer does the angles |
| **4 directions** for monsters | Monsters can get away with fewer directions |

---

## 3. Vertical Slice Asset List (about 25 items)

| Category | Items |
|---|---|
| Player | Fabricator (on foot) + Titan Frame (mounted) |
| Enemy | 1 monster type + 1 rival miner (can reuse the player character with a palette swap) |
| World | Ground tileset/textures for 1 zone, 3–5 props (rocks, ruins, crashed ark debris) |
| Farr vein | 3 states (full, half, depleted) + a glow effect |
| Base | Refinery building, debt office NPC |
| UI | HUD (HP, weight, debt), inventory, mining progress bar |
| Icons | About 15 (ores, items, skills) |
| VFX | Mining sparks, hit flash, Siege Mode blast, death and loot drop |

## 4. Full Game (later)
- Concept art: 3 factions, 12 base classes, 24 advanced‑job looks, 3 Forsworn, Dzahhakka, the Oracle, Aelfwyne
- Monsters per zone, environments per zone, the Scar
- Faction emblems, UI skins per faction
- Story stills or cutscenes

---

## 5. AI Tools for Turning Your Imagination into Images

| Tool | Best for |
|---|---|
| **Antigravity image generator** (built into this chat) | Quick concept art from your descriptions. Ask me to do it |
| **PixelLab** | Pixel‑art characters, including **multi‑direction sprites** |
| **Retro Diffusion** | Pixel‑art assets and tiles |
| **Scenario.gg** | Train a model on *your own drawings* to keep the style consistent |
| **Stable Diffusion + ControlNet + LoRA** (local, free) | Full control: pose your own sketches, train on your style |
| **Adobe Firefly** | Trained on licensed images, the safest choice commercially |

> [!WARNING]
> - **Steam requires you to disclose** AI‑generated content.
> - Pure AI output generally **can't be copyrighted** (US). Your own edits and paintovers can be.
> - Some players react badly to AI art. **Best practice:** use AI for **concepts, references and ideas**, then make the final assets yourself (drawn, painted over, or modeled from the concepts).
