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
const FLOATING_TEXT := preload("res://scripts/floating_combat_text.gd")
const SFX_MANAGER_SCRIPT := preload("res://scripts/sfx_manager.gd")
const BGM_MANAGER_SCRIPT := preload("res://scripts/bgm_manager.gd")
const COMBAT_VFX := preload("res://scripts/combat_vfx.gd")

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
var active_summon_beacon: Node3D = null
var _armor_vendor_slot_cursor := 1 # Cycles HELMET..SHOES when buying individual armor pieces
var _upgrade_slot_cursor := 0      # Cycles WEAPON..SHOES for +1..+7 Farr Talic upgrading
var _shield_buff_timer := 0.0      # Tank Job Fortify Buff (40% damage reduction)
var weapon_stance_index := 0       # 0 = Class Native, 1 = Melee (2.8m), 2 = Ranged (Bow/Rifle), 3 = Force Staff
var _rf_buff_timer := 0.0          # RF-Style 120s Faction Combat & Force Buff Suite
var _buff_regen_accum := 0.0       # Periodic HP/FP regeneration tick while RF Buffs active
var _attack_lunge_timer := 0.0     # Brief visual sprite lunge/recoil during Melee/Ranged attacks
var _attack_lunge_dir := Vector3.ZERO
var quest_kills := 0               # Repeatable Faction Bounty Quest kill counter (3 Kills + 10 Farr -> 1 Talic)

## Main Story Campaign Progress (Chapters I-V per Faction) & Lore Codex Cursor
var story_chapter_by_faction: Dictionary = {
	"sveleitre": 0,
	"order": 0,
	"legion": 0,
}
var story_kills := 0
var story_farr_mined := 0
var story_boss_kills := 0
var codex_cursor := 0
var request_open_story_window := false

## Live Combat Damage & Heal Telemetry Meter
var combat_dmg_dealt_total := 0
var combat_dmg_dealt_last := 0
var combat_dmg_dealt_max := 0
var combat_dmg_taken_total := 0
var combat_dmg_taken_last := 0
var combat_hp_healed_total := 0
var combat_hp_healed_last := 0

## In-Game Options & Settings (Saved persistently)
## tab_target_mode:
##   0 = Closest to Mouse Cursor (2D screen projection)
##   1 = Lowest HP First
##   2 = Closest to Character (3D world distance)
const TAB_MODE_LABELS := [
	"Closest to Mouse Cursor",
	"Lowest HP First",
	"Closest to Character",
]
var tab_target_mode := 0
var auto_target_on_kill := true
var show_floating_dmg := true
var sfx_volume_pct := 80
var music_volume_pct := 70
var cam_sensitivity_mult := 1.0
var _sfx: Node = null
var _bgm: Node = null

## Persistent Character Save (RF-style: log back in exactly where you left off)
## - Bags, equipment, wallet, debt, level, position & carried Farr ore all persist.
## - On death only unrefined Farr ore drops; you respawn at your bound Rebirth NPC (or HQ default).
const SAVE_PATH := "user://farr_character_save.txt"
const SAVE_VERSION := 2
@export var autosave_interval := 5.0
var current_map_id := "svel_hq"
var bind_points: Dictionary = {} # faction_id -> {"map_id": String, "pos": Vector3, "name": String}
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
	_sfx = SFX_MANAGER_SCRIPT.new()
	add_child(_sfx)
	_bgm = BGM_MANAGER_SCRIPT.new()
	add_child(_bgm)
	current_debt = starting_debt
	_upkeep_timer = upkeep_interval
	_init_equipment_and_bags()
	var loaded := load_game()
	_apply_user_settings()
	_recalc_vital_stats()
	if not loaded:
		current_map_id = str(_faction_dict()["hq_map_id"])
		global_position = _faction_dict()["hq_spawn"]
		current_hp = max_hp
		current_fp = max_fp
		current_sp = max_sp
	_sync_world_to_current_map()
	_apply_faction_tint()
	_connect_world_enemies()
	_emit_state()
	var cur_map_name: String = GameData.MAPS.get(current_map_id, {}).get("name", current_map_id)
	if loaded:
		event_logged.emit("Welcome back! Lv.%d %s restored in [%s] (saved: %s). Rebirth: %s." % [
			level, _faction_dict()["name"], cur_map_name, last_saved_text, _respawn_name()
		])
	else:
		event_logged.emit("Entered [%s]! Press [M] for 9-Map World Warp, click 3D Portals or HQ Side NPCs!" % cur_map_name)
		save_game()


func _sync_world_to_current_map() -> void:
	var world_mgr := get_tree().get_first_node_in_group("world_zone_manager")
	if world_mgr and world_mgr.has_method("load_map"):
		world_mgr.call("load_map", current_map_id)
		if world_mgr.has_method("ground_height_at"):
			global_position.y = float(world_mgr.call("ground_height_at", global_position.x, global_position.z)) + 0.1
	if _bgm and _bgm.has_method("play_for_map"):
		_bgm.call("play_for_map", current_map_id)


func travel_to_map(target_map_id: String, custom_pos: Variant = null, silent: bool = false) -> bool:
	if not GameData.MAPS.has(target_map_id):
		return false
	var mdata: Dictionary = GameData.MAPS[target_map_id]
	var f := _faction_dict()
	var my_fid: String = str(f["id"])
	var owner_fid: String = str(mdata.get("owner_faction", "all"))
	if owner_fid != "all" and owner_fid != my_fid:
		event_logged.emit("ACCESS DENIED: [%s] is restricted territory! %s cannot enter another faction's HQ or Basic Ground." % [
			mdata["name"], f["name"]
		])
		return false

	if is_mining:
		_cancel_mining("")
	siege_mode = false
	auto_attacking = false
	active_vendor_npc = null
	active_summon_beacon = null
	_set_selected_enemy(null)
	_clear_click_target()
	_interact_target = null

	current_map_id = target_map_id
	_sync_world_to_current_map()

	var dest_pos: Vector3 = f["hq_spawn"]
	if typeof(custom_pos) == TYPE_VECTOR3:
		dest_pos = custom_pos
	else:
		var spawns: Dictionary = mdata.get("spawns", {})
		dest_pos = spawns.get(my_fid, Vector3(0.0, 0.1, 14.0))

	var world_mgr := get_tree().get_first_node_in_group("world_zone_manager")
	if world_mgr and world_mgr.has_method("ground_height_at"):
		dest_pos.y = float(world_mgr.call("ground_height_at", dest_pos.x, dest_pos.z)) + 0.1
	global_position = dest_pos
	velocity = Vector3.ZERO
	if fravashi_instance and is_instance_valid(fravashi_instance) and fravashi_instance.visible:
		fravashi_instance.global_position = global_position + Vector3(1.5, 0.0, 1.0)
		fravashi_instance.assigned_target = null

	_connect_world_enemies()
	_play_sfx("warp_portal")
	save_game()
	_emit_state()
	if not silent:
		event_logged.emit("Warped to [%s] (%s)!" % [mdata["name"], mdata.get("level_band", "")])
	return true


func _play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	if _sfx and _sfx.has_method("play"):
		_sfx.call("play", sfx_name, pitch)


func _apply_user_settings() -> void:
	if _sfx:
		_sfx.set("volume_pct", sfx_volume_pct)
	if _bgm:
		_bgm.set("volume_pct", music_volume_pct)
	if show_floating_dmg:
		if is_in_group("disable_floating_combat_text"):
			remove_from_group("disable_floating_combat_text")
	else:
		if not is_in_group("disable_floating_combat_text"):
			add_to_group("disable_floating_combat_text")
	var rig := get_tree().get_first_node_in_group("camera_rig")
	if rig:
		rig.set("sensitivity_mult", cam_sensitivity_mult)


func cycle_tab_target_mode() -> void:
	tab_target_mode = (tab_target_mode + 1) % TAB_MODE_LABELS.size()
	save_game()
	_play_sfx("target_lock")
	event_logged.emit("Setting: [Tab] Target Priority -> %s." % TAB_MODE_LABELS[tab_target_mode])
	_emit_state()


func toggle_auto_target_on_kill() -> void:
	auto_target_on_kill = not auto_target_on_kill
	save_game()
	_play_sfx("target_lock")
	event_logged.emit("Setting: Auto-Target Next Enemy on Kill -> %s." % ("ON" if auto_target_on_kill else "OFF"))
	_emit_state()


func toggle_floating_dmg_setting() -> void:
	show_floating_dmg = not show_floating_dmg
	_apply_user_settings()
	save_game()
	_play_sfx("target_lock")
	event_logged.emit("Setting: 3D Floating Combat & Heal Numbers -> %s." % ("ON" if show_floating_dmg else "OFF"))
	_emit_state()


