extends CharacterBody3D
## Data-Driven Player Controller:
## - Physical 3D HQ Vendor NPCs stationed at the sides of each Faction HQ (must walk up to trade!)
## - 6 Equipment Slots (WEAPON, HELMET, UPPER, LOWER, GLOVES, SHOES)
##   with Order+Druj Shared (ORGANIC_VAR) vs. Sveleitre-Only (CHASSIS_SVEL) compatibility
## - Automatic HP / FP / SP Charger Storage with adjustable % thresholds pulling from Bag stacks
## - Multi-Bag Inventory (starts with 2 Bags = 16 slots, expandable to 5 Bags = 40 slots) + Auto-Arrange [O]

signal state_updated(status_data: Dictionary)
signal event_logged(message: String)

const DROPPED_BAG_SCENE := preload("res://scenes/dropped_ore_bag.tscn")
const FRAVASHI_SCENE := preload("res://scenes/fravashi_companion.tscn")

@export var base_move_speed := 6.0
@export var overburdened_speed_mult := 0.6
@export var acceleration := 30.0
@export var hold_retarget_interval := 0.1
@export var max_weight := 100.0
@export var starting_debt := 5000
@export var upkeep_interval := 25.0
@export var upkeep_cost := 75

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: DirectionalSprite = $Sprite
@onready var marker: MeshInstance3D = $TargetMarker

var faction_index := 0
var class_index := 0
var job_branch := 0
var is_ascended_leader := false

## 6 Equipment Slots per compatibility group:
## - Order & Legion share `equipped_organic_slots`
## - Sveleitre uses `equipped_chassis_slots`
var equipped_organic_slots: Dictionary = {}
var equipped_chassis_slots: Dictionary = {}

## Multi-Bag System (RF Online style: 1 to 5 bags, 8 slots per bag)
var unlocked_bags := 2
var active_bag_tab := 0
var bag_slots: Array = []

## Automatic HP / FP / SP Charger Thresholds (0 = OFF, otherwise % threshold)
var auto_hp_pct := 55
var auto_fp_pct := 45
var auto_sp_pct := 45

## Currently open physical 3D Vendor NPC (null when not standing next to an NPC)
var active_vendor_npc: VendorNpc = null
var _armor_vendor_slot_cursor := 1 # Cycles HELMET..SHOES when buying individual armor pieces

## Persistent Character Save (RF-style: log back in exactly where you left off)
## - Bags, equipment, wallet, debt, level, position & carried Farr ore all persist.
## - On death only unrefined Farr ore drops; you respawn at your bound Rebirth NPC (or HQ default).
const SAVE_PATH := "user://farr_character_save.txt"
const SAVE_VERSION := 1
@export var autosave_interval := 5.0
var bind_points: Dictionary = {} # faction_id -> {"pos": Vector3, "name": String}
var last_saved_text := "Never"
var _autosave_timer := 5.0
var _save_disabled := false
var _wipe_confirm_timer := 0.0

var level := 1
var xp := 0

var max_hp := 300
var current_hp := 300
var max_fp := 180
var current_fp := 180
var max_sp := 160
var current_sp := 160

var unrefined_units := 0
var current_weight := 0.0
var unrefined_value := 0
var current_debt := 5000
var wallet_credits := 900

var is_mining := false
var mining_progress := 0.0

var selected_enemy: EnemyUnit = null
var auto_attacking := false
var siege_mode := false
var fravashi_instance: FravashiCompanion = null
var frame_mounted := false

var _attack_cd := 0.0
var _skill2_cd := 0.0
var _skill3_cd := 0.0
var _potion_cd := 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _has_click_target := false
var _holding_world_click := false
var _retarget_timer := 0.0
var _upkeep_timer := 0.0
var _interact_target: Node3D = null
var _mining_vein: FarrVein = null


func _ready() -> void:
	add_to_group("friendly_combatant")
	current_debt = starting_debt
	_upkeep_timer = upkeep_interval
	_init_equipment_and_bags()
	var loaded := load_game()
	_recalc_vital_stats()
	if not loaded:
		current_hp = max_hp
		current_fp = max_fp
		current_sp = max_sp
	_apply_faction_tint()
	_connect_world_enemies()
	_emit_state()
	if loaded:
		event_logged.emit("Welcome back! Lv.%d %s restored where you logged out (last save: %s). Rebirth Point: %s." % [
			level, _faction_dict()["name"], last_saved_text, _respawn_name()
		])
	else:
		event_logged.emit("New character created! Click HQ Side NPCs to trade, [I] Equipment & Bags, Rebirth NPC to bind respawn.")
		save_game()


func _init_equipment_and_bags() -> void:
	for slot in GameData.EQUIP_SLOTS:
		equipped_organic_slots[slot] = GameData.make_equipment_item(0, slot, GameData.EQUIP_ORGANIC_VAR)
		equipped_chassis_slots[slot] = GameData.make_equipment_item(0, slot, GameData.EQUIP_CHASSIS_SVEL)

	bag_slots.clear()
	for i in range(unlocked_bags * GameData.BAG_SLOTS_PER_BAG):
		bag_slots.append({})

	add_item_to_bags(GameData.make_consumable_item("POT_HP", 10))
	add_item_to_bags(GameData.make_consumable_item("POT_FP", 10))
	add_item_to_bags(GameData.make_consumable_item("POT_SP", 10))
	add_item_to_bags(GameData.make_consumable_item("AMMO_PACK", 120))
	add_item_to_bags(GameData.make_consumable_item("SCROLL_HQ", 3))


func _connect_world_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemy_unit"):
		var enemy := node as EnemyUnit
		if enemy and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_click"):
		_holding_world_click = true
		_retarget_timer = 0.0
	elif event.is_action_released("move_click"):
		_holding_world_click = false
	elif event.is_action_pressed("faction_cycle"):
		cycle_faction()
	elif event.is_action_pressed("class_cycle"):
		cycle_class()
	elif event.is_action_pressed("job_branch_toggle"):
		toggle_job_branch()
	elif event.is_action_pressed("dev_level_up"):
		dev_boost_level()
	elif event.is_action_pressed("teleport_hq"):
		teleport_to_hq()
	elif event.is_action_pressed("simulate_death"):
		simulate_death()
	elif event.is_action_pressed("target_cycle"):
		cycle_target()
	elif event.is_action_pressed("auto_arrange_bags"):
		auto_arrange_bags()
	elif event.is_action_pressed("skill_1"):
		use_skill(1)
	elif event.is_action_pressed("skill_2"):
		use_skill(2)
	elif event.is_action_pressed("skill_3"):
		use_skill(3)
	elif event.is_action_pressed("skill_4"):
		use_skill(4)
	elif event.is_action_pressed("potion_hp"):
		use_potion("HP", false)
	elif event.is_action_pressed("potion_fp"):
		use_potion("FP", false)
	elif event.is_action_pressed("potion_sp"):
		use_potion("SP", false)
	elif event.is_action_pressed("use_scroll"):
		use_teleport_scroll()


