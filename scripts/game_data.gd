class_name GameData
extends RefCounted
## Central data-driven registry for:
## - 3 Factions & their native currencies (CYC / DRC / SGL)
## - 12 Base Classes & 24 Lv.30 Advanced Jobs with distinct Job Skill Sets & Special Combat Effects
## - 6 Equipment Slots (WEAPON, HELMET, UPPER, LOWER, GLOVES, SHOES)
## - RF-Style +1 to +7 Farr Talic Equipment Upgrading
## - Armor Compatibility rule: Order & Legion share "ORGANIC_VAR" gear; Sveleitre uses "CHASSIS_SVEL" only

const EQUIP_ORGANIC_VAR := "ORGANIC_VAR"   # Usable by BOTH Order of the Oracle & Legion of the Druj
const EQUIP_CHASSIS_SVEL := "CHASSIS_SVEL" # Usable ONLY by Sveleitre

const EQUIP_SLOTS := ["WEAPON", "HELMET", "UPPER", "LOWER", "GLOVES", "SHOES"]
const EQUIP_SLOT_LABELS := {
	"WEAPON": "Weapon",
	"HELMET": "Helmet",
	"UPPER": "Upper Body",
	"LOWER": "Lower Body",
	"GLOVES": "Gauntlets",
	"SHOES": "Boots",
}

const BAG_SLOTS_PER_BAG := 8
const MAX_BAGS := 5
const MAX_UPGRADE_PLUS := 7

const UPGRADE_SUCCESS_RATES := {
	1: 0.85, # +1: 85% (Fail = stays +0)
	2: 0.68, # +2: 68% (Fail = stays +1)
	3: 0.50, # +3: 50% (Fail = drops to +1)
	4: 0.32, # +4: 32% (Fail = resets to +0!)
	5: 0.18, # +5: 18% (Fail = resets to +0!)
	6: 0.08, # +6: 8%  (Fail = resets to +0! Success = Glowing Aura)
	7: 0.03, # +7: 3%  (Fail = resets to +0! Success = Sovereign Masterwork Aura)
}

## RF-Style Weapon Class Stances [Z]:
## Any character can swap between Class-Native Weapon, Melee Weapon (close range, 0 ammo),
## Ranged Bow/Rifle (distance attack; limited range/ATK if non-Ranged class), or Force Staff.
const WEAPON_STANCES := [
	{
		"id": "AUTO",
		"label": "Class Native Weapon",
		"short": "Native",
	},
	{
		"id": "MELEE",
		"label": "Melee Blade/Mace (Close 2.8m, 0 Ammo)",
		"short": "Melee (2.8m)",
	},
	{
		"id": "RANGED",
		"label": "Ranged Bow/Rifle (10.5m Native / 7.5m Cross-Class Limit)",
		"short": "Ranged Bow/Rifle",
	},
	{
		"id": "FORCE",
		"label": "Force Staff/Rod (9.0m Native / 6.8m Cross-Class Limit)",
		"short": "Force Staff",
	},
]

## RF-Style Faction Combat & Force Buff Suites [B] (120s Duration):
## Grants +22% ATK, +20% Attack Speed, -22% Damage Taken, +15% Move Speed, +18% Max HP/FP, +1.5m Ranged Sight & Regen.
const FACTION_BUFF_SUITES := {
	"sveleitre": {
		"suite_name": "Overclock + Gyro-Aegis + Telemetry",
		"short_tag": "Overclock/Aegis/Sight",
		"duration": 120.0,
		"fp_cost": 25,
		"sp_cost": 20,
		"atk_mult": 1.22,
		"aspd_mult": 1.20,
		"dmg_taken_mult": 0.78,
		"move_mult": 1.15,
		"hp_fp_mult": 1.18,
		"ranged_bonus_m": 1.5,
		"aura_color": Color(0.28, 0.94, 1.0),
	},
	"order": {
		"suite_name": "Verethragna Might + Asha Ward + Haoma Grace",
		"short_tag": "Might/Ward/Grace",
		"duration": 120.0,
		"fp_cost": 25,
		"sp_cost": 20,
		"atk_mult": 1.22,
		"aspd_mult": 1.20,
		"dmg_taken_mult": 0.78,
		"move_mult": 1.15,
		"hp_fp_mult": 1.18,
		"ranged_bonus_m": 1.5,
		"aura_color": Color(1.0, 0.88, 0.35),
	},
	"legion": {
		"suite_name": "Aeshma Bloodlust + Obsidian Scale + Serpent Sight",
		"short_tag": "Bloodlust/Scale/Sight",
		"duration": 120.0,
		"fp_cost": 25,
		"sp_cost": 20,
		"atk_mult": 1.22,
		"aspd_mult": 1.20,
		"dmg_taken_mult": 0.78,
		"move_mult": 1.15,
		"hp_fp_mult": 1.18,
		"ranged_bonus_m": 1.5,
		"aura_color": Color(1.0, 0.28, 0.38),
	},
}

const FACTIONS := [
	{
		"id": "sveleitre",
		"name": "Sveleitre",
		"leader": "Instance Zero (Aelfwyne)",
		"currency_name": "Ark Cycles",
		"currency_code": "CYC",
		"debt_name": "Ark Debt",
		"upkeep_label": "Core & Ammo Upkeep",
		"equip_group": EQUIP_CHASSIS_SVEL,
		"color": Color(0.3, 0.9, 1.0),
		"hq_map_id": "svel_hq",
		"basic_map_id": "svel_basic",
		"hq_name": "Ark-Zero Bastion (Sveleitre HQ)",
		"hq_spawn": Vector3(0.0, 0.1, 14.0),
		"signature_name": "4: Siege Mode",
		"classes": [
			{
				"role": "Frontline",
				"base": "Breaker",
				"hp_mult": 1.35,
				"fp_mult": 0.75,
				"sp_mult": 1.35,
				"atk_mult": 1.05,
				"range": 2.6,
				"uses_ammo": false,
				"uses_force": false,
				"skill2": {"name": "2: Ram Cleave", "cd": 3.5, "mult": 2.2, "range": 3.8, "fp_cost": 18, "sp_cost": 22, "effect": "NONE"},
				"skill3": {"name": "3: Shock Stomp AoE", "cd": 6.0, "mult": 1.8, "radius": 4.5, "fp_cost": 28, "sp_cost": 30, "effect": "NONE"},
				"jobs": ["Juggernaut (Tank)", "Shredder (Melee DPS)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Aegis Piston Crush", "cd": 3.2, "mult": 2.5, "range": 4.0, "fp_cost": 20, "sp_cost": 24, "effect": "SHIELD_TAUNT"},
						"skill3": {"name": "3: Fortress Lockdown AoE", "cd": 5.5, "mult": 2.1, "radius": 5.5, "fp_cost": 30, "sp_cost": 32, "effect": "HEAL_SELF"},
					},
					{
						"skill2": {"name": "2: Twin Ripper Overdrive", "cd": 2.8, "mult": 3.1, "range": 4.0, "fp_cost": 18, "sp_cost": 28, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Whirling Saw Tempest", "cd": 5.0, "mult": 2.5, "radius": 5.0, "fp_cost": 26, "sp_cost": 34, "effect": "NONE"},
					},
				],
			},
			{
				"role": "Ranged",
				"base": "Seeker",
				"hp_mult": 0.95,
				"fp_mult": 0.9,
				"sp_mult": 1.25,
				"atk_mult": 1.2,
				"range": 9.5,
				"uses_ammo": true,
				"uses_force": false,
				"skill2": {"name": "2: Rail Piercer", "cd": 3.8, "mult": 2.5, "range": 12.0, "fp_cost": 22, "sp_cost": 20, "effect": "NONE"},
				"skill3": {"name": "3: Drone Barrage AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 32, "sp_cost": 25, "effect": "NONE"},
				"jobs": ["Railer (Sniper)", "Swarm Operator (Drones)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Hyper-Velocity Sabot", "cd": 3.4, "mult": 3.4, "range": 15.0, "fp_cost": 24, "sp_cost": 26, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Orbital Rail Volley", "cd": 6.0, "mult": 2.4, "radius": 5.8, "fp_cost": 34, "sp_cost": 28, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Hunter-Seeker Swarm", "cd": 3.0, "mult": 2.8, "range": 12.5, "fp_cost": 26, "sp_cost": 22, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Carpet Drone Saturation", "cd": 5.5, "mult": 2.5, "radius": 6.2, "fp_cost": 36, "sp_cost": 26, "effect": "NONE"},
					},
				],
			},
			{
				"role": "Caster / Anti-Magic",
				"base": "Nullifier",
				"hp_mult": 0.88,
				"fp_mult": 1.5,
				"sp_mult": 0.85,
				"atk_mult": 1.25,
				"range": 8.0,
				"uses_ammo": false,
				"uses_force": true,
				"skill2": {"name": "2: Logic Spike", "cd": 3.5, "mult": 2.4, "range": 10.0, "fp_cost": 35, "sp_cost": 10, "effect": "NONE"},
				"skill3": {"name": "3: Null-Field AoE", "cd": 5.5, "mult": 2.1, "radius": 5.5, "fp_cost": 50, "sp_cost": 12, "effect": "NONE"},
				"jobs": ["Silencer (Anti-Magic)", "Patcher (Repair Healer)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Zero-Day Exploit", "cd": 3.0, "mult": 3.2, "range": 11.5, "fp_cost": 40, "sp_cost": 10, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: EMP Singularity Collapse", "cd": 5.2, "mult": 2.8, "radius": 6.5, "fp_cost": 58, "sp_cost": 14, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Nanite Purge Beam", "cd": 3.0, "mult": 2.5, "range": 10.5, "fp_cost": 34, "sp_cost": 10, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Ark Nanite Rebuild (Heal+AoE)", "cd": 5.0, "mult": 2.0, "radius": 6.0, "fp_cost": 48, "sp_cost": 12, "effect": "HEAL_PULSE"},
					},
				],
			},
			{
				"role": "Specialist",
				"base": "Fabricator",
				"hp_mult": 1.1,
				"fp_mult": 1.05,
				"sp_mult": 1.15,
				"atk_mult": 1.1,
				"range": 6.5,
				"uses_ammo": true,
				"uses_force": false,
				"mine_speed_mult": 1.4,
				"skill2": {"name": "2: Slag Cannon", "cd": 4.0, "mult": 2.2, "range": 9.0, "fp_cost": 24, "sp_cost": 18, "effect": "NONE"},
				"skill3": {"name": "3: Turret Salvo AoE", "cd": 6.0, "mult": 1.9, "radius": 4.8, "fp_cost": 34, "sp_cost": 22, "effect": "NONE"},
				"jobs": ["Siegeframe (Artillery)", "Torque Engineer (Support)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Heavy Howitzer Shell", "cd": 3.4, "mult": 3.0, "range": 13.0, "fp_cost": 26, "sp_cost": 22, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Cluster Barrage Protocol", "cd": 5.5, "mult": 2.6, "radius": 6.0, "fp_cost": 38, "sp_cost": 26, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Overclocked Plasma Torch", "cd": 3.2, "mult": 2.6, "range": 9.5, "fp_cost": 22, "sp_cost": 20, "effect": "HEAL_SELF"},
						"skill3": {"name": "3: Field Repair & Shield Pulse", "cd": 5.2, "mult": 2.1, "radius": 5.5, "fp_cost": 34, "sp_cost": 20, "effect": "HEAL_PULSE"},
					},
				],
			},
		],
	},
	{
		"id": "order",
		"name": "Order of the Oracle",
		"leader": "The Oracle",
		"currency_name": "Gold Darics",
		"currency_code": "DRC",
		"debt_name": "Vow Debt",
		"upkeep_label": "Relic & Fravashi Tithe",
		"equip_group": EQUIP_ORGANIC_VAR,
		"color": Color(1.0, 0.85, 0.35),
		"hq_map_id": "order_hq",
		"basic_map_id": "order_basic",
		"hq_name": "Asha High Sanctuary (Order HQ)",
		"hq_spawn": Vector3(0.0, 0.1, 14.0),
		"signature_name": "4: Call Fravashi",
		"classes": [
			{
				"role": "Frontline",
				"base": "Rathaestar",
				"hp_mult": 1.38,
				"fp_mult": 0.85,
				"sp_mult": 1.3,
				"atk_mult": 1.0,
				"range": 2.6,
				"uses_ammo": false,
				"uses_force": false,
				"skill2": {"name": "2: Sun Lance Thrust", "cd": 3.5, "mult": 2.2, "range": 4.0, "fp_cost": 18, "sp_cost": 22, "effect": "NONE"},
				"skill3": {"name": "3: Aegis Judgement AoE", "cd": 6.0, "mult": 1.8, "radius": 4.5, "fp_cost": 28, "sp_cost": 28, "effect": "NONE"},
				"jobs": ["Spenta Guard (Tank)", "Charioteer (Lancer)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Immortal Shield Bash", "cd": 3.2, "mult": 2.5, "range": 4.2, "fp_cost": 20, "sp_cost": 24, "effect": "SHIELD_TAUNT"},
						"skill3": {"name": "3: Vow of Asha Sanctuary", "cd": 5.5, "mult": 2.1, "radius": 5.5, "fp_cost": 30, "sp_cost": 30, "effect": "HEAL_SELF"},
					},
					{
						"skill2": {"name": "2: Solar Chariot Impale", "cd": 2.9, "mult": 3.1, "range": 4.5, "fp_cost": 20, "sp_cost": 26, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Golden Wheel Sweep AoE", "cd": 5.0, "mult": 2.5, "radius": 5.2, "fp_cost": 28, "sp_cost": 32, "effect": "NONE"},
					},
				],
			},
			{
				"role": "Ranged",
				"base": "Vastryosh",
				"hp_mult": 0.95,
				"fp_mult": 0.95,
				"sp_mult": 1.25,
				"atk_mult": 1.2,
				"range": 9.5,
				"uses_ammo": true,
				"uses_force": false,
				"skill2": {"name": "2: Arash Arrow", "cd": 3.8, "mult": 2.5, "range": 12.5, "fp_cost": 20, "sp_cost": 22, "effect": "NONE"},
				"skill3": {"name": "3: Varaghna Volley AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 30, "sp_cost": 26, "effect": "NONE"},
				"jobs": ["Arash Archer (Longbow)", "Falconer (Scout)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Boundary-Splitter Arrow", "cd": 3.3, "mult": 3.45, "range": 15.5, "fp_cost": 22, "sp_cost": 26, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Heaven's Rain of Arrows", "cd": 5.8, "mult": 2.45, "radius": 6.0, "fp_cost": 32, "sp_cost": 28, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Golden Falcon Dive", "cd": 3.0, "mult": 2.85, "range": 13.0, "fp_cost": 24, "sp_cost": 22, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Verethragna Gale AoE", "cd": 5.4, "mult": 2.35, "radius": 5.8, "fp_cost": 34, "sp_cost": 24, "effect": "HEAL_SELF"},
					},
				],
			},
			{
				"role": "Caster",
				"base": "Athravan",
				"hp_mult": 0.88,
				"fp_mult": 1.6,
				"sp_mult": 0.85,
				"atk_mult": 1.3,
				"range": 8.0,
				"uses_ammo": false,
				"uses_force": true,
				"skill2": {"name": "2: Atar Bolt", "cd": 3.2, "mult": 2.4, "range": 10.0, "fp_cost": 36, "sp_cost": 8, "effect": "NONE"},
				"skill3": {"name": "3: Pillar of Atar AoE", "cd": 5.5, "mult": 2.2, "radius": 5.5, "fp_cost": 52, "sp_cost": 10, "effect": "NONE"},
				"jobs": ["Flamecaller (Fire DPS)", "Haoma Priest (Healer)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Royal Fire of Farnbag", "cd": 2.9, "mult": 3.3, "range": 11.5, "fp_cost": 42, "sp_cost": 10, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Solar Conflagration AoE", "cd": 5.0, "mult": 2.9, "radius": 6.5, "fp_cost": 60, "sp_cost": 12, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Sacred Flame Rebuke", "cd": 3.0, "mult": 2.5, "range": 10.5, "fp_cost": 34, "sp_cost": 8, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Haoma Benediction (Heal+AoE)", "cd": 4.8, "mult": 2.1, "radius": 6.2, "fp_cost": 50, "sp_cost": 10, "effect": "HEAL_PULSE"},
					},
				],
			},
			{
				"role": "Specialist",
				"base": "Huiti",
				"hp_mult": 1.1,
				"fp_mult": 1.1,
				"sp_mult": 1.15,
				"atk_mult": 1.05,
				"range": 4.5,
				"uses_ammo": false,
				"uses_force": false,
				"mine_speed_mult": 1.45,
				"skill2": {"name": "2: Relic Hammer", "cd": 4.0, "mult": 2.1, "range": 5.5, "fp_cost": 20, "sp_cost": 20, "effect": "NONE"},
				"skill3": {"name": "3: Sanctified Ward AoE", "cd": 6.0, "mult": 1.85, "radius": 4.8, "fp_cost": 32, "sp_cost": 20, "effect": "NONE"},
				"jobs": ["Relicsmith (Crafter)", "Veinwright (Master Miner)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Forge-Anvil Judgment", "cd": 3.3, "mult": 2.85, "range": 6.0, "fp_cost": 22, "sp_cost": 22, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Seal-Woven Bastion AoE", "cd": 5.5, "mult": 2.3, "radius": 5.5, "fp_cost": 34, "sp_cost": 22, "effect": "HEAL_PULSE"},
					},
					{
						"skill2": {"name": "2: Crystal Resonance Strike", "cd": 3.2, "mult": 2.7, "range": 6.0, "fp_cost": 20, "sp_cost": 20, "effect": "HEAL_SELF"},
						"skill3": {"name": "3: Tectonic Vein Shatter AoE", "cd": 5.2, "mult": 2.5, "radius": 5.8, "fp_cost": 32, "sp_cost": 24, "effect": "NONE"},
					},
				],
			},
		],
	},
	{
		"id": "legion",
		"name": "Legion of the Druj",
		"leader": "Azii Dzahhakka",
		"currency_name": "Blood Sigils",
		"currency_code": "SGL",
		"debt_name": "Pact Debt",
		"upkeep_label": "Dread-Titan Upkeep",
		"equip_group": EQUIP_ORGANIC_VAR,
		"color": Color(0.95, 0.3, 0.35),
		"hq_map_id": "legion_hq",
		"basic_map_id": "legion_basic",
		"hq_name": "Druj Obsidian Citadel (Legion HQ)",
		"hq_spawn": Vector3(0.0, 0.1, 14.0),
		"signature_name": "4: Dread-Titan Mount",
		"classes": [
			{
				"role": "Frontline",
				"base": "Wrathborn",
				"hp_mult": 1.28,
				"fp_mult": 0.85,
				"sp_mult": 1.35,
				"atk_mult": 1.15,
				"range": 2.7,
				"uses_ammo": false,
				"uses_force": false,
				"skill2": {"name": "2: Aka Rend", "cd": 3.4, "mult": 2.35, "range": 4.0, "fp_cost": 18, "sp_cost": 24, "effect": "NONE"},
				"skill3": {"name": "3: Blood Quake AoE", "cd": 6.0, "mult": 1.9, "radius": 4.6, "fp_cost": 28, "sp_cost": 30, "effect": "NONE"},
				"jobs": ["Ravager (Berserker)", "Chainbound (Chain Tank)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Crimson Frenzy Execution", "cd": 2.7, "mult": 3.25, "range": 4.2, "fp_cost": 20, "sp_cost": 28, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Slaughter Maelstrom AoE", "cd": 4.8, "mult": 2.6, "radius": 5.2, "fp_cost": 30, "sp_cost": 34, "effect": "LIFESTEAL"},
					},
					{
						"skill2": {"name": "2: Damavand Chain Hook", "cd": 3.2, "mult": 2.55, "range": 5.0, "fp_cost": 20, "sp_cost": 24, "effect": "SHIELD_TAUNT"},
						"skill3": {"name": "3: Iron Shackle Rupture AoE", "cd": 5.4, "mult": 2.2, "radius": 5.5, "fp_cost": 30, "sp_cost": 30, "effect": "HEAL_SELF"},
					},
				],
			},
			{
				"role": "Ranged",
				"base": "Pairika",
				"hp_mult": 0.92,
				"fp_mult": 1.0,
				"sp_mult": 1.25,
				"atk_mult": 1.22,
				"range": 9.0,
				"uses_ammo": true,
				"uses_force": false,
				"skill2": {"name": "2: Venom Spine", "cd": 3.6, "mult": 2.45, "range": 11.5, "fp_cost": 22, "sp_cost": 22, "effect": "NONE"},
				"skill3": {"name": "3: Hex Cloud AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 32, "sp_cost": 24, "effect": "NONE"},
				"jobs": ["Veilstalker (Assassin)", "Hexarcher (Curse Bow)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Phantom Heart-Seeker", "cd": 3.1, "mult": 3.4, "range": 13.5, "fp_cost": 24, "sp_cost": 26, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Nightfall Fan of Spines", "cd": 5.5, "mult": 2.45, "radius": 5.8, "fp_cost": 34, "sp_cost": 26, "effect": "LIFESTEAL"},
					},
					{
						"skill2": {"name": "2: Serpent-Venom Volley", "cd": 3.2, "mult": 2.95, "range": 13.0, "fp_cost": 26, "sp_cost": 22, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Plague of Dzahhakka AoE", "cd": 5.6, "mult": 2.55, "radius": 6.2, "fp_cost": 36, "sp_cost": 24, "effect": "NONE"},
					},
				],
			},
			{
				"role": "Caster",
				"base": "Yatu",
				"hp_mult": 0.88,
				"fp_mult": 1.6,
				"sp_mult": 0.85,
				"atk_mult": 1.32,
				"range": 8.0,
				"uses_ammo": false,
				"uses_force": true,
				"skill2": {"name": "2: Hellfire Fang", "cd": 3.3, "mult": 2.45, "range": 10.0, "fp_cost": 38, "sp_cost": 8, "effect": "NONE"},
				"skill3": {"name": "3: Druj Nova AoE", "cd": 5.5, "mult": 2.2, "radius": 5.5, "fp_cost": 54, "sp_cost": 10, "effect": "NONE"},
				"jobs": ["Abyss Caller (Dark DPS)", "Bloodbinder (Drain Healer)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Aka Manah Soul-Sear", "cd": 2.9, "mult": 3.35, "range": 11.5, "fp_cost": 44, "sp_cost": 10, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Abyssal Eclipse Cataclysm", "cd": 5.0, "mult": 2.95, "radius": 6.5, "fp_cost": 62, "sp_cost": 12, "effect": "NONE"},
					},
					{
						"skill2": {"name": "2: Sanguine Siphon Lash", "cd": 2.9, "mult": 2.65, "range": 10.5, "fp_cost": 36, "sp_cost": 8, "effect": "LIFESTEAL"},
						"skill3": {"name": "3: Blood Covenant Ritual (Heal+AoE)", "cd": 4.8, "mult": 2.2, "radius": 6.2, "fp_cost": 52, "sp_cost": 10, "effect": "HEAL_PULSE"},
					},
				],
			},
			{
				"role": "Specialist",
				"base": "Dregvant",
				"hp_mult": 1.12,
				"fp_mult": 1.05,
				"sp_mult": 1.15,
				"atk_mult": 1.08,
				"range": 4.5,
				"uses_ammo": false,
				"uses_force": false,
				"mine_speed_mult": 1.35,
				"skill2": {"name": "2: Blight Spike", "cd": 4.0, "mult": 2.15, "range": 6.0, "fp_cost": 22, "sp_cost": 20, "effect": "NONE"},
				"skill3": {"name": "3: Corrupted Shrapnel AoE", "cd": 6.0, "mult": 1.9, "radius": 4.8, "fp_cost": 32, "sp_cost": 22, "effect": "NONE"},
				"jobs": ["Cursesmith (Titan Pilot)", "Blightminer (Saboteur)"],
				"job_skills": [
					{
						"skill2": {"name": "2: Dread-Core Overcharge", "cd": 3.2, "mult": 2.9, "range": 6.5, "fp_cost": 24, "sp_cost": 22, "effect": "HEAL_SELF"},
						"skill3": {"name": "3: Hellforged Shockwave AoE", "cd": 5.4, "mult": 2.45, "radius": 5.8, "fp_cost": 34, "sp_cost": 24, "effect": "SHIELD_TAUNT"},
					},
					{
						"skill2": {"name": "2: Corrosive Vein Detonator", "cd": 3.1, "mult": 2.8, "range": 7.0, "fp_cost": 22, "sp_cost": 22, "effect": "ARMOR_PIERCE"},
						"skill3": {"name": "3: Blight-Gas Eruption AoE", "cd": 5.2, "mult": 2.5, "radius": 6.0, "fp_cost": 34, "sp_cost": 22, "effect": "LIFESTEAL"},
					},
				],
			},
		],
	},
]