func cycle_sfx_volume() -> void:
	match sfx_volume_pct:
		80:
			sfx_volume_pct = 100
		100:
			sfx_volume_pct = 0
		0:
			sfx_volume_pct = 25
		25:
			sfx_volume_pct = 50
		_:
			sfx_volume_pct = 80
	_apply_user_settings()
	save_game()
	_play_sfx("heal")
	event_logged.emit("Setting: SFX Volume -> %s." % ("MUTED (0%)" if sfx_volume_pct == 0 else "%d%%" % sfx_volume_pct))
	_emit_state()


func test_sfx_sound() -> void:
	_play_sfx("skill_cast")
	event_logged.emit("Played synthesized Skill SFX preview (drop custom .wav files into res://assets/sfx/ to override!).")


func cycle_music_volume() -> void:
	match music_volume_pct:
		70:
			music_volume_pct = 100
		100:
			music_volume_pct = 0
		0:
			music_volume_pct = 25
		25:
			music_volume_pct = 50
		_:
			music_volume_pct = 70
	_apply_user_settings()
	save_game()
	_play_sfx("heal")
	event_logged.emit("Setting: Background Music (BGM) Volume -> %s." % ("MUTED (0%)" if music_volume_pct == 0 else "%d%%" % music_volume_pct))
	_emit_state()


func test_music_sound() -> void:
	if _bgm and _bgm.has_method("test_preview"):
		_bgm.call("test_preview")
	event_logged.emit("Previewed Zone BGM soundtrack (drop custom .ogg/.wav files into res://assets/music/ to override!).")


func cycle_cam_sensitivity() -> void:
	if is_equal_approx(cam_sensitivity_mult, 1.0):
		cam_sensitivity_mult = 1.5
	elif cam_sensitivity_mult > 1.2:
		cam_sensitivity_mult = 0.6
	else:
		cam_sensitivity_mult = 1.0
	_apply_user_settings()
	save_game()
	_play_sfx("target_lock")
	event_logged.emit("Setting: Camera Orbit Sensitivity -> %.1fx." % cam_sensitivity_mult)
	_emit_state()


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
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z:
			cycle_weapon_stance()
		elif event.keycode == KEY_B or event.keycode == KEY_9:
			cast_rf_buff_suite()


func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("move_click"):
		_holding_world_click = false

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_skill2_cd = maxf(0.0, _skill2_cd - delta)
	_skill3_cd = maxf(0.0, _skill3_cd - delta)
	_potion_cd = maxf(0.0, _potion_cd - delta)
	_shield_buff_timer = maxf(0.0, _shield_buff_timer - delta)
	_wipe_confirm_timer = maxf(0.0, _wipe_confirm_timer - delta)
	if _rf_buff_timer > 0.0:
		_rf_buff_timer = maxf(0.0, _rf_buff_timer - delta)
		_buff_regen_accum += delta
		if _buff_regen_accum >= 2.0:
			_buff_regen_accum = 0.0
			current_hp = mini(max_hp, current_hp + 10)
			current_fp = mini(max_fp, current_fp + 8)
		if _rf_buff_timer <= 0.0:
			_recalc_vital_stats()
			event_logged.emit("RF Combat & Force Buff Suite expired! Press [B] or [9] to recast.")

	if _attack_lunge_timer > 0.0:
		_attack_lunge_timer = maxf(0.0, _attack_lunge_timer - delta)
		var l_t := _attack_lunge_timer / 0.18
		if sprite:
			sprite.position.x = _attack_lunge_dir.x * 0.36 * sin(l_t * PI)
			sprite.position.z = _attack_lunge_dir.z * 0.36 * sin(l_t * PI)
	elif sprite and (absf(sprite.position.x) > 0.001 or absf(sprite.position.z) > 0.001):
		sprite.position.x = 0.0
		sprite.position.z = 0.0

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

	# Close summon beacon terminal if player walks away from the monument
	if active_summon_beacon != null:
		if not is_instance_valid(active_summon_beacon):
			active_summon_beacon = null
		else:
			var beacon_dist := Vector2(
				global_position.x - active_summon_beacon.global_position.x,
				global_position.z - active_summon_beacon.global_position.z
			).length()
			var max_bdist: float = float(active_summon_beacon.get("interact_distance")) if active_summon_beacon.get("interact_distance") != null else 3.6
			if beacon_dist > max_bdist + 2.0:
				active_summon_beacon = null
				_emit_state()

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
	if _rf_buff_timer > 0.0:
		speed *= 1.15
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


func _active_skill_2() -> Dictionary:
	var c := _class_dict()
	if level >= 30 and c.has("job_skills"):
		var j_skills: Array = c["job_skills"]
		return j_skills[job_branch]["skill2"]
	return c["skill2"]


func _active_skill_3() -> Dictionary:
	var c := _class_dict()
	if level >= 30 and c.has("job_skills"):
		var j_skills: Array = c["job_skills"]
		return j_skills[job_branch]["skill3"]
	return c["skill3"]


func cycle_upgrade_target_slot() -> void:
	_upgrade_slot_cursor = (_upgrade_slot_cursor + 1) % GameData.EQUIP_SLOTS.size()
	var slot_name: String = GameData.EQUIP_SLOTS[_upgrade_slot_cursor]
	event_logged.emit("Selected [%s] slot for Farr Talic Upgrading (+1 to +7)." % GameData.EQUIP_SLOT_LABELS.get(slot_name, slot_name))
	_emit_state()


