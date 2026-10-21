# FARR — GameData Library Reference (`scripts/game_data.gd`)

> [!IMPORTANT]
> **Where the GameData Library Lives in Your Project:**
> - **GDScript Source File**: [`scripts/game_data.gd`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/game_data.gd)
> - **Docs Reference Copy**: [`docs/gamedata_reference.md`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/docs/gamedata_reference.md)
>
> Every faction, currency, class ratio, Lv.30 job skill, equipment bracket, consumable stack size, and `+1` to `+7` Talic upgrade rate is defined in [`scripts/game_data.gd`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/game_data.gd).

---

## 1. Factions, Leaders, Currencies & Equipment Compatibility

| Faction | Leader | Currency | Debt Type | Exclusive `[4]` Racial Signature | Equipment Group |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Sveleitre** | *Instance Zero (Code Aelfwyne)* | **Ark Cycles (`CYC`)** | *Ark Debt* | `4: Siege Mode` (15m AoE Artillery) | `CHASSIS_SVEL` *(Sveleitre Only)* |
| **Order of the Oracle** | *The Oracle* | **Gold Darics (`DRC`)** | *Vow Debt* | `4: Call Fravashi` (Guardian Spirit Summon) | `ORGANIC_VAR` *(Shared with Legion)* |
| **Legion of the Druj** | *Azii Dzahhakka* | **Blood Sigils (`SGL`)** | *Pact Debt* | `4: Dread-Titan Mount` (+400 HP, +90% ATK) | `ORGANIC_VAR` *(Shared with Order)* |

---

## 2. All 12 Base Classes & 24 Lv.30 Advanced Job Skill Trees

