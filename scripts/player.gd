extends CharacterBody3D
## Data-Driven Player Controller (driven by `GameData`):
## - 3 Factions ([F]), 4 Base Classes per faction ([J]), 2 Lv.30 Advanced Job branches ([B])
## - Lv.1–45 Level Cap + Lv.50 Ascended Faction Leader (Archon) promotion ([L] to test leveling)
## - Lv.1–50 Equipment Tiers ([U] to buy next tier with Wallet FC)
## - Teleport to Faction HQ ([H]) across the 3-HQ + Central Scar map
## - 1 Exclusive Racial Signature per race ([4]): Sveleitre=Siege, Order=Fravashi, Legion=Dread-Titan Mount

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
var gear_tier_index := 0
var is_ascended_leader := false

var level := 1
var xp := 0
var max_hp := 300
var current_hp := 300

var unrefined_units := 0
var current_weight := 0.0
var unrefined_value := 0
var current_debt := 5000
var wallet_credits := 500

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
	_recalc_vital_stats()
	current_hp = max_hp
	_apply_faction_tint()
	_connect_world_enemies()
	_emit_state()
	event_logged.emit("Welcome to the Var! [F] Race, [J] Class, [B] Lv.30 Job, [U] Gear, [L] +5 Lv, [H] Warp HQ.")


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
	elif event.is_action_pressed("upgrade_gear"):
		upgrade_equipment()
	elif event.is_action_pressed("dev_level_up"):
		dev_boost_level()
	elif event.is_action_pressed("teleport_hq"):
		teleport_to_hq()
	elif event.is_action_pressed("simulate_death"):
		simulate_death()
	elif event.is_action_pressed("target_cycle"):
		cycle_target()
	elif event.is_action_pressed("skill_1"):
		use_skill(1)
	elif event.is_action_pressed("skill_2"):
		use_skill(2)
	elif event.is_action_pressed("skill_3"):
		use_skill(3)
	elif event.is_action_pressed("skill_4"):
		use_skill(4)


func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("move_click"):
		_holding_world_click = false

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_skill2_cd = maxf(0.0, _skill2_cd - delta)
	_skill3_cd = maxf(0.0, _skill3_cd - delta)

	if not auto_attacking and current_hp < max_hp:
		current_hp = mini(max_hp, current_hp + int(ceil(max_hp * 0.025 * delta)))

	_upkeep_timer -= delta
	if _upkeep_timer <= 0.0:
		_upkeep_timer = upkeep_interval
		current_debt += upkeep_cost
		var f: Dictionary = _faction_dict()
		event_logged.emit("%s accrued: +%d FC added to %s." % [f["upkeep_label"], upkeep_cost, f["debt_name"]])

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


func _gear_dict() -> Dictionary:
	return GameData.EQUIPMENT_TIERS[gear_tier_index]


func _active_job_title() -> String:
	var c := _class_dict()
	if level >= 30:
		var jobs: Array = c["jobs"]
		return "%s -> %s" % [c["base"], jobs[job_branch]]
	return "%s (%s)" % [c["base"], c["role"]]


func cycle_class() -> void:
	class_index = (class_index + 1) % 4
	_recalc_vital_stats()
	current_hp = max_hp
	var c := _class_dict()
	event_logged.emit("Switched Base Class -> %s (%s). Weapon Range: %.1fm." % [c["base"], c["role"], c["range"]])


func toggle_job_branch() -> void:
	job_branch = 1 - job_branch
	var c := _class_dict()
	var jobs: Array = c["jobs"]
	if level < 30:
		event_logged.emit("Selected future Lv.30 Job Branch: %s (unlocks at Lv.30!)." % jobs[job_branch])
	else:
		_recalc_vital_stats()
		event_logged.emit("Switched Lv.30 Advanced Job -> %s!" % jobs[job_branch])