func upgrade_selected_slot_with_talic() -> void:
	var slot_name: String = GameData.EQUIP_SLOTS[_upgrade_slot_cursor]
	var slot_lbl: String = GameData.EQUIP_SLOT_LABELS.get(slot_name, slot_name)
	var active_slots := _active_equipment_slots()
	var cur_item: Dictionary = active_slots.get(slot_name, {})
	if cur_item.is_empty():
		event_logged.emit("No item equipped in [%s] slot to upgrade!" % slot_lbl)
		return

	var cur_plus: int = int(cur_item.get("upgrade_plus", 0))
	if cur_plus >= GameData.MAX_UPGRADE_PLUS:
		event_logged.emit("%s is already at Maximum +7 Sovereign Masterwork!" % cur_item["name"])
		return

	if not consume_item_from_bags("TALIC_FARR", 1):
		event_logged.emit("Need 1x Farr Talic Crystal! Talics ONLY drop from Mini-Bosses, Bosses, World Bosses, or Faction Quests.")
		return

	var target_plus := cur_plus + 1
	var chance: float = float(GameData.UPGRADE_SUCCESS_RATES.get(target_plus, 0.03))
	var tier_idx: int = int(cur_item.get("tier_idx", 0))
	var eq_group: String = str(cur_item.get("equip_group", _faction_dict()["equip_group"]))

	if randf() <= chance:
		var upgraded := GameData.make_equipment_item(tier_idx, slot_name, eq_group, target_plus)
		active_slots[slot_name] = upgraded
		_recalc_vital_stats()
		_apply_faction_tint()
		_play_sfx("upgrade_success")
		var aura_note := " [GLOWING MASTERWORK AURA!]" if target_plus >= 6 else ""
		event_logged.emit("TALIC UPGRADE SUCCESS (%.0f%%)! %s -> +%d%s (%d Talics left)." % [
			chance * 100.0, upgraded["name"], target_plus, aura_note, get_item_count("TALIC_FARR")
		])
	else:
		# Hardcore RF-style failure penalty:
		# Attempting +1 or +2 -> stays at current +level
		# Attempting +3 -> drops to +1
		# Attempting +4, +5, +6, +7 -> Talic overload resets upgrade back to +0!
		var fallback_plus := 0
		if target_plus <= 2:
			fallback_plus = cur_plus
		elif target_plus == 3:
			fallback_plus = 1
		else:
			fallback_plus = 0
		var after_fail := GameData.make_equipment_item(tier_idx, slot_name, eq_group, fallback_plus)
		active_slots[slot_name] = after_fail
		_recalc_vital_stats()
		_apply_faction_tint()
		_play_sfx("upgrade_fail")
		if fallback_plus < cur_plus:
			event_logged.emit("TALIC OVERLOAD FAILURE (%.0f%%)! Upgrade shattered back to +%d (%s)." % [
				chance * 100.0, fallback_plus, after_fail["name"]
			])
		else:
			event_logged.emit("TALIC UPGRADE FAILED (%.0f%%)! Talic consumed, %s stayed at +%d." % [
				chance * 100.0, after_fail["name"], cur_plus
			])
	save_game()
	_emit_state()


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
		elif id == "TALIC_FARR":
			upgrade_selected_slot_with_talic()
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
	var float_tag := "[Auto]" if is_auto else ""
	if kind == "HP":
		if not consume_item_from_bags("POT_HP", 1):
			if not is_auto:
				event_logged.emit("Out of HP Potions in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var heal := int(round(max_hp * 0.55))
		current_hp = mini(max_hp, current_hp + heal)
		_potion_cd = 1.2
		record_heal_or_restore(heal, 0, 0, float_tag)
		event_logged.emit("%sUsed HP Potion (+%d HP, %d left in Bags)." % [tag, heal, get_item_count("POT_HP")])
	elif kind == "FP":
		if not consume_item_from_bags("POT_FP", 1):
			if not is_auto:
				event_logged.emit("Out of FP Chargers in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var gain := int(round(max_fp * 0.6))
		current_fp = mini(max_fp, current_fp + gain)
		_potion_cd = 1.2
		record_heal_or_restore(0, gain, 0, float_tag)
		event_logged.emit("%sUsed FP Charger (+%d FP, %d left in Bags)." % [tag, gain, get_item_count("POT_FP")])
	elif kind == "SP":
		if not consume_item_from_bags("POT_SP", 1):
			if not is_auto:
				event_logged.emit("Out of SP Stims in Bags! Walk to the HQ Potion NPC to buy more.")
			return
		var gain := int(round(max_sp * 0.6))
		current_sp = mini(max_sp, current_sp + gain)
		_potion_cd = 1.2
		record_heal_or_restore(0, 0, gain, float_tag)
		event_logged.emit("%sUsed SP Stim (+%d SP, %d left in Bags)." % [tag, gain, get_item_count("POT_SP")])
	_emit_state()


func use_teleport_scroll() -> void:
	if not consume_item_from_bags("SCROLL_HQ", 1):
		event_logged.emit("Out of Teleport Scrolls in Bags! Walk to the HQ Utility NPC to buy more.")
		return
	var f := _faction_dict()
	var hq_map: String = str(f["hq_map_id"])
	var left := get_item_count("SCROLL_HQ")
	if current_map_id != hq_map:
		travel_to_map(hq_map, f["hq_spawn"], true)
		event_logged.emit("Used Return Scroll -> Warped to [%s] (%d Scrolls left in Bags)." % [f["hq_name"], left])
	else:
		travel_to_map("farr_mining_ground", null, true)
		event_logged.emit("Used Crack Portal Scroll -> Warped to [The Crack — Central Farr Mining Ground] (%d Scrolls left)." % left)
	_emit_state()


# --- Physical 3D HQ Vendor NPC Transactions (Requires standing at the NPC!) ---

func close_vendor_shop() -> void:
	active_vendor_npc = null
	active_summon_beacon = null
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
				_complete_faction_talic_quest()
	elif vtype == "REBIRTH":
		var fid: String = str(f["id"])
		match action_index:
			0:
				var bind_pos := active_vendor_npc.global_position + Vector3(0.0, 0.1, 2.2)
				var map_title: String = GameData.MAPS.get(current_map_id, {}).get("name", current_map_id)
				bind_points[fid] = {
					"map_id": current_map_id,
					"pos": bind_pos,
					"name": "%s [%s]" % [active_vendor_npc.npc_name, map_title],
				}
				save_game()
				event_logged.emit("%s: Bound your Rebirth Spawn Point here in [%s]!" % [
					active_vendor_npc.npc_name, map_title
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
				var hp_restored := maxi(1, max_hp - current_hp)
				current_hp = max_hp
				current_fp = max_fp
				current_sp = max_sp
				record_heal_or_restore(hp_restored, 0, 0, "[Rebirth Shrine]")
				save_game()
				event_logged.emit("%s: Restored 100%% HP / FP / SP (-%d %s) & saved progress!" % [active_vendor_npc.npc_name, heal_cost, code])
			3:
				save_game()
				event_logged.emit("%s: Character state, Bags, Equipment & Position saved (%s)!" % [active_vendor_npc.npc_name, last_saved_text])
	elif vtype == "LEADER":
		match action_index:
			0:
				complete_current_story_chapter()
			1:
				request_open_story_window = true
				event_logged.emit("%s: Opening Illustrated Story Campaign & Lore Codex [N]..." % active_vendor_npc.npc_name)
			2:
				warp_to_story_chapter_zone()
			3:
				var hp_rest := maxi(1, max_hp - current_hp)
				current_hp = max_hp
				current_fp = max_fp
				current_sp = max_sp
				record_heal_or_restore(hp_rest, 0, 0, "[Sovereign Blessing]")
				save_game()
				event_logged.emit("%s bestowed Sovereign Blessing: 100%% HP / FP / SP restored!" % active_vendor_npc.npc_name)
	save_game()
	_emit_state()


func _active_story_chapter_dict() -> Dictionary:
	var fid: String = str(_faction_dict()["id"])
	var camp: Dictionary = GameData.STORY_CAMPAIGNS.get(fid, {})
	var chapters: Array = camp.get("chapters", [])
	var idx: int = int(story_chapter_by_faction.get(fid, 0))
	if idx < 0 or idx >= chapters.size():
		return {}
	return chapters[idx]


func complete_current_story_chapter() -> void:
	var f := _faction_dict()
	var fid: String = str(f["id"])
	var code: String = str(f["currency_code"])
	var camp: Dictionary = GameData.STORY_CAMPAIGNS.get(fid, {})
	var leader_name: String = str(camp.get("leader_name", f["leader"]))
	var ch := _active_story_chapter_dict()
	if ch.is_empty():
		event_logged.emit("%s: You have already completed all 5 Chapters of the %s Campaign!" % [leader_name, f["name"]])
		return

	var req_lv: int = int(ch.get("req_level", 1))
	var req_k: int = int(ch.get("req_kills", 0))
	var req_f: int = int(ch.get("req_farr", 0))
	var req_b: int = int(ch.get("req_boss", 0))

	if level < req_lv or story_kills < req_k or story_farr_mined < req_f or story_boss_kills < req_b:
		var boss_str := (" | Boss Kills: %d/%d" % [story_boss_kills, req_b]) if req_b > 0 else ""
		event_logged.emit("%s [%s]: Requirements not yet met! (Lv:%d/%d | Kills:%d/%d | Mined Farr:%d/%d%s)" % [
			leader_name, ch["title"], level, req_lv, story_kills, req_k, story_farr_mined, req_f, boss_str
		])
		return

	var rew_cur: int = int(ch.get("reward_currency", 500))
	var rew_debt: int = int(ch.get("reward_debt_relief", 500))
	var rew_talics: int = int(ch.get("reward_talics", 1))
	var rew_min_lv: int = int(ch.get("reward_min_level", level))
	var ch_num: int = int(ch.get("chapter", 1))

	wallet_credits += rew_cur
	current_debt = maxi(0, current_debt - rew_debt)
	if rew_talics > 0:
		add_item_to_bags(GameData.make_consumable_item("TALIC_FARR", rew_talics))
	if level < rew_min_lv:
		level = rew_min_lv

	var bonus_gear_note := ""
	if ch_num >= 5:
		var rare_wpn := GameData.make_equipment_item(4, "WEAPON", str(f["equip_group"]), 3)
		add_item_to_bags(rare_wpn)
		bonus_gear_note = " + %s!" % rare_wpn["name"]

	story_kills = 0
	story_farr_mined = 0
	story_boss_kills = 0
	story_chapter_by_faction[fid] = int(story_chapter_by_faction.get(fid, 0)) + 1

	_recalc_vital_stats()
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp
	_play_sfx("level_up")
	save_game()
	event_logged.emit("STORY CHAPTER COMPLETE! %s -> +%d %s, -%d Debt, +%dx Talic, Lv.%d%s" % [
		ch["title"], rew_cur, code, rew_debt, rew_talics, level, bonus_gear_note
	])
	_emit_state()


func warp_to_story_chapter_zone() -> void:
	var ch := _active_story_chapter_dict()
	if ch.is_empty():
		travel_to_map("contested_cauldron")
		return
	var target_map: String = str(ch.get("target_map", _faction_dict()["hq_map_id"]))
	travel_to_map(target_map)


func cycle_codex_entry(dir: int = 1) -> void:
	var total := GameData.LORE_CODEX_ENTRIES.size()
	if total <= 0:
		return
	codex_cursor = posmod(codex_cursor + dir, total)
	_play_sfx("target_lock")
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


func _complete_faction_talic_quest() -> void:
	var code: String = _faction_dict()["currency_code"]
	var req_kills := 3
	var req_farr := 10
	if quest_kills < req_kills or unrefined_units < req_farr:
		event_logged.emit("%s [Faction Quest]: Need %d/3 Mob Kills & %d/10 Unrefined Farr Ore to earn 1x Farr Talic Crystal!" % [
			active_vendor_npc.npc_name, quest_kills, unrefined_units
		])
		return
	var talic_item := GameData.make_consumable_item("TALIC_FARR", 1)
	if not add_item_to_bags(talic_item):
		event_logged.emit("%s: Your Bags are full! Make space before turning in the Faction Quest." % active_vendor_npc.npc_name)
		return
	quest_kills -= req_kills
	var ratio := float(req_farr) / float(maxi(1, unrefined_units))
	unrefined_units = maxi(0, unrefined_units - req_farr)
	current_weight = maxf(0.0, current_weight * (1.0 - ratio))
	unrefined_value = maxi(0, int(round(unrefined_value * (1.0 - ratio))))
	wallet_credits += 350
	event_logged.emit("QUEST COMPLETE! Turned in 3 Kills + 10 Farr -> Rewarded +1x Farr Talic Crystal & +350 %s!" % code)


func cycle_class() -> void:
	class_index = (class_index + 1) % 4
	_recalc_vital_stats()
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp
	save_game()
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
	save_game()


func teleport_to_hq() -> void:
	var f := _faction_dict()
	travel_to_map(str(f["hq_map_id"]), f["hq_spawn"], true)
	event_logged.emit("Arrived at [%s] (%s). Click any HQ Side Vendor NPC to trade or [M] to Warp!" % [f["hq_name"], f["name"]])


func _handle_click(delta: float) -> void:
	_retarget_timer -= delta
	if _holding_world_click and _retarget_timer <= 0.0:
		if get_viewport().gui_get_hovered_control() != null:
			_holding_world_click = false
			return
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
			active_summon_beacon = null
			_set_selected_enemy(enemy)
			auto_attacking = true
			event_logged.emit("Targeted & engaging %s." % enemy.enemy_name)
			_holding_world_click = false
		elif collider is FarrVein or collider is RefineryStation or collider is DroppedOreBag or collider is VendorNpc or (collider is Node3D and ((collider as Node3D).is_in_group("warp_portal") or (collider as Node3D).is_in_group("summon_beacon"))):
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

	if tab_target_mode == 0:
		# Mode 0: Closest to Mouse Cursor (2D screen projection)
		var cam := get_viewport().get_camera_3d()
		var mouse_pos := get_viewport().get_mouse_position()
		enemies.sort_custom(func(a: EnemyUnit, b: EnemyUnit) -> bool:
			return _screen_dist_to_mouse(cam, a, mouse_pos) < _screen_dist_to_mouse(cam, b, mouse_pos)
		)
	elif tab_target_mode == 1:
		# Mode 1: Lowest HP First (tie-breaker: distance to player)
		enemies.sort_custom(func(a: EnemyUnit, b: EnemyUnit) -> bool:
			if a.current_hp != b.current_hp:
				return a.current_hp < b.current_hp
			return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
		)
	else:
		# Mode 2: Closest to Character (3D world distance)
		enemies.sort_custom(func(a: EnemyUnit, b: EnemyUnit) -> bool:
			return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
		)

	var next_enemy: EnemyUnit = enemies[0]
	if selected_enemy != null and is_instance_valid(selected_enemy):
		if tab_target_mode == 0 and enemies[0] != selected_enemy:
			# Snap immediately to the enemy currently closest to the mouse cursor!
			next_enemy = enemies[0]
		else:
			var idx := enemies.find(selected_enemy)
			next_enemy = enemies[(idx + 1) % enemies.size()]

	_set_selected_enemy(next_enemy)
	_play_sfx("target_lock")
	event_logged.emit("Targeted [%s]: %s (HP %d/%d)." % [
		TAB_MODE_LABELS[tab_target_mode], next_enemy.enemy_name, next_enemy.current_hp, next_enemy.max_hp
	])


func _screen_dist_to_mouse(cam: Camera3D, enemy: EnemyUnit, mouse_pos: Vector2) -> float:
	if cam == null:
		return global_position.distance_to(enemy.global_position)
	var world_pt := enemy.global_position + Vector3(0.0, 1.0, 0.0)
	if cam.is_position_behind(world_pt):
		return 999999.0 + global_position.distance_to(world_pt)
	var screen_pt := cam.unproject_position(world_pt)
	return screen_pt.distance_to(mouse_pos)


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
	elif slot == 9:
		cast_rf_buff_suite()
	_emit_state()


func _resolved_weapon_mode() -> String:
	var c := _class_dict()
	var stance_id: String = str(GameData.WEAPON_STANCES[clampi(weapon_stance_index, 0, GameData.WEAPON_STANCES.size() - 1)]["id"])
	if stance_id == "AUTO":
		if bool(c.get("uses_force", false)):
			return "FORCE"
		if bool(c.get("uses_ammo", false)):
			return "RANGED"
		return "MELEE"
	return stance_id


func _is_cross_class_weapon() -> bool:
	var c := _class_dict()
	var w_mode := _resolved_weapon_mode()
	if weapon_stance_index == 0:
		return false
	if w_mode == "RANGED":
		return not bool(c.get("uses_ammo", false))
	if w_mode == "FORCE":
		return not bool(c.get("uses_force", false))
	if w_mode == "MELEE":
		return bool(c.get("uses_ammo", false)) or bool(c.get("uses_force", false))
	return false


func _weapon_mode_summary() -> String:
	var w_mode := _resolved_weapon_mode()
	var cross := _is_cross_class_weapon()
	var rng := _effective_attack_range()
	if w_mode == "MELEE":
		return "Melee Close (%.1fm%s)" % [rng, " Cross-Class" if cross else ""]
	if w_mode == "RANGED":
		return "Ranged Bow/Rifle (%.1fm%s)" % [rng, " Limited Cross-Class" if cross else ""]
	return "Force Staff (%.1fm%s)" % [rng, " Limited Cross-Class" if cross else ""]


func cycle_weapon_stance() -> void:
	weapon_stance_index = (weapon_stance_index + 1) % GameData.WEAPON_STANCES.size()
	_play_sfx("target_lock")
	save_game()
	var cross_note := " [Cross-Class Range/ATK Limit Active]" if _is_cross_class_weapon() else " [100% Class Synergy]"
	event_logged.emit("Weapon Mode [Z] -> %s%s" % [_weapon_mode_summary(), cross_note])
	_emit_state()


func cast_rf_buff_suite() -> void:
	var f := _faction_dict()
	var fid: String = str(f["id"])
	var suite: Dictionary = GameData.FACTION_BUFF_SUITES.get(fid, {})
	if suite.is_empty():
		return
	var fp_cost: int = int(suite.get("fp_cost", 25))
	var sp_cost: int = int(suite.get("sp_cost", 20))
	if current_fp < fp_cost or current_sp < sp_cost:
		event_logged.emit("Need %d FP & %d SP to cast RF Buff Suite (%s)! Use [6] FP or [7] SP Potion." % [
			fp_cost, sp_cost, suite["suite_name"]
		])
		return
	current_fp -= fp_cost
	current_sp -= sp_cost
	var was_unbuffed := (_rf_buff_timer <= 0.0)
	_rf_buff_timer = float(suite.get("duration", 120.0))
	_buff_regen_accum = 0.0
	_recalc_vital_stats()
	var bonus_heal := int(round(max_hp * 0.14)) if was_unbuffed else int(round(max_hp * 0.06))
	current_hp = mini(max_hp, current_hp + bonus_heal)
	_play_sfx("buff_cast")
	COMBAT_VFX.spawn_buff_aura(self, suite.get("aura_color", f["color"]))
	FLOATING_TEXT.spawn(
		self,
		global_position + Vector3(0.0, 2.55, 0.0),
		"BUFFS ON! +22% ATK / +20% ASPD / -22% DMG / +18% HP (120s)",
		suite.get("aura_color", Color(1.0, 0.92, 0.38)),
		36,
		1.9
	)
	save_game()
	event_logged.emit("RF BUFF SUITE ACTIVE (120s): %s -> +22%% ATK, +20%% ASPD, -22%% Dmg Taken, +15%% SPD, +18%% Max HP/FP!" % suite["suite_name"])
	_emit_state()


func _trigger_attack_vfx(target: Node3D, is_skill: bool = false) -> void:
	if target == null or not is_instance_valid(target):
		return
	var f := _faction_dict()
	var col: Color = f["color"]
	var to_t := target.global_position - global_position
	to_t.y = 0.0
	if to_t.length_squared() > 0.001:
		var dir := to_t.normalized()
		var w_mode := _resolved_weapon_mode()
		# Melee lunges forward; Ranged/Force has slight firing kickback
		_attack_lunge_dir = dir if (w_mode == "MELEE" and not siege_mode) else (-dir * 0.55)
		_attack_lunge_timer = 0.18

	var from_pos := global_position + Vector3(0.0, 1.85 if frame_mounted else 1.25, 0.0)
	if siege_mode:
		COMBAT_VFX.spawn_projectile(self, from_pos, target, col, false, true)
		COMBAT_VFX.spawn_aoe_blast(self, target.global_position, 4.0, col)
	else:
		var w_mode := _resolved_weapon_mode()
		if w_mode == "RANGED":
			COMBAT_VFX.spawn_projectile(self, from_pos, target, col.lightened(0.2 if is_skill else 0.0), false, is_skill)
		elif w_mode == "FORCE":
			COMBAT_VFX.spawn_projectile(self, from_pos, target, col.lightened(0.25 if is_skill else 0.05), true, is_skill)
		else:
			COMBAT_VFX.spawn_melee_slash(self, global_position, target.global_position, col, 1.35 if is_skill else 1.0)


func _cast_skill_2() -> void:
	if _skill2_cd > 0.0:
		event_logged.emit("Skill 2 on cooldown (%.1fs)." % _skill2_cd)
		return
	if selected_enemy == null or selected_enemy.is_dead:
		cycle_target()
	if selected_enemy == null:
		event_logged.emit("No target in range for Skill 2.")
		return
	var s2: Dictionary = _active_skill_2()
	var fp_cost: int = s2.get("fp_cost", 20)
	var sp_cost: int = s2.get("sp_cost", 15)
	if current_fp < fp_cost or current_sp < sp_cost:
		event_logged.emit("Not enough FP/SP for %s! Use [6] FP or [7] SP Potion." % s2["name"])
		return
	var dist := Vector2(global_position.x - selected_enemy.global_position.x, global_position.z - selected_enemy.global_position.z).length()
	var max_dist := maxf(maxf(float(s2["range"]), _effective_attack_range() + 1.5), 15.0 if siege_mode else 0.0)
	if dist > max_dist:
		event_logged.emit("Target too far for %s (move within %.1fm)." % [s2["name"], max_dist])
		return
	if is_mining:
		_cancel_mining("")
	current_fp -= fp_cost
	current_sp -= sp_cost
	_skill2_cd = float(s2["cd"])
	sprite.set_facing(selected_enemy.global_position - global_position)
	_trigger_attack_vfx(selected_enemy, true)
	var dmg := int(round(_effective_attack_damage() * float(s2["mult"])))
	var effect: String = str(s2.get("effect", "NONE"))
	var hit_tag := "[SKILL]"
	if effect == "ARMOR_PIERCE":
		dmg = int(round(dmg * 1.22))
		hit_tag = "[CRIT PIERCE!]"
	selected_enemy.receive_damage(dmg, self, true, hit_tag)
	record_damage_dealt(dmg)
	_play_sfx("skill_cast")
	var fx_note := _apply_skill_effect(effect, dmg)
	event_logged.emit("%s hit %s for %d DMG%s (-%d FP, -%d SP)!" % [
		s2["name"], selected_enemy.enemy_name, dmg, fx_note, fp_cost, sp_cost
	])


func _cast_skill_3() -> void:
	if _skill3_cd > 0.0:
		event_logged.emit("Skill 3 on cooldown (%.1fs)." % _skill3_cd)
		return
	var s3: Dictionary = _active_skill_3()
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
	var blast_rad := float(s3["radius"])
	if selected_enemy and not selected_enemy.is_dead:
		_trigger_attack_vfx(selected_enemy, true)
	COMBAT_VFX.spawn_aoe_blast(self, center, blast_rad, _faction_dict()["color"])
	var dmg := int(round(_effective_attack_damage() * float(s3["mult"])))
	var effect: String = str(s3.get("effect", "NONE"))
	var hits := _deal_aoe_damage(center, blast_rad, dmg, true, "[AoE SKILL]")
	_play_sfx("skill_cast", 0.92)
	var fx_note := _apply_skill_effect(effect, dmg * maxi(1, hits))
	event_logged.emit("%s hit %d enemy(s) for %d AoE DMG%s (-%d FP, -%d SP)!" % [
		s3["name"], hits, dmg, fx_note, fp_cost, sp_cost
	])


func _apply_skill_effect(effect: String, dmg_dealt: int) -> String:
	match effect:
		"SHIELD_TAUNT":
			_shield_buff_timer = 8.0
			var heal := int(round(max_hp * 0.18))
			current_hp = mini(max_hp, current_hp + heal)
			record_heal_or_restore(heal, 0, 0, "[Fortify]")
			return " [Tank Fortify: -40%% Dmg Taken 8s & +%d HP]" % heal
		"LIFESTEAL":
			var drain := maxi(15, int(round(dmg_dealt * 0.32)))
			current_hp = mini(max_hp, current_hp + drain)
			record_heal_or_restore(drain, 0, 0, "[Lifesteal]")
			return " [Drained +%d HP]" % drain
		"HEAL_SELF":
			var heal_s := int(round(max_hp * 0.28))
			var sp_s := int(round(max_sp * 0.20))
			current_hp = mini(max_hp, current_hp + heal_s)
			current_sp = mini(max_sp, current_sp + sp_s)
			record_heal_or_restore(heal_s, 0, sp_s, "[Self-Heal]")
			return " [Self-Repair: +%d HP, +%d SP]" % [heal_s, sp_s]
		"HEAL_PULSE":
			var heal_p := int(round(max_hp * 0.45))
			var sp_p := int(round(max_sp * 0.25))
			current_hp = mini(max_hp, current_hp + heal_p)
			current_sp = mini(max_sp, current_sp + sp_p)
			record_heal_or_restore(heal_p, 0, sp_p, "[Pulse]")
			if fravashi_instance and is_instance_valid(fravashi_instance) and fravashi_instance.visible:
				var f_heal := maxi(1, fravashi_instance.max_hp - fravashi_instance.current_hp)
				fravashi_instance.current_hp = fravashi_instance.max_hp
				FLOATING_TEXT.spawn(
					fravashi_instance,
					fravashi_instance.global_position + Vector3(0.0, 2.1, 0.0),
					"+%d HP [Fravashi]" % f_heal,
					Color(0.28, 1.0, 0.48),
					32,
					1.6
				)
			return " [Sanctuary Heal Pulse: +%d HP, +%d SP]" % [heal_p, sp_p]
		"ARMOR_PIERCE":
			return " [Armor-Piercing Crit!]"
	return ""


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

	var w_mode := _resolved_weapon_mode()
	var needs_charge := (w_mode == "RANGED") or (w_mode == "FORCE") or siege_mode
	if needs_charge:
		if not consume_item_from_bags("AMMO_PACK", 1):
			auto_attacking = false
			event_logged.emit("Out of Ammo / Force Cells! Restock at HQ Weapon NPC or press [Z] to swap to Melee Weapon (0 Ammo).")
			return

	_attack_cd = 0.85 if _rf_buff_timer > 0.0 else 1.05
	sprite.set_facing(to_enemy)
	_trigger_attack_vfx(selected_enemy, false)
	if siege_mode or w_mode != "MELEE":
		_play_sfx("ranged_shot")
	else:
		_play_sfx("attack_hit")
	var dmg := _effective_attack_damage()
	if siege_mode:
		current_debt += 15
		var hits := _deal_aoe_damage(selected_enemy.global_position, 4.0, dmg, true, "[SIEGE]")
		event_logged.emit("Siege Artillery hit %d target(s) for %d DMG (-1 Ammo, +15 CYC Debt)." % [hits, dmg])
	else:
		var enemy_name_before := selected_enemy.enemy_name
		var atk_tag := "[RANGED]" if w_mode == "RANGED" else ("[FORCE]" if w_mode == "FORCE" else "")
		selected_enemy.receive_damage(dmg, self, false, atk_tag)
		record_damage_dealt(dmg)
		event_logged.emit("Hit %s (%s) for -%d DMG!" % [enemy_name_before, w_mode, dmg])


func _deal_aoe_damage(center: Vector3, radius: float, dmg: int, is_skill: bool = true, hit_tag: String = "[AoE]") -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("enemy_unit"):
		var e := n as EnemyUnit
		if e and not e.is_dead:
			var d := Vector2(e.global_position.x - center.x, e.global_position.z - center.z).length()
			if d <= radius:
				e.receive_damage(dmg, self, is_skill, hit_tag)
				record_damage_dealt(dmg)
				count += 1
	return count


func receive_damage(amount: int, attacker: Node3D) -> void:
	if is_mining:
		_cancel_mining("Mining interrupted by enemy attack!")
	var shielded := _shield_buff_timer > 0.0
	var rf_buffed := _rf_buff_timer > 0.0
	var mult := (0.6 if shielded else 1.0) * (0.78 if rf_buffed else 1.0)
	var final_dmg := maxi(1, int(round(amount * mult)))
	current_hp = maxi(0, current_hp - final_dmg)
	record_damage_taken(final_dmg, shielded or rf_buffed)
	if frame_mounted:
		current_debt += 18
	var atk_name := (attacker as EnemyUnit).enemy_name if (attacker is EnemyUnit) else "Enemy"
	var shield_note := " [Fortify -40%]" if shielded else (" [Buff Ward -22%]" if rf_buffed else "")
	event_logged.emit("Took -%d DMG%s from %s (HP: %d/%d)!" % [final_dmg, shield_note, atk_name, current_hp, max_hp])
	if selected_enemy == null and attacker is EnemyUnit:
		_set_selected_enemy(attacker as EnemyUnit)
	if current_hp <= 0:
		simulate_death()
	_emit_state()


func record_damage_dealt(amount: int) -> void:
	if amount <= 0:
		return
	combat_dmg_dealt_total += amount
	combat_dmg_dealt_last = amount
	combat_dmg_dealt_max = maxi(combat_dmg_dealt_max, amount)


func record_damage_taken(amount: int, shielded: bool = false) -> void:
	if amount <= 0:
		return
	_play_sfx("damage_taken")
	combat_dmg_taken_total += amount
	combat_dmg_taken_last = amount
	var tag := " [SHIELDED]" if shielded else " HIT"
	var head_offset := Vector3(0.0, 2.75 if frame_mounted else 2.15, 0.0)
	FLOATING_TEXT.spawn(
		self,
		global_position + head_offset,
		"-%d%s" % [amount, tag],
		Color(1.0, 0.26, 0.26),
		36,
		1.65
	)


func record_heal_or_restore(hp_gain: int, fp_gain: int = 0, sp_gain: int = 0, tag: String = "") -> void:
	if hp_gain > 0 or fp_gain > 0 or sp_gain > 0:
		_play_sfx("heal")
	var suffix := (" " + tag) if tag != "" else ""
	var head_offset := Vector3(0.0, 2.85 if frame_mounted else 2.25, 0.0)
	if hp_gain > 0:
		combat_hp_healed_total += hp_gain
		combat_hp_healed_last = hp_gain
		FLOATING_TEXT.spawn(
			self,
			global_position + head_offset,
			"+%d HP%s" % [hp_gain, suffix],
			Color(0.26, 1.0, 0.46),
			36,
			1.75
		)
	if fp_gain > 0:
		FLOATING_TEXT.spawn(
			self,
			global_position + head_offset + Vector3(0.18, 0.22, 0.0),
			"+%d FP%s" % [fp_gain, suffix],
			Color(0.38, 0.88, 1.0),
			32,
			1.6
		)
	if sp_gain > 0:
		FLOATING_TEXT.spawn(
			self,
			global_position + head_offset + Vector3(-0.18, 0.35, 0.0),
			"+%d SP%s" % [sp_gain, suffix],
			Color(1.0, 0.82, 0.32),
			32,
			1.6
		)


func reset_combat_telemetry() -> void:
	combat_dmg_dealt_total = 0
	combat_dmg_dealt_last = 0
	combat_dmg_dealt_max = 0
	combat_dmg_taken_total = 0
	combat_dmg_taken_last = 0
	combat_hp_healed_total = 0
	combat_hp_healed_last = 0
	event_logged.emit("Combat Damage & Heal Telemetry Meter reset to 0.")
	_emit_state()


func _on_enemy_died(enemy: EnemyUnit, _killer: Node3D) -> void:
	var was_selected := (selected_enemy == enemy)
	if was_selected:
		_set_selected_enemy(null)
		auto_attacking = false
	var f := _faction_dict()
	var cur_mdata: Dictionary = GameData.MAPS.get(current_map_id, {})
	var focus: String = str(cur_mdata.get("farming_focus", ""))

	# 1. Economic / Bounty Multipliers per Map Niche:
	var bounty_mult := 1.0
	if focus == "WEALTH_CREDITS":
		bounty_mult = 2.5 # Ether Sky Platform 2.5x Bounty Gold Farm
	elif focus == "PVP_BOUNTY":
		bounty_mult = 1.4 # Sette Dune Sea PvP War Bounty
	elif focus == "DUNGEON_LOOT":
		bounty_mult = 1.25 # Ancient Vaults
	var final_bounty: int = int(round(enemy.bounty_reward * bounty_mult))
	wallet_credits += final_bounty

	quest_kills += 3 if enemy.level >= 50 else 1
	story_kills += 1
	if enemy.level >= 28:
		story_boss_kills += 1

	# 2. XP Progression Multipliers per Map Niche:
	var xp_mult := 1.5 if (focus == "DUNGEON_LOOT" or focus == "COMPONENT_SALVAGE") else 1.0
	xp += int(round(55 * xp_mult))

	if enemy.is_pit_boss:
		_play_sfx("level_up")
		event_logged.emit("★★★ CONQUERED ZONE PIT BOSS [%s]! +%d %s Bounty ★★★" % [
			enemy.enemy_name, final_bounty, f["currency_code"]
		])
	var needed := level * 90
	if xp >= needed and level < 45:
		xp -= needed
		level += 1
		_recalc_vital_stats()
		current_hp = max_hp
		current_fp = max_fp
		current_sp = max_sp
		_play_sfx("level_up")
		event_logged.emit("LEVEL UP! Reached Level %d (Cap 45 / Leader 50)." % level)
	elif not enemy.is_pit_boss:
		var bonus_tag := " [2.5x Wealth Multiplier]" if focus == "WEALTH_CREDITS" else ""
		event_logged.emit("Slain %s! +%d %s Bounty%s (Quest Kills: %d/3) & dropped Farr bag." % [
			enemy.enemy_name, final_bounty, f["currency_code"], bonus_tag, quest_kills
		])

	_roll_rare_equipment_drop(enemy)
	if was_selected and auto_target_on_kill:
		# Auto-select next living enemy within 18m according to active [Tab] priority mode
		for n in get_tree().get_nodes_in_group("enemy_unit"):
			var cand := n as EnemyUnit
			if cand and not cand.is_dead and global_position.distance_to(cand.global_position) <= 18.0:
				cycle_target()
				break
	save_game()
	_emit_state()


## Low-probability monster equipment & Farr Talic drop placed directly into your Bag!
## Talics ONLY drop from Mini-Bosses (Lv.25-39), Bosses (Lv.40-49), and World Bosses (Lv.50) (or Faction Quests)!
func _roll_rare_equipment_drop(enemy: EnemyUnit) -> void:
	var cur_mdata: Dictionary = GameData.MAPS.get(current_map_id, {})
	var focus: String = str(cur_mdata.get("farming_focus", ""))

	if enemy.is_pit_boss:
		# GUARANTEED BOUNTIFUL PIT BOSS LOOT:
		var bonus_talic: int = 1 if (focus == "TALIC_FARMING" or focus == "SOVEREIGN_TALICS" or focus == "COSMIC_TALICS" or focus == "DUNGEON_LOOT" or focus == "ENDGAME_RAID") else 0
		var pb_talics: int = (2 if randf() < 0.5 else 3) + bonus_talic
		add_item_to_bags(GameData.make_consumable_item("TALIC_FARR", pb_talics))

		var pb_tier := 5 if enemy.level >= 45 else (4 if enemy.level >= 35 else (3 if enemy.level >= 20 else 2))
		var pb_group := GameData.EQUIP_CHASSIS_SVEL if randf() < 0.35 else GameData.EQUIP_ORGANIC_VAR
		var pb_slot: String = GameData.EQUIP_SLOTS[randi() % GameData.EQUIP_SLOTS.size()]
		var pb_gear := GameData.make_equipment_item(pb_tier, pb_slot, pb_group)
		if add_item_to_bags(pb_gear):
			event_logged.emit("★ PIT BOSS LOOT: +%dx Farr Talics & [%s] awarded to your Bags!" % [pb_talics, pb_gear["name"]])
		else:
			event_logged.emit("★ PIT BOSS LOOT: +%dx Farr Talics awarded! Bags full for [%s]." % [pb_talics, pb_gear["name"]])
		return

	var dropped_talics := 0
	if enemy.level >= 50:
		dropped_talics = 2 if randf() < 0.40 else 1
		add_item_to_bags(GameData.make_consumable_item("TALIC_FARR", dropped_talics))
	elif (enemy.level >= 35 or focus == "TALIC_FARMING" or focus == "SOVEREIGN_TALICS" or focus == "COSMIC_TALICS") and randf() < (0.65 if focus == "TALIC_FARMING" else 0.45):
		dropped_talics = 1
		add_item_to_bags(GameData.make_consumable_item("TALIC_FARR", 1))
	elif enemy.level >= 25 and randf() < (0.42 if focus == "TALIC_FARMING" else 0.22):
		dropped_talics = 1
		add_item_to_bags(GameData.make_consumable_item("TALIC_FARR", 1))

	var drop_chance := 1.0 if enemy.level >= 50 else (0.65 if focus == "RARE_GEAR" else (0.45 if enemy.level >= 25 else 0.22))
	if randf() > drop_chance:
		if dropped_talics > 0:
			event_logged.emit("TALIC DROP -> Bag: +%dx Farr Talic Crystal from %s!" % [dropped_talics, enemy.enemy_name])
		return

	var dropped_tier_idx := 5 if enemy.level >= 45 else (4 if enemy.level >= 35 else (3 if enemy.level >= 25 else 1))
	var rolled_group := GameData.EQUIP_CHASSIS_SVEL if randf() < 0.35 else GameData.EQUIP_ORGANIC_VAR
	var random_slot: String = GameData.EQUIP_SLOTS[randi() % GameData.EQUIP_SLOTS.size()]
	var dropped_item := GameData.make_equipment_item(dropped_tier_idx, random_slot, rolled_group)

	if add_item_to_bags(dropped_item):
		var talic_note := (" + %dx Farr Talic Crystal!" % dropped_talics) if dropped_talics > 0 else "!"
		event_logged.emit("LOOT DROP -> Bag: %s%s Open [I] to equip/upgrade." % [dropped_item["name"], talic_note])
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
	if _is_cross_class_weapon():
		base_atk *= 0.82
	if _rf_buff_timer > 0.0:
		base_atk *= 1.22
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
		return 16.5 if _rf_buff_timer > 0.0 else 15.0
	var c := _class_dict()
	var w_mode := _resolved_weapon_mode()
	var cross := _is_cross_class_weapon()
	var r := float(c["range"])
	if weapon_stance_index != 0:
		if w_mode == "MELEE":
			r = 2.8
		elif w_mode == "RANGED":
			r = 7.5 if cross else maxf(r, 10.5)
		elif w_mode == "FORCE":
			r = 6.8 if cross else maxf(r, 9.0)
	if _rf_buff_timer > 0.0 and w_mode != "MELEE":
		r += 1.5
	if frame_mounted:
		r = maxf(r, 3.6)
	return r


func _recalc_vital_stats() -> void:
	var c := _class_dict()
	var g := _total_gear_bonuses()
	var job_mult := 1.2 if level >= 30 else 1.0
	var archon_mult := 1.35 if is_ascended_leader else 1.0
	var buff_hp_fp_mult := 1.18 if _rf_buff_timer > 0.0 else 1.0

	var raw_hp := (280 + (level - 1) * 28 + int(g["hp"])) * float(c["hp_mult"]) * job_mult * archon_mult * buff_hp_fp_mult
	var raw_fp := (160 + (level - 1) * 16 + int(g["fp"])) * float(c["fp_mult"]) * job_mult * archon_mult * buff_hp_fp_mult
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
	elif target.is_in_group("warp_portal"):
		var dest_map := str(target.get("target_map_id"))
		travel_to_map(dest_map)
	elif target.is_in_group("summon_beacon"):
		active_summon_beacon = target
		var bname: String = str(target.get("beacon_name")) if target.get("beacon_name") != null else "Summon Beacon"
		event_logged.emit("Activated %s. Ready to summon grinding waves or awaken Pit Boss!" % bname)
		_emit_state()


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
		story_farr_mined += added_units
		current_weight = minf(current_weight + added_weight, max_weight)
		unrefined_value += added_val
		_play_sfx("mine_ore")
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
	_play_sfx("mine_ore", 1.15)

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
	active_summon_beacon = null
	sprite.scale = Vector3.ONE
	sprite.position.y = 0.8
	if fravashi_instance and is_instance_valid(fravashi_instance):
		fravashi_instance.visible = false

	faction_index = (faction_index + 1) % GameData.FACTIONS.size()
	_recalc_vital_stats()
	_apply_faction_tint()
	var f := _faction_dict()
	var cur_mdata: Dictionary = GameData.MAPS.get(current_map_id, {})
	if str(cur_mdata.get("owner_faction", "all")) != "all":
		travel_to_map(str(f["hq_map_id"]), f["hq_spawn"], true)
	var shared_note := "Chassis-Only Gear" if f["equip_group"] == GameData.EQUIP_CHASSIS_SVEL else "Shares Organic/Relic Gear between Order & Druj"
	event_logged.emit("Switched Race -> %s | HQ Map: %s | Currency: %s (%s) | %s" % [
		f["name"], f["hq_name"], f["currency_name"], f["currency_code"], shared_note
	])


func _respawn_map_id() -> String:
	var f := _faction_dict()
	var fid: String = str(f["id"])
	if bind_points.has(fid):
		var bp: Dictionary = bind_points[fid]
		var b_map := str(bp.get("map_id", f["hq_map_id"]))
		if GameData.MAPS.has(b_map):
			return b_map
	return str(f["hq_map_id"])


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
		return "%s (Bound Rebirth)" % str(bp.get("name", f["hq_name"]))
	return "%s (HQ Default)" % str(f["hq_name"])


func simulate_death() -> void:
	if is_mining:
		_cancel_mining("")
	auto_attacking = false
	siege_mode = false
	active_vendor_npc = null
	active_summon_beacon = null
	_clear_click_target()
	_interact_target = null
	current_hp = max_hp
	current_fp = max_fp
	current_sp = max_sp

	var spawn_map := _respawn_map_id()
	var spawn_dest := _respawn_position()
	var spawn_label := _respawn_name()
	var death_pos := global_position
	var same_map := (spawn_map == current_map_id)

	# RF / FARR Rule: All Bag items (Potions, Scrolls, Ammo, Gear) stay 100% in your Bags!
	# Only Unrefined Farr Ore drops at your death coordinate so anyone can loot it.
	var drop_units := int(ceil(unrefined_units * 0.5))
	var drop_weight := 0.0
	var drop_val := 0
	if drop_units > 0:
		var ratio := float(drop_units) / float(unrefined_units)
		drop_weight = current_weight * ratio
		drop_val = int(round(unrefined_value * ratio))
		unrefined_units -= drop_units
		current_weight = maxf(0.0, current_weight - drop_weight)
		unrefined_value = maxi(0, unrefined_value - drop_val)

	if not same_map:
		travel_to_map(spawn_map, spawn_dest, true)
	else:
		global_position = spawn_dest
		velocity = Vector3.ZERO
		if drop_units > 0 and get_parent():
			var bag := DROPPED_BAG_SCENE.instantiate() as DroppedOreBag
			get_parent().add_child(bag)
			bag.global_position = Vector3(death_pos.x, 0.0, death_pos.z)
			bag.setup(drop_units, drop_weight, drop_val)

	if drop_units > 0:
		event_logged.emit("CHINVAT REBIRTH: Slain! Dropped %d Unrefined Farr (All Bag items kept!) -> Respawned at %s." % [
			drop_units, spawn_label
		])
	else:
		event_logged.emit("CHINVAT REBIRTH: Respawned at %s (All Bag items & Equipment kept!)." % spawn_label)

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
		"map_id": current_map_id,
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
		"quest_kills": quest_kills,
		"bind_points": bind_points,
		"last_saved_text": last_saved_text,
		"tab_target_mode": tab_target_mode,
		"auto_target_on_kill": auto_target_on_kill,
		"show_floating_dmg": show_floating_dmg,
		"sfx_volume_pct": sfx_volume_pct,
		"music_volume_pct": music_volume_pct,
		"cam_sensitivity_mult": cam_sensitivity_mult,
		"story_chapter_by_faction": story_chapter_by_faction,
		"story_kills": story_kills,
		"story_farr_mined": story_farr_mined,
		"story_boss_kills": story_boss_kills,
		"codex_cursor": codex_cursor,
		"weapon_stance_index": weapon_stance_index,
		"rf_buff_timer": _rf_buff_timer,
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
	var default_hq_map := str(GameData.FACTIONS[faction_index]["hq_map_id"])
	var saved_map := str(d.get("map_id", default_hq_map))
	current_map_id = saved_map if GameData.MAPS.has(saved_map) else default_hq_map
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
	quest_kills = maxi(0, int(d.get("quest_kills", 0)))
	if d.has("bind_points") and typeof(d["bind_points"]) == TYPE_DICTIONARY:
		bind_points = d["bind_points"]
	last_saved_text = str(d.get("last_saved_text", "Restored"))
	tab_target_mode = clampi(int(d.get("tab_target_mode", 0)), 0, TAB_MODE_LABELS.size() - 1)
	auto_target_on_kill = bool(d.get("auto_target_on_kill", true))
	show_floating_dmg = bool(d.get("show_floating_dmg", true))
	sfx_volume_pct = clampi(int(d.get("sfx_volume_pct", 80)), 0, 100)
	music_volume_pct = clampi(int(d.get("music_volume_pct", 70)), 0, 100)
	cam_sensitivity_mult = clampf(float(d.get("cam_sensitivity_mult", 1.0)), 0.4, 2.0)
	if d.has("story_chapter_by_faction") and typeof(d["story_chapter_by_faction"]) == TYPE_DICTIONARY:
		for k in d["story_chapter_by_faction"].keys():
			story_chapter_by_faction[str(k)] = clampi(int(d["story_chapter_by_faction"][k]), 0, 5)
	story_kills = maxi(0, int(d.get("story_kills", 0)))
	story_farr_mined = maxi(0, int(d.get("story_farr_mined", 0)))
	story_boss_kills = maxi(0, int(d.get("story_boss_kills", 0)))
	codex_cursor = clampi(int(d.get("codex_cursor", 0)), 0, maxi(0, GameData.LORE_CODEX_ENTRIES.size() - 1))
	weapon_stance_index = clampi(int(d.get("weapon_stance_index", 0)), 0, GameData.WEAPON_STANCES.size() - 1)
	_rf_buff_timer = maxf(0.0, float(d.get("rf_buff_timer", 0.0)))

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
		var slots := _active_equipment_slots()
		var wpn_plus := int(slots.get("WEAPON", {}).get("upgrade_plus", 0))
		var up_plus := int(slots.get("UPPER", {}).get("upgrade_plus", 0))
		if maxi(wpn_plus, up_plus) >= 6:
			sprite.accent_color = Color(1.0, 0.95, 0.45)
			sprite.body_color = Color(0.82, 0.78, 0.65)
		else:
			sprite.accent_color = f["color"]
			sprite.body_color = Color(0.55, 0.6, 0.66)
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
	var s2: Dictionary = _active_skill_2()
	var s3: Dictionary = _active_skill_3()
	var upg_slot: String = GameData.EQUIP_SLOTS[_upgrade_slot_cursor]
	var upg_lbl: String = GameData.EQUIP_SLOT_LABELS.get(upg_slot, upg_slot)
	var upg_item: Dictionary = _active_equipment_slots().get(upg_slot, {})
	var cur_plus: int = int(upg_item.get("upgrade_plus", 0))

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
			"quest_kills": quest_kills,
			"quest_farr": unrefined_units,
		}

	var cur_mdata: Dictionary = GameData.MAPS.get(current_map_id, {})
	var fid: String = str(f["id"])
	var camp: Dictionary = GameData.STORY_CAMPAIGNS.get(fid, {})
	var cur_ch := _active_story_chapter_dict()
	var ch_idx: int = int(story_chapter_by_faction.get(fid, 0))
	var codex_list: Array = GameData.LORE_CODEX_ENTRIES
	var cur_codex: Dictionary = codex_list[clampi(codex_cursor, 0, codex_list.size() - 1)] if not codex_list.is_empty() else {}
	var open_req := request_open_story_window
	request_open_story_window = false
	var story_info := {
		"leader_name": str(camp.get("leader_name", f["leader"])),
		"leader_title": str(camp.get("leader_title", "Faction Sovereign")),
		"leader_portrait": str(camp.get("portrait_path", "")),
		"chapter_index": ch_idx,
		"total_chapters": (camp.get("chapters", []) as Array).size(),
		"chapter": cur_ch,
		"story_kills": story_kills,
		"story_farr_mined": story_farr_mined,
		"story_boss_kills": story_boss_kills,
		"request_open": open_req,
		"codex_index": codex_cursor,
		"codex_total": codex_list.size(),
		"codex_entry": cur_codex,
	}
	var suite: Dictionary = GameData.FACTION_BUFF_SUITES.get(fid, {})
	var stance_dict: Dictionary = GameData.WEAPON_STANCES[clampi(weapon_stance_index, 0, GameData.WEAPON_STANCES.size() - 1)]

	var beacon_info: Variant = null
	if active_summon_beacon and is_instance_valid(active_summon_beacon):
		beacon_info = {
			"name": str(active_summon_beacon.get("beacon_name")),
			"zone_id": str(active_summon_beacon.get("zone_id")),
			"pit_boss_name": active_summon_beacon.get_pit_boss_name() if active_summon_beacon.has_method("get_pit_boss_name") else "Zone Pit Boss",
		}

	state_updated.emit({
		"active_beacon": beacon_info,
		"faction": f["name"],
		"faction_id": f["id"],
		"current_map_id": current_map_id,
		"current_map_name": cur_mdata.get("name", current_map_id),
		"current_map_band": cur_mdata.get("level_band", ""),
		"equip_group": f["equip_group"],
		"currency_name": f["currency_name"],
		"currency_code": f["currency_code"],
		"debt_name": f["debt_name"],
		"job_title": _active_job_title(),
		"gear_name": _active_gear_summary(),
		"weapon_mode_summary": _weapon_mode_summary(),
		"weapon_stance_label": str(stance_dict.get("label", "Class Native Weapon")),
		"attack_range": _effective_attack_range(),
		"rf_buff_timer": _rf_buff_timer,
		"rf_buff_short": str(suite.get("short_tag", "RF Buffs")),
		"respawn_name": _respawn_name(),
		"last_saved": last_saved_text,
		"equipped_slots": _active_equipment_slots(),
		"upgrade_slot_label": upg_lbl,
		"upgrade_cur_plus": cur_plus,
		"talics": get_item_count("TALIC_FARR"),
		"shield_buff": _shield_buff_timer,
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
		"dmg_dealt_total": combat_dmg_dealt_total,
		"dmg_dealt_last": combat_dmg_dealt_last,
		"dmg_dealt_max": combat_dmg_dealt_max,
		"dmg_taken_total": combat_dmg_taken_total,
		"dmg_taken_last": combat_dmg_taken_last,
		"hp_healed_total": combat_hp_healed_total,
		"hp_healed_last": combat_hp_healed_last,
		"tab_target_label": TAB_MODE_LABELS[tab_target_mode],
		"auto_target_on_kill": auto_target_on_kill,
		"show_floating_dmg": show_floating_dmg,
		"sfx_volume_pct": sfx_volume_pct,
		"music_volume_pct": music_volume_pct,
		"cam_sensitivity_mult": cam_sensitivity_mult,
		"story_info": story_info,
	})


# ------------------------------------------------------------------------------
# SUMMON BEACON ACTIONS
# ------------------------------------------------------------------------------
func interact_beacon_summon_wave() -> void:
	if active_summon_beacon and is_instance_valid(active_summon_beacon):
		var count: int = active_summon_beacon.summon_monster_wave(self) if active_summon_beacon.has_method("summon_monster_wave") else 0
		if count > 0:
			event_logged.emit("Summoned grinding wave of %d hostile mobs around the Beacon!" % count)
			_play_sfx("ability_cast")


func interact_beacon_summon_boss() -> void:
	if active_summon_beacon and is_instance_valid(active_summon_beacon):
		var pb_name: String = active_summon_beacon.get_pit_boss_name() if active_summon_beacon.has_method("get_pit_boss_name") else "Zone Pit Boss"
		var success: bool = active_summon_beacon.summon_pit_boss(self) if active_summon_beacon.has_method("summon_pit_boss") else false
		if success:
			event_logged.emit("ROAR! Awakened Pit Boss [%s] in the Boss Pit arena!" % pb_name)
			_play_sfx("level_up")
		else:
			event_logged.emit("Pit Boss [%s] is already active in the Boss Pit!" % pb_name)


func interact_beacon_clear_summons() -> void:
	var world_mgr := get_tree().get_first_node_in_group("world_zone_manager")
	if world_mgr and world_mgr.has_method("clear_summoned_mobs"):
		var cleared: int = world_mgr.clear_summoned_mobs()
		event_logged.emit("Cleared %d summoned wave mobs." % cleared)


func close_beacon_menu() -> void:
	active_summon_beacon = null
	_emit_state()
