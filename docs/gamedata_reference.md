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

## 6. Complete 30-Map World Zone Architecture (`GameData.MAPS` & `GameData.MAP_ORDER`)

Players travel between zones by walking into physical **3D Warp Portals** ([`WarpPortal`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/warp_portal.gd)) or opening the **World Map & Warp Atlas (`[M]`)**, which features a scrollable 30-zone directory with level bands and economic farming badges.

### 6.1 Specialized Farming Focus Multipliers (`scripts/player.gd`)
Mirroring RF Online's design where distinct zones serve dedicated player progression goals (e.g. Ether for currency farming, Volcanic Cauldron for Talics, Outcast/Beast for rare armor, and the Crag for Chip Wars), each zone has an active `farming_focus`:
- **`WEALTH_CREDITS`** (e.g. *Aetherium Sky-Platforms*): **`2.5x` Currency Bounty** on every monster kill (Calliana-style wealth farm).
- **`TALIC_FARMING`** (e.g. *Great Volcanic Caldera*): **Double Talic Drops** (two independent rolls on all mini-boss and pit boss talic drops).
- **`RARE_GEAR`** (e.g. *Catacombs of the First Kings*): **`65%` Rare Gear Drop Rate** (increased from base 20%).
- **`FORCE_POTIONS`** (e.g. *Luminescent Aqueduct*): Boosted FP potion caches and force catalysts.
- **`DUNGEON_LOOT`** (e.g. *Ancient Vaults & Deep Dungeons*): **`1.5x XP` Multiplier**, guaranteed multi-talics, and high-tier equipment caches.
- **`MEGAVEIN_EXTRACTION`** (e.g. *Abyssal Vein Core*): **`3x Farr Ore` Yield** per mining cycle (`12–18` ore per extraction).
- **`ORE_EXTRACTION` / `ARTILLERY_PVP`** (e.g. *The Crack Mining Ground* / *Ridge of Tri-Bastions*): Three-faction contested ore mining and strategic ridge warfare.
- **`ENDGAME_RAID` / `WORLD_BOSS`**: Apex world boss encounters with guaranteed masterwork weapons, multi-talics, and max currency bounties.

### 6.2 The Complete 30-Map Atlas Directory

