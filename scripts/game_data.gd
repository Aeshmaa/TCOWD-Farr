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
	"svel_hq",
	"svel_basic",
	"order_hq",
	"order_basic",
	"legion_hq",
	"legion_basic",
	"contested_steppes",
	"contested_cauldron",
	"farr_mining_ground",
]

const MAPS := {
	# --------------------------------------------------------------------------
	# 1. SVELEITRE MAPS (HQ + Basic Leveling Ground)
	# --------------------------------------------------------------------------
	"svel_hq": {
		"id": "svel_hq",
		"name": "Ark-Zero Bastion (Sveleitre HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "sveleitre",
		"level_band": "Safe HQ / Lv.1-12",
		"ground_color": Color(0.18, 0.24, 0.30),
		"sky_top": Color(0.08, 0.16, 0.28),
		"sky_horizon": Color(0.22, 0.42, 0.58),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 14.0),
			"order": Vector3(0.0, 0.1, 14.0),
			"legion": Vector3(0.0, 0.1, 14.0),
		},
		"refineries": [
			{"name": "Sveleitre Ark-Zero Core Refinery", "pos": Vector3(0.0, 0.0, 22.0)},
		],
		"npcs": [
			{"name": "Injector Unit V-01", "title": "Ark Potion & Charger NPC", "type": "POTION", "faction": "sveleitre", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.25, 0.95, 0.75)},
			{"name": "Ordnance Unit W-02", "title": "Weapon & Ammo/Force NPC", "type": "WEAPON", "faction": "sveleitre", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.35, 0.85, 1.0)},
			{"name": "Chassis Foundry A-03", "title": "Svel Chassis Armor NPC (Lv.1-45)", "type": "ARMOR", "faction": "sveleitre", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.45, 0.75, 1.0)},
			{"name": "Logistics Node U-04", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "sveleitre", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.75, 0.9, 1.0)},
			{"name": "Ark Backup Core R-00", "title": "HQ Rebirth & Save NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.5, 1.0, 0.85)},
			{"name": "INSTANCE ZERO: CODE AELFWYNE", "title": "Sveleitre Sovereign (Story Campaign)", "type": "LEADER", "faction": "sveleitre", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.88, 0.92, 0.98), "accent": Color(0.35, 0.95, 1.0)},
		],
		"veins": [
			{"name": "Ark Perimeter Starter Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(0.35, 0.9, 1.0)},
		],
		"portals": [
			{"title": "North Gate -> Sveleitre Basic Leveling", "target": "svel_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "East Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Scrap Scavenger (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.42, 0.48, 0.54), "accent": Color(0.4, 0.85, 1.0)},
			{"name": "Glitch-Spider Drone (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.35, 0.42, 0.50), "accent": Color(0.3, 0.95, 0.85)},
			{"name": "Feral Servo-Hound (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -26.0), "scale": 1.05, "body": Color(0.32, 0.45, 0.55), "accent": Color(0.3, 0.85, 1.0)},
		],
	},

	"svel_basic": {
		"id": "svel_basic",
		"name": "Cryo-Scrap Frontier (Sveleitre Basic Lv.12-28)",
		"category": "FACTION_BASIC",
		"owner_faction": "sveleitre",
		"level_band": "Lv.12-28 Basic Ground",
		"ground_color": Color(0.22, 0.28, 0.34),
		"sky_top": Color(0.10, 0.20, 0.32),
		"sky_horizon": Color(0.28, 0.48, 0.62),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 30.0),
			"order": Vector3(0.0, 0.1, 30.0),
			"legion": Vector3(0.0, 0.1, 30.0),
		},
		"refineries": [],
		"npcs": [
			{"name": "Forward Relay Beacon R-01", "title": "Outpost Rebirth & Save NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(7.0, 0.0, 32.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.5, 1.0, 0.85)},
		],
		"veins": [
			{"name": "Cryo-Scrap Farr Vein (Lv.12-25)", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.1, "max_units": 5, "yield": 12, "val": 28, "dur": 2.0, "col": Color(0.4, 0.85, 1.0)},
			{"name": "Frozen Conduit Vein (Lv.15-28)", "pos": Vector3(16.0, 0.0, -8.0), "scale": 1.1, "max_units": 5, "yield": 14, "val": 32, "dur": 2.0, "col": Color(0.4, 0.85, 1.0)},
		],
		"portals": [
			{"title": "South Gate -> Ark-Zero Bastion (Sveleitre HQ)", "target": "svel_hq", "pos": Vector3(-7.0, 0.0, 35.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "North-West Gate -> Shattered Steppes (Contested Lv.28-38)", "target": "contested_steppes", "pos": Vector3(-10.0, 0.0, -38.0), "col": Color(0.95, 0.75, 0.25)},
			{"title": "North-East Gate -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(10.0, 0.0, -38.0), "col": Color(1.0, 0.55, 0.2)},
		],
		"enemies": [
			{"name": "Corrupted Ark Drone (Lv.14)", "lv": 14, "hp": 380, "atk": 25, "bounty": 250, "farr_u": 16, "farr_v": 420, "pos": Vector3(-12.0, 0.0, 14.0), "scale": 1.1, "body": Color(0.32, 0.45, 0.55), "accent": Color(0.3, 0.85, 1.0)},
			{"name": "Rogue Cryo-Welder (Lv.18)", "lv": 18, "hp": 490, "atk": 32, "bounty": 320, "farr_u": 18, "farr_v": 520, "pos": Vector3(12.0, 0.0, 12.0), "scale": 1.12, "body": Color(0.30, 0.42, 0.58), "accent": Color(0.35, 0.9, 1.0)},
			{"name": "Hijacked Frame-Stalker (Lv.22)", "lv": 22, "hp": 620, "atk": 39, "bounty": 410, "farr_u": 22, "farr_v": 680, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.18, "body": Color(0.28, 0.38, 0.52), "accent": Color(0.2, 0.95, 1.0)},
			{"name": "Heavy Siege-Automaton (Lv.25)", "lv": 25, "hp": 740, "atk": 44, "bounty": 490, "farr_u": 25, "farr_v": 820, "pos": Vector3(12.0, 0.0, -12.0), "scale": 1.22, "body": Color(0.25, 0.35, 0.48), "accent": Color(0.4, 0.95, 1.0)},
			{"name": "SUB-CORE OVERSEER MK-IV (Mini-Boss Lv.28)", "lv": 28, "hp": 1150, "atk": 56, "bounty": 850, "farr_u": 35, "farr_v": 1250, "pos": Vector3(0.0, 0.0, -24.0), "scale": 1.65, "body": Color(0.20, 0.32, 0.45), "accent": Color(0.15, 1.0, 0.95)},
		],
	},

	# --------------------------------------------------------------------------
	# 2. ORDER OF THE ORACLE MAPS (HQ + Basic Leveling Ground)
	# --------------------------------------------------------------------------
	"order_hq": {
		"id": "order_hq",
		"name": "Asha High Sanctuary (Order HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "order",
		"level_band": "Safe HQ / Lv.1-12",
		"ground_color": Color(0.34, 0.30, 0.22),
		"sky_top": Color(0.22, 0.20, 0.14),
		"sky_horizon": Color(0.58, 0.48, 0.28),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 14.0),
			"order": Vector3(0.0, 0.1, 14.0),
			"legion": Vector3(0.0, 0.1, 14.0),
		},
		"refineries": [
			{"name": "Sanctuary of Asha Sacred Refinery", "pos": Vector3(0.0, 0.0, 22.0)},
		],
		"npcs": [
			{"name": "Haoma Alchemist Darius", "title": "Sanctuary Potion NPC", "type": "POTION", "faction": "order", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.88, 0.35)},
			{"name": "Atar Forgemaster Kaveh", "title": "Weapon & Force Charge NPC", "type": "WEAPON", "faction": "order", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.78, 0.28)},
			{"name": "Royal Armorer Bahram", "title": "Order/Druj Shared Armor NPC", "type": "ARMOR", "faction": "order", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.85, 0.45)},
			{"name": "Scribe of the Seal", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "order", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.92, 0.55)},
			{"name": "Chinvat Priestess Rashnu", "title": "HQ Rebirth & Save NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.95, 0.6)},
			{"name": "THE ORACLE, VOICE OF THE SEAL", "title": "Order Sovereign (Story Campaign)", "type": "LEADER", "faction": "order", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.92, 0.86, 0.72), "accent": Color(1.0, 0.88, 0.35)},
		],
		"veins": [
			{"name": "Sanctuary Courtyard Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(1.0, 0.85, 0.32)},
		],
		"portals": [
			{"title": "North Gate -> Order Basic Leveling", "target": "order_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "East Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Fallen Acolyte (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.55, 0.46, 0.25), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Dune Ash-Jackal (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.58, 0.44, 0.26), "accent": Color(1.0, 0.75, 0.30)},
			{"name": "Apostate Spear-Guard (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -26.0), "scale": 1.05, "body": Color(0.52, 0.42, 0.22), "accent": Color(1.0, 0.88, 0.4)},
		],
	},

	"order_basic": {
		"id": "order_basic",
		"name": "Sun-Bleached Terraces (Order Basic Lv.12-28)",
		"category": "FACTION_BASIC",
		"owner_faction": "order",
		"level_band": "Lv.12-28 Basic Ground",
		"ground_color": Color(0.38, 0.33, 0.24),
		"sky_top": Color(0.25, 0.22, 0.15),
		"sky_horizon": Color(0.64, 0.52, 0.32),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 30.0),
			"order": Vector3(0.0, 0.1, 30.0),
			"legion": Vector3(0.0, 0.1, 30.0),
		},
		"refineries": [],
		"npcs": [
			{"name": "Outpost Flame-Keeper Sraosha", "title": "Outpost Rebirth & Save NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(7.0, 0.0, 32.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.95, 0.6)},
		],
		"veins": [
			{"name": "Terrace Amber Farr Vein (Lv.12-25)", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.1, "max_units": 5, "yield": 12, "val": 28, "dur": 2.0, "col": Color(1.0, 0.85, 0.35)},
			{"name": "Sun-Altar Farr Vein (Lv.15-28)", "pos": Vector3(16.0, 0.0, -8.0), "scale": 1.1, "max_units": 5, "yield": 14, "val": 32, "dur": 2.0, "col": Color(1.0, 0.85, 0.35)},
		],
		"portals": [
			{"title": "South Gate -> Asha High Sanctuary (Order HQ)", "target": "order_hq", "pos": Vector3(-7.0, 0.0, 35.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North-West Gate -> Shattered Steppes (Contested Lv.28-38)", "target": "contested_steppes", "pos": Vector3(-10.0, 0.0, -38.0), "col": Color(0.95, 0.75, 0.25)},
			{"title": "North-East Gate -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(10.0, 0.0, -38.0), "col": Color(1.0, 0.55, 0.2)},
		],
		"enemies": [
			{"name": "Oathbreaker Sentinel (Lv.14)", "lv": 14, "hp": 380, "atk": 25, "bounty": 250, "farr_u": 16, "farr_v": 420, "pos": Vector3(-12.0, 0.0, 14.0), "scale": 1.1, "body": Color(0.55, 0.46, 0.25), "accent": Color(1.0, 0.85, 0.35)},
			{"name": "Heretic Fire-Magus (Lv.18)", "lv": 18, "hp": 490, "atk": 32, "bounty": 320, "farr_u": 18, "farr_v": 520, "pos": Vector3(12.0, 0.0, 12.0), "scale": 1.12, "body": Color(0.58, 0.42, 0.22), "accent": Color(1.0, 0.72, 0.25)},
			{"name": "Gilded War-Charioteer (Lv.22)", "lv": 22, "hp": 620, "atk": 39, "bounty": 410, "farr_u": 22, "farr_v": 680, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.18, "body": Color(0.52, 0.40, 0.20), "accent": Color(1.0, 0.88, 0.3)},
			{"name": "Corrupted Fravashi-Vessel (Lv.25)", "lv": 25, "hp": 740, "atk": 44, "bounty": 490, "farr_u": 25, "farr_v": 820, "pos": Vector3(12.0, 0.0, -12.0), "scale": 1.22, "body": Color(0.60, 0.48, 0.25), "accent": Color(1.0, 0.92, 0.45)},
			{"name": "DISGRACED HIGH INQUISITOR (Mini-Boss Lv.28)", "lv": 28, "hp": 1150, "atk": 56, "bounty": 850, "farr_u": 35, "farr_v": 1250, "pos": Vector3(0.0, 0.0, -24.0), "scale": 1.65, "body": Color(0.65, 0.50, 0.22), "accent": Color(1.0, 0.95, 0.4)},
		],
	},

	# --------------------------------------------------------------------------
	# 3. LEGION OF THE DRUJ MAPS (HQ + Basic Leveling Ground)
	# --------------------------------------------------------------------------
	"legion_hq": {
		"id": "legion_hq",
		"name": "Druj Obsidian Citadel (Legion HQ)",
		"category": "FACTION_HQ",
		"owner_faction": "legion",
		"level_band": "Safe HQ / Lv.1-12",
		"ground_color": Color(0.24, 0.14, 0.17),
		"sky_top": Color(0.16, 0.06, 0.10),
		"sky_horizon": Color(0.45, 0.16, 0.22),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 14.0),
			"order": Vector3(0.0, 0.1, 14.0),
			"legion": Vector3(0.0, 0.1, 14.0),
		},
		"refineries": [
			{"name": "Citadel of Dzahhakka Blood Refinery", "pos": Vector3(0.0, 0.0, 22.0)},
		],
		"npcs": [
			{"name": "Bloodbrewer Zarik", "title": "Citadel Potion NPC", "type": "POTION", "faction": "legion", "pos": Vector3(-10.0, 0.0, 14.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(0.98, 0.30, 0.38)},
			{"name": "Aka-Warpsmith Vartan", "title": "Weapon & Force Charge NPC", "type": "WEAPON", "faction": "legion", "pos": Vector3(-10.0, 0.0, 8.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(0.95, 0.25, 0.45)},
			{"name": "Obsidian Armorer Sorush", "title": "Order/Druj Shared Armor NPC", "type": "ARMOR", "faction": "legion", "pos": Vector3(10.0, 0.0, 14.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(1.0, 0.38, 0.35)},
			{"name": "Pact-Keeper Narseh", "title": "Scrolls, Bags & Talic Quest NPC", "type": "UTILITY", "faction": "legion", "pos": Vector3(10.0, 0.0, 8.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(0.95, 0.45, 0.50)},
			{"name": "Blood-Anchor Astovidatu", "title": "HQ Rebirth & Save NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(-6.0, 0.0, 21.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(1.0, 0.45, 0.65)},
			{"name": "AZII DZAHHAKKA, HERALD OF DRUJ", "title": "Legion Sovereign (Story Campaign)", "type": "LEADER", "faction": "legion", "pos": Vector3(6.0, 0.0, 21.0), "body": Color(0.28, 0.12, 0.16), "accent": Color(1.0, 0.22, 0.35)},
		],
		"veins": [
			{"name": "Citadel Blood-Vein (Lv.1-12)", "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.0, "max_units": 5, "yield": 8, "val": 18, "dur": 1.6, "col": Color(0.98, 0.28, 0.38)},
		],
		"portals": [
			{"title": "North Gate -> Legion Basic Leveling", "target": "legion_basic", "pos": Vector3(0.0, 0.0, -38.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "East Breach -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(22.0, 0.0, 2.0), "col": Color(1.0, 0.65, 0.2)},
		],
		"enemies": [
			{"name": "Lesser Daeva (Lv.3)", "lv": 3, "hp": 140, "atk": 10, "bounty": 100, "farr_u": 10, "farr_v": 200, "pos": Vector3(-10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.50, 0.18, 0.22), "accent": Color(1.0, 0.30, 0.35)},
			{"name": "Pit-Thrall Scavenger (Lv.6)", "lv": 6, "hp": 190, "atk": 14, "bounty": 135, "farr_u": 12, "farr_v": 240, "pos": Vector3(10.0, 0.0, -14.0), "scale": 1.0, "body": Color(0.45, 0.16, 0.24), "accent": Color(0.95, 0.25, 0.45)},
			{"name": "Venom-Scale Viperid (Lv.10)", "lv": 10, "hp": 260, "atk": 19, "bounty": 175, "farr_u": 14, "farr_v": 280, "pos": Vector3(0.0, 0.0, -26.0), "scale": 1.05, "body": Color(0.42, 0.14, 0.20), "accent": Color(1.0, 0.35, 0.4)},
		],
	},

	"legion_basic": {
		"id": "legion_basic",
		"name": "Ashen Blood-Basin (Legion Basic Lv.12-28)",
		"category": "FACTION_BASIC",
		"owner_faction": "legion",
		"level_band": "Lv.12-28 Basic Ground",
		"ground_color": Color(0.28, 0.16, 0.19),
		"sky_top": Color(0.18, 0.07, 0.12),
		"sky_horizon": Color(0.52, 0.18, 0.25),
		"spawns": {
			"sveleitre": Vector3(0.0, 0.1, 30.0),
			"order": Vector3(0.0, 0.1, 30.0),
			"legion": Vector3(0.0, 0.1, 30.0),
		},
		"refineries": [],
		"npcs": [
			{"name": "Outpost Soul-Binder Vizaresh", "title": "Outpost Rebirth & Save NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(7.0, 0.0, 32.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(1.0, 0.45, 0.65)},
		],
		"veins": [
			{"name": "Basin Crimson Farr Vein (Lv.12-25)", "pos": Vector3(-16.0, 0.0, 10.0), "scale": 1.1, "max_units": 5, "yield": 12, "val": 28, "dur": 2.0, "col": Color(0.95, 0.3, 0.38)},
			{"name": "Obsidian Fissure Vein (Lv.15-28)", "pos": Vector3(16.0, 0.0, -8.0), "scale": 1.1, "max_units": 5, "yield": 14, "val": 32, "dur": 2.0, "col": Color(0.95, 0.3, 0.38)},
		],
		"portals": [
			{"title": "South Gate -> Druj Obsidian Citadel (Legion HQ)", "target": "legion_hq", "pos": Vector3(-7.0, 0.0, 35.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "North-West Gate -> Shattered Steppes (Contested Lv.28-38)", "target": "contested_steppes", "pos": Vector3(-10.0, 0.0, -38.0), "col": Color(0.95, 0.75, 0.25)},
			{"title": "North-East Gate -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(10.0, 0.0, -38.0), "col": Color(1.0, 0.55, 0.2)},
		],
		"enemies": [
			{"name": "Nasru Blood-Hound (Lv.14)", "lv": 14, "hp": 380, "atk": 25, "bounty": 250, "farr_u": 16, "farr_v": 420, "pos": Vector3(-12.0, 0.0, 14.0), "scale": 1.1, "body": Color(0.50, 0.18, 0.22), "accent": Color(1.0, 0.30, 0.35)},
			{"name": "Flayed Executioner (Lv.18)", "lv": 18, "hp": 490, "atk": 32, "bounty": 320, "farr_u": 18, "farr_v": 520, "pos": Vector3(12.0, 0.0, 12.0), "scale": 1.12, "body": Color(0.48, 0.15, 0.25), "accent": Color(0.95, 0.25, 0.45)},
			{"name": "Serpent-Cult Hexer (Lv.22)", "lv": 22, "hp": 620, "atk": 39, "bounty": 410, "farr_u": 22, "farr_v": 680, "pos": Vector3(-12.0, 0.0, -8.0), "scale": 1.18, "body": Color(0.42, 0.14, 0.32), "accent": Color(0.95, 0.20, 0.55)},
			{"name": "Obsidian Titan-Spawn (Lv.25)", "lv": 25, "hp": 740, "atk": 44, "bounty": 490, "farr_u": 25, "farr_v": 820, "pos": Vector3(12.0, 0.0, -12.0), "scale": 1.22, "body": Color(0.38, 0.12, 0.22), "accent": Color(1.0, 0.22, 0.38)},
			{"name": "AKA-MANAH WAR-EXECUTIONER (Mini-Boss Lv.28)", "lv": 28, "hp": 1150, "atk": 56, "bounty": 850, "farr_u": 35, "farr_v": 1250, "pos": Vector3(0.0, 0.0, -24.0), "scale": 1.65, "body": Color(0.45, 0.10, 0.18), "accent": Color(1.0, 0.15, 0.35)},
		],
	},

	# --------------------------------------------------------------------------
	# 4. SHARED CONTESTED UPPER-LEVEL MAPS (2 Maps: All 3 Factions Contest Spots)
	# --------------------------------------------------------------------------
	"contested_steppes": {
		"id": "contested_steppes",
		"name": "Shattered Persepolis Steppes (Contested Lv.28-38)",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Contested Lv.28-38 + Boss Yima",
		"ground_color": Color(0.32, 0.27, 0.22),
		"sky_top": Color(0.16, 0.14, 0.22),
		"sky_horizon": Color(0.48, 0.36, 0.28),
		"spawns": {
			"sveleitre": Vector3(-34.0, 0.1, 26.0),
			"order": Vector3(34.0, 0.1, 26.0),
			"legion": Vector3(0.0, 0.1, 36.0),
		},
		"refineries": [],
		"npcs": [
			{"name": "Steppes Relay R-02 (Svel)", "title": "Contested Rebirth & Save NPC", "type": "REBIRTH", "faction": "sveleitre", "pos": Vector3(-38.0, 0.0, 28.0), "body": Color(0.22, 0.28, 0.35), "accent": Color(0.5, 1.0, 0.85)},
			{"name": "Steppes Shrine Sraosha (Order)", "title": "Contested Rebirth & Save NPC", "type": "REBIRTH", "faction": "order", "pos": Vector3(38.0, 0.0, 28.0), "body": Color(0.45, 0.38, 0.22), "accent": Color(1.0, 0.95, 0.6)},
			{"name": "Steppes Blood-Pillar (Legion)", "title": "Contested Rebirth & Save NPC", "type": "REBIRTH", "faction": "legion", "pos": Vector3(4.0, 0.0, 40.0), "body": Color(0.38, 0.16, 0.20), "accent": Color(1.0, 0.45, 0.65)},
		],
		"veins": [
			{"name": "Steppes Ruin Farr Vein (Lv.28-38)", "pos": Vector3(0.0, 0.0, 8.0), "scale": 1.2, "max_units": 6, "yield": 16, "val": 48, "dur": 2.3, "col": Color(1.0, 0.68, 0.22)},
		],
		"portals": [
			{"title": "SW Gate -> Sveleitre Basic Frontier", "target": "svel_basic", "pos": Vector3(-42.0, 0.0, 22.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "SE Gate -> Order Basic Terraces", "target": "order_basic", "pos": Vector3(42.0, 0.0, 22.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "South Gate -> Legion Basic Blood-Basin", "target": "legion_basic", "pos": Vector3(-4.0, 0.0, 42.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "North-West Gate -> Scorched Var Cauldron (Lv.36-45)", "target": "contested_cauldron", "pos": Vector3(-12.0, 0.0, -40.0), "col": Color(1.0, 0.3, 0.2)},
			{"title": "North-East Gate -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(12.0, 0.0, -40.0), "col": Color(1.0, 0.6, 0.15)},
		],
		"enemies": [
			{"name": "Druj Vein-Stalker (Contested Spot A - Lv.28)", "lv": 28, "hp": 820, "atk": 48, "bounty": 540, "farr_u": 28, "farr_v": 900, "pos": Vector3(-18.0, 0.0, 6.0), "scale": 1.25, "body": Color(0.45, 0.15, 0.55), "accent": Color(1.0, 0.2, 0.45)},
			{"name": "Immortal Bull-Capital Construct (Spot B - Lv.32)", "lv": 32, "hp": 1020, "atk": 58, "bounty": 680, "farr_u": 32, "farr_v": 1150, "pos": Vector3(18.0, 0.0, 6.0), "scale": 1.28, "body": Color(0.55, 0.42, 0.24), "accent": Color(1.0, 0.82, 0.3)},
			{"name": "Orphaned Fork-Guard (Contested Spot C - Lv.35)", "lv": 35, "hp": 1220, "atk": 68, "bounty": 840, "farr_u": 36, "farr_v": 1400, "pos": Vector3(-14.0, 0.0, -12.0), "scale": 1.32, "body": Color(0.25, 0.42, 0.48), "accent": Color(0.2, 0.95, 1.0)},
			{"name": "Hollow Royal Warden (Contested Spot D - Lv.38)", "lv": 38, "hp": 1420, "atk": 76, "bounty": 980, "farr_u": 40, "farr_v": 1620, "pos": Vector3(14.0, 0.0, -12.0), "scale": 1.35, "body": Color(0.48, 0.36, 0.22), "accent": Color(1.0, 0.78, 0.22)},
			{"name": "YIMA, THE HOLLOW KING (Forsworn World Boss)", "lv": 50, "hp": 5800, "atk": 140, "bounty": 4500, "farr_u": 70, "farr_v": 5200, "pos": Vector3(0.0, 0.0, -26.0), "scale": 3.8, "range": 5.0, "aggro": 11.0, "body": Color(0.55, 0.42, 0.24), "accent": Color(1.0, 0.85, 0.25)},
		],
	},

	"contested_cauldron": {
		"id": "contested_cauldron",
		"name": "Scorched Var Cauldron (Contested Lv.36-45)",
		"category": "CONTESTED_UPPER",
		"owner_faction": "all",
		"level_band": "Contested Lv.36-45 + Bosses Aeshma & Orphan",
		"ground_color": Color(0.22, 0.16, 0.16),
		"sky_top": Color(0.18, 0.06, 0.08),
		"sky_horizon": Color(0.55, 0.20, 0.16),
		"spawns": {
			"sveleitre": Vector3(-34.0, 0.1, 28.0),
			"order": Vector3(34.0, 0.1, 28.0),
			"legion": Vector3(0.0, 0.1, 36.0),
		},
		"refineries": [],
		"npcs": [],
		"veins": [
			{"name": "Cauldron Magma-Farr Vein (Lv.36-45)", "pos": Vector3(0.0, 0.0, 6.0), "scale": 1.35, "max_units": 6, "yield": 20, "val": 75, "dur": 2.6, "col": Color(1.0, 0.35, 0.18)},
		],
		"portals": [
			{"title": "South Gate -> Shattered Persepolis Steppes (Lv.28-38)", "target": "contested_steppes", "pos": Vector3(-10.0, 0.0, 40.0), "col": Color(0.95, 0.75, 0.25)},
			{"title": "East Gate -> Central Farr Mining Ground", "target": "farr_mining_ground", "pos": Vector3(10.0, 0.0, 40.0), "col": Color(1.0, 0.55, 0.2)},
		],
		"enemies": [
			{"name": "Orphaned Dread-Chassis (Spot A - Lv.38)", "lv": 38, "hp": 1400, "atk": 75, "bounty": 960, "farr_u": 38, "farr_v": 1580, "pos": Vector3(-18.0, 0.0, 10.0), "scale": 1.35, "body": Color(0.25, 0.42, 0.48), "accent": Color(0.2, 0.95, 1.0)},
			{"name": "Aeshma's Wrath-Fiend (Spot B - Lv.41)", "lv": 41, "hp": 1720, "atk": 88, "bounty": 1200, "farr_u": 44, "farr_v": 1950, "pos": Vector3(18.0, 0.0, 10.0), "scale": 1.4, "body": Color(0.55, 0.16, 0.18), "accent": Color(1.0, 0.22, 0.18)},
			{"name": "Abyssal Daeva Overlord (Spot C - Lv.44)", "lv": 44, "hp": 2100, "atk": 102, "bounty": 1500, "farr_u": 50, "farr_v": 2400, "pos": Vector3(0.0, 0.0, -8.0), "scale": 1.48, "body": Color(0.42, 0.12, 0.35), "accent": Color(1.0, 0.25, 0.55)},
			{"name": "AESHMA, THE WRATH UNBOUND (Forsworn World Boss)", "lv": 50, "hp": 6500, "atk": 165, "bounty": 5000, "farr_u": 80, "farr_v": 6000, "pos": Vector3(-20.0, 0.0, -26.0), "scale": 4.5, "range": 5.5, "aggro": 12.0, "body": Color(0.88, 0.86, 0.85), "accent": Color(1.0, 0.15, 0.15)},
			{"name": "THE ORPHAN PROCESS (Forsworn World Boss)", "lv": 50, "hp": 6000, "atk": 148, "bounty": 4600, "farr_u": 75, "farr_v": 5500, "pos": Vector3(20.0, 0.0, -26.0), "scale": 3.8, "range": 5.5, "aggro": 11.5, "body": Color(0.28, 0.34, 0.40), "accent": Color(0.18, 0.95, 1.0)},
		],
	},

	# --------------------------------------------------------------------------
	# 5. CENTRAL FARR MINING WAR GROUND (1 Map: All 3 Factions Gather for Ore!)
	# --------------------------------------------------------------------------
	"farr_mining_ground": {
		"id": "farr_mining_ground",
		"name": "The Crack — Central Farr Mining Ground",
		"category": "MINING_WAR",
		"owner_faction": "all",
		"level_band": "All-Faction PvPvE Ore War (Lv.25-50)",
		"ground_color": Color(0.24, 0.20, 0.28),
		"sky_top": Color(0.14, 0.08, 0.24),
		"sky_horizon": Color(0.62, 0.38, 0.18),
		"spawns": {
			"sveleitre": Vector3(-34.0, 0.1, 28.0),
			"order": Vector3(34.0, 0.1, 28.0),
			"legion": Vector3(0.0, 0.1, -36.0),
		},
		"refineries": [
			{"name": "Crack Core Contested Field Refinery", "pos": Vector3(0.0, 0.0, 18.0)},
		],
		"npcs": [],
		"veins": [
			{"name": "West Contested Rich Farr Vein (Lv.25-35)", "pos": Vector3(-14.0, 0.0, 6.0), "scale": 1.25, "max_units": 6, "yield": 16, "val": 55, "dur": 2.3, "col": Color(1.0, 0.55, 0.12)},
			{"name": "East Contested Rich Farr Vein (Lv.25-35)", "pos": Vector3(14.0, 0.0, 6.0), "scale": 1.25, "max_units": 6, "yield": 16, "val": 55, "dur": 2.3, "col": Color(1.0, 0.55, 0.12)},
			{"name": "North Contested Rich Farr Vein (Lv.25-35)", "pos": Vector3(0.0, 0.0, -16.0), "scale": 1.25, "max_units": 6, "yield": 16, "val": 55, "dur": 2.3, "col": Color(1.0, 0.55, 0.12)},
			{"name": "SCAR MEGAVEIN ALPHA (Lv.35-45 Core Ore)", "pos": Vector3(-6.0, 0.0, -2.0), "scale": 1.55, "max_units": 8, "yield": 26, "val": 98, "dur": 2.8, "col": Color(0.98, 0.22, 0.38)},
			{"name": "SCAR MEGAVEIN OMEGA (Lv.35-45 Core Ore)", "pos": Vector3(6.0, 0.0, -2.0), "scale": 1.55, "max_units": 8, "yield": 26, "val": 98, "dur": 2.8, "col": Color(0.98, 0.22, 0.38)},
		],
		"portals": [
			{"title": "SW Breach -> Sveleitre HQ (Ark-Zero Bastion)", "target": "svel_hq", "pos": Vector3(-40.0, 0.0, 32.0), "col": Color(0.3, 0.9, 1.0)},
			{"title": "SE Breach -> Order HQ (Asha Sanctuary)", "target": "order_hq", "pos": Vector3(40.0, 0.0, 32.0), "col": Color(1.0, 0.85, 0.35)},
			{"title": "North Breach -> Legion HQ (Druj Citadel)", "target": "legion_hq", "pos": Vector3(0.0, 0.0, -42.0), "col": Color(0.95, 0.3, 0.35)},
			{"title": "South Gate -> Shattered Persepolis Steppes", "target": "contested_steppes", "pos": Vector3(0.0, 0.0, 38.0), "col": Color(0.95, 0.75, 0.25)},
		],
		"enemies": [
			{"name": "Crack Vein-Warden West (Lv.30)", "lv": 30, "hp": 900, "atk": 52, "bounty": 600, "farr_u": 32, "farr_v": 1100, "pos": Vector3(-18.0, 0.0, 2.0), "scale": 1.25, "body": Color(0.45, 0.22, 0.55), "accent": Color(1.0, 0.45, 0.2)},
			{"name": "Crack Vein-Warden East (Lv.30)", "lv": 30, "hp": 900, "atk": 52, "bounty": 600, "farr_u": 32, "farr_v": 1100, "pos": Vector3(18.0, 0.0, 2.0), "scale": 1.25, "body": Color(0.45, 0.22, 0.55), "accent": Color(1.0, 0.45, 0.2)},
			{"name": "Core Megavein Enforcer (Lv.38)", "lv": 38, "hp": 1450, "atk": 76, "bounty": 1050, "farr_u": 45, "farr_v": 1800, "pos": Vector3(0.0, 0.0, -10.0), "scale": 1.38, "body": Color(0.52, 0.16, 0.38), "accent": Color(1.0, 0.25, 0.45)},
			{"name": "CRACK CORE ARCH-LEVIATHAN (Mine Boss Lv.45)", "lv": 45, "hp": 3800, "atk": 118, "bounty": 3200, "farr_u": 65, "farr_v": 4200, "pos": Vector3(0.0, 0.0, 2.0), "scale": 2.8, "range": 4.8, "aggro": 10.5, "body": Color(0.58, 0.18, 0.42), "accent": Color(1.0, 0.55, 0.15)},
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


