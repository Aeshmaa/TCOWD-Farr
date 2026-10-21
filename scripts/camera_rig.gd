extends Node3D
## RF Online-style multi-mode camera rig (Desktop Mouse + MacBook Trackpad/Keyboard support).
##
## MacBook Trackpad & Keyboard Controls:
##   - Hold [Space] + slide 1 finger on trackpad: 360° Free Orbit & Tilt (no click needed!)
##   - [Q] / [E] keys: Rotate camera 360° Left / Right
##   - [T] / [G] keys: Tilt camera Up / Down
##   - [Z] / [X] or [=] / [-] keys: Smooth Zoom In / Out
##   - Trackpad Pinch-to-Zoom or Two-Finger Scroll: Smooth Zoom In / Out
##   - Desktop Mouse: Hold Right/Middle-Click + Drag to Orbit, Scroll Wheel to Zoom

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
@export var key_orbit_speed := 110.0
@export var key_tilt_speed := 55.0
@export var chase_turn_speed := 4.5

@export_group("Zoom & Follow")
@export var follow_speed := 10.0
## Zoom level normalized (0.0 = closest, 1.0 = farthest war overview).
@export_range(0.0, 1.0) var zoom_t := 0.35
@export var zoom_step := 0.07
@export var key_zoom_speed := 0.65
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
var sensitivity_mult := 1.0


func _ready() -> void:
	add_to_group("camera_rig")
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

	# Keyboard 360° orbit ([Q]/[E]) and tilt ([T]/[G]) for MacBook convenience.
	if current_mode != CamMode.ISO_LOCKED:
		var orbit_axis := Input.get_axis("cam_orbit_left", "cam_orbit_right")
		if orbit_axis != 0.0:
			_yaw_deg = wrapf(_yaw_deg - orbit_axis * key_orbit_speed * sensitivity_mult * delta, -180.0, 180.0)
		var tilt_axis := Input.get_axis("cam_tilt_down", "cam_tilt_up")
		if tilt_axis != 0.0:
			_pitch_deg = clampf(_pitch_deg + tilt_axis * key_tilt_speed * sensitivity_mult * delta, min_pitch, max_pitch)

	# Keyboard zoom ([Z]/[X] or [=]/[-]).
	var zoom_axis := Input.get_axis("cam_zoom_in", "cam_zoom_out")
	if zoom_axis != 0.0:
		_target_zoom_t = clampf(_target_zoom_t + zoom_axis * key_zoom_speed * delta, 0.0, 1.0)

	# Position follow (disabled in STAY_STILL mode so camera stays anchored in place).
	if _target and current_mode != CamMode.STAY_STILL:
		var desired_pos := _target.global_position + Vector3(0.0, 0.9, 0.0)
		var t := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(desired_pos, t)

	# Auto-behind yaw in CHASE_BEHIND mode when not manually rotating.
	if current_mode == CamMode.CHASE_BEHIND and not _rotating and _target:
		var vel := Vector3.ZERO
		if _target is CharacterBody3D:
			vel = (_target as CharacterBody3D).velocity
			vel.y = 0.0
		if vel.length_squared() > 0.2:
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
		_yaw_deg = wrapf(_yaw_deg - mm.relative.x * mouse_sensitivity * sensitivity_mult, -180.0, 180.0)
		_pitch_deg = clampf(_pitch_deg - mm.relative.y * mouse_sensitivity * sensitivity_mult, min_pitch, max_pitch)

	# MacBook Trackpad Pinch-to-Zoom gesture
	var mag := event as InputEventMagnifyGesture
	if mag:
		_target_zoom_t = clampf(_target_zoom_t - (mag.factor - 1.0) * 0.8, 0.0, 1.0)

	# MacBook Trackpad Two-Finger Scroll/Pan gesture
	var pan := event as InputEventPanGesture
	if pan:
		_target_zoom_t = clampf(_target_zoom_t + pan.delta.y * 0.03, 0.0, 1.0)
		if current_mode != CamMode.ISO_LOCKED and absf(pan.delta.x) > 0.01:
			_yaw_deg = wrapf(_yaw_deg - pan.delta.x * 2.2, -180.0, 180.0)

	# Standard Mouse Wheel
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