| Tier | Map ID | Zone Name | Level Band | Farming Focus | Faction Access | Zone Pit Boss |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **T1: Safe HQs** | `svel_hq` | **Ark-Zero Bastion** | `Lv.1–12` | `HQ_SAFE` | `sveleitre` only | Arc-Reactor Overseer (`Lv.12`) |
| | `order_hq` | **Asha High Sanctuary** | `Lv.1–12` | `HQ_SAFE` | `order` only | Sanctuary Corrupted Golem (`Lv.12`) |
| | `legion_hq` | **Druj Obsidian Citadel** | `Lv.1–12` | `HQ_SAFE` | `legion` only | Obsidian Blood-Gargant (`Lv.12`) |
| **T2: Basic Leveling** | `svel_basic` | **Cryo-Scrap Frontier** | `Lv.12–25` | `BASIC_SOLO` | `sveleitre` only | Cryo-Conduit Dreadnought (`Lv.28`) |
| | `order_basic` | **Sun-Bleached Terraces** | `Lv.12–25` | `BASIC_SOLO` | `order` only | Azur-Fravashi Zealot (`Lv.28`) |
| | `legion_basic` | **Ashen Blood-Basin** | `Lv.12–25` | `BASIC_SOLO` | `legion` only | Aka-Manah War-Executioner (`Lv.28`) |
| **T3: Outposts** | `svel_outpost` | **Sub-Deck Turbine Chasm (Outpost 117)** | `Lv.22–32` | `COMPONENT_SALVAGE` | `sveleitre` only | Sub-Deck Turbine Colossus (`Lv.30`) |
| | `order_outpost` | **Pilgrim's Oasis Sanctuary (Solus Outpost)** | `Lv.22–32` | `RESTORATIVE_HERBS` | `order` only | Oasis Guardian Fravashi (`Lv.30`) |
| | `legion_outpost` | **Brimstone Quarry Fortress (Anacaade)** | `Lv.22–32` | `MINERAL_ARMOR` | `legion` only | Quarry Slag-Behemoth (`Lv.30`) |
| **T4: Borderlands** | `border_sette` | **The Sette Dune Sea** | `Lv.30–38` | `PVP_BOUNTY` | All 3 Factions | Dune-Stalker Arch-Scorpion (`Lv.35`) |
| | `border_glacier` | **Permafrost Rift Valley** | `Lv.30–38` | `CRYO_CORE` | All 3 Factions | Permafrost Cryo-Titan (`Lv.35`) |
| | `border_trench` | **Basalt Divide Trenches** | `Lv.30–38` | `PIERCING_AMMO` | All 3 Factions | Trench-Breaker Dread-Gorger (`Lv.35`) |
| **T5: Economic Farms** | `farm_ether_sky` | **Aetherium Floating Platforms (The Sky Floe)** | `Lv.36–42` | `WEALTH_CREDITS` *(2.5x Currency)* | All 3 Factions | Aether-Core Arch-Valkyrie (`Lv.40`) |
| | `farm_caldera_magma` | **The Great Volcanic Caldera** | `Lv.38–46` | `TALIC_FARMING` *(2x Talic Drops)* | All 3 Factions | Magma-Maw Drake-Tyrant (`Lv.44`) |
| | `farm_relic_catacombs` | **Catacombs of the First Kings** | `Lv.38–46` | `RARE_GEAR` *(65% Drop Rate)* | All 3 Factions | Catacomb Tomb-Sovereign (`Lv.44`) |
| | `farm_deep_aquifer` | **Subterranean Luminescent Aqueduct** | `Lv.36–44` | `FORCE_POTIONS` | All 3 Factions | Aqueduct Hydra-Serpent (`Lv.42`) |
| **T6: Upper Contested** | `contested_steppes` | **Shattered Persepolis Steppes** | `Lv.38–48` | `WORLD_BOSS` | All 3 Factions | Persepolis Ruin Goliath (`Lv.38`) + **Yima (`Lv.50`)** |
| | `contested_cauldron` | **Scorched Var Cauldron** | `Lv.40–50` | `WORLD_BOSS` | All 3 Factions | Abyssal Daeva Overlord (`Lv.44`) + **Aeshma & Orphan Process (`Lv.50`)** |
| | `steppes_highlands` | **Persepolis Upper Royal Terrace** | `Lv.42–50` | `SOVEREIGN_TALICS` | All 3 Factions | Royal Apadana Colossus (`Lv.48`) |
| | `cauldron_abyss` | **The Daevic Chasm of Druj** | `Lv.44–50` | `DARK_ESSENCE` | All 3 Factions | Chasm Void-Leviathan (`Lv.48`) |
| **T7: The Crack War** | `farr_mining_ground` | **The Crack — Central Farr Mining Ground** | `Lv.25–50` | `ORE_EXTRACTION` *(Chip/Vein War)* | All 3 Factions | Crack Core Arch-Leviathan (`Lv.45`) |
| | `mining_lower_crater` | **The Abyssal Vein Core (Lower Mining Ground)** | `Lv.45–52` | `MEGAVEIN_EXTRACTION` *(3x Ore)* | All 3 Factions | Core Drill Overclocker (`Lv.48`) |
| | `mining_breach_ridge` | **The Ridge of Tri-Bastions** | `Lv.35–50` | `ARTILLERY_PVP` | All 3 Factions | Siege-Bastion Sentinel (`Lv.45`) |
| **T8: Beast Highlands**| `beast_plateau` | **The Great Beast Plateau** | `Lv.45–52` | `CHITIN_ARMOR` | All 3 Factions | Chitin Queen Skorpion (`Lv.48`) |
| | `outcast_wasteland` | **Wastelands of the Forsworn** | `Lv.46–52` | `EXILE_WEAPONS` | All 3 Factions | Exile Warlord Rostam (`Lv.48`) |
| | `sky_fracture_ridge` | **Sky-Fracture Pinnacle** | `Lv.48–54` | `COSMIC_TALICS` | All 3 Factions | Dome-Breach Sky-Colossus (`Lv.50`) |
| **T9: Ancient Vaults** | `dungeon_ark_core` | **Ark-Zero Mainframe Supercore** | `Lv.45–52` | `DUNGEON_LOOT` *(1.5x XP)* | All 3 Factions | Mainframe Purge Sentinel (`Lv.50`) |
| | `dungeon_var_roots` | **The Foundations of the Var** | `Lv.46–54` | `DUNGEON_LOOT` *(1.5x XP)* | All 3 Factions | Foundation Titan of Yima (`Lv.50`) |
| | `dungeon_daeva_crypt` | **Crypt of the Seven Corrupted Daevas** | `Lv.48–55` | `DUNGEON_LOOT` *(1.5x XP)* | All 3 Factions | Arch-Daeva of Despair (`Lv.52`) |
| | `dungeon_sky_sanctum` | **The Celestial Seal Sanctum** | `Lv.50–55` | `ENDGAME_RAID` *(Apex Vault)* | All 3 Factions | Celestial Seraph of Asha (`Lv.55`) |

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

