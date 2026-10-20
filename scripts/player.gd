extends CharacterBody3D
## Phase 1 player controller.
## - Left click (or hold) to move along the navmesh, RF Online style.
## - WASD / arrow keys move relative to the camera and cancel the click target.

@export var move_speed := 5.0
@export var acceleration := 30.0
## How often (seconds) to re-target while the mouse button is held.
@export var hold_retarget_interval := 0.1

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: DirectionalSprite = $Sprite
@onready var marker: MeshInstance3D = $TargetMarker

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _has_click_target := false
var _retarget_timer := 0.0


func _physics_process(delta: float) -> void:
	_handle_click(delta)

	var wish := Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input != Vector2.ZERO:
		_clear_click_target()
		wish = _camera_relative(input)
	elif _has_click_target:
		if agent.is_navigation_finished():
			_clear_click_target()
		else:
			wish = agent.get_next_path_position() - global_position
			wish.y = 0.0
			wish = wish.normalized()

	var target_vel := wish * move_speed
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
	if Input.is_action_just_pressed("move_click"):
		_retarget_timer = 0.0
	if Input.is_action_pressed("move_click") and _retarget_timer <= 0.0:
		_retarget_timer = hold_retarget_interval
		var hit: Variant = _mouse_to_world(get_viewport().get_mouse_position())
		if hit != null:
			_set_click_target(hit)


func _set_click_target(pos: Vector3) -> void:
	agent.target_position = pos
	_has_click_target = true
	marker.global_position = pos + Vector3(0.0, 0.05, 0.0)
	marker.visible = true


func _clear_click_target() -> void:
	_has_click_target = false
	marker.visible = false


## Raycast from the camera through the mouse into the world. Returns Vector3 or null.
func _mouse_to_world(screen_pos: Vector2) -> Variant:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit["position"]


## Converts a 2D input vector into a world direction on the ground plane,
## so "W" always means "up on screen" regardless of camera yaw.
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
