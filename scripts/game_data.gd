class_name GameData
extends RefCounted
## Central data-driven registry for:
## - 3 Factions & their native currencies (CYC / DRC / SGL)
## - 12 Base Classes & 24 Lv.30 Advanced Jobs with HP / FP / SP ratios
## - 6 Equipment Slots (WEAPON, HELMET, UPPER, LOWER, GLOVES, SHOES)
## - Armor Compatibility rule: Order & Legion share "ORGANIC_VAR" gear; Sveleitre uses "CHASSIS_SVEL" only
## - Multi-Bag Item definitions (Stackable Potions, Ammo/Force, Scrolls, and Equippable Gear)
## - 4 Physical HQ NPC Vendor catalogs (POTION, WEAPON, ARMOR, UTILITY)

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
		"hq_spawn": Vector3(-38.0, 0.1, 38.0),
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
				"skill2": {"name": "2: Ram Cleave", "cd": 3.5, "mult": 2.2, "range": 3.8, "fp_cost": 18, "sp_cost": 22},
				"skill3": {"name": "3: Shock Stomp AoE", "cd": 6.0, "mult": 1.8, "radius": 4.5, "fp_cost": 28, "sp_cost": 30},
				"jobs": ["Juggernaut (Tank)", "Shredder (Melee DPS)"],
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
				"skill2": {"name": "2: Rail Piercer", "cd": 3.8, "mult": 2.5, "range": 12.0, "fp_cost": 22, "sp_cost": 20},
				"skill3": {"name": "3: Drone Barrage AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 32, "sp_cost": 25},
				"jobs": ["Railer (Sniper)", "Swarm Operator (Drones)"],
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
				"skill2": {"name": "2: Logic Spike", "cd": 3.5, "mult": 2.4, "range": 10.0, "fp_cost": 35, "sp_cost": 10},
				"skill3": {"name": "3: Null-Field AoE", "cd": 5.5, "mult": 2.1, "radius": 5.5, "fp_cost": 50, "sp_cost": 12},
				"jobs": ["Silencer (Anti-Magic)", "Patcher (Repair Healer)"],
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
				"skill2": {"name": "2: Slag Cannon", "cd": 4.0, "mult": 2.2, "range": 9.0, "fp_cost": 24, "sp_cost": 18},
				"skill3": {"name": "3: Turret Salvo AoE", "cd": 6.0, "mult": 1.9, "radius": 4.8, "fp_cost": 34, "sp_cost": 22},
				"jobs": ["Siegeframe (Artillery)", "Torque Engineer (Support)"],
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
		"hq_spawn": Vector3(38.0, 0.1, 38.0),
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
				"skill2": {"name": "2: Sun Lance Thrust", "cd": 3.5, "mult": 2.2, "range": 4.0, "fp_cost": 18, "sp_cost": 22},
				"skill3": {"name": "3: Aegis Judgement AoE", "cd": 6.0, "mult": 1.8, "radius": 4.5, "fp_cost": 28, "sp_cost": 28},
				"jobs": ["Spenta Guard (Tank)", "Charioteer (Lancer)"],
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
				"skill2": {"name": "2: Arash Arrow", "cd": 3.8, "mult": 2.5, "range": 12.5, "fp_cost": 20, "sp_cost": 22},
				"skill3": {"name": "3: Varaghna Volley AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 30, "sp_cost": 26},
				"jobs": ["Arash Archer (Longbow)", "Falconer (Scout)"],
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
				"skill2": {"name": "2: Atar Bolt", "cd": 3.2, "mult": 2.4, "range": 10.0, "fp_cost": 36, "sp_cost": 8},
				"skill3": {"name": "3: Pillar of Atar AoE", "cd": 5.5, "mult": 2.2, "radius": 5.5, "fp_cost": 52, "sp_cost": 10},
				"jobs": ["Flamecaller (Fire DPS)", "Haoma Priest (Healer)"],
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
				"skill2": {"name": "2: Relic Hammer", "cd": 4.0, "mult": 2.1, "range": 5.5, "fp_cost": 20, "sp_cost": 20},
				"skill3": {"name": "3: Sanctified Ward AoE", "cd": 6.0, "mult": 1.85, "radius": 4.8, "fp_cost": 32, "sp_cost": 20},
				"jobs": ["Relicsmith (Crafter)", "Veinwright (Master Miner)"],
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
		"hq_spawn": Vector3(38.0, 0.1, -38.0),
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
				"skill2": {"name": "2: Aka Rend", "cd": 3.4, "mult": 2.35, "range": 4.0, "fp_cost": 18, "sp_cost": 24},
				"skill3": {"name": "3: Blood Quake AoE", "cd": 6.0, "mult": 1.9, "radius": 4.6, "fp_cost": 28, "sp_cost": 30},
				"jobs": ["Ravager (Berserker)", "Chainbound (Chain Tank)"],
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
				"skill2": {"name": "2: Venom Spine", "cd": 3.6, "mult": 2.45, "range": 11.5, "fp_cost": 22, "sp_cost": 22},
				"skill3": {"name": "3: Hex Cloud AoE", "cd": 6.5, "mult": 1.9, "radius": 5.0, "fp_cost": 32, "sp_cost": 24},
				"jobs": ["Veilstalker (Assassin)", "Hexarcher (Curse Bow)"],
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
				"skill2": {"name": "2: Hellfire Fang", "cd": 3.3, "mult": 2.45, "range": 10.0, "fp_cost": 38, "sp_cost": 8},
				"skill3": {"name": "3: Druj Nova AoE", "cd": 5.5, "mult": 2.2, "radius": 5.5, "fp_cost": 54, "sp_cost": 10},
				"jobs": ["Abyss Caller (Dark DPS)", "Bloodbinder (Drain Healer)"],
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
				"skill2": {"name": "2: Blight Spike", "cd": 4.0, "mult": 2.15, "range": 6.0, "fp_cost": 22, "sp_cost": 20},
				"skill3": {"name": "3: Corrupted Shrapnel AoE", "cd": 6.0, "mult": 1.9, "radius": 4.8, "fp_cost": 32, "sp_cost": 22},
				"jobs": ["Cursesmith (Titan Pilot)", "Blightminer (Saboteur)"],
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
	return {}


static func make_equipment_item(tier_idx: int, slot: String, equip_group: String) -> Dictionary:
	var t: Dictionary = EQUIPMENT_TIERS[clampi(tier_idx, 0, EQUIPMENT_TIERS.size() - 1)]
	var prefix: String = t["chassis_prefix"] if equip_group == EQUIP_CHASSIS_SVEL else t["organic_prefix"]
	var slot_label: String = EQUIP_SLOT_LABELS.get(slot, slot)
	var group_tag := "[Svel]" if equip_group == EQUIP_CHASSIS_SVEL else "[Order/Druj]"

	var is_weapon := (slot == "WEAPON")
	var atk_val := int(t["bonus_atk"]) if is_weapon else int(round(float(t["bonus_atk"]) * 0.12))
	var hp_val := int(round(float(t["bonus_hp"]) * 0.35)) if is_weapon else int(t["bonus_hp"])
	var fp_val := int(round(float(t["bonus_fp"]) * 0.4)) if is_weapon else int(t["bonus_fp"])
	var sp_val := int(round(float(t["bonus_sp"]) * 0.4)) if is_weapon else int(t["bonus_sp"])

	var slot_order := EQUIP_SLOTS.find(slot)
	var sort_key := 100 + slot_order * 20 - int(t["tier"])

	return {
		"id": "EQ_%s_T%d_%s" % [equip_group, t["tier"], slot],
		"name": "%s %s %s" % [prefix, slot_label, group_tag],
		"category": "EQUIP",
		"slot": slot,
		"tier_idx": tier_idx,
		"tier": int(t["tier"]),
		"req_lv": int(t["req_lv"]),
		"bracket": str(t["bracket"]),
		"rarity": str(t["rarity"]),
		"equip_group": equip_group,
		"bonus_atk": atk_val,
		"bonus_hp": hp_val,
		"bonus_fp": fp_val,
		"bonus_sp": sp_val,
		"sell_price": maxi(35, int(round(float(t["piece_cost"]) * 0.45)) + int(t["tier"]) * 30),
		"stackable": false,
		"max_stack": 1,
		"count": 1,
		"sort_key": sort_key,
	}
