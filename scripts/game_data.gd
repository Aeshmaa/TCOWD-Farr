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
	1: 1.00, # +1: 100% Safe
	2: 1.00, # +2: 100% Safe
	3: 1.00, # +3: 100% Safe
	4: 0.78, # +4: 78%
	5: 0.58, # +5: 58%
	6: 0.40, # +6: 40% (Glowing Aura!)
	7: 0.25, # +7: 25% (Sovereign Masterwork Aura!)
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
		"hq_name": "Colony Ark Hub (SW)",
		"hq_spawn": Vector3(-52.0, 0.1, 52.0),
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
		"hq_name": "Sanctuary of Asha (SE)",
		"hq_spawn": Vector3(52.0, 0.1, 52.0),
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
		"hq_name": "Citadel of Dzahhakka (NE)",
		"hq_spawn": Vector3(52.0, 0.1, -52.0),
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
