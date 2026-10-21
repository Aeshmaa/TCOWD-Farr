extends CharacterBody3D
## Phase 1 + Phase 2/3 Player Controller:
## - NavMesh click-to-move + WASD movement
## - Click Farr Veins to approach & channel mining (locks in place; moving cancels)
## - Carry weight system (Overburdened >80% slows movement; Full at 100% stops mining)
## - Click Refinery Station to extract unrefined Farr, pay down Faction Debt & earn Credits
## - Chinvat Bridge death penalty test ([K]): drops 50% of unrefined Farr in a lootable bag

signal state_updated(status_data: Dictionary)
signal event_logged(message: String)

const DROPPED_BAG_SCENE := preload("res://scenes/dropped_ore_bag.tscn")

const FACTIONS := [
	{"name": "Sveleitre", "debt_name": "Ark Debt", "upkeep_label": "Frame & Core Upkeep", "color": Color(0.3, 0.9, 1.0)},
	{"name": "Order of the Oracle", "debt_name": "Vow Debt", "upkeep_label": "Relic & Fravashi Tithe", "color": Color(1.0, 0.85, 0.35)},
	{"name": "Legion of the Druj", "debt_name": "Pact Debt", "upkeep_label": "Ahriman Pact Tribute", "color": Color(0.95, 0.3, 0.35)},
]

@export var base_move_speed := 5.5
@export var overburdened_speed_mult := 0.6
@export var acceleration := 30.0
@export var hold_retarget_interval := 0.1
@export var max_weight := 100.0
@export var starting_debt := 5000
@export var upkeep_interval := 25.0
@export var upkeep_cost := 75
@export var respawn_point := Vector3(0.0, 0.1, 8.0)

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: DirectionalSprite = $Sprite
@onready var marker: MeshInstance3D = $TargetMarker

var faction_index := 0
var unrefined_units := 0
var current_weight := 0.0
var unrefined_value := 0
var current_debt := 5000
var wallet_credits := 0

var is_mining := false
var mining_progress := 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _has_click_target := false
var _holding_world_click := false
var _retarget_timer := 0.0
var _upkeep_timer := 0.0
var _interact_target: Node3D = null
var _mining_vein: FarrVein = null


func _ready() -> void:
	current_debt = starting_debt
	_upkeep_timer = upkeep_interval
	_apply_faction_tint()
	_emit_state()
	event_logged.emit("Entered the Var. Click a glowing Farr Vein to mine, or the blue Refinery to extract.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_click"):
		_holding_world_click = true
		_retarget_timer = 0.0
	elif event.is_action_released("move_click"):
		_holding_world_click = false
	elif event.is_action_pressed("faction_cycle"):
		cycle_faction()
	elif event.is_action_pressed("simulate_death"):
		simulate_death()


func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("move_click"):
		_holding_world_click = false

	# Periodic faction upkeep tick (debt pressure).
	_upkeep_timer -= delta
	if _upkeep_timer <= 0.0:
		_upkeep_timer = upkeep_interval
		current_debt += upkeep_cost
		var f: Dictionary = FACTIONS[faction_index]
		event_logged.emit("%s accrued: +%d FC added to %s." % [f["upkeep_label"], upkeep_cost, f["debt_name"]])
		_emit_state()

	_handle_click(delta)

	var wish := Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input != Vector2.ZERO:
		if is_mining:
			_cancel_mining("Mining interrupted by movement.")
		_interact_target = null
		_clear_click_target()
		wish = _camera_relative(input)
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