## 8. `[Tab]` Target Priority Options, In-Game Settings (`[Esc]`) & Audio Architecture (`SfxManager` & `BgmManager`)

- **`[Tab]` Target Priority Modes** (switchable in `Settings [Esc]`):
  1. **`Closest to Mouse Cursor`** *(Default)* — projects each enemy's 3D position onto your 2D viewport and locks onto the living enemy nearest your mouse cursor.
  2. **`Lowest HP First (Finish Off)`** — locks onto the enemy with the lowest current HP percentage within `28m`.
  3. **`Closest to Character (3D Distance)`** — locks onto the nearest enemy to your character's 3D position.

- **Special Effects Audio (`scripts/sfx_manager.gd`):** Synthesizes 12 16-bit PCM `AudioStreamWAV` effects in memory (`target_lock`, `attack_hit`, `ranged_shot`, `skill_cast`, `buff_cast`, `damage_taken`, `heal`, `mine_ore`, `upgrade_success`, `upgrade_fail`, `warp_portal`, `level_up`) and automatically overrides any cue if you drop a matching `.wav` or `.ogg` file into `res://assets/sfx/`.

- **Background Music & Soundscapes (`scripts/bgm_manager.gd`):**
  - **Procedural Ambient Soundscapes:** Synthesizes seamless, non-repetitive harmonic audio loops in memory for all biome themes (cybernetic drone in `TECH_ARK`, sacred modal flute/choir pads in `HOLY_TEMPLE`, tectonic subterranean rumble in `MAGMA_CALDERA`, martial industrial war percussion in `CRACK_MINING`, celestial fifths in `AETHER_SKY`, etc.).
  - **Seamless Cross-fading:** Uses dual `AudioStreamPlayer` nodes to smoothly cross-fade music over `1.2 seconds` when transitioning across maps.
  - **Custom Soundtrack Support:** Automatically checks `res://assets/music/<map_id>.ogg` (or `.wav`) and `res://assets/music/<theme>.ogg` (or `.wav`). Drop any custom track into that folder to hear it in-game immediately!
  - **Independent Volume Controls:** Adjust both **SFX Volume** and **BGM Volume** independently in `Settings [Esc]`.

---

## 9. Weapon Class Stances (`[Z]`), Cross-Class Ranged Limits, 3D Projectile/Slash VFX & RF Buff Suite (`[B]`)

### 9.1 Weapon Class Stances (`[Z]` / `Weap [Z]` Button)
Just like RF Online where any class can equip a Melee weapon up close or a Ranged bow/rifle to pull enemies from a distance (with cross-class range/damage limits), press **`[Z]`** (or click **`Weap [Z]`** on the bottom Skill Bar) to cycle between 4 Weapon Modes (`GameData.WEAPON_STANCES`):

| Weapon Stance (`[Z]`) | Native Class Range & ATK | Cross-Class Range & ATK Limit | Ammo / Force Cost | 3D Attack Visual (`scripts/combat_vfx.gd`) |
|---|---|---|---|---|
| **`AUTO (Class Native)`** | `100%` Class Range (`2.6m`–`9.5m`) & `100%` ATK | None (`100%` Synergy) | Per Class | Automatic per Class |
| **`MELEE (Blade/Mace/Lance)`** | **`2.8m` Close Distance**, `100%` ATK | **`2.8m` Close Distance**, `82%` ATK *(Rangers/Mages can fight up close with 0 Ammo!)* | **`0 Ammo`** | **3D Glowing Melee Slash Arc + Character Forward Lunge** |
| **`RANGED (Bow/Rifle/Launcher)`** | **`10.5m` Full Distance**, `100%` ATK | **`7.5m` Limited Distance**, `82%` ATK *(Melee Tanks/Warriors can pull & kite from range!)* | `-1 Ammo / Shot` | **3D High-Velocity Tracer Bolt / Arrow + Firing Kickback** |
| **`FORCE (Staff/Seal-Rod)`** | **`9.0m` Full Distance**, `100%` ATK | **`6.8m` Limited Distance**, `82%` ATK | `-1 Force Cell / Bolt` | **3D Luminous Force Orb + Tail Trail** |

