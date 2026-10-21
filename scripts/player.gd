extends CharacterBody3D
## Phase 1–4 Player Controller:
## - NavMesh click-to-move + WASD movement
## - Farr Vein mining channel + Carry Weight + Refinery Debt payment + Chinvat Bridge death drop
## - RF-style Tab-Target combat + 4-slot Skill Hotbar ([1]–[4])
## - Asymmetric Faction Signatures:
##     * Sveleitre: Titan Frame Mount (2.1x scale, repair debt on hit) + Siege Mode (locked artillery AoE)
##     * Order of the Oracle: Fravashi AI Companion (follows, tanks aggro, levels up)
##     * Legion of the Druj: Daeva Possession transformation (2.1x scale, high ATK + lifesteal, Pact Debt drain)

signal state_updated(status_data: Dictionary)
signal event_logged(message: String)

const DROPPED_BAG_SCENE := preload("res://scenes/dropped_ore_bag.tscn")
const FRAVASHI_SCENE := preload("res://scenes/fravashi_companion.tscn")

const FACTIONS := [
	{
		"name": "Sveleitre",
		"debt_name": "Ark Debt",
		"upkeep_label": "Frame & Core Upkeep",
		"color": Color(0.3, 0.9, 1.0),
		"skill2": "2: Rail Piercer",
		"skill3": "3: Siege Mode",
		"skill4": "4: Titan Frame",
	},
	{
		"name": "Order of the Oracle",
		"debt_name": "Vow Debt",
		"upkeep_label": "Relic & Fravashi Tithe",
		"color": Color(1.0, 0.85, 0.35),
		"skill2": "2: Atar Lance",
		"skill3": "3: Pillar of Atar",
		"skill4": "4: Call Fravashi",
	},
	{
		"name": "Legion of the Druj",
		"debt_name": "Pact Debt",
		"upkeep_label": "Ahriman Pact Tribute",
		"color": Color(0.95, 0.3, 0.35),
		"skill2": "2: Aka Rend",
		"skill3": "3: Druj Nova",
		"skill4": "4: Daeva Form",
	},
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

@export_group("Combat")
@export var base_max_hp := 300
@export var base_attack_damage := 28
@export var base_attack_range := 2.6
@export var attack_interval := 1.05

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: DirectionalSprite = $Sprite
@onready var marker: MeshInstance3D = $TargetMarker

var faction_index := 0
var level := 1
var xp := 0
var max_hp := 300
var current_hp := 300

var unrefined_units := 0
var current_weight := 0.0
var unrefined_value := 0
var current_debt := 5000
var wallet_credits := 0

var is_mining := false
var mining_progress := 0.0

# Combat & Faction Signature states
var selected_enemy: EnemyUnit = null
var auto_attacking := false
var siege_mode := false
var frame_mounted := false
var daeva_possessed := false
var fravashi_instance: FravashiCompanion = null

var _attack_cd := 0.0
var _skill2_cd := 0.0
var _skill3_cd := 0.0
var _pact_drain_timer := 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _has_click_target := false
var _holding_world_click := false
var _retarget_timer := 0.0
var _upkeep_timer := 0.0
var _interact_target: Node3D = null
var _mining_vein: FarrVein = null


func _ready() -> void:
	add_to_group("friendly_combatant")
	max_hp = base_max_hp
	current_hp = max_hp
	current_debt = starting_debt
	_upkeep_timer = upkeep_interval
	_apply_faction_tint()
	_connect_world_enemies()
	_emit_state()
	event_logged.emit("Ready! Click Enemy to Target/Attack, [Tab] cycle target, [1-4] Skills, or click a Farr Vein to mine.")


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

	# Out-of-combat natural HP regeneration.
	if not auto_attacking and current_hp < max_hp:
		current_hp = mini(max_hp, current_hp + int(ceil(max_hp * 0.02 * delta)))

	# Legion Daeva Possession Pact Debt drain.
	if daeva_possessed:
		_pact_drain_timer += delta
		if _pact_drain_timer >= 4.0:
			_pact_drain_timer = 0.0
			current_debt += 20
			event_logged.emit("Daeva Possession drains +20 FC into Pact Debt.")

	# Periodic faction upkeep tick.
	_upkeep_timer -= delta
	if _upkeep_timer <= 0.0:
		_upkeep_timer = upkeep_interval
		current_debt += upkeep_cost
		var f: Dictionary = FACTIONS[faction_index]
		event_logged.emit("%s accrued: +%d FC added to %s." % [f["upkeep_label"], upkeep_cost, f["debt_name"]])

	if selected_enemy and (not is_instance_valid(selected_enemy) or selected_enemy.is_dead):
		_set_selected_enemy(null)
		auto_attacking = false

	_handle_click(delta)

	var wish := Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if siege_mode:
		# Siege mode locks the player in place!
		if input != Vector2.ZERO:
			event_logged.emit("Locked in Siege Mode! Press [3] to undeploy before moving.")
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
			if selected_enemy == enemy:
				auto_attacking = true
				event_logged.emit("Engaging %s!" % enemy.enemy_name)
			else:
				_set_selected_enemy(enemy)
				auto_attacking = true
				event_logged.emit("Targeted & engaging %s." % enemy.enemy_name)
			_holding_world_click = false
		elif collider is FarrVein or collider is RefineryStation or collider is DroppedOreBag:
			var node := collider as Node3D
			if siege_mode:
				event_logged.emit("Cannot walk while in Siege Mode! Press [3] to undeploy.")
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
	var dist := Vector2(global_position.x - selected_enemy.global_position.x, global_position.z - selected_enemy.global_position.z).length()
	if dist > 8.5:
		event_logged.emit("Target too far for Skill 2 (move within 8.5m).")
		return
	if is_mining:
		_cancel_mining("")
	_skill2_cd = 4.0
	sprite.set_facing(selected_enemy.global_position - global_position)
	var dmg := int(round(_effective_attack_damage() * 2.3))
	selected_enemy.receive_damage(dmg, self)
	if daeva_possessed:
		current_hp = mini(max_hp, current_hp + int(dmg * 0.35))
	var f: Dictionary = FACTIONS[faction_index]
	event_logged.emit("%s hit %s for %d DMG!" % [f["skill2"], selected_enemy.enemy_name, dmg])


func _cast_skill_3() -> void:
	if faction_index == 0:
		# Sveleitre: Toggle Siege Mode!
		siege_mode = not siege_mode
		if siege_mode:
			if is_mining:
				_cancel_mining("")
			_clear_click_target()
			event_logged.emit("SIEGE MODE DEPLOYED: Locked in place! Range 14m, AoE splash, +15 FC ammo debt per shot.")
		else:
			event_logged.emit("Siege Mode retracted. Mobile again.")
		return

	# Order (Pillar of Atar) / Legion (Druj Nova) AoE burst:
	if _skill3_cd > 0.0:
		event_logged.emit("Skill 3 on cooldown (%.1fs)." % _skill3_cd)
		return
	var center := selected_enemy.global_position if (selected_enemy and not selected_enemy.is_dead) else global_position
	_skill3_cd = 6.0
	var dmg := int(round(_effective_attack_damage() * 1.9))
	var hits := _deal_aoe_damage(center, 4.8, dmg)
	var f: Dictionary = FACTIONS[faction_index]
	event_logged.emit("%s unleashed! Hit %d enemy(s) for %d AoE DMG." % [f["skill3"], hits, dmg])


func _cast_signature_4() -> void:
	if faction_index == 0:
		# Sveleitre: Mount / Dismount Titan Frame
		frame_mounted = not frame_mounted
		_recalc_vital_stats()
		if frame_mounted:
			sprite.scale = Vector3(2.1, 2.1, 2.1)
			sprite.position.y = 1.65
			event_logged.emit("MOUNTED TITAN FRAME (2.1x scale, +300 HP, +80% ATK). Hits taken add Frame Repair Debt!")
		else:
			sprite.scale = Vector3.ONE
			sprite.position.y = 0.8
			event_logged.emit("Dismounted Titan Frame.")
	elif faction_index == 1:
		# Order: Summon / Dismiss Fravashi Companion
		if fravashi_instance == null or not is_instance_valid(fravashi_instance):
			fravashi_instance = FRAVASHI_SCENE.instantiate() as FravashiCompanion
			get_parent().add_child(fravashi_instance)
			fravashi_instance.owner_player = self
			fravashi_instance.companion_event.connect(func(msg: String) -> void: event_logged.emit(msg))
			fravashi_instance.global_position = global_position + Vector3(1.5, 0.0, 1.0)
			fravashi_instance.assigned_target = selected_enemy
			event_logged.emit("Summoned Fravashi Guardian Spirit (Lv.%d)! It draws aggro and levels up." % fravashi_instance.level)
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
		# Legion: Daeva Possession transformation
		daeva_possessed = not daeva_possessed
		_recalc_vital_stats()
		if daeva_possessed:
			sprite.scale = Vector3(2.1, 2.1, 2.1)
			sprite.position.y = 1.65
			event_logged.emit("DAEVA POSSESSION ACTIVE (2.1x scale, +110% ATK, 35% Lifesteal, drains Pact Debt)!")
		else:
			sprite.scale = Vector3.ONE
			sprite.position.y = 0.8
			event_logged.emit("Ended Daeva Possession.")


func _process_auto_attack() -> void:
	if selected_enemy == null or selected_enemy.is_dead:
		auto_attacking = false
		return
	var to_enemy := selected_enemy.global_position - global_position
	to_enemy.y = 0.0
	if to_enemy.length() > _effective_attack_range() + 0.25:
		return
	if _attack_cd > 0.0:
		return

	_attack_cd = attack_interval
	sprite.set_facing(to_enemy)
	var dmg := _effective_attack_damage()
	if siege_mode:
		current_debt += 15
		var hits := _deal_aoe_damage(selected_enemy.global_position, 3.8, dmg)
		event_logged.emit("Siege Artillery shell hit %d target(s) for %d DMG (+15 FC ammo debt)." % [hits, dmg])
	else:
		selected_enemy.receive_damage(dmg, self)
		if daeva_possessed:
			current_hp = mini(max_hp, current_hp + int(dmg * 0.35))


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
		# Mounting a Titan Frame costs repair debt when hit!
		current_debt += 12
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
	xp += 45
	var needed := level * 100
	if xp >= needed and level < 45:
		xp -= needed
		level += 1
		base_max_hp += 25
		base_attack_damage += 5
		_recalc_vital_stats()
		current_hp = max_hp
		event_logged.emit("LEVEL UP! Reached Level %d (Cap 45 / Leader 50)." % level)
	else:
		event_logged.emit("Slain %s! Earned +%d FC Bounty & dropped Farr bag." % [enemy.enemy_name, enemy.bounty_reward])
	_emit_state()


func _effective_attack_damage() -> int:
	var mult := 1.0
	if frame_mounted:
		mult *= 1.8
	if daeva_possessed:
		mult *= 2.1
	if siege_mode:
		mult *= 1.65
	return int(round(base_attack_damage * mult))


func _effective_attack_range() -> float:
	if siege_mode:
		return 14.0
	if frame_mounted or daeva_possessed:
		return 3.4
	return base_attack_range


func _recalc_vital_stats() -> void:
	var bonus_hp := 300 if frame_mounted else (150 if daeva_possessed else 0)
	max_hp = base_max_hp + bonus_hp
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
			event_logged.emit("Carry weight full (%.0f / %.0f)! Extract at the Refinery first." % [current_weight, max_weight])
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

	var f: Dictionary = FACTIONS[faction_index]
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
	# Reset active signature states when switching faction skin.
	siege_mode = false
	frame_mounted = false
	daeva_possessed = false
	sprite.scale = Vector3.ONE
	sprite.position.y = 0.8
	if fravashi_instance and is_instance_valid(fravashi_instance):
		fravashi_instance.visible = false

	faction_index = (faction_index + 1) % FACTIONS.size()
	_recalc_vital_stats()
	_apply_faction_tint()
	var f: Dictionary = FACTIONS[faction_index]
	event_logged.emit("Switched Faction -> %s (%s). Press [4] for signature ability!" % [f["name"], f["debt_name"]])


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
		event_logged.emit("CHINVAT BRIDGE: Respawned at Base Refinery.")

	global_position = respawn_point
	velocity = Vector3.ZERO


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
	var target_name := ""
	var target_hp := 0
	var target_max_hp := 1
	if selected_enemy and is_instance_valid(selected_enemy) and not selected_enemy.is_dead:
		target_name = "Lv.%d %s" % [selected_enemy.level, selected_enemy.enemy_name]
		target_hp = selected_enemy.current_hp
		target_max_hp = selected_enemy.max_hp

	state_updated.emit({
		"faction": f["name"],
		"debt_name": f["debt_name"],
		"level": level,
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
		"siege_mode": siege_mode,
		"frame_mounted": frame_mounted,
		"daeva_possessed": daeva_possessed,
		"skill2_label": f["skill2"],
		"skill3_label": f["skill3"],
		"skill4_label": f["skill4"],
		"skill2_cd": _skill2_cd,
		"skill3_cd": _skill3_cd,
	})
