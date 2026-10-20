extends Node3D
## Isometric orthographic camera rig.
## The rig follows the target; the child Camera3D sits `distance` units back
## along the rig's local +Z, so pitch/yaw of the rig = camera angle.
## Mouse wheel zooms by changing the orthographic size.

@export var target_path: NodePath
@export_range(-89.0, -5.0) var pitch_degrees := -30.0
@export var yaw_degrees := 45.0
@export var distance := 40.0
@export var follow_speed := 8.0
@export var zoom_min := 8.0
@export var zoom_max := 40.0
@export var zoom_step := 2.0

@onready var camera: Camera3D = $Camera3D

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0.0, 0.0, distance)
	if _target:
		global_position = _target.global_position


func _process(delta: float) -> void:
	if _target:
		# Frame-rate independent smoothing.
		var t := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(_target.global_position, t)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera.size = clampf(camera.size - zoom_step, zoom_min, zoom_max)
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera.size = clampf(camera.size + zoom_step, zoom_min, zoom_max)