func upgrade_equipment() -> void:
	if gear_tier_index + 1 >= GameData.EQUIPMENT_TIERS.size():
		event_logged.emit("Already wearing maximum Tier 7 Ascended Archon Regalia!")
		return
	var next_gear: Dictionary = GameData.EQUIPMENT_TIERS[gear_tier_index + 1]
	var req_lv: int = next_gear["req_lv"]
	var cost: int = next_gear["cost"]
	if level < req_lv:
		event_logged.emit("Need Level %d to equip %s (use [L] to test leveling!)." % [req_lv, next_gear["name"]])
		return
	if wallet_credits < cost:
		event_logged.emit("Need %d Wallet FC to buy %s (you have %d FC)." % [cost, next_gear["name"], wallet_credits])
		return
	wallet_credits -= cost
	gear_tier_index += 1
	_recalc_vital_stats()
	current_hp = max_hp
	event_logged.emit("EQUIPPED %s! (+%d HP, +%d ATK)" % [next_gear["name"], next_gear["bonus_hp"], next_gear["bonus_atk"]])


func dev_boost_level() -> void:
	if level < 45:
		var prev := level
		level = mini(45, level + 5)
		if prev < 30 and level >= 30:
			var jobs: Array = _class_dict()["jobs"]
			event_logged.emit("REACHED LV.%d! Promoted to Advanced Job: %s!" % [level, jobs[job_branch]])
		else:
			event_logged.emit("Boosted to Level %d (Normal Cap: 45). Wallet +1000 FC for gear testing." % level)
		wallet_credits += 1000
	elif not is_ascended_leader:
		is_ascended_leader = true
		level = 50
		wallet_credits += 5000
		event_logged.emit("ELECTED FACTION LEADER (ASCENDED ARCHON)! Raised to Lv.50 & unlocked Archon Regalia!")
	else:
		is_ascended_leader = false
		level = 1
		gear_tier_index = 0
		event_logged.emit("Reset back to Level 1 Recruit.")
	_recalc_vital_stats()
	current_hp = max_hp


func teleport_to_hq() -> void:
	if is_mining:
		_cancel_mining("")
	siege_mode = false
	auto_attacking = false
	_clear_click_target()
	_interact_target = null
	var f := _faction_dict()
	global_position = f["hq_spawn"]
	velocity = Vector3.ZERO
	event_logged.emit("Warped to %s (%s)." % [f["hq_name"], f["name"]])


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
			_set_selected_enemy(enemy)
			auto_attacking = true
			event_logged.emit("Targeted & engaging %s." % enemy.enemy_name)
			_holding_world_click = false
		elif collider is FarrVein or collider is RefineryStation or collider is DroppedOreBag:
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
	var dist := Vector2(global_position.x - selected_enemy.global_position.x, global_position.z - selected_enemy.global_position.z).length()
	var max_dist := maxf(float(s2["range"]), 15.0 if siege_mode else 0.0)
	if dist > max_dist:
		event_logged.emit("Target too far for %s (move within %.1fm)." % [s2["name"], max_dist])
		return
	if is_mining:
		_cancel_mining("")
	_skill2_cd = float(s2["cd"])
	sprite.set_facing(selected_enemy.global_position - global_position)
	var dmg := int(round(_effective_attack_damage() * float(s2["mult"])))
	selected_enemy.receive_damage(dmg, self)
	event_logged.emit("%s hit %s for %d DMG!" % [s2["name"], selected_enemy.enemy_name, dmg])


func _cast_skill_3() -> void:
	if _skill3_cd > 0.0:
		event_logged.emit("Skill 3 on cooldown (%.1fs)." % _skill3_cd)
		return
	if is_mining:
		_cancel_mining("")
	var s3: Dictionary = _class_dict()["skill3"]
	var center := selected_enemy.global_position if (selected_enemy and not selected_enemy.is_dead) else global_position
	_skill3_cd = float(s3["cd"])
	var dmg := int(round(_effective_attack_damage() * float(s3["mult"])))
	var hits := _deal_aoe_damage(center, float(s3["radius"]), dmg)
	event_logged.emit("%s unleashed! Hit %d enemy(s) for %d AoE DMG." % [s3["name"], hits, dmg])