func _handle_click(delta: float) -> void:
	_retarget_timer -= delta
	if _holding_world_click and _retarget_timer <= 0.0:
		_retarget_timer = hold_retarget_interval
		var hit_info := _mouse_raycast(get_viewport().get_mouse_position())
		if hit_info.is_empty():
			return
		var collider: Object = hit_info.get("collider")
		var pos: Vector3 = hit_info.get("position")

		if collider is FarrVein or collider is RefineryStation or collider is DroppedOreBag:
			var node := collider as Node3D
			# Avoid restarting mining if already mining this exact vein.
			if is_mining and _mining_vein == node:
				return
			if is_mining:
				_cancel_mining("Switched target.")
			_interact_target = node
			_set_click_target(node.global_position)
			_holding_world_click = false
		else:
			if is_mining:
				_cancel_mining("Mining canceled by moving away.")
			_interact_target = null
			_set_click_target(pos)


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
			event_logged.emit("Carry weight full (%.0f / %.0f)! Extract at the Refinery first." % [current_weight, max_weight])
			return
		is_mining = true
		_mining_vein = vein
		mining_progress = 0.0
		event_logged.emit("Mining %s... (locked in place)" % vein.vein_name)
		_emit_state()
	elif target is RefineryStation:
		_refine_and_pay_debt()
	elif target is DroppedOreBag:
		_loot_dropped_bag(target as DroppedOreBag)


func _process_mining(delta: float) -> void:
	if _mining_vein == null or not is_instance_valid(_mining_vein) or not _mining_vein.can_mine():
		_cancel_mining("Vein depleted.")
		return
	if current_weight >= max_weight:
		_cancel_mining("Inventory weight limit reached! Return to the Refinery.")
		return

	mining_progress += delta / max(_mining_vein.mine_duration, 0.2)
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
			_cancel_mining("Bag hits 100%% weight capacity! Head to the Refinery.")
			return
	_emit_state()


func _cancel_mining(reason: String) -> void:
	is_mining = false
	_mining_vein = null
	mining_progress = 0.0
	if reason != "":
		event_logged.emit(reason)
	_emit_state()


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
		# 70% of refined ore automatically garnishes toward Faction Debt, 30% to wallet.
		debt_paid = mini(current_debt, int(ceil(total_fc * 0.7)))
		current_debt -= debt_paid
	var wallet_gain := total_fc - debt_paid
	wallet_credits += wallet_gain

	var f: Dictionary = FACTIONS[faction_index]
	event_logged.emit("Refined %d Farr -> %d FC! Paid %d toward %s, +%d FC to Wallet." % [
		units_refined, total_fc, debt_paid, f["debt_name"], wallet_gain
	])
	_emit_state()


func _loot_dropped_bag(bag: DroppedOreBag) -> void:
	if current_weight >= max_weight:
		event_logged.emit("Too heavy to loot dropped Farr bag! Refine current ore first.")
		return
	unrefined_units += bag.units
	current_weight = minf(current_weight + bag.weight, max_weight)
	unrefined_value += bag.value
	event_logged.emit("Recovered %d Unrefined Farr (worth %d FC) from dropped bag!" % [bag.units, bag.value])
	bag.queue_free()
	_emit_state()


func cycle_faction() -> void:
	faction_index = (faction_index + 1) % FACTIONS.size()
	_apply_faction_tint()
	var f: Dictionary = FACTIONS[faction_index]
	event_logged.emit("Switched Faction Skin -> %s (%s)." % [f["name"], f["debt_name"]])
	_emit_state()


func simulate_death() -> void:
	if is_mining:
		_cancel_mining("")
	_clear_click_target()
	_interact_target = null

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
		event_logged.emit("CHINVAT BRIDGE: Respawned at Base Refinery (no unrefined ore carried).")

	global_position = respawn_point
	velocity = Vector3.ZERO
	_emit_state()


func _apply_faction_tint() -> void:
	if sprite:
		var f: Dictionary = FACTIONS[faction_index]
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
	var f: Dictionary = FACTIONS[faction_index]
	state_updated.emit({
		"faction": f["name"],
		"debt_name": f["debt_name"],
		"debt": current_debt,
		"wallet": wallet_credits,
		"unrefined_units": unrefined_units,
		"unrefined_value": unrefined_value,
		"weight": current_weight,
		"max_weight": max_weight,
		"is_mining": is_mining,
		"mining_progress": mining_progress,
		"mining_vein_name": _mining_vein.vein_name if (_mining_vein and is_instance_valid(_mining_vein)) else "",
	})
