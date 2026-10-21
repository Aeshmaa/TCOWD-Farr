class_name FravashiCompanion
extends CharacterBody3D
## Order of the Oracle signature companion (replaces RF's Animus).
## Follows the player, draws enemy aggro, attacks the player's target, and levels up independently!

signal companion_event(msg: String)

@export var move_speed := 5.8
@export var follow_distance := 2.2
@export var attack_range := 2.4
@export var attack_interval := 1.1

@onready var sprite: DirectionalSprite = $Sprite
@onready var label_3d: Label3D = $Label3D

var owner_player: Node3D = null
var assigned_target: EnemyUnit = null
var level := 1
var xp := 0
var max_hp := 180
var current_hp := 180
var attack_damage := 22

var _attack_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("friendly_combatant")
	add_to_group("fravashi_companion")
	if sprite:
		sprite.body_color = Color(1.0, 0.88, 0.42)
		sprite.accent_color = Color(1.0, 0.98, 0.8)
		sprite.texture = sprite._make_placeholder_sheet(64)
	_refresh_label()


func _physics_process(delta: float) -> void:
	if not visible or owner_player == null or not is_instance_valid(owner_player):
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	if assigned_target and (not is_instance_valid(assigned_target) or assigned_target.is_dead):
		assigned_target = null

	var wish := Vector3.ZERO
	if assigned_target:
		var to_enemy := assigned_target.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() > attack_range:
			wish = to_enemy.normalized()
		else:
			sprite.set_facing(to_enemy)
			if _attack_timer <= 0.0:
				_attack_timer = attack_interval
				assigned_target.receive_damage(attack_damage, self)
				gain_xp(12)
	else:
		var to_owner := owner_player.global_position - global_position
		to_owner.y = 0.0
		if to_owner.length() > follow_distance:
			wish = to_owner.normalized()
		else:
			current_hp = mini(max_hp, current_hp + int(ceil(max_hp * 0.04 * delta)))
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


func receive_damage(amount: int, attacker: Node3D) -> void:
	if not visible:
		return
	current_hp = maxi(0, current_hp - amount)
	if assigned_target == null and attacker is EnemyUnit:
		assigned_target = attacker as EnemyUnit
	_refresh_label()
	if current_hp <= 0:
		visible = false
		assigned_target = null
		companion_event.emit("Your Fravashi was shattered! Re-binding rite added +250 FC to Vow Debt.")
		if owner_player and "current_debt" in owner_player:
			owner_player.current_debt += 250
			owner_player.call("_emit_state")


func gain_xp(amount: int) -> void:
	xp += amount
	var needed := level * 60
	if xp >= needed:
		xp -= needed
		level += 1
		max_hp += 35
		current_hp = max_hp
		attack_damage += 6
		companion_event.emit("Fravashi ascended to Level %d! (HP %d, ATK %d)" % [level, max_hp, attack_damage])
	_refresh_label()


func _refresh_label() -> void:
	if label_3d:
		label_3d.text = "Fravashi Spirit [Lv.%d]\nHP: %d / %d" % [level, current_hp, max_hp]