### 9.2 RF Online-Style Self-Buff Suite (`[B]` or `[9]` / `9: RF Buffs [B]`)
Press **`[B]`** or **`[9]`** (or click **`9: RF Buffs [B]`** on the Skill Bar) to consume `25 FP` & `20 SP` and activate your faction's **120-second RF Combat & Force Buff Suite** (`GameData.FACTION_BUFF_SUITES`), spawning a **3D rising aura ring and light pillar**:
- **Sveleitre:** *Overclock Actuator + Reactive Gyro-Aegis + Telemetry Link*
- **Order of the Oracle:** *Verethragna Might + Sacred Asha Ward + Haoma Vital Grace*
- **Legion of the Druj:** *Aeshma Bloodlust + Obsidian Scale Pact + Serpent Dark Sight*
- **Active Buff Bonuses (`120s`):** **`+22% ATK`**, **`+20% Attack Speed`**, **`-22% Damage Taken`** *(stacks with Tank Fortify)*, **`+15% Move Speed`**, **`+18% Max HP & Max FP`**, **`+1.5m Ranged/Force Distance`**, and **`+10 HP / +8 FP` periodic regeneration**.

---

## 10. Expansive 3D Terrain, Procedural Height Landforms, 23 Biome Landmarks & Boss Pits

### 10.1 Multi-Tier Walkable Height Variation & Landforms
Across all 30 world zones, [`WorldZoneManager`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/world.gd) dynamically generates multi-tiered 3D terrain:
- **Elevated Terraces & Plateaus (`height = 2.4m – 3.8m`):** Placed in the outer quadrants (`40m – 65m` from center), keeping the central arena open while providing strategic high ground.
- **Walkable Sloping Ramps (`slope ~ 13.4°`):** Wide ramps connecting ground level (`y = 0.0`) to elevated platforms, fully walkable by players and mobs and dynamically baked into Godot 4's `NavigationMesh`.
- **Rolling Hills & Bluffs (`radius = 14m – 18m`, `height = 1.6m – 2.2m`):** Low-gradient natural mounds.
- **Sky Bridges & Walkways:** Elevated high-tech gangways and energy bridges in sky platforms and mainframe supercores.
- **Perimeter Ring Mountain Cliffs:** 68 rocky monolith bastions enclosing the `230m x 230m` boundaries (`X, Z = ±115m`).
- **Cinematic Atmosphere & Distance Fog:** Procedural distance fog (`fog_density = 0.0055`) and horizon-matched directional sunlight across all 30 maps.

### 10.2 Distinctive 23 Biome Thematic Landmarks
Every zone features architectural structures and environmental monuments tailored to its specific theme:
- `TECH_ARK` / `ARK_SUPERCORE`: Crashed alloy bulkheads, neon cyan tech pylons, server blade mainframe racks with blinking LED arrays.
- `AETHER_SKY`: Levitating sky island discs with glowing thruster rings, floating boulders, and crystal cloud spires.
- `HOLY_TEMPLE` / `SKY_SANCTUM`: Ivory-gold peristyle colonnades, sacred fire altars, floating celestial halos of white-gold light.
- `DESERT_RUINS` / `PERSEPOLIS_STEPPES`: Ancient Persian obelisks, hypostyle columns with double-bull capitals, monumental stone terraces.
- `MAGMA_CALDERA` / `SCORCHED_CAULDRON`: Glowing molten lava fissures with dynamic OmniLight3D, obsidian monolith blades, and smoking fumaroles.
- `CATACOMB_CRYPT` / `DAEVA_CRYPT`: Ancient Persian royal sarcophagi, subterranean mausoleum pillared arches, and necrotic soul-fire braziers.
- `LUMINESCENT_AQUIFER`: Giant bioluminescent mushroom caps emitting turquoise spore light, crystal stalagmites, and stone aqueduct arches.
- `BEAST_HIGHLAND`: Colossal apex predator skeletal ribcage arches forming walkable bone tunnels, mammoth tusk shrines.
- `OUTCAST_WASTELAND`: Scavenger watchtowers with searchlights, spiked defensive palisades, and rusted engine scrap heaps.
- `SKY_FRACTURE`: Gravity-inverted floating boulders hovering in midair, cosmic rift spires with starfall purple/cyan glow.
- `VAR_ROOTS`: Titanic petrified tree roots curving through gold-inlaid stone vaults and royal Yima seal discs.
- `BORDER_TRENCHES`: Sandbag revetment bunkers, fortified firing parapets, and military barricades.
- `CRACK_MINING` / `LOWER_CRATER` / `BREACH_RIDGE`: 14m Central Raw Amber Farr Megaspire, heavy industrial drill rigs, and sniper battlements.