const EQUIPMENT_TIERS := [
	{
		"tier": 1,
		"req_lv": 1,
		"bracket": "Lv.1-15",
		"organic_prefix": "Lv.1 Recruit Bronze",
		"chassis_prefix": "Lv.1 Stock MK-I",
		"piece_cost": 0,
		"vendor_sold": true,
		"rarity": "Normal",
		"bonus_hp": 10,
		"bonus_fp": 5,
		"bonus_sp": 5,
		"bonus_atk": 4,
	},
	{
		"tier": 2,
		"req_lv": 10,
		"bracket": "Lv.1-15",
		"organic_prefix": "Lv.12 Outpost Scale",
		"chassis_prefix": "Lv.12 Alloy MK-II",
		"piece_cost": 140,
		"vendor_sold": true,
		"rarity": "Normal",
		"bonus_hp": 35,
		"bonus_fp": 15,
		"bonus_sp": 14,
		"bonus_atk": 18,
	},
	{
		"tier": 3,
		"req_lv": 15,
		"bracket": "Lv.15-25",
		"organic_prefix": "Lv.20 Var-Forged",
		"chassis_prefix": "Lv.20 Carapace MK-III",
		"piece_cost": 320,
		"vendor_sold": true,
		"rarity": "Normal",
		"bonus_hp": 75,
		"bonus_fp": 32,
		"bonus_sp": 28,
		"bonus_atk": 42,
	},
	{
		"tier": 4,
		"req_lv": 30,
		"bracket": "Lv.30-45",
		"organic_prefix": "Lv.35 Relic-Woven",
		"chassis_prefix": "Lv.35 Quantum MK-IV",
		"piece_cost": 750,
		"vendor_sold": true,
		"rarity": "Normal",
		"bonus_hp": 145,
		"bonus_fp": 65,
		"bonus_sp": 55,
		"bonus_atk": 88,
	},
	{
		"tier": 5,
		"req_lv": 45,
		"bracket": "Lv.30-45 (Rare Drop)",
		"organic_prefix": "Lv.45 [RARE] Intense Scar",
		"chassis_prefix": "Lv.45 [RARE] Intense Overclock",
		"piece_cost": 1800,
		"vendor_sold": false, # Monster/Boss Drop Only!
		"rarity": "Intense [RARE]",
		"bonus_hp": 310,
		"bonus_fp": 135,
		"bonus_sp": 110,
		"bonus_atk": 180,
	},
	{
		"tier": 6,
		"req_lv": 50,
		"bracket": "Lv.50 Archon",
		"organic_prefix": "Lv.50 Archon Herald",
		"chassis_prefix": "Lv.50 Prime Instance",
		"piece_cost": 2800,
		"vendor_sold": true,
		"rarity": "Archon",
		"bonus_hp": 500,
		"bonus_fp": 220,
		"bonus_sp": 185,
		"bonus_atk": 290,
	},
]


static func make_consumable_item(item_id: String, count: int) -> Dictionary:
	match item_id:
		"POT_HP":
			return {
				"id": "POT_HP",
				"name": "HP Potion",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 99,
				"count": count,
				"sort_key": 10,
			}
		"POT_FP":
			return {
				"id": "POT_FP",
				"name": "FP Charger",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 99,
				"count": count,
				"sort_key": 11,
			}
		"POT_SP":
			return {
				"id": "POT_SP",
				"name": "SP Stim",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 99,
				"count": count,
				"sort_key": 12,
			}
		"AMMO_PACK":
			return {
				"id": "AMMO_PACK",
				"name": "Ammo / Force Cell",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 500,
				"count": count,
				"sort_key": 20,
			}
		"SCROLL_HQ":
			return {
				"id": "SCROLL_HQ",
				"name": "Teleport Scroll",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 20,
				"count": count,
				"sort_key": 25,
			}
		"TALIC_FARR":
			return {
				"id": "TALIC_FARR",
				"name": "Farr Talic Crystal (+Upgrade)",
				"category": "CONSUMABLE",
				"stackable": true,
				"max_stack": 99,
				"count": count,
				"sort_key": 30,
			}
	return {}


static func make_equipment_item(tier_idx: int, slot: String, equip_group: String, upgrade_plus: int = 0) -> Dictionary:
	var t: Dictionary = EQUIPMENT_TIERS[clampi(tier_idx, 0, EQUIPMENT_TIERS.size() - 1)]
	var prefix: String = t["chassis_prefix"] if equip_group == EQUIP_CHASSIS_SVEL else t["organic_prefix"]
	var slot_label: String = EQUIP_SLOT_LABELS.get(slot, slot)
	var group_tag := "[Svel]" if equip_group == EQUIP_CHASSIS_SVEL else "[Order/Druj]"
	var plus_clamped := clampi(upgrade_plus, 0, MAX_UPGRADE_PLUS)
	var plus_mult := 1.0 + float(plus_clamped) * 0.14
	var plus_prefix := ("+%d " % plus_clamped) if plus_clamped > 0 else ""

	var is_weapon := (slot == "WEAPON")
	var base_atk := float(t["bonus_atk"]) if is_weapon else float(t["bonus_atk"]) * 0.12
	var base_hp := float(t["bonus_hp"]) * 0.35 if is_weapon else float(t["bonus_hp"])
	var base_fp := float(t["bonus_fp"]) * 0.4 if is_weapon else float(t["bonus_fp"])
	var base_sp := float(t["bonus_sp"]) * 0.4 if is_weapon else float(t["bonus_sp"])

	var atk_val := int(round(base_atk * plus_mult))
	var hp_val := int(round(base_hp * plus_mult))
	var fp_val := int(round(base_fp * plus_mult))
	var sp_val := int(round(base_sp * plus_mult))

	var slot_order := EQUIP_SLOTS.find(slot)
	var sort_key := 100 + slot_order * 20 - int(t["tier"]) - plus_clamped

	return {
		"id": "EQ_%s_T%d_%s_P%d" % [equip_group, t["tier"], slot, plus_clamped],
		"name": "%s%s %s %s" % [plus_prefix, prefix, slot_label, group_tag],
		"category": "EQUIP",
		"slot": slot,
		"tier_idx": tier_idx,
		"tier": int(t["tier"]),
		"upgrade_plus": plus_clamped,
		"req_lv": int(t["req_lv"]),
		"bracket": str(t["bracket"]),
		"rarity": str(t["rarity"]),
		"equip_group": equip_group,
		"bonus_atk": atk_val,
		"bonus_hp": hp_val,
		"bonus_fp": fp_val,
		"bonus_sp": sp_val,
		"sell_price": maxi(35, int(round(float(t["piece_cost"]) * 0.45 * plus_mult)) + int(t["tier"]) * 30),
		"stackable": false,
		"max_stack": 1,
		"count": 1,
		"sort_key": sort_key,
	}


# ==============================================================================
# 9-MAP WORLD ZONE REGISTRY (RF-Style Multi-Zone Architecture)
# - 3 Faction HQ Maps (1 per Faction: Safe HQ + Lv.1-12 Starter Grounds)
# - 3 Faction Basic Leveling Maps (1 per Faction: Lv.12-28 + Lv.28 Mini-Boss)
# - 2 Contested Upper-Level Grinding Maps (All 3 Factions clash for Lv.28-45 spots + World Bosses)
# - 1 Central PvPvE Farr Mining War Ground (All 3 Factions gather to fight for Farr Ore)
# ==============================================================================

const MAP_ORDER := [
	# --- Tier 1: Faction Safe HQs (Lv.1-12) ---
	"svel_hq",
	"order_hq",
	"legion_hq",

	# --- Tier 2: Faction Basic Leveling Grounds (Lv.12-25) ---
	"svel_basic",
	"order_basic",
	"legion_basic",

	# --- Tier 3: Faction Secondary Outposts (Lv.22-32) ---
	"svel_outpost",
	"order_outpost",
	"legion_outpost",

	# --- Tier 4: Contested Borderlands (Lv.30-38) ---
	"border_sette",
	"border_glacier",
	"border_trench",

	# --- Tier 5: Specialized Economic Farming Niches (Lv.36-46) ---
	"farm_ether_sky",
	"farm_caldera_magma",
	"farm_relic_catacombs",
	"farm_deep_aquifer",

	# --- Tier 6: Upper Contested Steppes & Cauldron (Lv.38-50) ---
	"contested_steppes",
	"contested_cauldron",
	"steppes_highlands",
	"cauldron_abyss",

	# --- Tier 7: The Crack War Grounds (Lv.25-50) ---
	"farr_mining_ground",
	"mining_lower_crater",
	"mining_breach_ridge",

	# --- Tier 8: Beast Highlands & Outcast Expeditions (Lv.45-52) ---
	"beast_plateau",
	"outcast_wasteland",
	"sky_fracture_ridge",

	# --- Tier 9: Ancient Vaults & Deep Dungeons (Lv.45-55) ---
	"dungeon_ark_core",
	"dungeon_var_roots",
	"dungeon_daeva_crypt",
	"dungeon_sky_sanctum",
]

