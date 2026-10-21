extends CanvasLayer
## Phase 1 + 2/3 HUD:
## - Top-left RF Camera Mode & Projection bar
## - Top-right Faction Debt, Wallet Credits & Carry Weight readout
## - Bottom-center Mining Channel Progress bar + Status Log

@export var camera_rig_path: NodePath
@export var player_path: NodePath

@onready var cam_button: Button = $TopBar/CamModeButton
@onready var proj_button: Button = $TopBar/ProjButton
@onready var reset_button: Button = $TopBar/ResetButton
@onready var faction_button: Button = $TopBar/FactionButton
@onready var death_button: Button = $TopBar/DeathButton

@onready var economy_label: Label = $EconomyPanel/Margin/EconomyLabel
@onready var weight_bar: ProgressBar = $EconomyPanel/Margin/WeightBar
@onready var mining_panel: PanelContainer = $MiningPanel
@onready var mining_label: Label = $MiningPanel/VBox/MiningLabel
@onready var mining_bar: ProgressBar = $MiningPanel/VBox/MiningBar
@onready var log_label: Label = $LogLabel

var _rig: Node
var _player: Node


func _ready() -> void:
	_rig = get_node_or_null(camera_rig_path)
	if _rig:
		_rig.mode_changed.connect(_on_mode_changed)
		cam_button.pressed.connect(func() -> void: _rig.cycle_mode())
		proj_button.pressed.connect(func() -> void: _rig.toggle_projection())
		reset_button.pressed.connect(func() -> void: _rig.reset_view())
		_rig._emit_state()

	_player = get_node_or_null(player_path)
	if _player:
		_player.state_updated.connect(_on_player_state)
		_player.event_logged.connect(_on_event_logged)
		faction_button.pressed.connect(func() -> void: _player.cycle_faction())
		death_button.pressed.connect(func() -> void: _player.simulate_death())
		_player._emit_state()


func _on_mode_changed(mode_name: String, proj_name: String) -> void:
	cam_button.text = "CAM [C]: " + mode_name
	proj_button.text = "VIEW [V]: " + proj_name


func _on_player_state(d: Dictionary) -> void:
	faction_button.text = "Faction [F]: %s" % d["faction"]
	var wt: float = d["weight"]
	var max_wt: float = d["max_weight"]
	var overburden := " [OVERBURDENED -40% SPD]" if wt >= max_wt * 0.8 else ""
	economy_label.text = (
		"%s: %d FC   |   Wallet: %d FC\n" % [d["debt_name"], d["debt"], d["wallet"]]
		+ "Unrefined Farr: %d units (est. %d FC)\n" % [d["unrefined_units"], d["unrefined_value"]]
		+ "Carry Weight: %.0f / %.0f%s" % [wt, max_wt, overburden]
	)
	weight_bar.max_value = max_wt
	weight_bar.value = wt

	var mining: bool = d["is_mining"]
	mining_panel.visible = mining
	if mining:
		mining_label.text = "Mining %s... (Move to cancel)" % d["mining_vein_name"]
		mining_bar.value = float(d["mining_progress"]) * 100.0


func _on_event_logged(msg: String) -> void:
	log_label.text = "> " + msg
