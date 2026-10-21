extends Node3D
## RF Online-style multi-mode camera rig.
##
## Modes (cycle with [C] key or HUD [CAM] button):
##   1. ORBIT_360    - Follows player; hold Right/Middle mouse to orbit 360° & tilt; scroll to zoom close or far.
##   2. CHASE_BEHIND - Follows player and smoothly swings behind the player's facing direction when moving.
##   3. ISO_LOCKED   - Locked tactical angle (-32° pitch, 45° yaw); scroll to zoom.
##   4. STAY_STILL   - Detaches pivot in place so the camera stays still while the player walks around (can still orbit 360° & zoom).
##
## Projection (toggle with [V] key or HUD [PROJ] button):
##   - PERSPECTIVE (RF Online style: close over-the-shoulder zoom to huge war-zone overview)
##   - ORTHOGONAL  (classic flat 2.5D tactical view)

signal mode_changed(mode_name: String, projection_name: String)

enum CamMode {
	ORBIT_360,
	CHASE_BEHIND,
	ISO_LOCKED,
	STAY_STILL,
}

const MODE_NAMES := {
	CamMode.ORBIT_360: "1: 360° Free Orbit",
	CamMode.CHASE_BEHIND: "2: Chase Behind",
	CamMode.ISO_LOCKED: "3: Isometric Lock",
	CamMode.STAY_STILL: "4: Stay Still (Watch)",
}

@export var target_path: NodePath
@export var current_mode: CamMode = CamMode.ORBIT_360
@export var use_perspective := true

@export_group("Angles")
@export var default_pitch := -32.0
@export var default_yaw := 45.0
@export var min_pitch := -82.0
@export var max_pitch := -10.0
@export var mouse_sensitivity := 0.28
@export var chase_turn_speed := 4.5

@export_group("Zoom & Follow")
@export var follow_speed := 10.0
## Zoom level normalized (0.0 = closest, 1.0 = farthest war overview).
@export_range(0.0, 1.0) var zoom_t := 0.35
@export var zoom_step := 0.07
@export var zoom_smooth := 12.0
@export var persp_dist_min := 4.5
@export var persp_dist_max := 55.0
@export var ortho_size_min := 6.0
@export var ortho_size_max := 48.0

@onready var camera: Camera3D = $Camera3D

var _target: Node3D
var _pitch_deg := -32.0
var _yaw_deg := 45.0
var _target_zoom_t := 0.35
var _rotating := false


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_pitch_deg = default_pitch
	_yaw_deg = default_yaw
	_target_zoom_t = zoom_t
	if _target:
		global_position = _target.global_position + Vector3(0.0, 0.9, 0.0)
	_apply_projection(true)
	_emit_state()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("cam_mode_cycle"):
		cycle_mode()
	if Input.is_action_just_pressed("cam_projection_toggle"):
		toggle_projection()
	if Input.is_action_just_pressed("cam_reset"):
		reset_view()

	# Position follow (disabled in STAY_STILL mode so camera stays anchored in place).
	if _target and current_mode != CamMode.STAY_STILL:
		var desired_pos := _target.global_position + Vector3(0.0, 0.9, 0.0)
		var t := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(desired_pos, t)

	# Auto-behind yaw in CHASE_BEHIND mode when not manually dragging the mouse.
	if current_mode == CamMode.CHASE_BEHIND and not _rotating and _target:
		var vel := Vector3.ZERO
		if _target is CharacterBody3D:
			vel = (_target as CharacterBody3D).velocity
			vel.y = 0.0
		if vel.length_squared() > 0.2:
			# Camera looks along -Z, so to look in `vel` direction, yaw = atan2(-vel.x, -vel.z).
			var desired_yaw := rad_to_deg(atan2(-vel.x, -vel.z))
			var t_yaw := 1.0 - exp(-chase_turn_speed * delta)
			_yaw_deg = rad_to_deg(lerp_angle(deg_to_rad(_yaw_deg), deg_to_rad(desired_yaw), t_yaw))

	if current_mode == CamMode.ISO_LOCKED:
		var t_iso := 1.0 - exp(-8.0 * delta)
		_pitch_deg = lerpf(_pitch_deg, default_pitch, t_iso)
		_yaw_deg = rad_to_deg(lerp_angle(deg_to_rad(_yaw_deg), deg_to_rad(default_yaw), t_iso))

	rotation_degrees = Vector3(_pitch_deg, _yaw_deg, 0.0)

	# Smooth zoom interpolation.
	var zt := 1.0 - exp(-zoom_smooth * delta)
	zoom_t = lerpf(zoom_t, _target_zoom_t, zt)
	_apply_zoom()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_rotate"):
		_rotating = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_released("cam_rotate"):
		_rotating = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var mm := event as InputEventMouseMotion
	if mm and _rotating and current_mode != CamMode.ISO_LOCKED:
		_yaw_deg = wrapf(_yaw_deg - mm.relative.x * mouse_sensitivity, -180.0, 180.0)
		_pitch_deg = clampf(_pitch_deg - mm.relative.y * mouse_sensitivity, min_pitch, max_pitch)

	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom_t = clampf(_target_zoom_t - zoom_step, 0.0, 1.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom_t = clampf(_target_zoom_t + zoom_step, 0.0, 1.0)


func cycle_mode() -> void:
	current_mode = ((int(current_mode) + 1) % CamMode.size()) as CamMode
	_emit_state()


func toggle_projection() -> void:
	use_perspective = not use_perspective
	_apply_projection(false)
	_emit_state()


func reset_view() -> void:
	_pitch_deg = default_pitch
	_yaw_deg = default_yaw
	_target_zoom_t = 0.35
	if _target:
		global_position = _target.global_position + Vector3(0.0, 0.9, 0.0)


func _apply_projection(_immediate: bool) -> void:
	if use_perspective:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 50.0
	else:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_apply_zoom()


func _apply_zoom() -> void:
	if use_perspective:
		var dist := lerpf(persp_dist_min, persp_dist_max, zoom_t * zoom_t)
		camera.position = Vector3(0.0, 0.0, dist)
	else:
		camera.position = Vector3(0.0, 0.0, 60.0)
		camera.size = lerpf(ortho_size_min, ortho_size_max, zoom_t)


func _emit_state() -> void:
	var proj_str := "Perspective (3D Depth)" if use_perspective else "Orthographic (2.5D Flat)"
	mode_changed.emit(MODE_NAMES[current_mode], proj_str)
