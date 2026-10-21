extends CanvasLayer
## Simple RF Online-style top-left camera control bar & status readout.

@export var camera_rig_path: NodePath

@onready var cam_button: Button = $TopBar/CamModeButton
@onready var proj_button: Button = $TopBar/ProjButton
@onready var reset_button: Button = $TopBar/ResetButton

var _rig: Node


func _ready() -> void:
	_rig = get_node_or_null(camera_rig_path)
	if _rig:
		_rig.mode_changed.connect(_on_mode_changed)
		cam_button.pressed.connect(func() -> void: _rig.cycle_mode())
		proj_button.pressed.connect(func() -> void: _rig.toggle_projection())
		reset_button.pressed.connect(func() -> void: _rig.reset_view())
		_rig._emit_state()


func _on_mode_changed(mode_name: String, proj_name: String) -> void:
	cam_button.text = "CAM [C]: " + mode_name
	proj_button.text = "VIEW [V]: " + proj_name