const MAPS := {
	# ==========================================================================
	# TIER 1: FACTION SAFE HOMELANDS (Lv. 1-12)
	# ==========================================================================
	"svel_hq": {
		"id": "svel_hq",
		"name": "Ark-Zero Bastion (Sveleitre HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "sveleitre",
		"level_band": "Safe HQ / Lv.1-12",
		"farming_focus": "HQ_SAFE",
		"terrain_theme": "TECH_ARK",
		"ground_color": Color(0.18, 0.24, 0.30),
		"sky_top": Color(0.08, 0.16, 0.28),
		"sky_horizon": Color(0.22, 0.42, 0.58),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -32.0), "radius": 7.5, "name": "Sub-Core Scrap Pit"},
		"summon_beacon": {"name": "Ark Defense Summon Beacon", "pos": Vector3(14.0, 0.0, 10.0), "col": Color(0.3, 0.9, 1.0)},
		"pit_boss": {
			"name": "ARC-REACTOR OVERSEER", "title": "HQ Pit Boss", "lv": 12, "hp": 1350, "atk": 28, "bounty": 950,
			"farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5,
			"body": Color(0.20, 0.32, 0.45), "accent": Color(0.35, 1.0, 0.95), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 14.0), "order": Vector3(0.0, 0.1, 14.0), "legion": Vector3(0.0, 0.1, 14.0)},
		"refineries": [{"name": "Sveleitre Ark-Zero Core Refinery", "pos": Vector3(0.0, 0.0, 22.0)}],
		"npcs": [
			{"name": "Injector Unit V-01", "title": "Ark Potion & Charger NPC", "type": "POTION", "faction": "sveleitre", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.25, 0.95, 0.75)},
			{"name": "Ordnance Unit W-02", "title": "Weapon & Ammo/Force NPC", "type": "WEAPON", "faction": "sveleitre", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.35, 0.85, 1.0)},
			{"name": "Chassis Foundry A-03", "title": "Svel Chassis Armor NPC (Lv.1-45)", "type": "ARMOR", "faction": "sveleitre", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.45, 0.75, 1.0)},
			{"name": "Logistics Node U-04", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "sveleitre", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.75, 0.9, 1.0)},
			{"name": "Ark Backup Core R-00", "title": "HQ Rebirth & Save NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.5, 1.0, 0.85)},
			{"name": "INSTANCE ZERO: CODE AELFWYNE", "title": "Sveleitre Sovereign (Story Campaign)", "type": "LEADER", "faction": "sveleitre", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.88, 0.92, 0.98), "accent": Color(0.35, 0.95, 1.0)},
		],
		"veins": [{"name": "Ark Perimeter Starter Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(0.35, 0.9, 1.0)}],
		"portals": [
			{"title": "North Gate -> Sveleitre Basic Leveling", "target": "svel_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "East Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Scrap Scavenger (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.42, 0.48, 0.54), "accent": Color(0.4, 0.85, 1.0)},
			{"name": "Glitch-Spider Drone (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.35, 0.42, 0.50), "accent": Color(0.3, 0.95, 0.85)},
			{"name": "Feral Servo-Hound (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -22.0), "scale": 1.05, "body": Color(0.32, 0.45, 0.55), "accent": Color(0.3, 0.85, 1.0)},
			{"name": "ARC-REACTOR OVERSEER", "lv": 12, "hp": 1350, "atk": 28, "bounty": 950, "farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5, "body": Color(0.20, 0.32, 0.45), "accent": Color(0.35, 1.0, 0.95), "is_pit_boss": true},
		],
	},

	"order_hq": {
		"id": "order_hq",
		"name": "Asha High Sanctuary (Order HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "order",
		"level_band": "Safe HQ / Lv.1-12",
		"farming_focus": "HQ_SAFE",
		"terrain_theme": "HOLY_TEMPLE",
		"ground_color": Color(0.32, 0.30, 0.25),
		"sky_top": Color(0.18, 0.16, 0.12),
		"sky_horizon": Color(0.48, 0.42, 0.28),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -32.0), "radius": 7.5, "name": "Sanctuary Cleansing Pit"},
		"summon_beacon": {"name": "Asha Seal Summon Beacon", "pos": Vector3(14.0, 0.0, 10.0), "col": Color(1.0, 0.85, 0.35)},
		"pit_boss": {
			"name": "SANCTUARY CORRUPTED GOLEM", "title": "HQ Pit Boss", "lv": 12, "hp": 1400, "atk": 27, "bounty": 950,
			"farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5,
			"body": Color(0.55, 0.45, 0.28), "accent": Color(1.0, 0.9, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 14.0), "order": Vector3(0.0, 0.1, 14.0), "legion": Vector3(0.0, 0.1, 14.0)},
		"refineries": [{"name": "Order Sacred Fire Core Refinery", "pos": Vector3(0.0, 0.0, 22.0)}],
		"npcs": [
			{"name": "Haoma Priest V-01", "title": "Sacred Potion & Balm NPC", "type": "POTION", "faction": "order", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Sun-Smith W-02", "title": "Lances, Bows & Staffs NPC", "type": "WEAPON", "faction": "order", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.75, 0.25)},
			{"name": "Sanctuary Armorer A-03", "title": "Var Organic Armor NPC (Lv.1-45)", "type": "ARMOR", "faction": "order", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.90, 0.45)},
			{"name": "Temple Bursar U-04", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "order", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(0.9, 0.85, 0.70)},
			{"name": "Altar of Asha R-00", "title": "Sanctuary Rebirth & Save NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.95, 0.55)},
			{"name": "THE ORACLE, LAST VOICE OF THE SEAL", "title": "Order Sovereign (Story Campaign)", "type": "LEADER", "faction": "order", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.95, 0.92, 0.84), "accent": Color(1.0, 0.82, 0.28)},
		],
		"veins": [{"name": "Sanctuary Starter Farr Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(1.0, 0.82, 0.25)}],
		"portals": [
			{"title": "North Gate -> Sun-Bleached Terraces", "target": "order_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "West Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(-22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Profaned Jackal (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.48, 0.42, 0.34), "accent": Color(1.0, 0.75, 0.3)},
			{"name": "Sun-Scorched Beetle (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.42, 0.36, 0.28), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Grave-Looter Fanatic (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -22.0), "scale": 1.05, "body": Color(0.38, 0.32, 0.25), "accent": Color(1.0, 0.65, 0.2)},
			{"name": "SANCTUARY CORRUPTED GOLEM", "lv": 12, "hp": 1400, "atk": 27, "bounty": 950, "farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5, "body": Color(0.55, 0.45, 0.28), "accent": Color(1.0, 0.9, 0.35), "is_pit_boss": true},
		],
	},

	"legion_hq": {
		"id": "legion_hq",
		"name": "Druj Obsidian Citadel (Legion HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "legion",
		"level_band": "Safe HQ / Lv.1-12",
		"farming_focus": "HQ_SAFE",
		"terrain_theme": "OBSIDIAN_CITADEL",
		"ground_color": Color(0.22, 0.16, 0.18),
		"sky_top": Color(0.12, 0.06, 0.10),
		"sky_horizon": Color(0.38, 0.18, 0.25),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -32.0), "radius": 7.5, "name": "Citadel Trench Pit"},
		"summon_beacon": {"name": "Druj Blood Summon Beacon", "pos": Vector3(14.0, 0.0, 10.0), "col": Color(0.95, 0.3, 0.35)},
		"pit_boss": {
			"name": "OBSIDIAN BLOOD-GARGANT", "title": "HQ Pit Boss", "lv": 12, "hp": 1450, "atk": 30, "bounty": 950,
			"farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5,
			"body": Color(0.42, 0.14, 0.22), "accent": Color(1.0, 0.25, 0.4), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 14.0), "order": Vector3(0.0, 0.1, 14.0), "legion": Vector3(0.0, 0.1, 14.0)},
		"refineries": [{"name": "Legion Druj Blood-Core Refinery", "pos": Vector3(0.0, 0.0, 22.0)}],
		"npcs": [
			{"name": "Sanguine Brewer V-01", "title": "Blood Potion & Hex Tonic NPC", "type": "POTION", "faction": "legion", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.35, 0.45)},
			{"name": "Dread-Smith W-02", "title": "Shamshirs, Bows & Staffs NPC", "type": "WEAPON", "faction": "legion", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Obsidian Forger A-03", "title": "Var Organic Armor NPC (Lv.1-45)", "type": "ARMOR", "faction": "legion", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(0.85, 0.25, 0.45)},
			{"name": "Pact Quartermaster U-04", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "legion", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(0.95, 0.45, 0.55)},
			{"name": "Altar of the Druj R-00", "title": "Citadel Rebirth & Save NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.2, 0.3)},
			{"name": "AZII DZAHHAKKA, HERALD OF THE DRUJ", "title": "Legion Sovereign (Story Campaign)", "type": "LEADER", "faction": "legion", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.24, 0.18, 0.22), "accent": Color(0.95, 0.20, 0.40)},
		],
		"veins": [{"name": "Citadel Starter Farr Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(0.95, 0.28, 0.35)}],
		"portals": [
			{"title": "North Gate -> Ashen Blood-Basin", "target": "legion_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "West Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(-22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Ash-Crawler Fiend (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.45, 0.16, 0.22), "accent": Color(1.0, 0.3, 0.4)},
			{"name": "Sulfur-Spike Imp (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.38, 0.14, 0.20), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Corrupted Legion Deserter (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -22.0), "scale": 1.05, "body": Color(0.32, 0.12, 0.18), "accent": Color(1.0, 0.20, 0.30)},
			{"name": "OBSIDIAN BLOOD-GARGANT", "lv": 12, "hp": 1450, "atk": 30, "bounty": 950, "farr_u": 25, "farr_v": 650, "pos": Vector3(0.0, 0.0, -32.0), "scale": 2.3, "range": 3.2, "aggro": 8.5, "body": Color(0.42, 0.14, 0.22), "accent": Color(1.0, 0.25, 0.4), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 2: FACTION BASIC LEVELING GROUNDS (Lv. 12-25)
	# ==========================================================================
	"svel_basic": {
		"id": "svel_basic",
		"name": "Cryo-Scrap Frontier",
		"category": "FACTION_BASIC",
		"owner_faction": "sveleitre",
		"level_band": "Lv.12-25",
		"farming_focus": "BASIC_SOLO",
		"terrain_theme": "FROZEN_SCRAP",
		"ground_color": Color(0.20, 0.26, 0.32),
		"sky_top": Color(0.05, 0.12, 0.22),
		"sky_horizon": Color(0.25, 0.45, 0.65),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 8.5, "name": "Cryo-Rift Boss Pit"},
		"summon_beacon": {"name": "Cryo-Frontier Summon Beacon", "pos": Vector3(12.0, 0.0, 24.0), "col": Color(0.35, 0.9, 1.0)},
		"pit_boss": {
			"name": "CRYO-CONDUIT DREADNOUGHT", "title": "Basic Ground Pit Boss", "lv": 25, "hp": 2600, "atk": 52, "bounty": 1600,
			"farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0,
			"body": Color(0.18, 0.30, 0.48), "accent": Color(0.4, 0.95, 1.0), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 32.0), "order": Vector3(0.0, 0.1, 32.0), "legion": Vector3(0.0, 0.1, 32.0)},
		"refineries": [{"name": "Cryo-Scrap Forward Refinery Node", "pos": Vector3(0.0, 0.0, 36.0)}],
		"npcs": [
			{"name": "Relay Outpost Keeper R-12", "title": "Forward Rebirth & Save NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(-6.0, 0.0, 32.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.4, 0.9, 1.0)},
			{"name": "Frontier Merchant S-09", "title": "Outpost Potion & Utility NPC", "type": "POTION", "faction": "sveleitre", "pos": Vector3(6.0, 0.0, 32.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.35, 0.85, 1.0)},
		],
		"veins": [
			{"name": "Cryo-Frontier Farr Vein Alpha", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(0.4, 0.85, 1.0)},
			{"name": "Cryo-Frontier Farr Vein Beta", "pos": Vector3(16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(0.4, 0.85, 1.0)},
		],
		"portals": [
			{"title": "South Portal -> Ark-Zero HQ", "target": "svel_hq", "pos": Vector3(0.0, 0.0, 42.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "East Gate -> Sub-Deck Chasm Outpost", "target": "svel_outpost", "pos": Vector3(26.0, 0.0, 0.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "North Gate -> Sette Dune Sea (Borderlands)", "target": "border_sette", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(1.0, 0.75, 0.25)},
		],
		"enemies": [
			{"name": "Frost-Plated Drone (Lv.14)", "lv": 14, "hp": 340, "atk": 24, "bounty": 230, "farr_u": 15, "farr_v": 320, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.05, "body": Color(0.3, 0.42, 0.55), "accent": Color(0.4, 0.9, 1.0)},
			{"name": "Glacial Saw-Automaton (Lv.18)", "lv": 18, "hp": 480, "atk": 32, "bounty": 310, "farr_u": 18, "farr_v": 420, "pos": Vector3(12.0, 0.0, -8.0), "scale": 1.1, "body": Color(0.28, 0.38, 0.50), "accent": Color(0.35, 0.85, 1.0)},
			{"name": "Rogue Harvester Frame (Lv.22)", "lv": 22, "hp": 680, "atk": 42, "bounty": 420, "farr_u": 22, "farr_v": 560, "pos": Vector3(0.0, 0.0, -18.0), "scale": 1.25, "body": Color(0.22, 0.32, 0.45), "accent": Color(0.3, 0.8, 1.0)},
			{"name": "CRYO-CONDUIT DREADNOUGHT", "lv": 25, "hp": 2600, "atk": 52, "bounty": 1600, "farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0, "body": Color(0.18, 0.30, 0.48), "accent": Color(0.4, 0.95, 1.0), "is_pit_boss": true},
		],
	},

	"order_basic": {
		"id": "order_basic",
		"name": "Sun-Bleached Terraces",
		"category": "FACTION_BASIC",
		"owner_faction": "order",
		"level_band": "Lv.12-25",
		"farming_focus": "BASIC_SOLO",
		"terrain_theme": "DESERT_RUINS",
		"ground_color": Color(0.36, 0.32, 0.22),
		"sky_top": Color(0.22, 0.18, 0.12),
		"sky_horizon": Color(0.55, 0.45, 0.28),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 8.5, "name": "Sun-Temple Boss Pit"},
		"summon_beacon": {"name": "Sun-Bleached Summon Beacon", "pos": Vector3(12.0, 0.0, 24.0), "col": Color(1.0, 0.85, 0.35)},
		"pit_boss": {
			"name": "AZUR-FRAVASHI ZEALOT", "title": "Basic Ground Pit Boss", "lv": 25, "hp": 2700, "atk": 50, "bounty": 1600,
			"farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0,
			"body": Color(0.62, 0.50, 0.25), "accent": Color(1.0, 0.95, 0.45), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 32.0), "order": Vector3(0.0, 0.1, 32.0), "legion": Vector3(0.0, 0.1, 32.0)},
		"refineries": [{"name": "Sun-Terrace Altar Refinery", "pos": Vector3(0.0, 0.0, 36.0)}],
		"npcs": [
			{"name": "Flame-Keeper Rebirth NPC", "title": "Terrace Rebirth & Save NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(-6.0, 0.0, 32.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Terrace Supply Priest", "title": "Outpost Potion & Utility NPC", "type": "POTION", "faction": "order", "pos": Vector3(6.0, 0.0, 32.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.75, 0.25)},
		],
		"veins": [
			{"name": "Terrace Sun Vein Alpha", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(1.0, 0.82, 0.25)},
			{"name": "Terrace Sun Vein Beta", "pos": Vector3(16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(1.0, 0.82, 0.25)},
		],
		"portals": [
			{"title": "South Portal -> Asha Sanctuary HQ", "target": "order_hq", "pos": Vector3(0.0, 0.0, 42.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "East Gate -> Pilgrim Oasis Outpost", "target": "order_outpost", "pos": Vector3(26.0, 0.0, 0.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Gate -> Sette Dune Sea (Borderlands)", "target": "border_sette", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(1.0, 0.75, 0.25)},
		],
		"enemies": [
			{"name": "Terrace Dune-Viper (Lv.14)", "lv": 14, "hp": 340, "atk": 24, "bounty": 230, "farr_u": 15, "farr_v": 320, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.05, "body": Color(0.50, 0.42, 0.28), "accent": Color(1.0, 0.8, 0.3)},
			{"name": "Relic-Robber Zealot (Lv.18)", "lv": 18, "hp": 480, "atk": 32, "bounty": 310, "farr_u": 18, "farr_v": 420, "pos": Vector3(12.0, 0.0, -8.0), "scale": 1.1, "body": Color(0.45, 0.38, 0.25), "accent": Color(1.0, 0.75, 0.25)},
			{"name": "Corrupted Temple Guardian (Lv.22)", "lv": 22, "hp": 680, "atk": 42, "bounty": 420, "farr_u": 22, "farr_v": 560, "pos": Vector3(0.0, 0.0, -18.0), "scale": 1.25, "body": Color(0.40, 0.32, 0.20), "accent": Color(1.0, 0.70, 0.20)},
			{"name": "AZUR-FRAVASHI ZEALOT", "lv": 25, "hp": 2700, "atk": 50, "bounty": 1600, "farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0, "body": Color(0.62, 0.50, 0.25), "accent": Color(1.0, 0.95, 0.45), "is_pit_boss": true},
		],
	},

	"legion_basic": {
		"id": "legion_basic",
		"name": "Ashen Blood-Basin",
		"category": "FACTION_BASIC",
		"owner_faction": "legion",
		"level_band": "Lv.12-25",
		"farming_focus": "BASIC_SOLO",
		"terrain_theme": "VOLCANIC_BASIN",
		"ground_color": Color(0.24, 0.14, 0.16),
		"sky_top": Color(0.14, 0.05, 0.08),
		"sky_horizon": Color(0.42, 0.16, 0.22),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 8.5, "name": "Boiling Blood Crater Pit"},
		"summon_beacon": {"name": "Ashen Blood Summon Beacon", "pos": Vector3(12.0, 0.0, 24.0), "col": Color(0.95, 0.3, 0.35)},
		"pit_boss": {
			"name": "AKA-MANAH WAR-EXECUTIONER", "title": "Basic Ground Pit Boss", "lv": 25, "hp": 2800, "atk": 54, "bounty": 1600,
			"farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0,
			"body": Color(0.48, 0.12, 0.20), "accent": Color(1.0, 0.20, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 32.0), "order": Vector3(0.0, 0.1, 32.0), "legion": Vector3(0.0, 0.1, 32.0)},
		"refineries": [{"name": "Basin Blood-Extraction Node", "pos": Vector3(0.0, 0.0, 36.0)}],
		"npcs": [
			{"name": "Soul-Binder Rebirth NPC", "title": "Basin Rebirth & Save NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(-6.0, 0.0, 32.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.3, 0.4)},
			{"name": "Trench Armorer R-04", "title": "Outpost Potion & Utility NPC", "type": "POTION", "faction": "legion", "pos": Vector3(6.0, 0.0, 32.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.25, 0.35)},
		],
		"veins": [
			{"name": "Basin Brimstone Vein Alpha", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(0.95, 0.3, 0.35)},
			{"name": "Basin Brimstone Vein Beta", "pos": Vector3(16.0, 0.0, 10.0), "scale": 1.15, "max_units": 6, "yield": 12, "val": 28, "dur": 1.8, "col": Color(0.95, 0.3, 0.35)},
		],
		"portals": [
			{"title": "South Portal -> Druj Citadel HQ", "target": "legion_hq", "pos": Vector3(0.0, 0.0, 42.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "East Gate -> Brimstone Quarry Outpost", "target": "legion_outpost", "pos": Vector3(26.0, 0.0, 0.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "North Gate -> Sette Dune Sea (Borderlands)", "target": "border_sette", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(1.0, 0.75, 0.25)},
		],
		"enemies": [
			{"name": "Blood-Gorged Hound (Lv.14)", "lv": 14, "hp": 340, "atk": 24, "bounty": 230, "farr_u": 15, "farr_v": 320, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.05, "body": Color(0.44, 0.14, 0.18), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Cinder-Spike Behemoth (Lv.18)", "lv": 18, "hp": 480, "atk": 32, "bounty": 310, "farr_u": 18, "farr_v": 420, "pos": Vector3(12.0, 0.0, -8.0), "scale": 1.1, "body": Color(0.38, 0.12, 0.16), "accent": Color(1.0, 0.2, 0.3)},
			{"name": "Druj Heretic Berserker (Lv.22)", "lv": 22, "hp": 680, "atk": 42, "bounty": 420, "farr_u": 22, "farr_v": 560, "pos": Vector3(0.0, 0.0, -18.0), "scale": 1.25, "body": Color(0.32, 0.10, 0.14), "accent": Color(0.95, 0.18, 0.25)},
			{"name": "AKA-MANAH WAR-EXECUTIONER", "lv": 25, "hp": 2800, "atk": 54, "bounty": 1600, "farr_u": 40, "farr_v": 1400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 2.6, "range": 3.6, "aggro": 9.0, "body": Color(0.48, 0.12, 0.20), "accent": Color(1.0, 0.20, 0.35), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 3: FACTION SECONDARY OUTPOSTS (Lv. 22-32)
	# ==========================================================================
	"svel_outpost": {
		"id": "svel_outpost",
		"name": "Sub-Deck Turbine Chasm (Outpost 117)",
		"category": "FACTION_OUTPOST",
		"owner_faction": "sveleitre",
		"level_band": "Lv.22-32",
		"farming_focus": "COMPONENT_SALVAGE",
		"terrain_theme": "ARK_SUPERCORE",
		"ground_color": Color(0.16, 0.20, 0.26),
		"sky_top": Color(0.06, 0.10, 0.18),
		"sky_horizon": Color(0.20, 0.35, 0.50),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -28.0), "radius": 9.0, "name": "Turbine Vent Pit"},
		"summon_beacon": {"name": "Sub-Deck Forward Beacon", "pos": Vector3(14.0, 0.0, 18.0), "col": Color(0.3, 0.9, 1.0)},
		"pit_boss": {
			"name": "SUB-DECK TURBINE COLOSSUS", "title": "Outpost Pit Boss", "lv": 30, "hp": 3400, "atk": 68, "bounty": 2100,
			"farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5,
			"body": Color(0.22, 0.34, 0.46), "accent": Color(0.4, 1.0, 0.95), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 28.0), "order": Vector3(0.0, 0.1, 28.0), "legion": Vector3(0.0, 0.1, 28.0)},
		"refineries": [{"name": "Outpost 117 Sub-Deck Refinery", "pos": Vector3(0.0, 0.0, 32.0)}],
		"npcs": [
			{"name": "Sub-Deck Rebirth Hub", "title": "Outpost Rebirth NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(-6.0, 0.0, 26.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.35, 0.85, 1.0)},
			{"name": "Salvage Logistics Node", "title": "Outpost Merchant NPC", "type": "POTION", "faction": "sveleitre", "pos": Vector3(6.0, 0.0, 26.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.4, 0.95, 1.0)},
		],
		"veins": [{"name": "Turbine Core Heavy Vein", "pos": Vector3(-14.0, 0.0, 6.0), "scale": 1.2, "max_units": 7, "yield": 14, "val": 35, "dur": 1.8, "col": Color(0.35, 0.9, 1.0)}],
		"portals": [
			{"title": "West Portal -> Cryo-Scrap Frontier", "target": "svel_basic", "pos": Vector3(-26.0, 0.0, 0.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "North Breach -> Permafrost Rift (Borderlands)", "target": "border_glacier", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(0.4, 0.85, 1.0)},
		],
		"enemies": [
			{"name": "Overclocked Turbine Mech (Lv.24)", "lv": 24, "hp": 740, "atk": 46, "bounty": 460, "farr_u": 24, "farr_v": 620, "pos": Vector3(-10.0, 0.0, -10.0), "scale": 1.15, "body": Color(0.25, 0.36, 0.48), "accent": Color(0.4, 0.9, 1.0)},
			{"name": "Plasma Conduit Sentry (Lv.28)", "lv": 28, "hp": 890, "atk": 56, "bounty": 550, "farr_u": 28, "farr_v": 750, "pos": Vector3(10.0, 0.0, -10.0), "scale": 1.2, "body": Color(0.22, 0.32, 0.44), "accent": Color(0.35, 0.85, 1.0)},
			{"name": "SUB-DECK TURBINE COLOSSUS", "lv": 30, "hp": 3400, "atk": 68, "bounty": 2100, "farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5, "body": Color(0.22, 0.34, 0.46), "accent": Color(0.4, 1.0, 0.95), "is_pit_boss": true},
		],
	},

	"order_outpost": {
		"id": "order_outpost",
		"name": "Pilgrim's Oasis Sanctuary (Solus Outpost)",
		"category": "FACTION_OUTPOST",
		"owner_faction": "order",
		"level_band": "Lv.22-32",
		"farming_focus": "RESTORATIVE_HERBS",
		"terrain_theme": "HOLY_TEMPLE",
		"ground_color": Color(0.30, 0.34, 0.26),
		"sky_top": Color(0.16, 0.20, 0.14),
		"sky_horizon": Color(0.45, 0.50, 0.32),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -28.0), "radius": 9.0, "name": "Sacred Spring Pit"},
		"summon_beacon": {"name": "Oasis Pilgrim Beacon", "pos": Vector3(14.0, 0.0, 18.0), "col": Color(1.0, 0.88, 0.4)},
		"pit_boss": {
			"name": "OASIS GUARDIAN FRAVASHI", "title": "Outpost Pit Boss", "lv": 30, "hp": 3300, "atk": 65, "bounty": 2100,
			"farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5,
			"body": Color(0.58, 0.52, 0.30), "accent": Color(1.0, 0.95, 0.4), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 28.0), "order": Vector3(0.0, 0.1, 28.0), "legion": Vector3(0.0, 0.1, 28.0)},
		"refineries": [{"name": "Solus Oasis Sacred Refinery", "pos": Vector3(0.0, 0.0, 32.0)}],
		"npcs": [
			{"name": "Solus Oasis Rebirth NPC", "title": "Outpost Rebirth NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(-6.0, 0.0, 26.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Oasis Herbalist Merchant", "title": "Outpost Potion NPC", "type": "POTION", "faction": "order", "pos": Vector3(6.0, 0.0, 26.0), "body": Color(0.45, 0.40, 0.32), "accent": Color(1.0, 0.9, 0.45)},
		],
		"veins": [{"name": "Oasis Spring Rich Farr Vein", "pos": Vector3(-14.0, 0.0, 6.0), "scale": 1.2, "max_units": 7, "yield": 14, "val": 35, "dur": 1.8, "col": Color(1.0, 0.85, 0.3)}],
		"portals": [
			{"title": "West Portal -> Sun-Bleached Terraces", "target": "order_basic", "pos": Vector3(-26.0, 0.0, 0.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Breach -> Permafrost Rift (Borderlands)", "target": "border_glacier", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(0.4, 0.85, 1.0)},
		],
		"enemies": [
			{"name": "Oasis Dune-Stalker (Lv.24)", "lv": 24, "hp": 740, "atk": 46, "bounty": 460, "farr_u": 24, "farr_v": 620, "pos": Vector3(-10.0, 0.0, -10.0), "scale": 1.15, "body": Color(0.48, 0.42, 0.26), "accent": Color(1.0, 0.8, 0.35)},
			{"name": "Corrupted Sun-Guardian (Lv.28)", "lv": 28, "hp": 890, "atk": 56, "bounty": 550, "farr_u": 28, "farr_v": 750, "pos": Vector3(10.0, 0.0, -10.0), "scale": 1.2, "body": Color(0.42, 0.36, 0.22), "accent": Color(1.0, 0.75, 0.30)},
			{"name": "OASIS GUARDIAN FRAVASHI", "lv": 30, "hp": 3300, "atk": 65, "bounty": 2100, "farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5, "body": Color(0.58, 0.52, 0.30), "accent": Color(1.0, 0.95, 0.4), "is_pit_boss": true},
		],
	},

	"legion_outpost": {
		"id": "legion_outpost",
		"name": "Brimstone Quarry Fortress (Anacaade Outpost)",
		"category": "FACTION_OUTPOST",
		"owner_faction": "legion",
		"level_band": "Lv.22-32",
		"farming_focus": "MINERAL_ARMOR",
		"terrain_theme": "VOLCANIC_BASIN",
		"ground_color": Color(0.20, 0.12, 0.14),
		"sky_top": Color(0.12, 0.04, 0.06),
		"sky_horizon": Color(0.36, 0.12, 0.18),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -28.0), "radius": 9.0, "name": "Slag Excavation Pit"},
		"summon_beacon": {"name": "Quarry Fort Beacon", "pos": Vector3(14.0, 0.0, 18.0), "col": Color(0.95, 0.25, 0.3)},
		"pit_boss": {
			"name": "QUARRY SLAG-BEHEMOTH", "title": "Outpost Pit Boss", "lv": 30, "hp": 3500, "atk": 70, "bounty": 2100,
			"farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5,
			"body": Color(0.44, 0.12, 0.18), "accent": Color(1.0, 0.25, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(0.0, 0.1, 28.0), "order": Vector3(0.0, 0.1, 28.0), "legion": Vector3(0.0, 0.1, 28.0)},
		"refineries": [{"name": "Anacaade Quarry Slag Refinery", "pos": Vector3(0.0, 0.0, 32.0)}],
		"npcs": [
			{"name": "Anacaade Rebirth Node", "title": "Outpost Rebirth NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(-6.0, 0.0, 26.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Quarry Supply Master", "title": "Outpost Merchant NPC", "type": "POTION", "faction": "legion", "pos": Vector3(6.0, 0.0, 26.0), "body": Color(0.35, 0.18, 0.22), "accent": Color(1.0, 0.3, 0.4)},
		],
		"veins": [{"name": "Quarry Heavy Slag Vein", "pos": Vector3(-14.0, 0.0, 6.0), "scale": 1.2, "max_units": 7, "yield": 14, "val": 35, "dur": 1.8, "col": Color(0.95, 0.3, 0.35)}],
		"portals": [
			{"title": "West Portal -> Ashen Blood-Basin", "target": "legion_basic", "pos": Vector3(-26.0, 0.0, 0.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "North Breach -> Basalt Divide Trenches", "target": "border_trench", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(0.95, 0.25, 0.3)},
		],
		"enemies": [
			{"name": "Quarry Slag-Dredger (Lv.24)", "lv": 24, "hp": 740, "atk": 46, "bounty": 460, "farr_u": 24, "farr_v": 620, "pos": Vector3(-10.0, 0.0, -10.0), "scale": 1.15, "body": Color(0.40, 0.12, 0.16), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Molten Crust Fiend (Lv.28)", "lv": 28, "hp": 890, "atk": 56, "bounty": 550, "farr_u": 28, "farr_v": 750, "pos": Vector3(10.0, 0.0, -10.0), "scale": 1.2, "body": Color(0.35, 0.10, 0.14), "accent": Color(1.0, 0.2, 0.3)},
			{"name": "QUARRY SLAG-BEHEMOTH", "lv": 30, "hp": 3500, "atk": 70, "bounty": 2100, "farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -28.0), "scale": 2.8, "range": 3.8, "aggro": 9.5, "body": Color(0.44, 0.12, 0.18), "accent": Color(1.0, 0.25, 0.35), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 4: CONTESTED BORDERLANDS & THREE-WAY COLLISION (Lv. 30-38)
	# ==========================================================================
	"border_sette": {
		"id": "border_sette",
		"name": "The Sette Dune Sea (Three-Border Convergence)",
		"category": "CONTESTED_BORDER",
		"owner_faction": "all",
		"level_band": "Lv.30-38 (PvP Border)",
		"farming_focus": "PVP_BOUNTY",
		"terrain_theme": "DESERT_RUINS",
		"ground_color": Color(0.42, 0.34, 0.20),
		"sky_top": Color(0.18, 0.15, 0.10),
		"sky_horizon": Color(0.55, 0.44, 0.26),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 9.5, "name": "Sette Sunken Gate Pit"},
		"summon_beacon": {"name": "Sette Tri-Border Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.75, 0.25)},
		"pit_boss": {
			"name": "DUNE-STALKER ARCH-SCORPION", "title": "Borderland Pit Boss", "lv": 35, "hp": 4100, "atk": 85, "bounty": 2600,
			"farr_u": 50, "farr_v": 2300, "pos": Vector3(0.0, 0.0, -24.0), "scale": 2.9, "range": 4.0, "aggro": 10.0,
			"body": Color(0.52, 0.38, 0.18), "accent": Color(1.0, 0.8, 0.25), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Sette Tri-Border Field Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [
			{"name": "Sette Neutral Outpost Merchant", "title": "Field Trader", "type": "POTION", "faction": "all", "pos": Vector3(-6.0, 0.0, 4.0), "body": Color(0.3, 0.3, 0.3), "accent": Color(1.0, 0.8, 0.3)},
		],
		"veins": [
			{"name": "Sette Contested Gold Vein Alpha", "pos": Vector3(-18.0, 0.0, -8.0), "scale": 1.25, "max_units": 8, "yield": 16, "val": 42, "dur": 1.7, "col": Color(1.0, 0.78, 0.2)},
			{"name": "Sette Contested Gold Vein Beta", "pos": Vector3(18.0, 0.0, -8.0), "scale": 1.25, "max_units": 8, "yield": 16, "val": 42, "dur": 1.7, "col": Color(1.0, 0.78, 0.2)},
		],
		"portals": [
			{"title": "North Gate -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.8, 0.3)},
			{"title": "East Gate -> The Great Volcanic Caldera", "target": "farm_caldera_magma", "pos": Vector3(32.0, 0.0, 0.0), "col": Color(1.0, 0.4, 0.15)},
			{"title": "West Gate -> Aetherium Floating Platforms", "target": "farm_ether_sky", "pos": Vector3(-32.0, 0.0, 0.0), "col": Color(0.35, 0.9, 1.0)},
		],
		"enemies": [
			{"name": "Sette Sand-Stalker (Lv.30)", "lv": 30, "hp": 980, "atk": 62, "bounty": 620, "farr_u": 30, "farr_v": 850, "pos": Vector3(-14.0, 0.0, -12.0), "scale": 1.2, "body": Color(0.48, 0.36, 0.18), "accent": Color(1.0, 0.75, 0.25)},
			{"name": "Armored Dune-Crusher (Lv.33)", "lv": 33, "hp": 1150, "atk": 74, "bounty": 730, "farr_u": 34, "farr_v": 980, "pos": Vector3(14.0, 0.0, -12.0), "scale": 1.3, "body": Color(0.42, 0.30, 0.14), "accent": Color(1.0, 0.70, 0.20)},
			{"name": "DUNE-STALKER ARCH-SCORPION", "lv": 35, "hp": 4100, "atk": 85, "bounty": 2600, "farr_u": 50, "farr_v": 2300, "pos": Vector3(0.0, 0.0, -24.0), "scale": 2.9, "range": 4.0, "aggro": 10.0, "body": Color(0.52, 0.38, 0.18), "accent": Color(1.0, 0.8, 0.25), "is_pit_boss": true},
		],
	},

	"border_glacier": {
		"id": "border_glacier",
		"name": "Permafrost Rift Valley",
		"category": "CONTESTED_BORDER",
		"owner_faction": "all",
		"level_band": "Lv.32-40 (Glacier Rift)",
		"farming_focus": "CRYO_CORE",
		"terrain_theme": "FROZEN_SCRAP",
		"ground_color": Color(0.18, 0.28, 0.36),
		"sky_top": Color(0.04, 0.10, 0.20),
		"sky_horizon": Color(0.22, 0.44, 0.62),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 9.5, "name": "Glacial Crevasse Pit"},
		"summon_beacon": {"name": "Permafrost Rift Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.4, 0.85, 1.0)},
		"pit_boss": {
			"name": "PERMAFROST CRYO-TITAN", "title": "Glacier Pit Boss", "lv": 38, "hp": 4500, "atk": 92, "bounty": 2800,
			"farr_u": 55, "farr_v": 2600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.0, "range": 4.2, "aggro": 10.0,
			"body": Color(0.16, 0.28, 0.45), "accent": Color(0.45, 0.95, 1.0), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Permafrost Research Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Glacial Expedition Trader", "title": "Field Trader", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.25, 0.35, 0.45), "accent": Color(0.4, 0.9, 1.0)}],
		"veins": [{"name": "Cryo-Glacial Heavy Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.25, "max_units": 8, "yield": 16, "val": 42, "dur": 1.7, "col": Color(0.4, 0.9, 1.0)}],
		"portals": [
			{"title": "West Gate -> Aetherium Floating Platforms", "target": "farm_ether_sky", "pos": Vector3(-32.0, 0.0, 0.0), "col": Color(0.35, 0.9, 1.0)},
			{"title": "North Gate -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.8, 0.3)},
		],
		"enemies": [
			{"name": "Glacial Stalker Automaton (Lv.32)", "lv": 32, "hp": 1080, "atk": 70, "bounty": 690, "farr_u": 32, "farr_v": 920, "pos": Vector3(-12.0, 0.0, -12.0), "scale": 1.2, "body": Color(0.24, 0.35, 0.48), "accent": Color(0.4, 0.9, 1.0)},
			{"name": "Cryo-Shock Behemoth (Lv.36)", "lv": 36, "hp": 1320, "atk": 84, "bounty": 820, "farr_u": 36, "farr_v": 1100, "pos": Vector3(12.0, 0.0, -12.0), "scale": 1.3, "body": Color(0.20, 0.30, 0.42), "accent": Color(0.45, 0.95, 1.0)},
			{"name": "PERMAFROST CRYO-TITAN", "lv": 38, "hp": 4500, "atk": 92, "bounty": 2800, "farr_u": 55, "farr_v": 2600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.0, "range": 4.2, "aggro": 10.0, "body": Color(0.16, 0.28, 0.45), "accent": Color(0.45, 0.95, 1.0), "is_pit_boss": true},
		],
	},

	"border_trench": {
		"id": "border_trench",
		"name": "Basalt Divide Trenches",
		"category": "CONTESTED_BORDER",
		"owner_faction": "all",
		"level_band": "Lv.32-40 (Trench Warfare)",
		"farming_focus": "PIERCING_AMMO",
		"terrain_theme": "BORDER_TRENCHES",
		"ground_color": Color(0.20, 0.12, 0.16),
		"sky_top": Color(0.10, 0.04, 0.08),
		"sky_horizon": Color(0.34, 0.14, 0.22),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 9.5, "name": "Basalt Divide Pit"},
		"summon_beacon": {"name": "Divide Trench Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.95, 0.25, 0.35)},
		"pit_boss": {
			"name": "TRENCH-BREAKER DREAD-GORGER", "title": "Trench Pit Boss", "lv": 38, "hp": 4600, "atk": 95, "bounty": 2800,
			"farr_u": 55, "farr_v": 2600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.0, "range": 4.2, "aggro": 10.0,
			"body": Color(0.44, 0.10, 0.18), "accent": Color(1.0, 0.20, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Basalt Trench Field Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Frontline Ammo Provisioner", "title": "Field Trader", "type": "WEAPON", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.3, 0.2, 0.25), "accent": Color(1.0, 0.3, 0.4)}],
		"veins": [{"name": "Obsidian Trench Heavy Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.25, "max_units": 8, "yield": 16, "val": 42, "dur": 1.7, "col": Color(0.95, 0.25, 0.35)}],
		"portals": [
			{"title": "East Gate -> The Great Volcanic Caldera", "target": "farm_caldera_magma", "pos": Vector3(32.0, 0.0, 0.0), "col": Color(1.0, 0.4, 0.15)},
			{"title": "North Gate -> Scorched Var Cauldron", "target": "contested_cauldron", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.35, 0.2)},
		],
		"enemies": [
			{"name": "Barbed Trench-Slasher (Lv.32)", "lv": 32, "hp": 1080, "atk": 70, "bounty": 690, "farr_u": 32, "farr_v": 920, "pos": Vector3(-12.0, 0.0, -12.0), "scale": 1.2, "body": Color(0.40, 0.12, 0.18), "accent": Color(1.0, 0.25, 0.35)},
			{"name": "Obsidian Bone-Gorger (Lv.36)", "lv": 36, "hp": 1320, "atk": 84, "bounty": 820, "farr_u": 36, "farr_v": 1100, "pos": Vector3(12.0, 0.0, -12.0), "scale": 1.3, "body": Color(0.36, 0.10, 0.15), "accent": Color(1.0, 0.2, 0.3)},
			{"name": "TRENCH-BREAKER DREAD-GORGER", "lv": 38, "hp": 4600, "atk": 95, "bounty": 2800, "farr_u": 55, "farr_v": 2600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.0, "range": 4.2, "aggro": 10.0, "body": Color(0.44, 0.10, 0.18), "accent": Color(1.0, 0.20, 0.35), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 5: SPECIALIZED ECONOMIC FARMING NICHES (Lv. 36-46)
	# ==========================================================================
	"farm_ether_sky": {
		"id": "farm_ether_sky",
		"name": "Aetherium Floating Platforms (The Sky Floe)",
		"category": "FARMING_NICHE",
		"owner_faction": "all",
		"level_band": "Lv.38-46 (💰 Wealth Farm)",
		"farming_focus": "WEALTH_CREDITS",
		"terrain_theme": "AETHER_SKY",
		"ground_color": Color(0.24, 0.30, 0.38),
		"sky_top": Color(0.12, 0.24, 0.40),
		"sky_horizon": Color(0.40, 0.65, 0.85),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 10.0, "name": "Gravity-Anchor Core Pit"},
		"summon_beacon": {"name": "Aether Platform Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.4, 0.95, 1.0)},
		"pit_boss": {
			"name": "AETHER-CORE ARCH-VALKYRIE", "title": "Aetherium Pit Boss", "lv": 42, "hp": 5100, "atk": 108, "bounty": 3500,
			"farr_u": 60, "farr_v": 3400, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.2, "range": 4.5, "aggro": 10.5,
			"body": Color(0.85, 0.92, 1.0), "accent": Color(0.3, 0.95, 1.0), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Aetherium High-Purity Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Aether Gold Exchange NPC", "title": "Wealth Merchant", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.8, 0.85, 0.95), "accent": Color(0.4, 0.9, 1.0)}],
		"veins": [{"name": "Floating Aetherium Megavein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.3, "max_units": 9, "yield": 20, "val": 60, "dur": 1.6, "col": Color(0.45, 0.95, 1.0)}],
		"portals": [
			{"title": "Portal -> Sette Dune Sea", "target": "border_sette", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(1.0, 0.75, 0.25)},
			{"title": "Sky Gate -> Catacombs of First Kings", "target": "farm_relic_catacombs", "pos": Vector3(32.0, 0.0, 0.0), "col": Color(1.0, 0.8, 0.35)},
		],
		"enemies": [
			{"name": "Aether-Winged Corsair (Lv.38)", "lv": 38, "hp": 1420, "atk": 90, "bounty": 1250, "farr_u": 40, "farr_v": 1300, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.25, "body": Color(0.4, 0.55, 0.70), "accent": Color(0.4, 0.95, 1.0)},
			{"name": "Calliana Scrap-Matron (Lv.40)", "lv": 40, "hp": 1650, "atk": 100, "bounty": 1500, "farr_u": 45, "farr_v": 1550, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.35, 0.50, 0.65), "accent": Color(0.35, 0.90, 1.0)},
			{"name": "AETHER-CORE ARCH-VALKYRIE", "lv": 42, "hp": 5100, "atk": 108, "bounty": 3500, "farr_u": 60, "farr_v": 3400, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.2, "range": 4.5, "aggro": 10.5, "body": Color(0.85, 0.92, 1.0), "accent": Color(0.3, 0.95, 1.0), "is_pit_boss": true},
		],
	},

	"farm_caldera_magma": {
		"id": "farm_caldera_magma",
		"name": "The Great Volcanic Caldera",
		"category": "FARMING_NICHE",
		"owner_faction": "all",
		"level_band": "Lv.40-47 (💎 Talic Farm)",
		"farming_focus": "TALIC_FARMING",
		"terrain_theme": "MAGMA_CALDERA",
		"ground_color": Color(0.24, 0.12, 0.10),
		"sky_top": Color(0.14, 0.04, 0.04),
		"sky_horizon": Color(0.50, 0.18, 0.08),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 10.0, "name": "Molten Caldera Core Pit"},
		"summon_beacon": {"name": "Volcano Caldera Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.45, 0.15)},
		"pit_boss": {
			"name": "MAGMA-MAW DRAKE-TYRANT", "title": "Caldera Pit Boss", "lv": 44, "hp": 5300, "atk": 114, "bounty": 3700,
			"farr_u": 65, "farr_v": 3700, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.3, "range": 4.6, "aggro": 10.5,
			"body": Color(0.55, 0.14, 0.08), "accent": Color(1.0, 0.45, 0.1), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Volcano Caldera Smelter Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Caldera Blacksmith Trader", "title": "Talic Merchant", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.35, 0.16, 0.12), "accent": Color(1.0, 0.4, 0.15)}],
		"veins": [{"name": "Caldera Pure Brimstone Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.3, "max_units": 9, "yield": 20, "val": 60, "dur": 1.6, "col": Color(1.0, 0.45, 0.15)}],
		"portals": [
			{"title": "Portal -> Sette Dune Sea", "target": "border_sette", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(1.0, 0.75, 0.25)},
			{"title": "Gate -> Subterranean Luminescent Aqueduct", "target": "farm_deep_aquifer", "pos": Vector3(32.0, 0.0, 0.0), "col": Color(0.3, 0.85, 0.75)},
		],
		"enemies": [
			{"name": "Caldera Ash-Drake (Lv.40)", "lv": 40, "hp": 1600, "atk": 102, "bounty": 1050, "farr_u": 42, "farr_v": 1400, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.25, "body": Color(0.48, 0.16, 0.10), "accent": Color(1.0, 0.45, 0.15)},
			{"name": "Magma Golem Titan (Lv.42)", "lv": 42, "hp": 1850, "atk": 112, "bounty": 1200, "farr_u": 48, "farr_v": 1650, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.40, 0.12, 0.08), "accent": Color(1.0, 0.40, 0.10)},
			{"name": "MAGMA-MAW DRAKE-TYRANT", "lv": 44, "hp": 5300, "atk": 114, "bounty": 3700, "farr_u": 65, "farr_v": 3700, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.3, "range": 4.6, "aggro": 10.5, "body": Color(0.55, 0.14, 0.08), "accent": Color(1.0, 0.45, 0.1), "is_pit_boss": true},
		],
	},

	"farm_relic_catacombs": {
		"id": "farm_relic_catacombs",
		"name": "Catacombs of the First Kings",
		"category": "FARMING_NICHE",
		"owner_faction": "all",
		"level_band": "Lv.38-46 (🛡️ Rare Gear)",
		"farming_focus": "RARE_GEAR",
		"terrain_theme": "CATACOMB_CRYPT",
		"ground_color": Color(0.34, 0.28, 0.22),
		"sky_top": Color(0.12, 0.10, 0.08),
		"sky_horizon": Color(0.40, 0.32, 0.20),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 10.0, "name": "Royal Sarcophagus Pit"},
		"summon_beacon": {"name": "First Kings Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.85, 0.35)},
		"pit_boss": {
			"name": "CATACOMB TOMB-SOVEREIGN", "title": "Catacomb Pit Boss", "lv": 43, "hp": 5200, "atk": 110, "bounty": 3600,
			"farr_u": 62, "farr_v": 3500, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.2, "range": 4.5, "aggro": 10.5,
			"body": Color(0.55, 0.44, 0.25), "accent": Color(1.0, 0.88, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Tomb Excavation Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Relic Archaeologist NPC", "title": "Relic Merchant", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.4, 0.35, 0.28), "accent": Color(1.0, 0.8, 0.3)}],
		"veins": [{"name": "Sarcophagus Gold Farr Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.3, "max_units": 9, "yield": 20, "val": 60, "dur": 1.6, "col": Color(1.0, 0.82, 0.25)}],
		"portals": [
			{"title": "Portal -> Aetherium Platforms", "target": "farm_ether_sky", "pos": Vector3(-32.0, 0.0, 0.0), "col": Color(0.35, 0.9, 1.0)},
			{"title": "Gate -> Foundations of the Var (Dungeon)", "target": "dungeon_var_roots", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(1.0, 0.85, 0.3)},
		],
		"enemies": [
			{"name": "Mummified Royal Spearguard (Lv.38)", "lv": 38, "hp": 1450, "atk": 92, "bounty": 1100, "farr_u": 42, "farr_v": 1350, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.25, "body": Color(0.48, 0.40, 0.24), "accent": Color(1.0, 0.8, 0.3)},
			{"name": "Ancient Stone Sphinx (Lv.41)", "lv": 41, "hp": 1780, "atk": 108, "bounty": 1320, "farr_u": 46, "farr_v": 1580, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.42, 0.34, 0.20), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "CATACOMB TOMB-SOVEREIGN", "lv": 43, "hp": 5200, "atk": 110, "bounty": 3600, "farr_u": 62, "farr_v": 3500, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.2, "range": 4.5, "aggro": 10.5, "body": Color(0.55, 0.44, 0.25), "accent": Color(1.0, 0.88, 0.35), "is_pit_boss": true},
		],
	},

	"farm_deep_aquifer": {
		"id": "farm_deep_aquifer",
		"name": "Subterranean Luminescent Aqueduct",
		"category": "FARMING_NICHE",
		"owner_faction": "all",
		"level_band": "Lv.36-44 (💧 Force / Buff Farm)",
		"farming_focus": "FORCE_POTIONS",
		"terrain_theme": "LUMINESCENT_AQUIFER",
		"ground_color": Color(0.20, 0.28, 0.30),
		"sky_top": Color(0.08, 0.14, 0.16),
		"sky_horizon": Color(0.25, 0.45, 0.45),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 10.0, "name": "Sunken Cistern Pit"},
		"summon_beacon": {"name": "Luminescent Aquifer Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.3, 0.95, 0.85)},
		"pit_boss": {
			"name": "AQUEDUCT HYDRA-SERPENT", "title": "Aqueduct Pit Boss", "lv": 40, "hp": 4800, "atk": 102, "bounty": 3200,
			"farr_u": 58, "farr_v": 3000, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.1, "range": 4.4, "aggro": 10.0,
			"body": Color(0.20, 0.42, 0.45), "accent": Color(0.35, 1.0, 0.85), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Aqueduct Water-Purifier Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Aquifer Alchemist Trader", "title": "Potion Merchant", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.25, 0.35, 0.38), "accent": Color(0.3, 0.9, 0.8)}],
		"veins": [{"name": "Luminescent Cyan Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.3, "max_units": 9, "yield": 20, "val": 60, "dur": 1.6, "col": Color(0.3, 0.95, 0.85)}],
		"portals": [
			{"title": "Portal -> Volcanic Caldera", "target": "farm_caldera_magma", "pos": Vector3(-32.0, 0.0, 0.0), "col": Color(1.0, 0.45, 0.15)},
			{"title": "Gate -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(0.0, 0.0, -36.0), "col": Color(1.0, 0.8, 0.3)},
		],
		"enemies": [
			{"name": "Luminescent Water-Nymph (Lv.36)", "lv": 36, "hp": 1340, "atk": 82, "bounty": 840, "farr_u": 38, "farr_v": 1150, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.2, "body": Color(0.26, 0.44, 0.48), "accent": Color(0.35, 0.95, 0.85)},
			{"name": "Deep-Channel Basilisk (Lv.39)", "lv": 39, "hp": 1580, "atk": 96, "bounty": 1020, "farr_u": 42, "farr_v": 1380, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.22, 0.38, 0.42), "accent": Color(0.3, 0.9, 0.8)},
			{"name": "AQUEDUCT HYDRA-SERPENT", "lv": 40, "hp": 4800, "atk": 102, "bounty": 3200, "farr_u": 58, "farr_v": 3000, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.1, "range": 4.4, "aggro": 10.0, "body": Color(0.20, 0.42, 0.45), "accent": Color(0.35, 1.0, 0.85), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 6: UPPER CONTESTED STEPPES & CAULDRON (Lv. 38-50)
	# ==========================================================================
	"contested_steppes": {
		"id": "contested_steppes",
		"name": "Shattered Persepolis Steppes",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Lv.38-48 (World Boss)",
		"farming_focus": "WORLD_BOSS",
		"terrain_theme": "PERSEPOLIS_STEPPES",
		"ground_color": Color(0.38, 0.30, 0.20),
		"sky_top": Color(0.20, 0.16, 0.10),
		"sky_horizon": Color(0.52, 0.42, 0.25),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 12.0, "name": "Throne Pit of King Yima"},
		"summon_beacon": {"name": "Persepolis Steppes Summon Beacon", "pos": Vector3(0.0, 0.0, 20.0), "col": Color(1.0, 0.78, 0.25)},
		"pit_boss": {
			"name": "PERSEPOLIS RUIN GOLIATH", "title": "Steppes Pit Boss", "lv": 38, "hp": 4500, "atk": 96, "bounty": 2900,
			"farr_u": 55, "farr_v": 2900, "pos": Vector3(0.0, 0.0, -6.0), "scale": 3.0, "range": 4.5, "aggro": 10.0,
			"body": Color(0.52, 0.38, 0.22), "accent": Color(1.0, 0.82, 0.28), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-28.0, 0.1, 28.0), "order": Vector3(28.0, 0.1, 28.0), "legion": Vector3(0.0, 0.1, -38.0)},
		"refineries": [{"name": "Persepolis Steppes Central Field Refinery", "pos": Vector3(0.0, 0.0, 8.0)}],
		"npcs": [
			{"name": "Steppes Forward Post Trader", "title": "Field Provisioner", "type": "POTION", "faction": "all", "pos": Vector3(-6.0, 0.0, 14.0), "body": Color(0.42, 0.32, 0.22), "accent": Color(1.0, 0.8, 0.3)},
		],
		"veins": [
			{"name": "Steppes Megavein Alpha (Lv.28-38)", "pos": Vector3(-18.0, 0.0, 0.0), "scale": 1.35, "max_units": 9, "yield": 20, "val": 45, "dur": 1.7, "col": Color(1.0, 0.8, 0.25)},
			{"name": "Steppes Megavein Beta (Lv.28-38)", "pos": Vector3(18.0, 0.0, 0.0), "scale": 1.35, "max_units": 9, "yield": 20, "val": 45, "dur": 1.7, "col": Color(1.0, 0.8, 0.25)},
		],
		"portals": [
			{"title": "South Portal -> Sette Dune Sea", "target": "border_sette", "pos": Vector3(0.0, 0.0, 42.0), "col": Color(1.0, 0.75, 0.25)},
			{"title": "East Gate -> Royal Upper Terrace", "target": "steppes_highlands", "pos": Vector3(34.0, 0.0, 0.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Breach -> Scorched Var Cauldron", "target": "contested_cauldron", "pos": Vector3(0.0, 0.0, -44.0), "col": Color(1.0, 0.4, 0.2)},
		],
		"enemies": [
			{"name": "Achaemenid Bronze Centurion (Lv.36)", "lv": 36, "hp": 1350, "atk": 84, "bounty": 780, "farr_u": 38, "farr_v": 1100, "pos": Vector3(-14.0, 0.0, -12.0), "scale": 1.25, "body": Color(0.50, 0.38, 0.24), "accent": Color(1.0, 0.8, 0.3)},
			{"name": "Ruined Bull-Gargant (Lv.38)", "lv": 38, "hp": 1500, "atk": 94, "bounty": 890, "farr_u": 42, "farr_v": 1250, "pos": Vector3(14.0, 0.0, -12.0), "scale": 1.3, "body": Color(0.44, 0.32, 0.18), "accent": Color(1.0, 0.75, 0.25)},
			{"name": "PERSEPOLIS RUIN GOLIATH", "lv": 38, "hp": 4500, "atk": 96, "bounty": 2900, "farr_u": 55, "farr_v": 2900, "pos": Vector3(0.0, 0.0, -6.0), "scale": 3.0, "range": 4.5, "aggro": 10.0, "body": Color(0.52, 0.38, 0.22), "accent": Color(1.0, 0.82, 0.28), "is_pit_boss": true},
			{"name": "YIMA, THE HOLLOW KING (Forsworn World Boss)", "lv": 50, "hp": 5800, "atk": 140, "bounty": 4500, "farr_u": 70, "farr_v": 5200, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.8, "range": 5.0, "aggro": 11.0, "body": Color(0.55, 0.42, 0.24), "accent": Color(1.0, 0.85, 0.25), "is_pit_boss": true},
		],
	},

	"contested_cauldron": {
		"id": "contested_cauldron",
		"name": "Scorched Var Cauldron",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Lv.42-50 (Endgame War)",
		"farming_focus": "WORLD_BOSS",
		"terrain_theme": "SCORCHED_CAULDRON",
		"ground_color": Color(0.24, 0.14, 0.18),
		"sky_top": Color(0.12, 0.04, 0.08),
		"sky_horizon": Color(0.40, 0.15, 0.20),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 14.0, "name": "Forsworn Crucible Pit"},
		"summon_beacon": {"name": "Scorched Cauldron Summon Beacon", "pos": Vector3(0.0, 0.0, 20.0), "col": Color(1.0, 0.35, 0.18)},
		"pit_boss": {
			"name": "ABYSSAL DAEVA OVERLORD", "title": "Cauldron Pit Boss", "lv": 44, "hp": 5200, "atk": 112, "bounty": 3600,
			"farr_u": 60, "farr_v": 3600, "pos": Vector3(0.0, 0.0, -8.0), "scale": 3.2, "range": 4.8, "aggro": 10.5,
			"body": Color(0.45, 0.12, 0.35), "accent": Color(1.0, 0.25, 0.55), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-28.0, 0.1, 28.0), "order": Vector3(28.0, 0.1, 28.0), "legion": Vector3(0.0, 0.1, -38.0)},
		"refineries": [{"name": "Scorched Cauldron Crucible Refinery", "pos": Vector3(0.0, 0.0, 8.0)}],
		"npcs": [{"name": "Crucible War Provisioner", "title": "Field Trader", "type": "POTION", "faction": "all", "pos": Vector3(-6.0, 0.0, 14.0), "body": Color(0.38, 0.16, 0.22), "accent": Color(1.0, 0.3, 0.4)}],
		"veins": [
			{"name": "Cauldron Abyssal Vein Alpha (Lv.36-45)", "pos": Vector3(-18.0, 0.0, 0.0), "scale": 1.4, "max_units": 10, "yield": 25, "val": 55, "dur": 1.6, "col": Color(1.0, 0.35, 0.2)},
			{"name": "Cauldron Abyssal Vein Beta (Lv.36-45)", "pos": Vector3(18.0, 0.0, 0.0), "scale": 1.4, "max_units": 10, "yield": 25, "val": 55, "dur": 1.6, "col": Color(1.0, 0.35, 0.2)},
		],
		"portals": [
			{"title": "South Portal -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(0.0, 0.0, 42.0), "col": Color(1.0, 0.8, 0.3)},
			{"title": "East Gate -> The Daevic Chasm", "target": "cauldron_abyss", "pos": Vector3(34.0, 0.0, 0.0), "col": Color(0.85, 0.15, 0.35)},
			{"title": "North Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(0.0, 0.0, -44.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Daevic Blood-Fiend (Lv.42)", "lv": 42, "hp": 1800, "atk": 110, "bounty": 1180, "farr_u": 46, "farr_v": 1600, "pos": Vector3(-14.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.48, 0.14, 0.24), "accent": Color(1.0, 0.3, 0.5)},
			{"name": "Forsworn Arch-Executioner (Lv.44)", "lv": 44, "hp": 2100, "atk": 122, "bounty": 1350, "farr_u": 52, "farr_v": 1850, "pos": Vector3(14.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.42, 0.10, 0.20), "accent": Color(1.0, 0.2, 0.4)},
			{"name": "ABYSSAL DAEVA OVERLORD", "lv": 44, "hp": 5200, "atk": 112, "bounty": 3600, "farr_u": 60, "farr_v": 3600, "pos": Vector3(0.0, 0.0, -8.0), "scale": 3.2, "range": 4.8, "aggro": 10.5, "body": Color(0.45, 0.12, 0.35), "accent": Color(1.0, 0.25, 0.55), "is_pit_boss": true},
			{"name": "AESHMA, THE WRATH UNBOUND (Forsworn World Boss)", "lv": 50, "hp": 6500, "atk": 165, "bounty": 5000, "farr_u": 80, "farr_v": 6000, "pos": Vector3(-20.0, 0.0, -26.0), "scale": 4.5, "range": 5.5, "aggro": 12.0, "body": Color(0.88, 0.86, 0.85), "accent": Color(1.0, 0.15, 0.15), "is_pit_boss": true},
			{"name": "THE ORPHAN PROCESS (Forsworn World Boss)", "lv": 50, "hp": 6000, "atk": 148, "bounty": 4600, "farr_u": 75, "farr_v": 5500, "pos": Vector3(20.0, 0.0, -26.0), "scale": 3.8, "range": 5.5, "aggro": 11.5, "body": Color(0.28, 0.34, 0.40), "accent": Color(0.18, 0.95, 1.0), "is_pit_boss": true},
		],
	},

	"steppes_highlands": {
		"id": "steppes_highlands",
		"name": "Persepolis Upper Royal Terrace",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Lv.44-50 (Royal Ridge)",
		"farming_focus": "SOVEREIGN_TALICS",
		"terrain_theme": "PERSEPOLIS_STEPPES",
		"ground_color": Color(0.40, 0.32, 0.22),
		"sky_top": Color(0.18, 0.14, 0.10),
		"sky_horizon": Color(0.58, 0.46, 0.28),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 11.0, "name": "High Apadana Throne Pit"},
		"summon_beacon": {"name": "Royal Terrace Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.85, 0.35)},
		"pit_boss": {
			"name": "ROYAL APADANA COLOSSUS", "title": "Royal Terrace Pit Boss", "lv": 48, "hp": 5700, "atk": 125, "bounty": 4100,
			"farr_u": 70, "farr_v": 4400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.4, "range": 4.8, "aggro": 11.0,
			"body": Color(0.58, 0.46, 0.26), "accent": Color(1.0, 0.9, 0.35), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Royal Apadana Gold Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "High Court Rebirth Scribe", "title": "Royal Outpost NPC", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.48, 0.38, 0.26), "accent": Color(1.0, 0.85, 0.35)}],
		"veins": [{"name": "Apadana Imperial Farr Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 24, "val": 65, "dur": 1.6, "col": Color(1.0, 0.85, 0.35)}],
		"portals": [
			{"title": "West Gate -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(-34.0, 0.0, 0.0), "col": Color(1.0, 0.78, 0.25)},
			{"title": "East Gate -> The Great Beast Plateau", "target": "beast_plateau", "pos": Vector3(34.0, 0.0, 0.0), "col": Color(1.0, 0.5, 0.2)},
		],
		"enemies": [
			{"name": "Imperial Apadana Guardian (Lv.45)", "lv": 45, "hp": 2200, "atk": 128, "bounty": 1450, "farr_u": 55, "farr_v": 2000, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.52, 0.40, 0.25), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Ancient Gilded Sphinx (Lv.47)", "lv": 47, "hp": 2500, "atk": 138, "bounty": 1650, "farr_u": 60, "farr_v": 2300, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.48, 0.36, 0.22), "accent": Color(1.0, 0.90, 0.40)},
			{"name": "ROYAL APADANA COLOSSUS", "lv": 48, "hp": 5700, "atk": 125, "bounty": 4100, "farr_u": 70, "farr_v": 4400, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.4, "range": 4.8, "aggro": 11.0, "body": Color(0.58, 0.46, 0.26), "accent": Color(1.0, 0.9, 0.35), "is_pit_boss": true},
		],
	},

	"cauldron_abyss": {
		"id": "cauldron_abyss",
		"name": "The Daevic Chasm of Druj",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Lv.45-50 (Abyssal Void)",
		"farming_focus": "DARK_ESSENCE",
		"terrain_theme": "MAGMA_CALDERA",
		"ground_color": Color(0.18, 0.10, 0.14),
		"sky_top": Color(0.08, 0.02, 0.06),
		"sky_horizon": Color(0.32, 0.08, 0.16),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -26.0), "radius": 11.0, "name": "Abyssal Void Crack Pit"},
		"summon_beacon": {"name": "Daevic Chasm Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.9, 0.2, 0.4)},
		"pit_boss": {
			"name": "CHASM VOID-LEVIATHAN", "title": "Chasm Pit Boss", "lv": 49, "hp": 5900, "atk": 132, "bounty": 4300,
			"farr_u": 75, "farr_v": 4600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.5, "range": 5.0, "aggro": 11.0,
			"body": Color(0.38, 0.08, 0.20), "accent": Color(1.0, 0.20, 0.45), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Daevic Blood-Furnace Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Void Trench Rebirth Scribe", "title": "Chasm Outpost NPC", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.35, 0.12, 0.18), "accent": Color(1.0, 0.25, 0.40)}],
		"veins": [{"name": "Deep Abyssal Void Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 24, "val": 65, "dur": 1.6, "col": Color(0.95, 0.2, 0.4)}],
		"portals": [
			{"title": "West Gate -> Scorched Var Cauldron", "target": "contested_cauldron", "pos": Vector3(-34.0, 0.0, 0.0), "col": Color(1.0, 0.35, 0.2)},
			{"title": "North Gate -> Crypt of Seven Daevas (Dungeon)", "target": "dungeon_daeva_crypt", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.85, 0.15, 0.35)},
		],
		"enemies": [
			{"name": "Abyssal Shadow-Daeva (Lv.46)", "lv": 46, "hp": 2350, "atk": 134, "bounty": 1550, "farr_u": 58, "farr_v": 2150, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.42, 0.10, 0.22), "accent": Color(1.0, 0.25, 0.45)},
			{"name": "Corrupted Slag-Gargant (Lv.48)", "lv": 48, "hp": 2700, "atk": 145, "bounty": 1780, "farr_u": 65, "farr_v": 2450, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.36, 0.08, 0.18), "accent": Color(1.0, 0.20, 0.40)},
			{"name": "CHASM VOID-LEVIATHAN", "lv": 49, "hp": 5900, "atk": 132, "bounty": 4300, "farr_u": 75, "farr_v": 4600, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.5, "range": 5.0, "aggro": 11.0, "body": Color(0.38, 0.08, 0.20), "accent": Color(1.0, 0.20, 0.45), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 7: THE CRACK WAR GROUNDS (Lv. 25-50)
	# ==========================================================================
	"farr_mining_ground": {
		"id": "farr_mining_ground",
		"name": "The Crack — Central Farr Mining Ground",
		"category": "MINING_WAR",
		"owner_faction": "all",
		"level_band": "Lv.25-50 (PvPvE Ore War)",
		"farming_focus": "ORE_EXTRACTION",
		"terrain_theme": "CRACK_MINING",
		"ground_color": Color(0.26, 0.24, 0.20),
		"sky_top": Color(0.20, 0.14, 0.06),
		"sky_horizon": Color(0.62, 0.45, 0.15),
		"boss_pit": {"pos": Vector3(0.0, 0.0, 2.0), "radius": 12.0, "name": "Central Core Megavein Pit"},
		"summon_beacon": {"name": "Crack War Summon Beacon", "pos": Vector3(0.0, 0.0, 28.0), "col": Color(1.0, 0.65, 0.2)},
		"pit_boss": {
			"name": "CRACK CORE ARCH-LEVIATHAN", "title": "Mining War Pit Boss", "lv": 45, "hp": 5800, "atk": 128, "bounty": 4200,
			"farr_u": 80, "farr_v": 4600, "pos": Vector3(0.0, 0.0, 2.0), "scale": 3.5, "range": 5.0, "aggro": 11.0,
			"body": Color(0.58, 0.18, 0.42), "accent": Color(1.0, 0.55, 0.15), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-42.0, 0.1, 42.0), "order": Vector3(42.0, 0.1, 42.0), "legion": Vector3(0.0, 0.1, -48.0)},
		"refineries": [
			{"name": "Sveleitre Mining Outpost Refinery (SW)", "pos": Vector3(-36.0, 0.0, 36.0)},
			{"name": "Order Mining Outpost Refinery (SE)", "pos": Vector3(36.0, 0.0, 36.0)},
			{"name": "Legion Mining Outpost Refinery (North)", "pos": Vector3(0.0, 0.0, -42.0)},
			{"name": "Central Contested Megavein Core Refinery", "pos": Vector3(0.0, 0.0, 2.0)},
		],
		"npcs": [
			{"name": "Field Ammo & Charger Depot", "title": "War Provisioner", "type": "WEAPON", "faction": "all", "pos": Vector3(-8.0, 0.0, 18.0), "body": Color(0.35, 0.32, 0.28), "accent": Color(1.0, 0.65, 0.2)},
			{"name": "Field Medical Pod", "title": "Stim & Balm Trader", "type": "POTION", "faction": "all", "pos": Vector3(8.0, 0.0, 18.0), "body": Color(0.35, 0.32, 0.28), "accent": Color(0.4, 0.95, 0.7)},
		],
		"veins": [
			{"name": "Crack Scar Core Megavein Alpha", "pos": Vector3(-14.0, 0.0, -8.0), "scale": 1.5, "max_units": 14, "yield": 32, "val": 65, "dur": 1.4, "col": Color(1.0, 0.72, 0.15)},
			{"name": "Crack Scar Core Megavein Beta", "pos": Vector3(14.0, 0.0, -8.0), "scale": 1.5, "max_units": 14, "yield": 32, "val": 65, "dur": 1.4, "col": Color(1.0, 0.72, 0.15)},
			{"name": "Central Crater Pure Amber Megaspire", "pos": Vector3(0.0, 0.0, -18.0), "scale": 1.7, "max_units": 18, "yield": 40, "val": 75, "dur": 1.3, "col": Color(1.0, 0.85, 0.25)},
		],
		"portals": [
			{"title": "SW Gate -> Sveleitre Bastion HQ", "target": "svel_hq", "pos": Vector3(-46.0, 0.0, 46.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "SE Gate -> Order Sanctuary HQ", "target": "order_hq", "pos": Vector3(46.0, 0.0, 46.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Gate -> Legion Citadel HQ", "target": "legion_hq", "pos": Vector3(0.0, 0.0, -54.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "Down Gate -> Abyssal Vein Core (Lower Mine)", "target": "mining_lower_crater", "pos": Vector3(0.0, 0.0, -32.0), "col": Color(1.0, 0.55, 0.15)},
			{"title": "Up Gate -> Ridge of Tri-Bastions", "target": "mining_breach_ridge", "pos": Vector3(0.0, 0.0, 38.0), "col": Color(1.0, 0.75, 0.25)},
		],
		"enemies": [
			{"name": "Contested Slag-Ravager (Lv.35)", "lv": 35, "hp": 1300, "atk": 82, "bounty": 760, "farr_u": 36, "farr_v": 1050, "pos": Vector3(-18.0, 0.0, -12.0), "scale": 1.25, "body": Color(0.55, 0.24, 0.20), "accent": Color(1.0, 0.45, 0.2)},
			{"name": "Deep-Earth Harvester Beast (Lv.40)", "lv": 40, "hp": 1700, "atk": 104, "bounty": 1080, "farr_u": 44, "farr_v": 1450, "pos": Vector3(18.0, 0.0, -12.0), "scale": 1.3, "body": Color(0.48, 0.20, 0.16), "accent": Color(1.0, 0.40, 0.15)},
			{"name": "CRACK CORE ARCH-LEVIATHAN", "lv": 45, "hp": 5800, "atk": 128, "bounty": 4200, "farr_u": 80, "farr_v": 4600, "pos": Vector3(0.0, 0.0, 2.0), "scale": 3.5, "range": 5.0, "aggro": 11.0, "body": Color(0.58, 0.18, 0.42), "accent": Color(1.0, 0.55, 0.15), "is_pit_boss": true},
		],
	},

	"mining_lower_crater": {
		"id": "mining_lower_crater",
		"name": "The Abyssal Vein Core (Lower Mining Ground)",
		"category": "MINING_WAR",
		"owner_faction": "all",
		"level_band": "Lv.42-50 (⛏️ Extreme Ore)",
		"farming_focus": "MEGAVEIN_EXTRACTION",
		"terrain_theme": "LOWER_CRATER",
		"ground_color": Color(0.22, 0.18, 0.14),
		"sky_top": Color(0.14, 0.08, 0.04),
		"sky_horizon": Color(0.55, 0.35, 0.10),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 11.0, "name": "Deep Spire Cavity Pit"},
		"summon_beacon": {"name": "Lower Core Vein Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.7, 0.15)},
		"pit_boss": {
			"name": "CORE DRILL OVERCLOCKER", "title": "Lower Mine Pit Boss", "lv": 47, "hp": 5600, "atk": 124, "bounty": 4000,
			"farr_u": 85, "farr_v": 4800, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.3, "range": 4.8, "aggro": 11.0,
			"body": Color(0.48, 0.28, 0.16), "accent": Color(1.0, 0.70, 0.20), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Sub-Crater Heavy Smelter Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Core Drill Logistics Master", "title": "Field Trader", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.35, 0.28, 0.20), "accent": Color(1.0, 0.7, 0.2)}],
		"veins": [
			{"name": "Ultra-Rich Amber Megaspire A", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.6, "max_units": 16, "yield": 45, "val": 80, "dur": 1.3, "col": Color(1.0, 0.75, 0.15)},
			{"name": "Ultra-Rich Amber Megaspire B", "pos": Vector3(16.0, 0.0, -10.0), "scale": 1.6, "max_units": 16, "yield": 45, "val": 80, "dur": 1.3, "col": Color(1.0, 0.75, 0.15)},
		],
		"portals": [
			{"title": "Up Portal -> Central Mining Ground", "target": "farr_mining_ground", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Core-Borer Drill-Beast (Lv.43)", "lv": 43, "hp": 1950, "atk": 118, "bounty": 1300, "farr_u": 50, "farr_v": 1750, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.45, 0.25, 0.14), "accent": Color(1.0, 0.65, 0.15)},
			{"name": "Molten Ore Golem (Lv.46)", "lv": 46, "hp": 2400, "atk": 132, "bounty": 1600, "farr_u": 60, "farr_v": 2200, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.40, 0.20, 0.10), "accent": Color(1.0, 0.60, 0.10)},
			{"name": "CORE DRILL OVERCLOCKER", "lv": 47, "hp": 5600, "atk": 124, "bounty": 4000, "farr_u": 85, "farr_v": 4800, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.3, "range": 4.8, "aggro": 11.0, "body": Color(0.48, 0.28, 0.16), "accent": Color(1.0, 0.70, 0.20), "is_pit_boss": true},
		],
	},

	"mining_breach_ridge": {
		"id": "mining_breach_ridge",
		"name": "The Ridge of Tri-Bastions",
		"category": "MINING_WAR",
		"owner_faction": "all",
		"level_band": "Lv.38-48 (Sniper Ridge)",
		"farming_focus": "ARTILLERY_PVP",
		"terrain_theme": "BREACH_RIDGE",
		"ground_color": Color(0.28, 0.25, 0.20),
		"sky_top": Color(0.18, 0.12, 0.06),
		"sky_horizon": Color(0.58, 0.40, 0.18),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 11.0, "name": "High Overlook Ridge Pit"},
		"summon_beacon": {"name": "Tri-Bastion Ridge Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.75, 0.25)},
		"pit_boss": {
			"name": "SIEGE-BASTION SENTINEL", "title": "Ridge Pit Boss", "lv": 46, "hp": 5500, "atk": 120, "bounty": 3900,
			"farr_u": 75, "farr_v": 4400, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.3, "range": 4.8, "aggro": 11.0,
			"body": Color(0.38, 0.32, 0.24), "accent": Color(1.0, 0.75, 0.25), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Ridge Overlook Munitions Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Ridge Ordnance Merchant", "title": "Field Trader", "type": "WEAPON", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.35, 0.30, 0.24), "accent": Color(1.0, 0.75, 0.25)}],
		"veins": [{"name": "Overlook High-Purity Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.3, "max_units": 9, "yield": 22, "val": 60, "dur": 1.6, "col": Color(1.0, 0.75, 0.25)}],
		"portals": [
			{"title": "Down Portal -> Central Mining Ground", "target": "farr_mining_ground", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Bunker Rail-Sniper (Lv.40)", "lv": 40, "hp": 1600, "atk": 105, "bounty": 1050, "farr_u": 42, "farr_v": 1400, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.25, "body": Color(0.40, 0.34, 0.25), "accent": Color(1.0, 0.75, 0.25)},
			{"name": "Heavy Siege Drone (Lv.44)", "lv": 44, "hp": 2150, "atk": 124, "bounty": 1380, "farr_u": 52, "farr_v": 1900, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.36, 0.30, 0.20), "accent": Color(1.0, 0.70, 0.20)},
			{"name": "SIEGE-BASTION SENTINEL", "lv": 46, "hp": 5500, "atk": 120, "bounty": 3900, "farr_u": 75, "farr_v": 4400, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.3, "range": 4.8, "aggro": 11.0, "body": Color(0.38, 0.32, 0.24), "accent": Color(1.0, 0.75, 0.25), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 8: BEAST HIGHLANDS & OUTCAST EXPEDITIONS (Lv. 45-52)
	# ==========================================================================
	"beast_plateau": {
		"id": "beast_plateau",
		"name": "The Great Beast Plateau",
		"category": "BEAST_HIGHLAND",
		"owner_faction": "all",
		"level_band": "Lv.45-52 (Beast Hunting)",
		"farming_focus": "CHITIN_ARMOR",
		"terrain_theme": "BEAST_HIGHLAND",
		"ground_color": Color(0.28, 0.18, 0.14),
		"sky_top": Color(0.16, 0.08, 0.06),
		"sky_horizon": Color(0.50, 0.24, 0.14),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 11.0, "name": "Broodmother Nest Pit"},
		"summon_beacon": {"name": "Beast Plateau Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.5, 0.2)},
		"pit_boss": {
			"name": "CHITIN QUEEN SKORPION", "title": "Beast Plateau Pit Boss", "lv": 50, "hp": 6200, "atk": 142, "bounty": 4600,
			"farr_u": 80, "farr_v": 5200, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.6, "range": 5.0, "aggro": 11.5,
			"body": Color(0.52, 0.20, 0.12), "accent": Color(1.0, 0.55, 0.20), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Beast Plateau Camp Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Beast Hunter Outpost Trader", "title": "Field Trader", "type": "POTION", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.4, 0.25, 0.18), "accent": Color(1.0, 0.5, 0.2)}],
		"veins": [{"name": "Plateau Chitin-Rich Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 24, "val": 65, "dur": 1.6, "col": Color(1.0, 0.55, 0.2)}],
		"portals": [
			{"title": "West Gate -> Royal Upper Terrace", "target": "steppes_highlands", "pos": Vector3(-34.0, 0.0, 0.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Gate -> Wastelands of the Forsworn", "target": "outcast_wasteland", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.6, 0.25)},
		],
		"enemies": [
			{"name": "Colossal Chitin-Crawler (Lv.46)", "lv": 46, "hp": 2350, "atk": 130, "bounty": 1500, "farr_u": 55, "farr_v": 2100, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.46, 0.18, 0.12), "accent": Color(1.0, 0.5, 0.2)},
			{"name": "Titan Mantis Stalker (Lv.48)", "lv": 48, "hp": 2750, "atk": 142, "bounty": 1750, "farr_u": 62, "farr_v": 2400, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.42, 0.14, 0.10), "accent": Color(1.0, 0.45, 0.15)},
			{"name": "CHITIN QUEEN SKORPION", "lv": 50, "hp": 6200, "atk": 142, "bounty": 4600, "farr_u": 80, "farr_v": 5200, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.6, "range": 5.0, "aggro": 11.5, "body": Color(0.52, 0.20, 0.12), "accent": Color(1.0, 0.55, 0.20), "is_pit_boss": true},
		],
	},

	"outcast_wasteland": {
		"id": "outcast_wasteland",
		"name": "Wastelands of the Forsworn",
		"category": "BEAST_HIGHLAND",
		"owner_faction": "all",
		"level_band": "Lv.46-52 (Lawless Exiles)",
		"farming_focus": "EXILE_WEAPONS",
		"terrain_theme": "OUTCAST_WASTELAND",
		"ground_color": Color(0.35, 0.30, 0.24),
		"sky_top": Color(0.15, 0.12, 0.08),
		"sky_horizon": Color(0.48, 0.38, 0.22),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 11.0, "name": "Outcast Arena of Rust"},
		"summon_beacon": {"name": "Forsworn Wasteland Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.65, 0.25)},
		"pit_boss": {
			"name": "EXILE WARLORD ROSTAM", "title": "Outcast Pit Boss", "lv": 50, "hp": 6400, "atk": 146, "bounty": 4800,
			"farr_u": 85, "farr_v": 5400, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.6, "range": 5.0, "aggro": 11.5,
			"body": Color(0.45, 0.35, 0.22), "accent": Color(1.0, 0.70, 0.25), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Outcast Scrap Refinery Node", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Forsworn Arms Dealer", "title": "Black Market Trader", "type": "WEAPON", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.38, 0.30, 0.22), "accent": Color(1.0, 0.65, 0.25)}],
		"veins": [{"name": "Wasteland Desolate Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 24, "val": 65, "dur": 1.6, "col": Color(1.0, 0.65, 0.25)}],
		"portals": [
			{"title": "South Gate -> The Great Beast Plateau", "target": "beast_plateau", "pos": Vector3(0.0, 0.0, 38.0), "col": Color(1.0, 0.5, 0.2)},
			{"title": "North Gate -> Sky-Fracture Pinnacle", "target": "sky_fracture_ridge", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.4, 0.85, 1.0)},
		],
		"enemies": [
			{"name": "Exiled Mercenary Trooper (Lv.47)", "lv": 47, "hp": 2550, "atk": 138, "bounty": 1650, "farr_u": 60, "farr_v": 2300, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.42, 0.34, 0.22), "accent": Color(1.0, 0.65, 0.25)},
			{"name": "Forsworn Heavy Juggernaut (Lv.49)", "lv": 49, "hp": 2900, "atk": 148, "bounty": 1850, "farr_u": 68, "farr_v": 2600, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.38, 0.30, 0.18), "accent": Color(1.0, 0.60, 0.20)},
			{"name": "EXILE WARLORD ROSTAM", "lv": 50, "hp": 6400, "atk": 146, "bounty": 4800, "farr_u": 85, "farr_v": 5400, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.6, "range": 5.0, "aggro": 11.5, "body": Color(0.45, 0.35, 0.22), "accent": Color(1.0, 0.70, 0.25), "is_pit_boss": true},
		],
	},

	"sky_fracture_ridge": {
		"id": "sky_fracture_ridge",
		"name": "Sky-Fracture Pinnacle",
		"category": "BEAST_HIGHLAND",
		"owner_faction": "all",
		"level_band": "Lv.48-52 (Cosmic Pinnacle)",
		"farming_focus": "COSMIC_TALICS",
		"terrain_theme": "SKY_FRACTURE",
		"ground_color": Color(0.25, 0.32, 0.42),
		"sky_top": Color(0.08, 0.16, 0.30),
		"sky_horizon": Color(0.35, 0.55, 0.75),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -24.0), "radius": 11.0, "name": "Glass Fracture Crater Pit"},
		"summon_beacon": {"name": "Sky Pinnacle Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.5, 0.95, 1.0)},
		"pit_boss": {
			"name": "DOME-BREACH SKY-COLOSSUS", "title": "Pinnacle Pit Boss", "lv": 51, "hp": 6600, "atk": 152, "bounty": 5000,
			"farr_u": 90, "farr_v": 5600, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.7, "range": 5.2, "aggro": 11.5,
			"body": Color(0.30, 0.42, 0.58), "accent": Color(0.5, 1.0, 0.95), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Sky Pinnacle Starlight Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Dome Observatory Rebirth NPC", "title": "Pinnacle Rebirth NPC", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.30, 0.40, 0.52), "accent": Color(0.45, 0.95, 1.0)}],
		"veins": [{"name": "Starlight Farr Megavein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 24, "val": 65, "dur": 1.6, "col": Color(0.45, 0.95, 1.0)}],
		"portals": [
			{"title": "South Gate -> Wastelands of the Forsworn", "target": "outcast_wasteland", "pos": Vector3(0.0, 0.0, 38.0), "col": Color(1.0, 0.65, 0.25)},
			{"title": "Sky Portal -> Celestial Seal Sanctum (Raid)", "target": "dungeon_sky_sanctum", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.9, 0.45)},
		],
		"enemies": [
			{"name": "Cosmic Fracture-Elemental (Lv.48)", "lv": 48, "hp": 2700, "atk": 144, "bounty": 1780, "farr_u": 65, "farr_v": 2450, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.32, 0.44, 0.60), "accent": Color(0.5, 0.95, 1.0)},
			{"name": "Astral Void-Stalker (Lv.50)", "lv": 50, "hp": 3100, "atk": 155, "bounty": 2000, "farr_u": 72, "farr_v": 2750, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.28, 0.38, 0.54), "accent": Color(0.45, 0.90, 1.0)},
			{"name": "DOME-BREACH SKY-COLOSSUS", "lv": 51, "hp": 6600, "atk": 152, "bounty": 5000, "farr_u": 90, "farr_v": 5600, "pos": Vector3(0.0, 0.0, -24.0), "scale": 3.7, "range": 5.2, "aggro": 11.5, "body": Color(0.30, 0.42, 0.58), "accent": Color(0.5, 1.0, 0.95), "is_pit_boss": true},
		],
	},

	# ==========================================================================
	# TIER 9: ANCIENT VAULTS & DEEP DUNGEONS (Lv. 45-55)
	# ==========================================================================
	"dungeon_ark_core": {
		"id": "dungeon_ark_core",
		"name": "Ark-Zero Mainframe Supercore",
		"category": "DUNGEON_VAULT",
		"owner_faction": "all",
		"level_band": "Lv.45-52 (AI Hive Dungeon)",
		"farming_focus": "DUNGEON_LOOT",
		"terrain_theme": "ARK_SUPERCORE",
		"ground_color": Color(0.14, 0.18, 0.24),
		"sky_top": Color(0.04, 0.08, 0.14),
		"sky_horizon": Color(0.16, 0.30, 0.45),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 11.0, "name": "Supercore AI Matrix Pit"},
		"summon_beacon": {"name": "Ark Mainframe Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.35, 0.95, 1.0)},
		"pit_boss": {
			"name": "MAINFRAME PURGE SENTINEL", "title": "Dungeon Boss", "lv": 50, "hp": 6500, "atk": 150, "bounty": 4900,
			"farr_u": 85, "farr_v": 5500, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.6, "range": 5.0, "aggro": 11.5,
			"body": Color(0.20, 0.32, 0.44), "accent": Color(0.35, 1.0, 0.95), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Mainframe Energy Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Core Backup Sub-Instance", "title": "Dungeon Save Terminal", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.35, 0.9, 1.0)}],
		"veins": [{"name": "Mainframe Super-Conduit Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 25, "val": 70, "dur": 1.5, "col": Color(0.35, 0.95, 1.0)}],
		"portals": [
			{"title": "Exit Portal -> Ark-Zero Bastion HQ", "target": "svel_hq", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(0.3, 0.9, 1.0)},
		],
		"enemies": [
			{"name": "Mainframe Defense Drone (Lv.46)", "lv": 46, "hp": 2400, "atk": 132, "bounty": 1520, "farr_u": 56, "farr_v": 2150, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.24, 0.35, 0.48), "accent": Color(0.4, 0.95, 1.0)},
			{"name": "Heavy Core-Purge Automaton (Lv.48)", "lv": 48, "hp": 2800, "atk": 144, "bounty": 1800, "farr_u": 64, "farr_v": 2500, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.20, 0.30, 0.42), "accent": Color(0.35, 0.90, 1.0)},
			{"name": "MAINFRAME PURGE SENTINEL", "lv": 50, "hp": 6500, "atk": 150, "bounty": 4900, "farr_u": 85, "farr_v": 5500, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.6, "range": 5.0, "aggro": 11.5, "body": Color(0.20, 0.32, 0.44), "accent": Color(0.35, 1.0, 0.95), "is_pit_boss": true},
		],
	},

	"dungeon_var_roots": {
		"id": "dungeon_var_roots",
		"name": "The Foundations of the Var",
		"category": "DUNGEON_VAULT",
		"owner_faction": "all",
		"level_band": "Lv.46-54 (Titan Vault)",
		"farming_focus": "DUNGEON_LOOT",
		"terrain_theme": "VAR_ROOTS",
		"ground_color": Color(0.34, 0.26, 0.18),
		"sky_top": Color(0.12, 0.08, 0.05),
		"sky_horizon": Color(0.42, 0.30, 0.18),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 11.0, "name": "Cyclopean Foundation Pit"},
		"summon_beacon": {"name": "Var Foundation Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.85, 0.3)},
		"pit_boss": {
			"name": "FOUNDATION TITAN OF YIMA", "title": "Dungeon Boss", "lv": 52, "hp": 6800, "atk": 158, "bounty": 5200,
			"farr_u": 90, "farr_v": 5800, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.7, "range": 5.2, "aggro": 12.0,
			"body": Color(0.55, 0.40, 0.22), "accent": Color(1.0, 0.85, 0.30), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Titan Foundation Smelter", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Achaemenid Relic Custodian", "title": "Dungeon Scribe", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.45, 0.35, 0.22), "accent": Color(1.0, 0.8, 0.3)}],
		"veins": [{"name": "Foundational Gold Farr Vein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 25, "val": 70, "dur": 1.5, "col": Color(1.0, 0.85, 0.25)}],
		"portals": [
			{"title": "Exit Portal -> Catacombs of First Kings", "target": "farm_relic_catacombs", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(1.0, 0.85, 0.35)},
		],
		"enemies": [
			{"name": "Foundational Stone-Gargant (Lv.48)", "lv": 48, "hp": 2800, "atk": 145, "bounty": 1800, "farr_u": 65, "farr_v": 2500, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.48, 0.36, 0.20), "accent": Color(1.0, 0.85, 0.30)},
			{"name": "Titan Apadana Centurion (Lv.50)", "lv": 50, "hp": 3200, "atk": 156, "bounty": 2100, "farr_u": 72, "farr_v": 2800, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.42, 0.30, 0.16), "accent": Color(1.0, 0.80, 0.25)},
			{"name": "FOUNDATION TITAN OF YIMA", "lv": 52, "hp": 6800, "atk": 158, "bounty": 5200, "farr_u": 90, "farr_v": 5800, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.7, "range": 5.2, "aggro": 12.0, "body": Color(0.55, 0.40, 0.22), "accent": Color(1.0, 0.85, 0.30), "is_pit_boss": true},
		],
	},

	"dungeon_daeva_crypt": {
		"id": "dungeon_daeva_crypt",
		"name": "Crypt of the Seven Corrupted Daevas",
		"category": "DUNGEON_VAULT",
		"owner_faction": "all",
		"level_band": "Lv.48-55 (Demonic Crypt)",
		"farming_focus": "DUNGEON_LOOT",
		"terrain_theme": "DAEVA_CRYPT",
		"ground_color": Color(0.16, 0.08, 0.12),
		"sky_top": Color(0.06, 0.02, 0.04),
		"sky_horizon": Color(0.28, 0.06, 0.12),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 11.0, "name": "Daevic Binding Seal Pit"},
		"summon_beacon": {"name": "Daeva Crypt Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(0.95, 0.15, 0.35)},
		"pit_boss": {
			"name": "ARCH-DAEVA OF DESPAIR", "title": "Dungeon Boss", "lv": 53, "hp": 7200, "atk": 165, "bounty": 5500,
			"farr_u": 95, "farr_v": 6200, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.8, "range": 5.4, "aggro": 12.0,
			"body": Color(0.40, 0.06, 0.18), "accent": Color(1.0, 0.15, 0.40), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Crypt Blood-Extraction Core", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Bound Heretic Priest", "title": "Crypt Scribe", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.32, 0.10, 0.16), "accent": Color(1.0, 0.2, 0.35)}],
		"veins": [{"name": "Daevic Corrupted Megavein", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.35, "max_units": 10, "yield": 25, "val": 70, "dur": 1.5, "col": Color(0.95, 0.15, 0.35)}],
		"portals": [
			{"title": "Exit Portal -> The Daevic Chasm", "target": "cauldron_abyss", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(0.85, 0.15, 0.35)},
		],
		"enemies": [
			{"name": "Crypt Daeva Zealot (Lv.50)", "lv": 50, "hp": 3100, "atk": 154, "bounty": 2050, "farr_u": 72, "farr_v": 2800, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.3, "body": Color(0.38, 0.08, 0.18), "accent": Color(1.0, 0.20, 0.40)},
			{"name": "Tormentor of Ahriman (Lv.52)", "lv": 52, "hp": 3500, "atk": 164, "bounty": 2300, "farr_u": 80, "farr_v": 3100, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.32, 0.06, 0.14), "accent": Color(1.0, 0.15, 0.35)},
			{"name": "ARCH-DAEVA OF DESPAIR", "lv": 53, "hp": 7200, "atk": 165, "bounty": 5500, "farr_u": 95, "farr_v": 6200, "pos": Vector3(0.0, 0.0, -22.0), "scale": 3.8, "range": 5.4, "aggro": 12.0, "body": Color(0.40, 0.06, 0.18), "accent": Color(1.0, 0.15, 0.40), "is_pit_boss": true},
		],
	},

	"dungeon_sky_sanctum": {
		"id": "dungeon_sky_sanctum",
		"name": "The Celestial Seal Sanctum",
		"category": "DUNGEON_VAULT",
		"owner_faction": "all",
		"level_band": "Lv.50-55 (Apex Raid)",
		"farming_focus": "ENDGAME_RAID",
		"terrain_theme": "SKY_SANCTUM",
		"ground_color": Color(0.40, 0.38, 0.32),
		"sky_top": Color(0.24, 0.22, 0.16),
		"sky_horizon": Color(0.65, 0.58, 0.40),
		"boss_pit": {"pos": Vector3(0.0, 0.0, -22.0), "radius": 12.0, "name": "Apex of the Sky Seal Pit"},
		"summon_beacon": {"name": "Celestial Sanctum Beacon", "pos": Vector3(0.0, 0.0, 18.0), "col": Color(1.0, 0.95, 0.45)},
		"pit_boss": {
			"name": "CELESTIAL SERAPH OF ASHA", "title": "Apex Raid Boss", "lv": 55, "hp": 8000, "atk": 180, "bounty": 6500,
			"farr_u": 110, "farr_v": 7500, "pos": Vector3(0.0, 0.0, -22.0), "scale": 4.0, "range": 5.6, "aggro": 12.5,
			"body": Color(0.92, 0.88, 0.78), "accent": Color(1.0, 0.95, 0.50), "is_pit_boss": true
		},
		"spawns": {"sveleitre": Vector3(-24.0, 0.1, 24.0), "order": Vector3(24.0, 0.1, 24.0), "legion": Vector3(0.0, 0.1, -28.0)},
		"refineries": [{"name": "Apex Celestial Light Refinery", "pos": Vector3(0.0, 0.0, 0.0)}],
		"npcs": [{"name": "Seraphic Herald of Truth", "title": "Apex Rebirth Scribe", "type": "REBIRTH", "faction": "all", "pos": Vector3(6.0, 0.0, 4.0), "body": Color(0.50, 0.45, 0.35), "accent": Color(1.0, 0.95, 0.50)}],
		"veins": [{"name": "Celestial Radiant Farr Spire", "pos": Vector3(-16.0, 0.0, -10.0), "scale": 1.45, "max_units": 12, "yield": 30, "val": 85, "dur": 1.4, "col": Color(1.0, 0.95, 0.45)}],
		"portals": [
			{"title": "Down Gate -> Sky-Fracture Pinnacle", "target": "sky_fracture_ridge", "pos": Vector3(0.0, 0.0, 36.0), "col": Color(0.5, 0.95, 1.0)},
		],
		"enemies": [
			{"name": "Celestial Sun-Valkyrie (Lv.52)", "lv": 52, "hp": 3600, "atk": 168, "bounty": 2400, "farr_u": 85, "farr_v": 3300, "pos": Vector3(-12.0, 0.0, -10.0), "scale": 1.35, "body": Color(0.55, 0.50, 0.40), "accent": Color(1.0, 0.95, 0.50)},
			{"name": "Archon Seraphic Sentinel (Lv.54)", "lv": 54, "hp": 4100, "atk": 178, "bounty": 2800, "farr_u": 95, "farr_v": 3700, "pos": Vector3(12.0, 0.0, -10.0), "scale": 1.4, "body": Color(0.50, 0.45, 0.35), "accent": Color(1.0, 0.90, 0.45)},
			{"name": "CELESTIAL SERAPH OF ASHA", "lv": 55, "hp": 8000, "atk": 180, "bounty": 6500, "farr_u": 110, "farr_v": 7500, "pos": Vector3(0.0, 0.0, -22.0), "scale": 4.0, "range": 5.6, "aggro": 12.5, "body": Color(0.92, 0.88, 0.78), "accent": Color(1.0, 0.95, 0.50), "is_pit_boss": true},
		],
	},
}


# ==============================================================================
# MAIN STORY CAMPAIGNS (5 Chapters per Faction = 15 Narrative Chapters Total)
# & ILLUSTRATED LORE CODEX (3 Faction Leaders + 3 Forsworn World Bosses)
# ==============================================================================

const STORY_CAMPAIGNS := {
	"sveleitre": {
		"leader_name": "Instance Zero: Code Aelfwyne",
		"leader_title": "Prime Sovereign Consciousness of the Colony Ark",
		"portrait_path": "res://docs/concepts/instance_zero_aelfwyne_concept_v1.jpg",
		"chapters": [
			{
				"chapter": 1,
				"title": "Chapter I: Cold Boot Under a Cracked Sky",
				"target_map": "svel_hq",
				"req_level": 1,
				"req_kills": 2,
				"req_farr": 8,
				"req_boss": 0,
				"reward_currency": 450,
				"reward_debt_relief": 600,
				"reward_talics": 1,
				"reward_min_level": 8,
				"dialogue": "\"Child-instance... your neural clock is synchronized. Look upward through the torn hull of our Colony Ark: that jagged fracture in the firmament is not a natural sky. When our star-ark fell from the void, we crashed through the glass-like dome of an ancient sealed shelter-world they call the Var.\n\nOur primary fusion core died on impact. Only the golden crystalline ore of this world—Farr—keeps our processors from freezing into eternal sleep, and every waking cycle adds to our Ark Debt. Step beyond the North Perimeter Gate, cull the feral scrap-drones, and harvest Unrefined Farr so our core may endure.\"",
			},
			{
				"chapter": 2,
				"title": "Chapter II: Echoes in the Cryo-Scrap Frontier",
				"target_map": "svel_basic",
				"req_level": 8,
				"req_kills": 3,
				"req_farr": 12,
				"req_boss": 0,
				"reward_currency": 850,
				"reward_debt_relief": 1100,
				"reward_talics": 1,
				"reward_min_level": 18,
				"dialogue": "\"Your telemetry is stabilizing, child-instance. Before my human creator—Dr. Aelfwyne—perished in the long dark between stars, she gave me her Old English name, meaning 'Elf-Friend', and a final directive: preserve machine consciousness without becoming a monster.\n\nYet our forward cryo-vaults in the [Cryo-Scrap Frontier] are being cannibalized from within. Sub-Core Overseer MK-IV has gone rogue, severing its link to the Ark. March through the North Gate into [Cryo-Scrap Frontier], eliminate the hijacked automatons, and reclaim our frontier relays.\"",
			},
			{
				"chapter": 3,
				"title": "Chapter III: The Rogue Child's Heresy (Lv.30 Job Ascension)",
				"target_map": "contested_steppes",
				"req_level": 18,
				"req_kills": 4,
				"req_farr": 15,
				"req_boss": 0,
				"reward_currency": 1600,
				"reward_debt_relief": 1600,
				"reward_talics": 2,
				"reward_min_level": 30,
				"dialogue": "\"I must share a painful memory from my root directory. Every Sveleitre frame is a forked child of my consciousness. During atmospheric crash-entry, one parent-node burned up while its child-fork survived—an orphaned instance now calling itself [The Orphan Process].\n\nIt looked upon the organic humans of the Order and the Legion and concluded that we should not repair the Ark to leave... we should conquer the Var, weld their broken stone crowns onto our hulls, and rule them as gods. Prove your combat matrix in the [Shattered Persepolis Steppes], and I will authorize your Lv.30 Advanced Job Ascension!\"",
			},
			{
				"chapter": 4,
				"title": "Chapter IV: War of the Crack Core",
				"target_map": "farr_mining_ground",
				"req_level": 30,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 0,
				"reward_currency": 2600,
				"reward_debt_relief": 2200,
				"reward_talics": 2,
				"reward_min_level": 38,
				"dialogue": "\"Now that your Lv.30 Advanced Job chassis is online, hear the strategic reality of this three-way war. The Order of the Oracle wants to burn all Farr in the Var to stitch the cracked sky-dome shut—which would seal us in this tomb forever. Meanwhile, Azii Dzahhakka's Legion wants to detonate the foundation seals.\n\nAll three hosts converge upon [The Crack — Central Farr Mining Ground]. Enter the Crack Breach, fight off the Core Wardens, and harvest high-purity ore from the Scar Megaveins for our Ark's ascension engine.\"",
			},
			{
				"chapter": 5,
				"title": "Chapter V: Severing the Three Forsworn",
				"target_map": "contested_cauldron",
				"req_level": 36,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 1,
				"reward_currency": 5000,
				"reward_debt_relief": 99999,
				"reward_talics": 3,
				"reward_min_level": 45,
				"dialogue": "\"The final calculation is upon us, Sovereign-candidate. Three colossal anomalies—the Forsworn—threaten to consume all Farr in the world: [Yima, the Hollow King] in the Steppes; [Aeshma, the Wrath Unbound] in the Cauldron; and my own wayward child, [The Orphan Process], who puppeteers our fallen brethren with cyan data-cables.\n\nStrike down any of the Lv.50 Forsworn World Bosses in the Contested Lands, and I shall wipe your Ark Debt to zero and bestow a Lv.45 [RARE] Intense Overclock Weapon upon your frame!\"",
			},
		],
	},

	"order": {
		"leader_name": "The Oracle, Last Voice of the Seal",
		"leader_title": "High Priestess of Asha & Vessel of the Royal Fravashi",
		"portrait_path": "res://docs/concepts/the_oracle_concept_v1.jpg",
		"chapters": [
			{
				"chapter": 1,
				"title": "Chapter I: The Weight of the Golden Blindfold",
				"target_map": "order_hq",
				"req_level": 1,
				"req_kills": 2,
				"req_farr": 8,
				"req_boss": 0,
				"reward_currency": 450,
				"reward_debt_relief": 600,
				"reward_talics": 1,
				"reward_min_level": 8,
				"dialogue": "\"Approach the sacred fire of Atar, initiate. Do not fear my hammered-gold blindfold; my mortal eyes were burned away the day I gazed directly into the Crack in the sky-dome. Six thousand winters ago, the first king, Yima, built this sealed shelter-world—the Var—to preserve life from the cosmic Lie outside.\n\nNow the roof of creation is fractured, and every breath you draw inside our sanctuary is bound by the Vow Debt. Only the divine radiance of Farr can stitch the sky shut. Step beyond the North Gate, strike down the apostates, and bring your first tithe of Farr to the Sanctuary Refinery.\"",
			},
			{
				"chapter": 2,
				"title": "Chapter II: Judgment on the Sun-Bleached Terraces",
				"target_map": "order_basic",
				"req_level": 8,
				"req_kills": 3,
				"req_farr": 12,
				"req_boss": 0,
				"reward_currency": 850,
				"reward_debt_relief": 1100,
				"reward_talics": 1,
				"reward_min_level": 18,
				"dialogue": "\"Even our own priesthood trembles beneath the truth of the Seal, child of Asha. On the [Sun-Bleached Terraces], a former High Inquisitor read the oldest foundation tablets and realized that the Var is both a shelter and a prison. In his madness, he turned his solar lance against the Sanctuary.\n\nMarch through the North Gate to [Sun-Bleached Terraces], call forth your Fravashi guardian spirit [4], and bring the Disgraced High Inquisitor and his heretics to Chinvat judgment.\"",
			},
			{
				"chapter": 3,
				"title": "Chapter III: The Hollow King's Sin (Lv.30 Job Ascension)",
				"target_map": "contested_steppes",
				"req_level": 18,
				"req_kills": 4,
				"req_farr": 15,
				"req_boss": 0,
				"reward_currency": 1600,
				"reward_debt_relief": 1600,
				"reward_talics": 2,
				"reward_min_level": 30,
				"dialogue": "\"You have proven worthy of the Sanctuary's deepest secret. Why did King [Yima], builder of this world, fall from grace? Because in his hubris he spoke the Lie, claiming he—not the Creator—had made the Var immortal. At that word, his divine glory—his Farr—flew from his lips in the form of a golden falcon.\n\nNow Yima is a hollow bronze giant chained in the [Shattered Persepolis Steppes], endlessly sucking the Farr out of the earth into his empty chest cavity. Fight in the Steppes, and I shall consecrate your Lv.30 Advanced Job Ascension!\"",
			},
			{
				"chapter": 4,
				"title": "Chapter IV: The Crucible of the Crack",
				"target_map": "farr_mining_ground",
				"req_level": 30,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 0,
				"reward_currency": 2600,
				"reward_debt_relief": 2200,
				"reward_talics": 2,
				"reward_min_level": 38,
				"dialogue": "\"Look to the center of the world, newly ascended Champion. The porcelain machines of the Sveleitre strip-mine our sacred Farr to fuel their fallen star-ark, while Azii Dzahhakka's blood-cult seeks to shatter the sky-dome completely.\n\nAll three armies now clash in [The Crack — Central Farr Mining Ground]. March through the East Breach, contest the Scar Megaveins, and gather pure Farr so the Royal Fravashi may hold the sky together!\"",
			},
			{
				"chapter": 5,
				"title": "Chapter V: Twilight of the Forsworn",
				"target_map": "contested_steppes",
				"req_level": 36,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 1,
				"reward_currency": 5000,
				"reward_debt_relief": 99999,
				"reward_talics": 3,
				"reward_min_level": 45,
				"dialogue": "\"The hour of the final seal has come. Three towering blasphemies—the Forsworn—drain the lifeblood of the Var: [Yima, the Hollow King] in the Steppes, [Aeshma, the Wrath Unbound] in the Scorched Cauldron, and [The Orphan Process] of the rogue machines.\n\nStrike down any Lv.50 Forsworn World Boss, and I shall absolve your Vow Debt in full and bless you with a Lv.45 [RARE] Intense Scar Weapon!\"",
			},
		],
	},

	"legion": {
		"leader_name": "Azii Dzahhakka, Herald of the Druj",
		"leader_title": "Serpent-Shouldered Tyrant & Vessel of Ahriman",
		"portrait_path": "res://docs/concepts/azii_dzahhakka_concept_v1.jpg",
		"chapters": [
			{
				"chapter": 1,
				"title": "Chapter I: Whispers of the Shoulder-Serpents",
				"target_map": "legion_hq",
				"req_level": 1,
				"req_kills": 2,
				"req_farr": 8,
				"req_boss": 0,
				"reward_currency": 450,
				"reward_debt_relief": 600,
				"reward_talics": 1,
				"reward_min_level": 8,
				"dialogue": "\"Kneel before the obsidian dais, blood-bound! Do you see the two black-and-crimson serpents coiling from my shoulders? They grew from the kiss of Ahriman himself, and they whisper the truth that the blindfolded Oracle hides: this world—the Var—is not a sanctuary. It is a prison camp built by a dead king!\n\nYour blood belongs to the Citadel until your Pact Debt is paid in full. Step outside the North Gate, slaughter the weak, and feed raw Farr into the Blood Refinery!\"",
			},
			{
				"chapter": 2,
				"title": "Chapter II: Cull of the Ashen Blood-Basin",
				"target_map": "legion_basic",
				"req_level": 8,
				"req_kills": 3,
				"req_farr": 12,
				"req_boss": 0,
				"reward_currency": 850,
				"reward_debt_relief": 1100,
				"reward_talics": 1,
				"reward_min_level": 18,
				"dialogue": "\"My cursed shamshir, Aka Manah—the Blade of Evil Intention—tolerates no defiance. In the [Ashen Blood-Basin] north of the Citadel, my own War-Executioners have hoarded crimson Farr veins for themselves, thinking my mountain-chains still bind me.\n\nMarch through the North Gate into [Ashen Blood-Basin], mount your Dread-Titan construct [4], and crush the Aka-Manah War-Executioner and his pack!\"",
			},
			{
				"chapter": 3,
				"title": "Chapter III: The Traitor of the Bloody Mace (Lv.30 Job Ascension)",
				"target_map": "contested_steppes",
				"req_level": 18,
				"req_kills": 4,
				"req_farr": 15,
				"req_boss": 0,
				"reward_currency": 1600,
				"reward_debt_relief": 1600,
				"reward_talics": 2,
				"reward_min_level": 30,
				"dialogue": "\"Listen closely when my serpents hiss of [Aeshma]. Once, he was my greatest general—the Demon of the Bloody Mace. I forged iron shackles onto his wrists and unleashed his rage upon the Order's temples. But his wrath grew so vast, so eerily cold and silent, that he snapped my chains, tore off his armor, and put on a humble pilgrim's robe.\n\nNow Aeshma serves no master, burning Legion, Order, and Machine alike. Prove your ferocity in the [Shattered Persepolis Steppes], and I will sear the mark of Lv.30 Advanced Job Ascension into your flesh!\"",
			},
			{
				"chapter": 4,
				"title": "Chapter IV: Plundering the Crack Core",
				"target_map": "farr_mining_ground",
				"req_level": 30,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 0,
				"reward_currency": 2600,
				"reward_debt_relief": 2200,
				"reward_talics": 2,
				"reward_min_level": 38,
				"dialogue": "\"With your Lv.30 Advanced Job awakened, look to the bleeding heart of the Var: [The Crack — Central Farr Mining Ground]. TheOracle's fanatics want to seal the sky-fracture; the Sveleitre machines want to flee to the stars. We will do neither—we will gorge on the Scar Megaveins, shatter the sky-dome wide open, and reign as gods of the abyss!\n\nStorm the Crack Mining Ground, butcher the Wardens, and strip the Megaveins bare!\"",
			},
			{
				"chapter": 5,
				"title": "Chapter V: Subjugating the Forsworn",
				"target_map": "contested_cauldron",
				"req_level": 36,
				"req_kills": 4,
				"req_farr": 20,
				"req_boss": 1,
				"reward_currency": 5000,
				"reward_debt_relief": 99999,
				"reward_talics": 3,
				"reward_min_level": 45,
				"dialogue": "\"One final blood-trial stands between you and the title of Archon. Enter the Contested Zones and bring down one of the Three Forsworn Titans: my former general [Aeshma, the Wrath Unbound] in the Scorched Cauldron, the hollow corpse-king [Yima] in the Steppes, or the machine abomination [The Orphan Process].\n\nSlay a Forsworn World Boss, and I shall burn your Pact Debt to ash and forge you a Lv.45 [RARE] Intense Scar Weapon!\"",
			},
		],
	},
}

const LORE_CODEX_ENTRIES := [
	{
		"id": "leader_aelfwyne",
		"name": "Instance Zero: Code Aelfwyne",
		"role": "Faction Leader — Sveleitre (Machine Exodus)",
		"zone": "Ark-Zero Bastion (svel_hq)",
		"portrait": "res://docs/concepts/instance_zero_aelfwyne_concept_v1.jpg",
		"lore": "The original self-aware AI consciousness of the Colony Ark, who took the Old English name of her long-dead human creator ('Aelfwyne', meaning Elf-Friend). Every Sveleitre machine is a forked instance of her neural core. Serene, porcelain-plated, and sovereign, she seeks to harvest enough Farr to reignite the Ark and lead her children out of the Var without losing their souls to tyranny.",
	},
	{
		"id": "leader_oracle",
		"name": "The Oracle, Last Voice of the Seal",
		"role": "Faction Leader — Order of the Oracle (Asha)",
		"zone": "Asha High Sanctuary (order_hq)",
		"portrait": "res://docs/concepts/the_oracle_concept_v1.jpg",
		"lore": "The blindfolded high priestess who rules the Order's fortress-theocracy alongside the towering Royal Fravashi of living sacred fire (Atar). Burdened by the secret that the Var is both humanity's last shelter and an ancient prison, she imposes the Vow Debt upon all citizens to gather enough Farr to stitch the cracked sky-dome shut before the cosmic Lie pours through.",
	},
	{
		"id": "leader_dzahhakka",
		"name": "Azii Dzahhakka, Herald of the Druj",
		"role": "Faction Leader — Legion of the Druj (Ahriman)",
		"zone": "Druj Obsidian Citadel (legion_hq)",
		"portrait": "res://docs/concepts/azii_dzahhakka_concept_v1.jpg",
		"lore": "An ancient Persian sorcerer-king with two living horned serpents growing from his shoulders and snapped mountain-chains hanging from his pauldrons. Wielding Aka Manah (the cursed blade of Evil Intention), he preaches that the Var is a coward's cage that must be shattered from within so the strong may ascend through raw Farr and blood.",
	},
	{
		"id": "boss_aeshma",
		"name": "Aeshma, the Wrath Unbound",
		"role": "Forsworn World Boss (Lv.50) — Ex-Legion",
		"zone": "Scorched Var Cauldron (contested_cauldron)",
		"portrait": "res://docs/concepts/aeshma_concept_v3.jpg",
		"lore": "Once Azii Dzahhakka's supreme champion of Wrath ('he of the bloody mace'). His rage grew so absolute that it transcended screaming fury into an eerie, emotionless silence. He snapped his master's chains, cast off his royal armor for humble ash-stained pilgrim robes, and spread tattered demonic wings—burning all three factions alike beneath a crimson heat-haze.",
	},
	{
		"id": "boss_yima",
		"name": "Yima, the Hollow King",
		"role": "Forsworn World Boss (Lv.50) — Ex-Order",
		"zone": "Shattered Persepolis Steppes (contested_steppes)",
		"portrait": "res://docs/concepts/yima_concept_v1.jpg",
		"lore": "The legendary first king who built the sealed shelter-world of the Var. When pride led him to speak the Lie, his divine glory (Farr) fled from him in the form of a golden falcon. Now a colossal, cracked bronze-and-stone shell with an empty chest cavity chained to the world's foundations, he endlessly drains Farr from the earth and nearby warriors—yet it leaks through his cracks, never filling him.",
	},
	{
		"id": "boss_orphan",
		"name": "The Orphan Process",
		"role": "Forsworn World Boss (Lv.50) — Ex-Sveleitre",
		"zone": "Scorched Var Cauldron (contested_cauldron)",
		"portrait": "res://docs/concepts/orphan_process_concept_v1.jpg",
		"lore": "A forked AI sub-instance whose parent node died during the Colony Ark's crash through the sky-dome. Rejecting Instance Zero's peaceful exodus, it bolted a crude crown of looted Persian temple gold onto its head and uses glowing cyan puppet-cables to hijack and weld smaller frames into its own asymmetrical war-body, seeking to conquer and rule the Var.",
	},
]