func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("move_click"):
		_holding_world_click = false

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_skill2_cd = maxf(0.0, _skill2_cd - delta)
	_skill3_cd = maxf(0.0, _skill3_cd - delta)
	_potion_cd = maxf(0.0, _potion_cd - delta)
	_wipe_confirm_timer = maxf(0.0, _wipe_confirm_timer - delta)

	# Periodic autosave (protects progress even if the game is force-stopped from the editor)
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		_autosave_timer = autosave_interval
		save_game()
	# Close physical NPC shop if player walks away from the NPC booth
	if active_vendor_npc != null:
		if not is_instance_valid(active_vendor_npc):
			active_vendor_npc = null
		else:
			var npc_dist := Vector2(
				global_position.x - active_vendor_npc.global_position.x,
				global_position.z - active_vendor_npc.global_position.z
			).length()
			if npc_dist > active_vendor_npc.interact_distance + 1.8:
				var closed_name := active_vendor_npc.npc_name
				active_vendor_npc = null
				event_logged.emit("Walked away from %s — shop closed." % closed_name)

	# Natural HP / FP / SP recovery + Automatic HP/FP/SP Charger Storage
	if not auto_attacking:
		current_hp = mini(max_hp, current_hp + int(ceil(max_hp * 0.02 * delta)))
	current_fp = mini(max_fp, current_fp + int(ceil(max_fp * 0.025 * delta)))
	current_sp = mini(max_sp, current_sp + int(ceil(max_sp * 0.03 * delta)))

	if _potion_cd <= 0.0:
		if auto_hp_pct > 0 and current_hp < int(max_hp * (float(auto_hp_pct) / 100.0)) and get_item_count("POT_HP") > 0:
			use_potion("HP", true)
		elif auto_fp_pct > 0 and current_fp < int(max_fp * (float(auto_fp_pct) / 100.0)) and get_item_count("POT_FP") > 0:
			use_potion("FP", true)
		elif auto_sp_pct > 0 and current_sp < int(max_sp * (float(auto_sp_pct) / 100.0)) and get_item_count("POT_SP") > 0:
			use_potion("SP", true)

	_upkeep_timer -= delta
	if _upkeep_timer <= 0.0:
		_upkeep_timer = upkeep_interval
		current_debt += upkeep_cost
		var f := _faction_dict()
		event_logged.emit("%s accrued: +%d %s added to %s." % [f["upkeep_label"], upkeep_cost, f["currency_code"], f["debt_name"]])

	if selected_enemy and (not is_instance_valid(selected_enemy) or selected_enemy.is_dead):
		_set_selected_enemy(null)
		auto_attacking = false

	_handle_click(delta)

	var wish := Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if siege_mode:
		if input != Vector2.ZERO:
			event_logged.emit("Locked in Siege Mode! Press [4] to undeploy before moving.")
		_clear_click_target()
		wish = Vector3.ZERO
	elif input != Vector2.ZERO:
		if is_mining:
			_cancel_mining("Mining interrupted by movement.")
		_interact_target = null
		auto_attacking = false
		_clear_click_target()
		wish = _camera_relative(input)
	elif auto_attacking and selected_enemy:
		var to_enemy := selected_enemy.global_position - global_position
		to_enemy.y = 0.0
		var atk_range := _effective_attack_range()
		if to_enemy.length() > atk_range:
			agent.target_position = selected_enemy.global_position
			wish = agent.get_next_path_position() - global_position
			wish.y = 0.0
			wish = wish.normalized()
		else:
			_clear_click_target()
			sprite.set_facing(to_enemy)
	elif _has_click_target:
		if _check_interact_arrival():
			wish = Vector3.ZERO
		elif agent.is_navigation_finished():
			_clear_click_target()
		else:
			wish = agent.get_next_path_position() - global_position
			wish.y = 0.0
			wish = wish.normalized()

	if is_mining:
		wish = Vector3.ZERO
		_process_mining(delta)
	elif auto_attacking and selected_enemy:
		_process_auto_attack()

	var speed := base_move_speed
	if current_weight >= max_weight * 0.8:
		speed *= overburdened_speed_mult

	var target_vel := wish * speed
	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()

	if wish != Vector3.ZERO:
		sprite.set_facing(wish)

	_emit_state()


func _faction_dict() -> Dictionary:
	return GameData.FACTIONS[faction_index]


func _class_dict() -> Dictionary:
	return _faction_dict()["classes"][class_index]


func _active_equipment_slots() -> Dictionary:
	if _faction_dict()["equip_group"] == GameData.EQUIP_CHASSIS_SVEL:
		return equipped_chassis_slots
	return equipped_organic_slots


func _active_gear_summary() -> String:
	var slots := _active_equipment_slots()
	var wpn: Dictionary = slots.get("WEAPON", {})
	var upper: Dictionary = slots.get("UPPER", {})
	var wpn_name: String = wpn.get("name", "Unarmed")
	var up_name: String = upper.get("name", "None")
	return "%s  |  %s" % [wpn_name, up_name]


func _active_job_title() -> String:
	var c := _class_dict()
	if level >= 30:
		var jobs: Array = c["jobs"]
		return "%s -> %s" % [c["base"], jobs[job_branch]]
	return "%s (%s)" % [c["base"], c["role"]]


# --- Multi-Bag Inventory, Auto-Arrange & Equipment Slot Functions ------------

func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in bag_slots:
		if not slot.is_empty() and slot.get("id", "") == item_id:
			total += int(slot.get("count", 1))
	return total


func consume_item_from_bags(item_id: String, amount: int = 1) -> bool:
	if get_item_count(item_id) < amount:
		return false
	var remaining := amount
	for i in range(bag_slots.size() - 1, -1, -1):
		var slot: Dictionary = bag_slots[i]
		if not slot.is_empty() and slot.get("id", "") == item_id:
			var cnt: int = int(slot.get("count", 1))
			var take := mini(cnt, remaining)
			cnt -= take
			remaining -= take
			if cnt <= 0:
				bag_slots[i] = {}
			else:
				slot["count"] = cnt
			if remaining <= 0:
				return true
	return remaining <= 0


func add_item_to_bags(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	if bool(item.get("stackable", false)):
		var item_id: String = item["id"]
		var max_stack: int = int(item.get("max_stack", 99))
		var remaining: int = int(item.get("count", 1))
		# 1. Fill existing partial stacks first
		for i in range(bag_slots.size()):
			var slot: Dictionary = bag_slots[i]
			if not slot.is_empty() and slot.get("id", "") == item_id:
				var cur: int = int(slot.get("count", 1))
				if cur < max_stack:
					var add := mini(max_stack - cur, remaining)
					slot["count"] = cur + add
					remaining -= add
					if remaining <= 0:
						return true
		# 2. Place remaining into empty slots
		for i in range(bag_slots.size()):
			if bag_slots[i].is_empty():
				var add := mini(max_stack, remaining)
				var new_stack := item.duplicate(true)
				new_stack["count"] = add
				bag_slots[i] = new_stack
				remaining -= add
				if remaining <= 0:
					return true
		return false
	else:
		for i in range(bag_slots.size()):
			if bag_slots[i].is_empty():
				bag_slots[i] = item.duplicate(true)
				return true
		return false


func auto_arrange_bags() -> void:
	var stacked_map: Dictionary = {}
	var non_stack_items: Array[Dictionary] = []

	for slot in bag_slots:
		if slot.is_empty():
			continue
		if bool(slot.get("stackable", false)):
			var item_id: String = slot["id"]
			if not stacked_map.has(item_id):
				var base_copy: Dictionary = slot.duplicate(true)
				base_copy["count"] = 0
				stacked_map[item_id] = base_copy
			stacked_map[item_id]["count"] = int(stacked_map[item_id]["count"]) + int(slot.get("count", 1))
		else:
			non_stack_items.append(slot.duplicate(true))

	var rebuilt: Array[Dictionary] = []
	for item_id in stacked_map.keys():
		var template: Dictionary = stacked_map[item_id]
		var total_cnt: int = int(template["count"])
		var max_st: int = int(template.get("max_stack", 99))
		while total_cnt > 0:
			var chunk := mini(max_st, total_cnt)
			var piece := template.duplicate(true)
			piece["count"] = chunk
			rebuilt.append(piece)
			total_cnt -= chunk

	rebuilt.append_array(non_stack_items)
	rebuilt.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka: int = int(a.get("sort_key", 999))
		var kb: int = int(b.get("sort_key", 999))
		if ka != kb:
			return ka < kb
		return str(a.get("name", "")) < str(b.get("name", ""))
	)

	var total_capacity := unlocked_bags * GameData.BAG_SLOTS_PER_BAG
	bag_slots.clear()
	for i in range(total_capacity):
		if i < rebuilt.size():
			bag_slots.append(rebuilt[i])
		else:
			bag_slots.append({})

	event_logged.emit("Auto-Arranged %d Bag(s): Stacked consumables & sorted equipment by slot/tier!" % unlocked_bags)
	_emit_state()