### 10.3 Dedicated Boss Pits & Zone Pit Bosses
Each zone has a dedicated **Boss Pit Arena** platform with 8 monolithic stone pillars, fire braziers, glowing inner rune circles, and a floating 3D title plate:

| Map ID | Boss Pit Name | Pit Boss Name | Level | HP | ATK | Guaranteed Loot & Talics |
|---|---|---|---|---|---|---|
| `svel_hq` | Sub-Core Scrap Pit | **ARC-REACTOR OVERSEER** | `Lv.12` | `1,350` | `28` | Guaranteed 2-3 Farr Talics + Lv.12 Rare Equipment + `950 CYC` Bounty |
| `svel_basic` | Cryo-Rift Boss Pit | **CRYO-CONDUIT DREADNOUGHT** | `Lv.28` | `3,100` | `64` | Guaranteed 2-3 Farr Talics + Lv.20 Rare Equipment + `1,950 CYC` Bounty |
| `order_hq` | Sanctuary Cleansing Pit | **SANCTUARY CORRUPTED GOLEM** | `Lv.12` | `1,400` | `27` | Guaranteed 2-3 Farr Talics + Lv.12 Rare Equipment + `950 DRC` Bounty |
| `order_basic` | Sun-Temple Boss Pit | **AZUR-FRAVASHI ZEALOT** | `Lv.28` | `3,200` | `62` | Guaranteed 2-3 Farr Talics + Lv.20 Rare Equipment + `1,950 DRC` Bounty |
| `legion_hq` | Citadel Trench Pit | **OBSIDIAN BLOOD-GARGANT`** | `Lv.12` | `1,450` | `30` | Guaranteed 2-3 Farr Talics + Lv.12 Rare Equipment + `950 SGL` Bounty |
| `legion_basic` | Boiling Blood Crater Pit | **AKA-MANAH WAR-EXECUTIONER** | `Lv.28` | `3,300` | `66` | Guaranteed 2-3 Farr Talics + Lv.20 Rare Equipment + `1,950 SGL` Bounty |
| `contested_steppes` | Throne Pit of King Yima | **PERSEPOLIS RUIN GOLIATH** | `Lv.38` | `4,500` | `96` | Guaranteed 2-3 Farr Talics + Lv.35 Rare Equipment + `2,900 Currency` |
| `contested_cauldron` | Forsworn Crucible Pit | **ABYSSAL DAEVA OVERLORD** | `Lv.44` | `5,200` | `112` | Guaranteed 2-3 Farr Talics + Lv.35 Rare Equipment + `3,600 Currency` |
| `farr_mining_ground` | Central Core Megavein Pit | **CRACK CORE ARCH-LEVIATHAN** | `Lv.45` | `5,800` | `128` | Guaranteed 2-3 Farr Talics + Lv.35-45 Rare Gear + `4,200 Currency` |

### 10.4 3D Interactive Monster Summon Beacon (`SummonBeacon`)
Every map has an interactive 3D monument ([`SummonBeacon`](file:///Users/wildanmuhammadyasinfadillah/Documents/antigravity/serene-einstein/scripts/summon_beacon.gd)) featuring a floating rotating prism crystal core and light beam:
- **Left-Click to Approach & Activate:** Walking up to the beacon opens the **Rift Summon Beacon Terminal** GUI window.
- **`[1] Summon Grinding Pack`**: Materializes a wave of 3 hostile zone monsters around the beacon with AoE blast VFX for instant leveling and grinding.
- **`[2] Awaken Zone Pit Boss`**: Awaken or resurrect the zone's dedicated Pit Boss immediately in the Boss Pit arena with full combat fanfare.
- **`[3] Clear Summoned Wave`**: Cleans up any active summoned mobs if players want to reset the grinding grounds.