func _cast_signature_4() -> void:
	if faction_index == 0:
		siege_mode = not siege_mode
		if siege_mode:
			if is_mining:
				_cancel_mining("")
			_clear_click_target()
			event_logged.emit("SVELEITRE SIEGE MODE: Locked in place! Range 15m, AoE artillery shells (+15 FC Ark Debt/shot).")
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
			event_logged.emit("LEGION SIGNATURE: Mounted Dread-Titan Construct (2.2x scale, +400 HP, +90% ATK). Hits taken cost +18 FC Repair Debt!")
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

	_attack_cd = 1.05
	sprite.set_facing(to_enemy)
	var dmg := _effective_attack_damage()
	if siege_mode:
		current_debt += 15
		var hits := _deal_aoe_damage(selected_enemy.global_position, 4.0, dmg)
		event_logged.emit("Siege Artillery shell hit %d target(s) for %d DMG (+15 FC Ark Debt)." % [hits, dmg])
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
	wallet_credits += enemy.bounty_reward
	xp += 55
	var needed := level * 90
	if xp >= needed and level < 45:
		xp -= needed
		level += 1
		_recalc_vital_stats()
		current_hp = max_hp
		event_logged.emit("LEVEL UP! Reached Level %d (Cap 45 / Leader 50)." % level)
	else:
		event_logged.emit("Slain %s! Earned +%d FC Bounty & dropped Farr bag." % [enemy.enemy_name, enemy.bounty_reward])
	_emit_state()


func _effective_attack_damage() -> int:
	var c := _class_dict()
	var g := _gear_dict()
	var base_atk := (24 + (level - 1) * 5 + int(g["bonus_atk"])) * float(c["atk_mult"])
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
	var g := _gear_dict()
	var raw_hp := (280 + (level - 1) * 28 + int(g["bonus_hp"])) * float(c["hp_mult"])
	if level >= 30:
		raw_hp *= 1.2
	if is_ascended_leader:
		raw_hp *= 1.35
	if frame_mounted:
		raw_hp += 400
	max_hp = int(round(raw_hp))
	current_hp = mini(current_hp, max_hp)


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
	if target is FarrVein:
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
		event_logged.emit("Extracted +%d Unrefined Farr (+%.0f wt, worth %d FC)." % [added_units, added_weight, added_val])
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
	event_logged.emit("Refined %d Farr -> %d FC! Paid %d toward %s, +%d FC to Wallet." % [
		units_refined, total_fc, debt_paid, f["debt_name"], wallet_gain
	])


func _loot_dropped_bag(bag: DroppedOreBag) -> void:
	if current_weight >= max_weight:
		event_logged.emit("Too heavy to loot dropped Farr bag! Refine current ore first.")
		return
	unrefined_units += bag.units
	current_weight = minf(current_weight + bag.weight, max_weight)
	unrefined_value += bag.value
	event_logged.emit("Recovered %d Unrefined Farr (worth %d FC) from dropped bag!" % [bag.units, bag.value])
	bag.queue_free()


func cycle_faction() -> void:
	siege_mode = false
	frame_mounted = false
	sprite.scale = Vector3.ONE
	sprite.position.y = 0.8
	if fravashi_instance and is_instance_valid(fravashi_instance):
		fravashi_instance.visible = false

	faction_index = (faction_index + 1) % GameData.FACTIONS.size()
	_recalc_vital_stats()
	_apply_faction_tint()
	var f := _faction_dict()
	event_logged.emit("Switched Race -> %s (%s). Press [H] to warp to %s!" % [f["name"], f["debt_name"], f["hq_name"]])


func simulate_death() -> void:
	if is_mining:
		_cancel_mining("")
	auto_attacking = false
	siege_mode = false
	_clear_click_target()
	_interact_target = null
	current_hp = max_hp

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
		event_logged.emit("CHINVAT BRIDGE: You died! Dropped %d Unrefined Farr at your death spot." % drop_units)
	else:
		event_logged.emit("CHINVAT BRIDGE: Respawned at %s." % _faction_dict()["hq_name"])

	global_position = _faction_dict()["hq_spawn"]
	velocity = Vector3.ZERO


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
	var g := _gear_dict()
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

	state_updated.emit({
		"faction": f["name"],
		"debt_name": f["debt_name"],
		"job_title": _active_job_title(),
		"gear_name": g["name"],
		"level": level,
		"is_leader": is_ascended_leader,
		"hp": current_hp,
		"max_hp": max_hp,
		"atk": _effective_attack_damage(),
		"debt": current_debt,
		"wallet": wallet_credits,
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