func select_bag_tab(bag_idx: int) -> void:
	if bag_idx < 0 or bag_idx >= unlocked_bags:
		event_logged.emit("Bag %d is locked! Visit the HQ Utility NPC to unlock up to 5 Bags." % (bag_idx + 1))
		return
	active_bag_tab = bag_idx
	_emit_state()


func interact_bag_slot(local_slot_idx: int) -> void:
	var global_idx := active_bag_tab * GameData.BAG_SLOTS_PER_BAG + local_slot_idx
	if global_idx < 0 or global_idx >= bag_slots.size():
		return
	var item: Dictionary = bag_slots[global_idx]
	if item.is_empty():
		return

	var cat: String = item.get("category", "")
	if cat == "CONSUMABLE":
		var id: String = item.get("id", "")
		if id == "POT_HP":
			use_potion("HP", false)
		elif id == "POT_FP":
			use_potion("FP", false)
		elif id == "POT_SP":
			use_potion("SP", false)
		elif id == "SCROLL_HQ":
			use_teleport_scroll()
		else:
			event_logged.emit("%s (%d) is used automatically when firing Ranged/Force attacks." % [item["name"], item["count"]])
	elif cat == "EQUIP":
		# If standing at an NPC and holding Shift or if item is incompatible, allow quick equip or check compatibility
		var my_group: String = _faction_dict()["equip_group"]
		var item_group: String = item.get("equip_group", "")
		if item_group != my_group:
			if active_vendor_npc != null:
				var price: int = int(item.get("sell_price", 100))
				var code: String = _faction_dict()["currency_code"]
				wallet_credits += price
				bag_slots[global_idx] = {}
				event_logged.emit("Sold incompatible %s to %s for +%d %s!" % [item["name"], active_vendor_npc.npc_name, price, code])
				_emit_state()
			else:
				event_logged.emit("Incompatible Race Gear! %s cannot equip %s. Walk to any HQ NPC to sell it!" % [_faction_dict()["name"], item["name"]])
			return

		var req_lv: int = int(item.get("req_lv", 1))
		if level < req_lv:
			event_logged.emit("Need Level %d to equip %s (current Lv.%d)." % [req_lv, item["name"], level])
			return

		var slot_name: String = item["slot"]
		var active_slots := _active_equipment_slots()
		var prev_equipped: Dictionary = active_slots.get(slot_name, {})
		active_slots[slot_name] = item
		bag_slots[global_idx] = prev_equipped
		_recalc_vital_stats()
		event_logged.emit("Equipped %s into [%s] slot!" % [item["name"], GameData.EQUIP_SLOT_LABELS.get(slot_name, slot_name)])
		_emit_state()


func unequip_equipment_slot(slot_name: String) -> void:
	var active_slots := _active_equipment_slots()
	var cur: Dictionary = active_slots.get(slot_name, {})
	if cur.is_empty():
		return
	if not add_item_to_bags(cur):
		event_logged.emit("Cannot unequip %s — all unlocked Bags are full!" % cur["name"])
		return
	active_slots[slot_name] = {}
	_recalc_vital_stats()
	event_logged.emit("Unequipped %s to Bag." % cur["name"])
	_emit_state()


func cycle_auto_charger(kind: String) -> void:
	if kind == "HP":
		auto_hp_pct = 75 if auto_hp_pct == 55 else (35 if auto_hp_pct == 75 else (0 if auto_hp_pct == 35 else 55))
		event_logged.emit("Auto-HP Charger set to: %s" % (("OFF" if auto_hp_pct == 0 else "<%d%% HP" % auto_hp_pct)))
	elif kind == "FP":
		auto_fp_pct = 65 if auto_fp_pct == 45 else (25 if auto_fp_pct == 65 else (0 if auto_fp_pct == 25 else 45))
		event_logged.emit("Auto-FP Charger set to: %s" % (("OFF" if auto_fp_pct == 0 else "<%d%% FP" % auto_fp_pct)))
	elif kind == "SP":
		auto_sp_pct = 65 if auto_sp_pct == 45 else (25 if auto_sp_pct == 65 else (0 if auto_sp_pct == 25 else 45))
		event_logged.emit("Auto-SP Charger set to: %s" % (("OFF" if auto_sp_pct == 0 else "<%d%% SP" % auto_sp_pct)))
	_emit_state()