### A. Sveleitre (`CHASSIS_SVEL`)
| Role | Base Class (`Lv.1–29`) | HP / FP / SP Multipliers | Base `[2]` & `[3]` Skills | Lv.30 Job Branch A (`[B]`) | Lv.30 Job Branch B (`[B]`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Frontline** | `Breaker` | `1.35x HP` / `0.75x FP` / `1.35x SP` | `Ram Cleave` / `Shock Stomp AoE` | **Juggernaut (Tank)**: `Aegis Piston Crush` (`SHIELD_TAUNT`: -40% Dmg 8s) & `Fortress Lockdown AoE` (`HEAL_SELF`) | **Shredder (Melee DPS)**: `Twin Ripper Overdrive` (`3.1x`, `LIFESTEAL`) & `Whirling Saw Tempest` (`2.5x AoE`) |
| **Ranged** | `Seeker` | `0.95x HP` / `0.90x FP` / `1.25x SP` | `Rail Piercer` / `Drone Barrage AoE` | **Railer (Sniper)**: `Hyper-Velocity Sabot` (`3.4x`, 15m, `ARMOR_PIERCE`) & `Orbital Rail Volley` | **Swarm Operator (Drones)**: `Hunter-Seeker Swarm` (`LIFESTEAL`) & `Carpet Drone Saturation` |
| **Caster** | `Nullifier` | `0.88x HP` / `1.50x FP` / `0.85x SP` | `Logic Spike` / `Null-Field AoE` | **Silencer (Anti-Magic)**: `Zero-Day Exploit` (`3.2x`, `ARMOR_PIERCE`) & `EMP Singularity Collapse` | **Patcher (Repair Healer)**: `Nanite Purge Beam` (`LIFESTEAL`) & `Ark Nanite Rebuild` (`HEAL_PULSE`: +45% HP) |
| **Specialist** | `Fabricator` (`1.4x` Mine) | `1.10x HP` / `1.05x FP` / `1.15x SP` | `Slag Cannon` / `Turret Salvo AoE` | **Siegeframe (Artillery)**: `Heavy Howitzer Shell` (`3.0x`, `ARMOR_PIERCE`) & `Cluster Barrage Protocol` | **Torque Engineer (Support)**: `Overclocked Plasma Torch` (`HEAL_SELF`) & `Field Repair & Shield Pulse` (`HEAL_PULSE`) |

### B. Order of the Oracle (`ORGANIC_VAR`)
| Role | Base Class (`Lv.1–29`) | HP / FP / SP Multipliers | Base `[2]` & `[3]` Skills | Lv.30 Job Branch A (`[B]`) | Lv.30 Job Branch B (`[B]`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Frontline** | `Rathaestar` | `1.38x HP` / `0.85x FP` / `1.30x SP` | `Sun Lance Thrust` / `Aegis Judgement AoE` | **Spenta Guard (Tank)**: `Immortal Shield Bash` (`SHIELD_TAUNT`) & `Vow of Asha Sanctuary` (`HEAL_SELF`) | **Charioteer (Lancer)**: `Solar Chariot Impale` (`3.1x`, `LIFESTEAL`) & `Golden Wheel Sweep AoE` |
| **Ranged** | `Vastryosh` | `0.95x HP` / `0.95x FP` / `1.25x SP` | `Arash Arrow` / `Varaghna Volley AoE` | **Arash Archer (Longbow)**: `Boundary-Splitter Arrow` (`3.45x`, 15.5m, `ARMOR_PIERCE`) & `Heaven's Rain of Arrows` | **Falconer (Scout)**: `Golden Falcon Dive` (`LIFESTEAL`) & `Verethragna Gale AoE` (`HEAL_SELF`) |
| **Caster** | `Athravan` | `0.88x HP` / `1.60x FP` / `0.85x SP` | `Atar Bolt` / `Pillar of Atar AoE` | **Flamecaller (Fire DPS)**: `Royal Fire of Farnbag` (`3.3x`, `ARMOR_PIERCE`) & `Solar Conflagration AoE` | **Haoma Priest (Healer)**: `Sacred Flame Rebuke` (`LIFESTEAL`) & `Haoma Benediction` (`HEAL_PULSE`: +45% HP) |
| **Specialist** | `Huiti` (`1.45x` Mine) | `1.10x HP` / `1.10x FP` / `1.15x SP` | `Relic Hammer` / `Sanctified Ward AoE` | **Relicsmith (Crafter)**: `Forge-Anvil Judgment` (`ARMOR_PIERCE`) & `Seal-Woven Bastion AoE` (`HEAL_PULSE`) | **Veinwright (Master Miner)**: `Crystal Resonance Strike` (`HEAL_SELF`) & `Tectonic Vein Shatter AoE` |

### C. Legion of the Druj (`ORGANIC_VAR`)
| Role | Base Class (`Lv.1–29`) | HP / FP / SP Multipliers | Base `[2]` & `[3]` Skills | Lv.30 Job Branch A (`[B]`) | Lv.30 Job Branch B (`[B]`) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Frontline** | `Wrathborn` | `1.28x HP` / `0.85x FP` / `1.35x SP` | `Aka Rend` / `Blood Quake AoE` | **Ravager (Berserker)**: `Crimson Frenzy Execution` (`3.25x`, `LIFESTEAL`) & `Slaughter Maelstrom AoE` (`LIFESTEAL`) | **Chainbound (Chain Tank)**: `Damavand Chain Hook` (`SHIELD_TAUNT`) & `Iron Shackle Rupture AoE` (`HEAL_SELF`) |
| **Ranged** | `Pairika` | `0.92x HP` / `1.00x FP` / `1.25x SP` | `Venom Spine` / `Hex Cloud AoE` | **Veilstalker (Assassin)**: `Phantom Heart-Seeker` (`3.4x`, `ARMOR_PIERCE`) & `Nightfall Fan of Spines` (`LIFESTEAL`) | **Hexarcher (Curse Bow)**: `Serpent-Venom Volley` (`LIFESTEAL`) & `Plague of Dzahhakka AoE` |
| **Caster** | `Yatu` | `0.88x HP` / `1.60x FP` / `0.85x SP` | `Hellfire Fang` / `Druj Nova AoE` | **Abyss Caller (Dark DPS)**: `Aka Manah Soul-Sear` (`3.35x`, `ARMOR_PIERCE`) & `Abyssal Eclipse Cataclysm` | **Bloodbinder (Drain Healer)**: `Sanguine Siphon Lash` (`LIFESTEAL`) & `Blood Covenant Ritual` (`HEAL_PULSE`) |
| **Specialist** | `Dregvant` (`1.35x` Mine) | `1.12x HP` / `1.05x FP` / `1.15x SP` | `Blight Spike` / `Corrupted Shrapnel AoE` | **Cursesmith (Titan Pilot)**: `Dread-Core Overcharge` (`HEAL_SELF`) & `Hellforged Shockwave AoE` (`SHIELD_TAUNT`) | **Blightminer (Saboteur)**: `Corrosive Vein Detonator` (`ARMOR_PIERCE`) & `Blight-Gas Eruption AoE` (`LIFESTEAL`) |

---

## 3. Equipment Brackets & 6 Slots (`WEAPON`, `HELMET`, `UPPER`, `LOWER`, `GLOVES`, `SHOES`)

| Tier | Req Lv | Bracket | Order & Legion (`ORGANIC_VAR`) | Sveleitre (`CHASSIS_SVEL`) | Acquisition | Base Piece Bonuses (Armor / Weapon) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | `Lv.1` | `Lv.1–15` | `Lv.1 Recruit Bronze` | `Lv.1 Stock MK-I` | Starter Gear | `+10 HP / +5 FP / +5 SP` (`+4 ATK` Wpn) |
| **2** | `Lv.10` | `Lv.1–15` | `Lv.12 Outpost Scale` | `Lv.12 Alloy MK-II` | HQ Vendor (`140`) or Mob Drop | `+35 HP / +15 FP / +14 SP` (`+18 ATK` Wpn) |
| **3** | `Lv.15` | `Lv.15–25` | `Lv.20 Var-Forged` | `Lv.20 Carapace MK-III` | HQ Vendor (`320`) or Elite Drop | `+75 HP / +32 FP / +28 SP` (`+42 ATK` Wpn) |
| **4** | `Lv.30` | `Lv.30–45` | `Lv.35 Relic-Woven` | `Lv.35 Quantum MK-IV` | HQ Vendor (`750`) or Elite Drop | `+145 HP / +65 FP / +55 SP` (`+88 ATK` Wpn) |
| **5** | `Lv.45` | `Lv.30–45 [RARE]` | `Lv.45 [RARE] Intense Scar` | `Lv.45 [RARE] Intense Overclock` | **Boss / Elite Drop ONLY** *(Never sold by NPC)* | `+310 HP / +135 FP / +110 SP` (`+180 ATK` Wpn) |
| **6** | `Lv.50` | `Lv.50 Archon` | `Lv.50 Archon Herald` | `Lv.50 Prime Instance` | Elected Archon Leader | `+500 HP / +220 FP / +185 SP` (`+290 ATK` Wpn) |

---

## 4. Hardcore RF-Style Farr Talic Upgrading (`+1` to `+7`)

**Farr Talic Crystals (`TALIC_FARR`) are NEVER sold for currency and NEVER given at startup.**
They can **only** be obtained from:
1. **Mini-Bosses / Elites (`Lv.25–34`)**: `22%` drop chance (`1x Talic`)
2. **High Elites / Field Bosses (`Lv.35–49`)**: `45%` drop chance (`1x Talic`)
3. **The 3 Forsworn World Bosses (`Lv.50` — *Aeshma*, *Yima*, *The Orphan Process*)**: `100%` guaranteed drop (`1x–2x Talics`)
4. **Repeatable Faction Bounty Quest (HQ Utility NPC)**: Turn in `3 Monster/Boss Kills + 10 Unrefined Farr Ore` → rewards **`+1x Farr Talic Crystal` + `350 Currency`**.

| Target `+Level` | Stat Multiplier | Success Rate | Failure Penalty | Visual Effect |
| :--- | :--- | :--- | :--- | :--- |
| **`+1`** | `1.14x` (`+14%`) | **85%** | Stays at `+0` (Talic consumed) | Standard |
| **`+2`** | `1.28x` (`+28%`) | **68%** | Stays at `+1` (Talic consumed) | Standard |
| **`+3`** | `1.42x` (`+42%`) | **50%** | Drops back to **`+1`** | Standard |
| **`+4`** | `1.56x` (`+56%`) | **32%** | Overload resets upgrade to **`+0`**! | Standard |
| **`+5`** | `1.70x` (`+70%`) | **18%** | Overload resets upgrade to **`+0`**! | Standard |
| **`+6`** | `1.84x` (`+84%`) | **8%** | Overload resets upgrade to **`+0`**! | **Glowing Masterwork Aura** |
| **`+7`** | `1.98x` (`+98%`) | **3%** | Overload resets upgrade to **`+0`**! | **Sovereign Masterwork Aura** |

---

## 6. 9-Map World Zone Architecture (`GameData.MAPS`)

Players travel between zones by walking into physical **3D Warp Portals** ([`WarpPortal`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/warp_portal.gd)) or opening the **World Map & Warp Atlas (`[M]`)**.

| Map ID | Zone Name | Category & Access | Level Band | Key Features, Bosses & Ore Nodes |
| :--- | :--- | :--- | :--- | :--- |
| **`svel_hq`** | **Ark-Zero Bastion** | **Sveleitre HQ** (`sveleitre` only) | Safe HQ / `Lv.1–12` | Core Refinery, 4 Side Vendor NPCs, HQ Rebirth NPC, Starter Vein, `Lv.3–10` Starter Mobs |
| **`svel_basic`** | **Cryo-Scrap Frontier** | **Sveleitre Basic Ground** (`sveleitre` only) | `Lv.12–28` | Forward Relay Rebirth NPC, 2 Frontier Veins, `Lv.14–25` Mobs + **`Sub-Core Overseer MK-IV (Mini-Boss Lv.28)`** |
| **`order_hq`** | **Asha High Sanctuary** | **Order HQ** (`order` only) | Safe HQ / `Lv.1–12` | Sacred Refinery, 4 Side Vendor NPCs, HQ Rebirth NPC, Starter Vein, `Lv.3–10` Starter Mobs |
| **`order_basic`** | **Sun-Bleached Terraces** | **Order Basic Ground** (`order` only) | `Lv.12–28` | Flame-Keeper Rebirth NPC, 2 Terrace Veins, `Lv.14–25` Mobs + **`Disgraced High Inquisitor (Mini-Boss Lv.28)`** |
| **`legion_hq`** | **Druj Obsidian Citadel** | **Legion HQ** (`legion` only) | Safe HQ / `Lv.1–12` | Blood Refinery, 4 Side Vendor NPCs, HQ Rebirth NPC, Starter Vein, `Lv.3–10` Starter Mobs |
| **`legion_basic`** | **Ashen Blood-Basin** | **Legion Basic Ground** (`legion` only) | `Lv.12–28` | Soul-Binder Rebirth NPC, 2 Basin Veins, `Lv.14–25` Mobs + **`Aka-Manah War-Executioner (Mini-Boss Lv.28)`** |
| **`contested_steppes`** | **Shattered Persepolis Steppes** | **Contested Upper Ground 1** (All 3 Factions) | `Lv.28–38` + Boss | 3 Faction Outpost Rebirth NPCs, 4 Contested Grinding Spots (`Lv.28–38`), World Boss **`Yima, the Hollow King (Lv.50)`** |
| **`contested_cauldron`** | **Scorched Var Cauldron** | **Contested Upper Ground 2** (All 3 Factions) | `Lv.36–45` + Bosses | Endgame Contested Grinding Spots (`Lv.38–44`), World Bosses **`Aeshma, the Wrath Unbound (Lv.50)`** & **`The Orphan Process (Lv.50)`** |
| **`farr_mining_ground`** | **The Crack — Central Farr Mining Ground** | **Central Ore War Zone** (All 3 Factions) | `Lv.25–50` PvPvE Ore War | 3 Faction Breach Camps, **3x Contested Rich Farr Veins**, **2x Scar Megavein Cores**, **Contested Field Refinery**, **`Crack Core Arch-Leviathan (Lv.45)`** |

---

## 7. 3D Faction Leader NPCs, 15-Chapter Story Campaign (`[N]`) & Illustrated Lore Codex

Every Faction HQ (`svel_hq`, `order_hq`, `legion_hq`) now features its **3D Faction Sovereign (`LEADER` NPC, `1.65x` scale)** standing at the center of the citadel, alongside the **`Story & Lore [N]`** campaign & codex window (`[N]` key or `TopBar` button):

| Faction | 3D Sovereign NPC in HQ | 5-Chapter Narrative Arc (`STORY_CAMPAIGNS`) | Chapter V Finale Reward |
|---|---|---|---|
| **Sveleitre (Machine Exodus)** | **`INSTANCE ZERO: CODE AELFWYNE`** | **Ch.I** *Cold Boot in a Fallen World* (`svel_hq`) $\rightarrow$ **Ch.II** *Clearing the Hull Breach* (`svel_basic`) $\rightarrow$ **Ch.III** *The Hollow King's Drain* (`contested_steppes`) $\rightarrow$ **Ch.IV** *Blood on the Ignition Veins* (`farr_mining_ground`) $\rightarrow$ **Ch.V** *Reclaiming the Orphaned Fork* (`contested_cauldron`) | `+2,500 CYC`, `-2,500 Ark Debt`, `+5x Farr Talic`, Boost to `Lv.45`, **`+3 Sovereign Masterwork Weapon`** |
| **Order of the Oracle (Asha)** | **`THE ORACLE, VOICE OF THE SEAL`** | **Ch.I** *TheWeight of the Blindfold* (`order_hq`) $\rightarrow$ **Ch.II** *Purging the Profaned Terraces* (`order_basic`) $\rightarrow$ **Ch.III** *The Fall of King Yima* (`contested_steppes`) $\rightarrow$ **Ch.IV** *Stanching the Sky's Wound* (`farr_mining_ground`) $\rightarrow$ **Ch.V** *He of the Bloody Mace* (`contested_cauldron`) | `+2,500 DRC`, `-2,500 Vow Debt`, `+5x Farr Talic`, Boost to `Lv.45`, **`+3 Sovereign Masterwork Weapon`** |
| **Legion of the Druj (Ahriman)** | **`AZII DZAHHAKKA, HERALD OF DRUJ`** | **Ch.I** *Whispers of the Two Serpents* (`legion_hq`) $\rightarrow$ **Ch.II** *Feeding the Basalt Trenches* (`legion_basic`) $\rightarrow$ **Ch.III** *Devouring the Hollow King* (`contested_steppes`) $\rightarrow$ **Ch.IV** *Shattering the Sky-Prison* (`farr_mining_ground`) $\rightarrow$ **Ch.V** *Subjugating the Unbound Wrath* (`contested_cauldron`) | `+2,500 SGL`, `-2,500 Pact Debt`, `+5x Farr Talic`, Boost to `Lv.45`, **`+3 Sovereign Masterwork Weapon`** |

- **Illustrated Lore Codex (`LORE_CODEX_ENTRIES`):** Browse all **6 full-color concept art portraits & lore dossiers** directly in-game (`Instance Zero: Code Aelfwyne`, `The Oracle`, `Azii Dzahhakka`, `Aeshma, the Wrath Unbound`, `Yima, the Hollow King`, and `The Orphan Process`).

---

## 8. `[Tab]` Target Priority Options, In-Game Settings (`[Esc]`) & Procedural/Custom Audio (`SfxManager`)

- **`[Tab]` Target Priority Modes** (switchable in `Settings [Esc]`):
  1. **`Closest to Mouse Cursor`** *(Default)* — projects each enemy's 3D position onto your 2D viewport and locks onto the living enemy nearest your mouse cursor.
  2. **`Lowest HP First (Finish Off)`** — locks onto the enemy with the lowest current HP percentage within `28m`.
  3. **`Closest to Character (3D Distance)`** — locks onto the nearest enemy to your character's 3D position.
- **Audio & Special Effects (`scripts/sfx_manager.gd`):** Synthesizes 10 16-bit PCM `AudioStreamWAV` effects in memory (`target_lock`, `attack_hit`, `skill_cast`, `damage_taken`, `heal`, `mine_ore`, `upgrade_success`, `upgrade_fail`, `warp_portal`, `level_up`) and automatically overrides any cue if you drop a matching `.wav` or `.ogg` file into `res://assets/sfx/`.

