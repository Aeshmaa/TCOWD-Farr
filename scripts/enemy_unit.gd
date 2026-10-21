class_name EnemyUnit
extends CharacterBody3D
## Hostile AI unit (Corrupted Daeva / Rival Miner / Rogue Automaton) that guards Farr veins.
## Supports tab-targeting, aggro pursuit, melee/ranged attacks, respawn, and Farr loot drops.

signal died(enemy: EnemyUnit, killer: Node3D)

const DROPPED_BAG_SCENE := preload("res://scenes/dropped_ore_bag.tscn")
const FLOATING_TEXT := preload("res://scripts/floating_combat_text.gd")
const COMBAT_VFX := preload("res://scripts/combat_vfx.gd")

@export var enemy_name := "Rival Strip-Miner"
@export var level := 12
@export var max_hp := 240
@export var attack_damage := 18
@export var attack_range := 2.3
@export var attack_interval := 1.5
@export var aggro_radius := 7.0
@export var leash_radius := 15.0
@export var move_speed := 3.6
@export var bounty_reward := 150
@export var drop_farr_units := 15
@export var drop_farr_value := 300
@export var respawn_seconds := 14.0
@export var body_color := Color(0.68, 0.22, 0.25)
@export var accent_color := Color(1.0, 0.4, 0.2)

@onready var sprite: DirectionalSprite = $Sprite
@onready var label_3d: Label3D = $Label3D
@onready var select_ring: MeshInstance3D = $SelectRing

var current_hp := 240
var is_dead := false
var home_position := Vector3.ZERO
var aggro_target: Node3D = null

var _attack_timer := 0.0
var _respawn_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("enemy_unit")
	home_position = global_position
	current_hp = max_hp
	if sprite:
		sprite.body_color = body_color
		sprite.accent_color = accent_color
		sprite.texture = sprite._make_placeholder_sheet(64)
	_refresh_label()


func _physics_process(delta: float) -> void:
	if is_dead:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	# Check aggro target validity or scan for nearby player/companion.
	if aggro_target and (not is_instance_valid(aggro_target) or not aggro_target.visible):
		aggro_target = null

	var dist_from_home := Vector2(global_position.x - home_position.x, global_position.z - home_position.z).length()
	if dist_from_home > leash_radius:
		aggro_target = null

	if aggro_target == null:
		aggro_target = _find_target_in_aggro()

	var wish := Vector3.ZERO
	if aggro_target:
		var to_target := aggro_target.global_position - global_position
		to_target.y = 0.0
		var dist := to_target.length()
		if dist > attack_range:
			wish = to_target.normalized()
		else:
			sprite.set_facing(to_target)
			if _attack_timer <= 0.0:
				_attack_timer = attack_interval
				if attack_range > 3.5:
					COMBAT_VFX.spawn_projectile(self, global_position + Vector3(0.0, 1.3, 0.0), aggro_target, accent_color, true, level >= 45)
				else:
					COMBAT_VFX.spawn_melee_slash(self, global_position, aggro_target.global_position, accent_color, 1.5 if level >= 45 else 0.9)
				if aggro_target.has_method("receive_damage"):
					aggro_target.call("receive_damage", attack_damage, self)
	elif dist_from_home > 0.6:
		var to_home := home_position - global_position
		to_home.y = 0.0
		wish = to_home.normalized()
		current_hp = mini(max_hp, current_hp + int(ceil(max_hp * 0.05 * delta)))
		_refresh_label()

	velocity.x = wish.x * move_speed
	velocity.z = wish.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()

	if wish != Vector3.ZERO:
		sprite.set_facing(wish)


func set_selected(selected: bool) -> void:
	if select_ring:
		select_ring.visible = selected and not is_dead


func receive_damage(amount: int, attacker: Node3D, is_skill: bool = false, hit_tag: String = "") -> void:
	if is_dead:
		return
	current_hp = maxi(0, current_hp - amount)
	if attacker and is_instance_valid(attacker):
		aggro_target = attacker

	var suffix := (" " + hit_tag) if hit_tag != "" else (" SKILL!" if is_skill else " DMG")
	var num_col := Color(1.0, 0.58, 0.16) if is_skill else Color(1.0, 0.94, 0.52)
	var f_size := 42 if is_skill else 34
	FLOATING_TEXT.spawn(
		self,
		global_position + Vector3(0.0, 2.25, 0.0),
		"-%d%s" % [amount, suffix],
		num_col,
		f_size,
		1.85 if is_skill else 1.55
	)

	_refresh_label()
	if current_hp <= 0:
		_die(attacker)


func _die(killer: Node3D) -> void:
	is_dead = true
	aggro_target = null
	_respawn_timer = respawn_seconds
	select_ring.visible = false
	sprite.visible = false
	$CollisionShape3D.disabled = true
	label_3d.text = "%s\n[Respawning...]" % enemy_name
	label_3d.modulate = Color(0.55, 0.55, 0.55)

	if drop_farr_units > 0 and get_parent():
		var bag := DROPPED_BAG_SCENE.instantiate() as DroppedOreBag
		get_parent().add_child(bag)
		bag.global_position = Vector3(global_position.x, 0.0, global_position.z)
		bag.setup(drop_farr_units, drop_farr_units * 2.0, drop_farr_value)

	died.emit(self, killer)


func _respawn() -> void:
	is_dead = false
	global_position = home_position
	current_hp = max_hp
	sprite.visible = true
	$CollisionShape3D.disabled = false
	_refresh_label()


func _find_target_in_aggro() -> Node3D:
	# Prefer Fravashi companion if it is closer (draws aggro for Order players!).
	var candidates := get_tree().get_nodes_in_group("friendly_combatant")
	var best: Node3D = null
	var best_dist := aggro_radius
	for c in candidates:
		var node := c as Node3D
		if node == null or not node.visible:
			continue
		var d := Vector2(global_position.x - node.global_position.x, global_position.z - node.global_position.z).length()
		# Fravashi has aggro priority bonus.
		if node.is_in_group("fravashi_companion"):
			d *= 0.65
		if d <= best_dist:
			best_dist = d
			best = node
	return best


func _refresh_label() -> void:
	if label_3d and not is_dead:
		label_3d.modulate = Color(1.0, 0.55, 0.5)
		label_3d.text = "Lv.%d %s\nHP: %d / %d" % [level, enemy_name, current_hp, max_hp]