func use_potion(kind: String, is_auto: bool) -> void:
	var tag := "[Auto-Charger] " if is_auto else ""
	if kind == "HP":
		if not consume_item_from_bags("POT_HP", 1):
			if not is_auto:
				event_logged.emit("Out of HP Potions in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var heal := int(round(max_hp * 0.55))
		current_hp = mini(max_hp, current_hp + heal)
		_potion_cd = 1.2
		event_logged.emit("%sUsed HP Potion (+%d HP, %d left in Bags)." % [tag, heal, get_item_count("POT_HP")])
	elif kind == "FP":
		if not consume_item_from_bags("POT_FP", 1):
			if not is_auto:
				event_logged.emit("Out of FP Chargers in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var gain := int(round(max_fp * 0.6))
		current_fp = mini(max_fp, current_fp + gain)
		_potion_cd = 1.2
		event_logged.emit("%sUsed FP Charger (+%d FP, %d left in Bags)." % [tag, gain, get_item_count("POT_FP")])
	elif kind == "SP":
		if not consume_item_from_bags("POT_SP", 1):
			if not is_auto:
				event_logged.emit("Out of SP Stims in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var gain := int(round(max_sp * 0.6))
		current_sp = mini(max_sp, current_sp + gain)
		_potion_cd = 1.2
		event_logged.emit("%sUsed SP Stim (+%d SP, %d left in Bags)." % [tag, gain, get_item_count("POT_SP")])
	_emit_state()


func use_teleport_scroll() -> void:
	if not consume_item_from_bags("SCROLL_HQ", 1):
		event_logged.emit("Out of Teleport Scrolls in Bags! Walk to the HQ Utility NPC to buy more.")
		return
	var f := _faction_dict()
	var hq_pos: Vector3 = f["hq_spawn"]
	var left := get_item_count("SCROLL_HQ")
	if global_position.distance_to(hq_pos) > 15.0:
		teleport_to_hq()
		event_logged.emit("Used Return Scroll -> Warped to %s (%d left in Bags)." % [f["hq_name"], left])
	else:
		if is_mining:
			_cancel_mining("")
		siege_mode = false
		auto_attacking = false
		active_vendor_npc = null
		_clear_click_target()
		global_position = Vector3(0.0, 0.1, 6.0)
		velocity = Vector3.ZERO
		event_logged.emit("Used Scar Portal Scroll -> Warped to Contested Center (%d left in Bags)." % left)
	_emit_state()


# --- Physical 3D HQ Vendor NPC Transactions (Requires standing at the NPC!) ---

func close_vendor_shop() -> void:
	active_vendor_npc = null
	_emit_state()


func execute_vendor_action(action_index: int) -> void:
	if active_vendor_npc == null or not is_instance_valid(active_vendor_npc):
		event_logged.emit("You must walk up to an HQ Vendor NPC at the sides of HQ to trade!")
		return
	var dist := Vector2(
		global_position.x - active_vendor_npc.global_position.x,
		global_position.z - active_vendor_npc.global_position.z
	).length()
	if dist > active_vendor_npc.interact_distance + 1.8:
		active_vendor_npc = null
		event_logged.emit("Too far from the Vendor NPC! Walk closer to their booth.")
		_emit_state()
		return

	var f := _faction_dict()
	var code: String = f["currency_code"]
	var vtype: String = active_vendor_npc.vendor_type
	var my_group: String = f["equip_group"]

	if vtype == "POTION":
		match action_index:
			0:
				_buy_stackable_from_npc("POT_HP", 10, 80, "HP Potion x10")
			1:
				_buy_stackable_from_npc("POT_FP", 10, 80, "FP Charger x10")
			2:
				_buy_stackable_from_npc("POT_SP", 10, 80, "SP Stim x10")
			3:
				if wallet_credits < 210:
					event_logged.emit("%s: Need 210 %s for Combo Charger Pack." % [active_vendor_npc.npc_name, code])
					return
				wallet_credits -= 210
				add_item_to_bags(GameData.make_consumable_item("POT_HP", 10))
				add_item_to_bags(GameData.make_consumable_item("POT_FP", 10))
				add_item_to_bags(GameData.make_consumable_item("POT_SP", 10))
				event_logged.emit("%s: Stored +10 HP, +10 FP, +10 SP in your Bags (-210 %s)." % [active_vendor_npc.npc_name, code])
	elif vtype == "WEAPON":
		match action_index:
			0:
				_buy_stackable_from_npc("AMMO_PACK", 100, 90, "Ammo / Force Cell x100")
			1:
				_buy_equipment_piece_from_npc(1, "WEAPON", my_group)
			2:
				_buy_equipment_piece_from_npc(2, "WEAPON", my_group)
			3:
				_buy_equipment_piece_from_npc(3, "WEAPON", my_group)
	elif vtype == "ARMOR":
		# Cycles through the 5 Armor slots (HELMET, UPPER, LOWER, GLOVES, SHOES)
		var armor_slot: String = GameData.EQUIP_SLOTS[_armor_vendor_slot_cursor]
		match action_index:
			0:
				if _buy_equipment_piece_from_npc(1, armor_slot, my_group):
					_advance_armor_cursor()
			1:
				if _buy_equipment_piece_from_npc(2, armor_slot, my_group):
					_advance_armor_cursor()
			2:
				if _buy_equipment_piece_from_npc(3, armor_slot, my_group):
					_advance_armor_cursor()
			3:
				_advance_armor_cursor()
				var next_slot: String = GameData.EQUIP_SLOTS[_armor_vendor_slot_cursor]
				event_logged.emit("%s: Switched armor slot selection to [%s]." % [
					active_vendor_npc.npc_name, GameData.EQUIP_SLOT_LABELS.get(next_slot, next_slot)
				])
	elif vtype == "UTILITY":
		match action_index:
			0:
				_buy_stackable_from_npc("SCROLL_HQ", 3, 90, "Teleport Scroll x3")
			1:
				if unlocked_bags >= GameData.MAX_BAGS:
					event_logged.emit("%s: You already unlocked all 5 Bags (40 slots max)!" % active_vendor_npc.npc_name)
					return
				var bag_cost := 350 * unlocked_bags
				if wallet_credits < bag_cost:
					event_logged.emit("%s: Need %d %s to unlock Bag %d." % [active_vendor_npc.npc_name, bag_cost, code, unlocked_bags + 1])
					return
				wallet_credits -= bag_cost
				unlocked_bags += 1
				for i in range(GameData.BAG_SLOTS_PER_BAG):
					bag_slots.append({})
				event_logged.emit("%s: Unlocked Bag %d (%d total bag slots)! (-%d %s)" % [
					active_vendor_npc.npc_name, unlocked_bags, unlocked_bags * GameData.BAG_SLOTS_PER_BAG, bag_cost, code
				])
			2:
				_sell_all_bag_equipment()
			3:
				if current_debt <= 0:
					event_logged.emit("%s: Your %s is already 0!" % [active_vendor_npc.npc_name, f["debt_name"]])
					return
				var pay := mini(500, mini(current_debt, wallet_credits))
				if pay <= 0:
					event_logged.emit("%s: You have 0 %s in Wallet to pay down debt." % [active_vendor_npc.npc_name, code])
					return
				wallet_credits -= pay
				current_debt -= pay
				event_logged.emit("%s: Paid %d %s toward %s!" % [active_vendor_npc.npc_name, pay, code, f["debt_name"]])
	elif vtype == "REBIRTH":
		var fid: String = str(f["id"])
		match action_index:
			0:
				var bind_pos := active_vendor_npc.global_position + Vector3(0.0, 0.1, 2.2)
				bind_points[fid] = {"pos": bind_pos, "name": active_vendor_npc.npc_name}
				save_game()
				event_logged.emit("%s: Bound your Rebirth Spawn Point here! On death you will respawn at %s." % [
					active_vendor_npc.npc_name, active_vendor_npc.npc_name
				])
			1:
				bind_points.erase(fid)
				save_game()
				event_logged.emit("%s: Reset your Rebirth Spawn Point back to %s (HQ Default Coordinates)." % [
					active_vendor_npc.npc_name, f["hq_name"]
				])
			2:
				var heal_cost := 50
				if wallet_credits < heal_cost:
					event_logged.emit("%s: Need %d %s for Full Vital Restoration." % [active_vendor_npc.npc_name, heal_cost, code])
					return
				wallet_credits -= heal_cost
				current_hp = max_hp
				current_fp = max_fp
				current_sp = max_sp
				save_game()
				event_logged.emit("%s: Restored 100%% HP / FP / SP (-%d %s) & saved progress!" % [active_vendor_npc.npc_name, heal_cost, code])
			3:
				save_game()
				event_logged.emit("%s: Character state, Bags, Equipment & Position saved (%s)!" % [active_vendor_npc.npc_name, last_saved_text])
	save_game()
	_emit_state()


func _advance_armor_cursor() -> void:
	_armor_vendor_slot_cursor += 1
	if _armor_vendor_slot_cursor >= GameData.EQUIP_SLOTS.size():
		_armor_vendor_slot_cursor = 1


func _buy_stackable_from_npc(item_id: String, count: int, cost: int, label: String) -> void:
	var code: String = _faction_dict()["currency_code"]
	if wallet_credits < cost:
		event_logged.emit("%s: Need %d %s for %s (you have %d)." % [active_vendor_npc.npc_name, cost, code, label, wallet_credits])
		return
	var item := GameData.make_consumable_item(item_id, count)
	if not add_item_to_bags(item):
		event_logged.emit("%s: Your Bags are full! Auto-Arrange [O] or unlock another Bag at the Utility NPC." % active_vendor_npc.npc_name)
		return
	wallet_credits -= cost
	event_logged.emit("%s: Bought %s -> stored in Bag (-%d %s)." % [active_vendor_npc.npc_name, label, cost, code])


func _buy_equipment_piece_from_npc(tier_idx: int, slot: String, equip_group: String) -> bool:
	var code: String = _faction_dict()["currency_code"]
	var tier_data: Dictionary = GameData.EQUIPMENT_TIERS[tier_idx]
	var cost: int = int(tier_data["piece_cost"])
	var item := GameData.make_equipment_item(tier_idx, slot, equip_group)
	if wallet_credits < cost:
		event_logged.emit("%s: Need %d %s for %s (you have %d)." % [active_vendor_npc.npc_name, cost, code, item["name"], wallet_credits])
		return false
	if not add_item_to_bags(item):
		event_logged.emit("%s: Your Bags are full! Make space or unlock another Bag." % active_vendor_npc.npc_name)
		return false
	wallet_credits -= cost
	event_logged.emit("%s: Purchased %s (-%d %s) -> Placed in Bag! Open [I] to equip." % [
		active_vendor_npc.npc_name, item["name"], cost, code
	])
	return true


func _sell_all_bag_equipment() -> void:
	var sold_count := 0
	var total_earned := 0
	for i in range(bag_slots.size()):
		var item: Dictionary = bag_slots[i]
		if not item.is_empty() and item.get("category", "") == "EQUIP":
			total_earned += int(item.get("sell_price", 80))
			sold_count += 1
			bag_slots[i] = {}
	var code: String = _faction_dict()["currency_code"]
	if sold_count == 0:
		event_logged.emit("%s: No unequipped gear in your Bags to sell." % active_vendor_npc.npc_name)
	else:
		wallet_credits += total_earned
		event_logged.emit("%s: Sold %d unequipped gear piece(s) from Bags for +%d %s!" % [
			active_vendor_npc.npc_name, sold_count, total_earned, code
		])


func cycle_class() -> void:
	class_index = (class_index + 1) % 4
	_recalc_vital_stats()
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp
	var c := _class_dict()
	event_logged.emit("Class -> %s (%s) | HP:%d FP:%d SP:%d | Range:%.1fm" % [
		c["base"], c["role"], max_hp, max_fp, max_sp, c["range"]
	])


func toggle_job_branch() -> void:
	job_branch = 1 - job_branch
	var c := _class_dict()
	var jobs: Array = c["jobs"]
	if level < 30:
		event_logged.emit("Selected future Lv.30 Job Branch: %s (unlocks at Lv.30!)." % jobs[job_branch])
	else:
		_recalc_vital_stats()
		event_logged.emit("Switched Lv.30 Advanced Job -> %s!" % jobs[job_branch])


func dev_boost_level() -> void:
	var f := _faction_dict()
	if level < 45:
		var prev := level
		level = mini(45, level + 5)
		wallet_credits += 1000
		if prev < 30 and level >= 30:
			var jobs: Array = _class_dict()["jobs"]
			event_logged.emit("REACHED LV.%d! Promoted to Advanced Job: %s (+1000 %s)!" % [level, jobs[job_branch], f["currency_code"]])
		else:
			event_logged.emit("Boosted to Level %d (Cap: 45) & +1000 %s." % [level, f["currency_code"]])
	elif not is_ascended_leader:
		is_ascended_leader = true
		level = 50
		wallet_credits += 5000
		event_logged.emit("ELECTED FACTION LEADER (ARCHON)! Raised to Lv.50 & +5000 %s!" % f["currency_code"])
	else:
		is_ascended_leader = false
		level = 1
		event_logged.emit("Reset back to Level 1 Recruit.")
	_recalc_vital_stats()
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp


func teleport_to_hq() -> void:
	if is_mining:
		_cancel_mining("")
	siege_mode = false
	auto_attacking = false
	active_vendor_npc = null
	_clear_click_target()
	_interact_target = null
	var f := _faction_dict()
	global_position = f["hq_spawn"]
	velocity = Vector3.ZERO
	event_logged.emit("Arrived at %s (%s). Click any HQ Side Vendor NPC to trade!" % [f["hq_name"], f["name"]])


func _handle_click(delta: float) -> void:
	_retarget_timer -= delta
	if _holding_world_click and _retarget_timer <= 0.0:
		_retarget_timer = hold_retarget_interval
		var hit_info := _mouse_raycast(get_viewport().get_mouse_position())
		if hit_info.is_empty():
			return
		var collider: Object = hit_info.get("collider")
		var pos: Vector3 = hit_info.get("position")

		if collider is EnemyUnit:
			var enemy := collider as EnemyUnit
			if enemy.is_dead:
				return
			if is_mining:
				_cancel_mining("Switched to combat.")
			_interact_target = null
			active_vendor_npc = null
			_set_selected_enemy(enemy)
			auto_attacking = true
			event_logged.emit("Targeted & engaging %s." % enemy.enemy_name)
			_holding_world_click = false
		elif collider is FarrVein or collider is RefineryStation or collider is DroppedOreBag or collider is VendorNpc:
			var node := collider as Node3D
			if siege_mode:
				event_logged.emit("Cannot walk while in Siege Mode! Press [4] to undeploy.")
				_holding_world_click = false
				return
			if is_mining and _mining_vein == node:
				return
			if is_mining:
				_cancel_mining("Switched target.")
			auto_attacking = false
			_interact_target = node
			_set_click_target(node.global_position)
			_holding_world_click = false
		else:
			if siege_mode:
				_holding_world_click = false
				return
			if is_mining:
				_cancel_mining("Mining canceled by moving away.")
			auto_attacking = false
			_interact_target = null
			_set_click_target(pos)


func cycle_target() -> void:
	var enemies: Array[EnemyUnit] = []
	for n in get_tree().get_nodes_in_group("enemy_unit"):
		var e := n as EnemyUnit
		if e and not e.is_dead:
			enemies.append(e)
	if enemies.is_empty():
		_set_selected_enemy(null)
		return
	enemies.sort_custom(func(a: EnemyUnit, b: EnemyUnit) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	var idx := enemies.find(selected_enemy)
	var next_enemy := enemies[(idx + 1) % enemies.size()]
	_set_selected_enemy(next_enemy)
	event_logged.emit("Targeted %s (HP %d/%d)." % [next_enemy.enemy_name, next_enemy.current_hp, next_enemy.max_hp])


func _set_selected_enemy(enemy: EnemyUnit) -> void:
	if selected_enemy and is_instance_valid(selected_enemy):
		selected_enemy.set_selected(false)
	selected_enemy = enemy
	if selected_enemy and is_instance_valid(selected_enemy):
		selected_enemy.set_selected(true)
	if fravashi_instance and is_instance_valid(fravashi_instance) and fravashi_instance.visible:
		fravashi_instance.assigned_target = selected_enemy


func use_skill(slot: int) -> void:
	if slot == 1:
		if selected_enemy == null:
			cycle_target()
		if selected_enemy:
			auto_attacking = not auto_attacking
			event_logged.emit("Auto-Attack: %s" % ("ON" if auto_attacking else "OFF"))
	elif slot == 2:
		_cast_skill_2()
	elif slot == 3:
		_cast_skill_3()
	elif slot == 4:
		_cast_signature_4()
	_emit_state()


func _cast_skill_2() -> void:
	if _skill2_cd > 0.0:
		event_logged.emit("Skill 2 on cooldown (%.1fs)." % _skill2_cd)
		return
	if selected_enemy == null or selected_enemy.is_dead:
		cycle_target()
	if selected_enemy == null:
		event_logged.emit("No target in range for Skill 2.")
		return
	var s2: Dictionary = _class_dict()["skill2"]
	var fp_cost: int = s2.get("fp_cost", 20)
	var sp_cost: int = s2.get("sp_cost", 15)
	if current_fp < fp_cost or current_sp < sp_cost:
		event_logged.emit("Not enough FP/SP for %s! Use [6] FP or [7] SP Potion." % s2["name"])
		return
	var dist := Vector2(global_position.x - selected_enemy.global_position.x, global_position.z - selected_enemy.global_position.z).length()
	var max_dist := maxf(float(s2["range"]), 15.0 if siege_mode else 0.0)
	if dist > max_dist:
		event_logged.emit("Target too far for %s (move within %.1fm)." % [s2["name"], max_dist])
		return
	if is_mining:
		_cancel_mining("")
	current_fp -= fp_cost
	current_sp -= sp_cost
	_skill2_cd = float(s2["cd"])
	sprite.set_facing(selected_enemy.global_position - global_position)
	var dmg := int(round(_effective_attack_damage() * float(s2["mult"])))
	selected_enemy.receive_damage(dmg, self)
	event_logged.emit("%s hit %s for %d DMG (-%d FP, -%d SP)!" % [s2["name"], selected_enemy.enemy_name, dmg, fp_cost, sp_cost])


func _cast_skill_3() -> void:
	if _skill3_cd > 0.0:
		event_logged.emit("Skill 3 on cooldown (%.1fs)." % _skill3_cd)
		return
	var s3: Dictionary = _class_dict()["skill3"]
	var fp_cost: int = s3.get("fp_cost", 30)
	var sp_cost: int = s3.get("sp_cost", 20)
	if current_fp < fp_cost or current_sp < sp_cost:
		event_logged.emit("Not enough FP/SP for %s! Use [6] FP or [7] SP Potion." % s3["name"])
		return
	if is_mining:
		_cancel_mining("")
	current_fp -= fp_cost
	current_sp -= sp_cost
	var center := selected_enemy.global_position if (selected_enemy and not selected_enemy.is_dead) else global_position
	_skill3_cd = float(s3["cd"])
	var dmg := int(round(_effective_attack_damage() * float(s3["mult"])))
	var hits := _deal_aoe_damage(center, float(s3["radius"]), dmg)
	event_logged.emit("%s hit %d enemy(s) for %d AoE DMG (-%d FP, -%d SP)!" % [s3["name"], hits, dmg, fp_cost, sp_cost])


func _cast_signature_4() -> void:
	if faction_index == 0:
		siege_mode = not siege_mode
		if siege_mode:
			if is_mining:
				_cancel_mining("")
			_clear_click_target()
			event_logged.emit("SVELEITRE SIEGE MODE: Locked in place! Range 15m, AoE shells (-1 Ammo & +15 CYC Ark Debt/shot).")
		else:
			event_logged.emit("Siege Mode retracted. Mobile again.")
	elif faction_index == 1:
		if fravashi_instance == null or not is_instance_valid(fravashi_instance):
			fravashi_instance = FRAVASHI_SCENE.instantiate() as FravashiCompanion
			get_parent().add_child(fravashi_instance)
			fravashi_instance.owner_player = self
			fravashi_instance.companion_event.connect(func(msg: String) -> void: event_logged.emit(msg))
			fravashi_instance.global_position = global_position + Vector3(1.5, 0.0, 1.0)
			fravashi_instance.assigned_target = selected_enemy
			event_logged.emit("ORDER SIGNATURE: Summoned Fravashi Spirit (Lv.%d)! Draws aggro & levels up." % fravashi_instance.level)
		else:
			fravashi_instance.visible = not fravashi_instance.visible
			if fravashi_instance.visible:
				fravashi_instance.current_hp = fravashi_instance.max_hp
				fravashi_instance.global_position = global_position + Vector3(1.5, 0.0, 1.0)
				fravashi_instance.assigned_target = selected_enemy
				event_logged.emit("Re-summoned Fravashi Spirit (Lv.%d)." % fravashi_instance.level)
			else:
				event_logged.emit("Dismissed Fravashi Spirit.")
	elif faction_index == 2:
		frame_mounted = not frame_mounted
		_recalc_vital_stats()
		if frame_mounted:
			sprite.scale = Vector3(2.2, 2.2, 2.2)
			sprite.position.y = 1.75
			event_logged.emit("LEGION SIGNATURE: Mounted Dread-Titan Construct (+400 HP, +90% ATK). Hits taken cost +18 SGL Pact Debt!")
		else:
			sprite.scale = Vector3.ONE
			sprite.position.y = 0.8
			event_logged.emit("Dismounted Dread-Titan Construct.")


func _process_auto_attack() -> void:
	if selected_enemy == null or selected_enemy.is_dead:
		auto_attacking = false
		return
	var to_enemy := selected_enemy.global_position - global_position
	to_enemy.y = 0.0
	if to_enemy.length() > _effective_attack_range() + 0.35:
		return
	if _attack_cd > 0.0:
		return

	var c := _class_dict()
	var needs_charge := bool(c.get("uses_ammo", false)) or bool(c.get("uses_force", false)) or siege_mode
	if needs_charge:
		if not consume_item_from_bags("AMMO_PACK", 1):
			auto_attacking = false
			event_logged.emit("Out of Ammo / Force Cells in Bags! Restock at the HQ Weapon & Force NPC.")
			return

	_attack_cd = 1.05
	sprite.set_facing(to_enemy)
	var dmg := _effective_attack_damage()
	if siege_mode:
		current_debt += 15
		var hits := _deal_aoe_damage(selected_enemy.global_position, 4.0, dmg)
		event_logged.emit("Siege Artillery hit %d target(s) for %d DMG (-1 Ammo, +15 CYC Debt)." % [hits, dmg])
	else:
		selected_enemy.receive_damage(dmg, self)


func _deal_aoe_damage(center: Vector3, radius: float, dmg: int) -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("enemy_unit"):
		var e := n as EnemyUnit
		if e and not e.is_dead:
			var d := Vector2(e.global_position.x - center.x, e.global_position.z - center.z).length()
			if d <= radius:
				e.receive_damage(dmg, self)
				count += 1
	return count


func receive_damage(amount: int, attacker: Node3D) -> void:
	if is_mining:
		_cancel_mining("Mining interrupted by enemy attack!")
	current_hp = maxi(0, current_hp - amount)
	if frame_mounted:
		current_debt += 18
	if selected_enemy == null and attacker is EnemyUnit:
		_set_selected_enemy(attacker as EnemyUnit)
	if current_hp <= 0:
		simulate_death()
	_emit_state()


func _on_enemy_died(enemy: EnemyUnit, _killer: Node3D) -> void:
	if selected_enemy == enemy:
		_set_selected_enemy(null)
		auto_attacking = false
	var f := _faction_dict()
	wallet_credits += enemy.bounty_reward
	xp += 55
	var needed := level * 90
	if xp >= needed and level < 45:
		xp -= needed
		level += 1
		_recalc_vital_stats()
		current_hp = max_hp
		current_fp = max_fp
		current_sp = max_sp
		event_logged.emit("LEVEL UP! Reached Level %d (Cap 45 / Leader 50)." % level)
	else:
		event_logged.emit("Slain %s! +%d %s Bounty & dropped Farr bag." % [enemy.enemy_name, enemy.bounty_reward, f["currency_code"]])

	_roll_rare_equipment_drop(enemy)
	_emit_state()


## Low-probability monster equipment drop placed directly into your Bag!
func _roll_rare_equipment_drop(enemy: EnemyUnit) -> void:
	var drop_chance := 1.0 if enemy.level >= 50 else (0.55 if enemy.level >= 25 else 0.30)
	if randf() > drop_chance:
		return

	var dropped_tier_idx := 4 if enemy.level >= 35 else (3 if enemy.level >= 25 else 1)
	var rolled_group := GameData.EQUIP_CHASSIS_SVEL if randf() < 0.35 else GameData.EQUIP_ORGANIC_VAR
	var random_slot: String = GameData.EQUIP_SLOTS[randi() % GameData.EQUIP_SLOTS.size()]
	var dropped_item := GameData.make_equipment_item(dropped_tier_idx, random_slot, rolled_group)

	if add_item_to_bags(dropped_item):
		event_logged.emit("LOOT DROP -> Bag: %s! Open [I] to equip or sell at HQ NPC." % dropped_item["name"])
	else:
		event_logged.emit("LOOT LOST: %s dropped, but your Bags are full! Press [O] or buy more Bags." % dropped_item["name"])


func _total_gear_bonuses() -> Dictionary:
	var totals := {"atk": 0, "hp": 0, "fp": 0, "sp": 0}
	var slots := _active_equipment_slots()
	for slot_name in GameData.EQUIP_SLOTS:
		var item: Dictionary = slots.get(slot_name, {})
		if not item.is_empty():
			totals["atk"] += int(item.get("bonus_atk", 0))
			totals["hp"] += int(item.get("bonus_hp", 0))
			totals["fp"] += int(item.get("bonus_fp", 0))
			totals["sp"] += int(item.get("bonus_sp", 0))
	return totals


func _effective_attack_damage() -> int:
	var c := _class_dict()
	var g := _total_gear_bonuses()
	var base_atk := (24 + (level - 1) * 5 + int(g["atk"])) * float(c["atk_mult"])
	if level >= 30:
		base_atk *= 1.25
	if is_ascended_leader:
		base_atk *= 1.3
	if frame_mounted:
		base_atk *= 1.9
	if siege_mode:
		base_atk *= 1.65
	return int(round(base_atk))


func _effective_attack_range() -> float:
	if siege_mode:
		return 15.0
	var c := _class_dict()
	var r := float(c["range"])
	if frame_mounted:
		r = maxf(r, 3.6)
	return r


func _recalc_vital_stats() -> void:
	var c := _class_dict()
	var g := _total_gear_bonuses()
	var job_mult := 1.2 if level >= 30 else 1.0
	var archon_mult := 1.35 if is_ascended_leader else 1.0

	var raw_hp := (280 + (level - 1) * 28 + int(g["hp"])) * float(c["hp_mult"]) * job_mult * archon_mult
	var raw_fp := (160 + (level - 1) * 16 + int(g["fp"])) * float(c["fp_mult"]) * job_mult * archon_mult
	var raw_sp := (150 + (level - 1) * 14 + int(g["sp"])) * float(c["sp_mult"]) * job_mult * archon_mult
	if frame_mounted:
		raw_hp += 400
	max_hp = int(round(raw_hp))
	max_fp = int(round(raw_fp))
	max_sp = int(round(raw_sp))
	current_hp = mini(current_hp, max_hp)
	current_fp = mini(current_fp, max_fp)
	current_sp = mini(current_sp, max_sp)


func _check_interact_arrival() -> bool:
	if _interact_target == null or not is_instance_valid(_interact_target):
		_interact_target = null
		return false
	var flat_dist := Vector2(global_position.x - _interact_target.global_position.x, global_position.z - _interact_target.global_position.z).length()
	var reach := 2.4
	if "interact_distance" in _interact_target:
		reach = _interact_target.get("interact_distance")
	if flat_dist <= reach:
		_clear_click_target()
		var dir := _interact_target.global_position - global_position
		sprite.set_facing(dir)
		_trigger_interaction(_interact_target)
		_interact_target = null
		return true
	return false


func _trigger_interaction(target: Node3D) -> void:
	if target is VendorNpc:
		var npc := target as VendorNpc
		if npc.faction_id != str(_faction_dict()["id"]):
			event_logged.emit("%s glares at you: \"I do not trade with outsiders of %s.\"" % [npc.npc_name, _faction_dict()["name"]])
			return
		active_vendor_npc = npc
		event_logged.emit("Speaking with %s <%s>." % [active_vendor_npc.npc_name, active_vendor_npc.npc_title])
		_emit_state()
	elif target is FarrVein:
		var vein := target as FarrVein
		if not vein.can_mine():
			event_logged.emit("%s is depleted. Waiting for regeneration..." % vein.vein_name)
			return
		if current_weight >= max_weight:
			event_logged.emit("Carry weight full (%.0f / %.0f)! Extract at a Refinery first." % [current_weight, max_weight])
			return
		is_mining = true
		_mining_vein = vein
		mining_progress = 0.0
		event_logged.emit("Mining %s... (locked in place)" % vein.vein_name)
	elif target is RefineryStation:
		_refine_and_pay_debt()
	elif target is DroppedOreBag:
		_loot_dropped_bag(target as DroppedOreBag)


func _process_mining(delta: float) -> void:
	if _mining_vein == null or not is_instance_valid(_mining_vein) or not _mining_vein.can_mine():
		_cancel_mining("Vein depleted.")
		return
	if current_weight >= max_weight:
		_cancel_mining("Inventory weight limit reached! Return to a Refinery.")
		return

	var c := _class_dict()
	var mine_mult: float = float(c.get("mine_speed_mult", 1.0))
	mining_progress += (delta * mine_mult) / max(_mining_vein.mine_duration, 0.2)
	if mining_progress >= 1.0:
		mining_progress = 0.0
		var result := _mining_vein.extract_one_cycle()
		var added_units: int = result["units"]
		var added_weight: float = result["weight"]
		var added_val: int = result["value"]
		unrefined_units += added_units
		current_weight = minf(current_weight + added_weight, max_weight)
		unrefined_value += added_val
		var code: String = _faction_dict()["currency_code"]
		event_logged.emit("Extracted +%d Unrefined Farr (+%.0f wt, worth %d %s)." % [added_units, added_weight, added_val, code])
		if not _mining_vein.can_mine():
			_cancel_mining("%s exhausted." % _mining_vein.vein_name)
			return
		if current_weight >= max_weight:
			_cancel_mining("Bag hits 100%% weight capacity! Head to a Refinery.")
			return


func _cancel_mining(reason: String) -> void:
	is_mining = false
	_mining_vein = null
	mining_progress = 0.0
	if reason != "":
		event_logged.emit(reason)


func _refine_and_pay_debt() -> void:
	if unrefined_units <= 0:
		event_logged.emit("No Unrefined Farr in your bag to refine.")
		return
	var total_fc := unrefined_value
	var units_refined := unrefined_units
	unrefined_units = 0
	current_weight = 0.0
	unrefined_value = 0

	var debt_paid := 0
	if current_debt > 0:
		debt_paid = mini(current_debt, int(ceil(total_fc * 0.7)))
		current_debt -= debt_paid
	var wallet_gain := total_fc - debt_paid
	wallet_credits += wallet_gain

	var f := _faction_dict()
	var code: String = f["currency_code"]
	event_logged.emit("Refined %d Farr -> %d %s! Paid %d toward %s, +%d %s to Wallet." % [
		units_refined, total_fc, code, debt_paid, f["debt_name"], wallet_gain, code
	])


func _loot_dropped_bag(bag: DroppedOreBag) -> void:
	if current_weight >= max_weight:
		event_logged.emit("Too heavy to loot dropped Farr bag! Refine current ore first.")
		return
	unrefined_units += bag.units
	current_weight = minf(current_weight + bag.weight, max_weight)
	unrefined_value += bag.value
	event_logged.emit("Recovered %d Unrefined Farr from dropped bag!" % bag.units)
	bag.queue_free()


func cycle_faction() -> void:
	siege_mode = false
	frame_mounted = false
	active_vendor_npc = null
	sprite.scale = Vector3.ONE
	sprite.position.y = 0.8
	if fravashi_instance and is_instance_valid(fravashi_instance):
		fravashi_instance.visible = false

	faction_index = (faction_index + 1) % GameData.FACTIONS.size()
	_recalc_vital_stats()
	_apply_faction_tint()
	var f := _faction_dict()
	var shared_note := "Chassis-Only Gear" if f["equip_group"] == GameData.EQUIP_CHASSIS_SVEL else "Shares Organic/Relic Gear between Order & Druj"
	event_logged.emit("Switched Race -> %s | Currency: %s (%s) | %s" % [f["name"], f["currency_name"], f["currency_code"], shared_note])


func _respawn_position() -> Vector3:
	var f := _faction_dict()
	var fid: String = str(f["id"])
	if bind_points.has(fid):
		var bp: Dictionary = bind_points[fid]
		return bp.get("pos", f["hq_spawn"])
	return f["hq_spawn"]


func _respawn_name() -> String:
	var f := _faction_dict()
	var fid: String = str(f["id"])
	if bind_points.has(fid):
		var bp: Dictionary = bind_points[fid]
		return "%s (Bound Rebirth NPC)" % str(bp.get("name", f["hq_name"]))
	return "%s (HQ Default)" % str(f["hq_name"])


func simulate_death() -> void:
	if is_mining:
		_cancel_mining("")
	auto_attacking = false
	siege_mode = false
	active_vendor_npc = null
	_clear_click_target()
	_interact_target = null
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp

	var spawn_dest := _respawn_position()
	var spawn_label := _respawn_name()

	# RF / FARR Rule: All Bag items (Potions, Scrolls, Ammo, Gear) stay 100% in your Bags!
	# Only Unrefined Farr Ore drops at your death coordinate so anyone can loot it.
	var drop_units := int(ceil(unrefined_units * 0.5))
	if drop_units > 0:
		var ratio := float(drop_units) / float(unrefined_units)
		var drop_weight := current_weight * ratio
		var drop_val := int(round(unrefined_value * ratio))
		unrefined_units -= drop_units
		current_weight = maxf(0.0, current_weight - drop_weight)
		unrefined_value = maxi(0, unrefined_value - drop_val)

		var bag := DROPPED_BAG_SCENE.instantiate() as DroppedOreBag
		get_parent().add_child(bag)
		bag.global_position = Vector3(global_position.x, 0.0, global_position.z)
		bag.setup(drop_units, drop_weight, drop_val)
		event_logged.emit("CHINVAT REBIRTH: Slain! Dropped %d Unrefined Farr (All Bag items kept!) -> Respawned at %s." % [
			drop_units, spawn_label
		])
	else:
		event_logged.emit("CHINVAT REBIRTH: Respawned at %s (All Bag items & Equipment kept!)." % spawn_label)

	global_position = spawn_dest
	velocity = Vector3.ZERO
	save_game()


func _exit_tree() -> void:
	save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func save_game() -> void:
	if _save_disabled:
		return
	var t := Time.get_time_dict_from_system()
	last_saved_text = "%02d:%02d:%02d" % [t.get("hour", 0), t.get("minute", 0), t.get("second", 0)]
	var saved_pos := global_position if is_inside_tree() else position
	var data := {
		"version": SAVE_VERSION,
		"pos": saved_pos,
		"faction_index": faction_index,
		"class_index": class_index,
		"job_branch": job_branch,
		"is_ascended_leader": is_ascended_leader,
		"level": level,
		"xp": xp,
		"current_hp": current_hp,
		"current_fp": current_fp,
		"current_sp": current_sp,
		"wallet_credits": wallet_credits,
		"current_debt": current_debt,
		"unrefined_units": unrefined_units,
		"current_weight": current_weight,
		"unrefined_value": unrefined_value,
		"unlocked_bags": unlocked_bags,
		"active_bag_tab": active_bag_tab,
		"bag_slots": bag_slots,
		"equipped_organic_slots": equipped_organic_slots,
		"equipped_chassis_slots": equipped_chassis_slots,
		"auto_hp_pct": auto_hp_pct,
		"auto_fp_pct": auto_fp_pct,
		"auto_sp_pct": auto_sp_pct,
		"bind_points": bind_points,
		"last_saved_text": last_saved_text,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(var_to_str(data))
		f.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed: Variant = str_to_var(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	if int(d.get("version", 0)) != SAVE_VERSION:
		return false

	faction_index = clampi(int(d.get("faction_index", 0)), 0, GameData.FACTIONS.size() - 1)
	class_index = clampi(int(d.get("class_index", 0)), 0, 3)
	job_branch = clampi(int(d.get("job_branch", 0)), 0, 1)
	is_ascended_leader = bool(d.get("is_ascended_leader", false))
	level = maxi(1, int(d.get("level", 1)))
	xp = maxi(0, int(d.get("xp", 0)))
	wallet_credits = maxi(0, int(d.get("wallet_credits", 900)))
	current_debt = maxi(0, int(d.get("current_debt", starting_debt)))
	unrefined_units = maxi(0, int(d.get("unrefined_units", 0)))
	current_weight = maxf(0.0, float(d.get("current_weight", 0.0)))
	unrefined_value = maxi(0, int(d.get("unrefined_value", 0)))
	unlocked_bags = clampi(int(d.get("unlocked_bags", 2)), 1, GameData.MAX_BAGS)
	active_bag_tab = clampi(int(d.get("active_bag_tab", 0)), 0, unlocked_bags - 1)

	if d.has("bag_slots") and typeof(d["bag_slots"]) == TYPE_ARRAY:
		bag_slots = d["bag_slots"]
	while bag_slots.size() < unlocked_bags * GameData.BAG_SLOTS_PER_BAG:
		bag_slots.append({})

	if d.has("equipped_organic_slots") and typeof(d["equipped_organic_slots"]) == TYPE_DICTIONARY:
		equipped_organic_slots = d["equipped_organic_slots"]
	if d.has("equipped_chassis_slots") and typeof(d["equipped_chassis_slots"]) == TYPE_DICTIONARY:
		equipped_chassis_slots = d["equipped_chassis_slots"]

	auto_hp_pct = int(d.get("auto_hp_pct", 55))
	auto_fp_pct = int(d.get("auto_fp_pct", 45))
	auto_sp_pct = int(d.get("auto_sp_pct", 45))
	if d.has("bind_points") and typeof(d["bind_points"]) == TYPE_DICTIONARY:
		bind_points = d["bind_points"]
	last_saved_text = str(d.get("last_saved_text", "Restored"))

	_recalc_vital_stats()
	current_hp = clampi(int(d.get("current_hp", max_hp)), 1, max_hp)
	current_fp = clampi(int(d.get("current_fp", max_fp)), 0, max_fp)
	current_sp = clampi(int(d.get("current_sp", max_sp)), 0, max_sp)

	if d.has("pos") and typeof(d["pos"]) == TYPE_VECTOR3:
		global_position = d["pos"]
	return true


func _apply_faction_tint() -> void:
	if sprite:
		var f := _faction_dict()
		sprite.accent_color = f["color"]
		sprite.texture = sprite._make_placeholder_sheet(64)


func _set_click_target(pos: Vector3) -> void:
	agent.target_position = pos
	_has_click_target = true
	marker.global_position = pos + Vector3(0.0, 0.05, 0.0)
	marker.visible = true


func _clear_click_target() -> void:
	_has_click_target = false
	marker.visible = false


func _mouse_raycast(screen_pos: Vector2) -> Dictionary:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return {}
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)


func _camera_relative(input: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	var cam_basis := cam.global_transform.basis
	var fwd := -cam_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * input.x - fwd * input.y).normalized()


func _emit_state() -> void:
	var f := _faction_dict()
	var c := _class_dict()
	var s2: Dictionary = c["skill2"]
	var s3: Dictionary = c["skill3"]

	var target_name := ""
	var target_hp := 0
	var target_max_hp := 1
	if selected_enemy and is_instance_valid(selected_enemy) and not selected_enemy.is_dead:
		target_name = "Lv.%d %s" % [selected_enemy.level, selected_enemy.enemy_name]
		target_hp = selected_enemy.current_hp
		target_max_hp = selected_enemy.max_hp

	var sig_active := siege_mode or frame_mounted or (fravashi_instance != null and is_instance_valid(fravashi_instance) and fravashi_instance.visible)

	var vendor_info := {}
	if active_vendor_npc and is_instance_valid(active_vendor_npc):
		var sel_slot: String = GameData.EQUIP_SLOTS[_armor_vendor_slot_cursor]
		vendor_info = {
			"name": active_vendor_npc.npc_name,
			"title": active_vendor_npc.npc_title,
			"type": active_vendor_npc.vendor_type,
			"armor_slot_label": GameData.EQUIP_SLOT_LABELS.get(sel_slot, sel_slot),
			"next_bag_num": unlocked_bags + 1,
			"next_bag_cost": 350 * unlocked_bags,
		}

	state_updated.emit({
		"faction": f["name"],
		"equip_group": f["equip_group"],
		"currency_name": f["currency_name"],
		"currency_code": f["currency_code"],
		"debt_name": f["debt_name"],
		"job_title": _active_job_title(),
		"gear_name": _active_gear_summary(),
		"respawn_name": _respawn_name(),
		"last_saved": last_saved_text,
		"equipped_slots": _active_equipment_slots(),
		"unlocked_bags": unlocked_bags,
		"active_bag_tab": active_bag_tab,
		"bag_slots": bag_slots,
		"auto_hp_pct": auto_hp_pct,
		"auto_fp_pct": auto_fp_pct,
		"auto_sp_pct": auto_sp_pct,
		"vendor_info": vendor_info,
		"level": level,
		"is_leader": is_ascended_leader,
		"hp": current_hp,
		"max_hp": max_hp,
		"fp": current_fp,
		"max_fp": max_fp,
		"sp": current_sp,
		"max_sp": max_sp,
		"atk": _effective_attack_damage(),
		"debt": current_debt,
		"wallet": wallet_credits,
		"hp_potions": get_item_count("POT_HP"),
		"fp_potions": get_item_count("POT_FP"),
		"sp_potions": get_item_count("POT_SP"),
		"ammo": get_item_count("AMMO_PACK"),
		"scrolls": get_item_count("SCROLL_HQ"),
		"unrefined_units": unrefined_units,
		"unrefined_value": unrefined_value,
		"weight": current_weight,
		"max_weight": max_weight,
		"is_mining": is_mining,
		"mining_progress": mining_progress,
		"mining_vein_name": _mining_vein.vein_name if (_mining_vein and is_instance_valid(_mining_vein)) else "",
		"target_name": target_name,
		"target_hp": target_hp,
		"target_max_hp": target_max_hp,
		"auto_attacking": auto_attacking,
		"sig_active": sig_active,
		"skill2_label": s2["name"],
		"skill3_label": s3["name"],
		"skill4_label": f["signature_name"],
		"skill2_cd": _skill2_cd,
		"skill3_cd": _skill3_cd,
	})
