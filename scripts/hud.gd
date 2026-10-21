extends CanvasLayer
## Data-driven HUD supporting:
## - Camera Mode / View Switcher
## - Race ([F]), Base Class ([J]), Lv.30 Job Branch ([B]), Gear Upgrade ([U]), Level Boost ([L]), HQ Warp ([H])
## - Enemy Target Bar + 4-Slot Skill Hotbar

@export var camera_rig_path: NodePath
@export var player_path: NodePath

@onready var cam_button: Button = $TopBar/CamModeButton
@onready var proj_button: Button = $TopBar/ProjButton
@onready var faction_button: Button = $TopBar/FactionButton
@onready var class_button: Button = $TopBar/ClassButton
@onready var branch_button: Button = $TopBar/BranchButton
@onready var gear_button: Button = $TopBar/GearButton
@onready var level_button: Button = $TopBar/LevelButton
@onready var hq_button: Button = $TopBar/HqButton

@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_label: Label = $TargetPanel/VBox/TargetLabel
@onready var target_bar: ProgressBar = $TargetPanel/VBox/TargetBar

@onready var economy_label: Label = $EconomyPanel/Margin/EconomyLabel
@onready var hp_bar: ProgressBar = $EconomyPanel/Margin/HpBar
@onready var weight_bar: ProgressBar = $EconomyPanel/Margin/WeightBar

@onready var skill1_btn: Button = $SkillBar/Skill1
@onready var skill2_btn: Button = $SkillBar/Skill2
@onready var skill3_btn: Button = $SkillBar/Skill3
@onready var skill4_btn: Button = $SkillBar/Skill4

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
		_rig._emit_state()

	_player = get_node_or_null(player_path)
	if _player:
		_player.state_updated.connect(_on_player_state)
		_player.event_logged.connect(_on_event_logged)
		faction_button.pressed.connect(func() -> void: _player.cycle_faction())
		class_button.pressed.connect(func() -> void: _player.cycle_class())
		branch_button.pressed.connect(func() -> void: _player.toggle_job_branch())
		gear_button.pressed.connect(func() -> void: _player.upgrade_equipment())
		level_button.pressed.connect(func() -> void: _player.dev_boost_level())
		hq_button.pressed.connect(func() -> void: _player.teleport_to_hq())
		skill1_btn.pressed.connect(func() -> void: _player.use_skill(1))
		skill2_btn.pressed.connect(func() -> void: _player.use_skill(2))
		skill3_btn.pressed.connect(func() -> void: _player.use_skill(3))
		skill4_btn.pressed.connect(func() -> void: _player.use_skill(4))
		_player._emit_state()


func _on_mode_changed(mode_name: String, proj_name: String) -> void:
	cam_button.text = "CAM [C]: " + mode_name
	proj_button.text = "VIEW [V]: " + proj_name


func _on_player_state(d: Dictionary) -> void:
	faction_button.text = "Race [F]: %s" % d["faction"]
	class_button.text = "Class [J]: %s" % d["job_title"]
	var wt: float = d["weight"]
	var max_wt: float = d["max_weight"]
	var overburden := " [OVERBURDENED]" if wt >= max_wt * 0.8 else ""
	var leader_tag := " [ASCENDED ARCHON]" if d["is_leader"] else ""
	economy_label.text = (
		"Lv.%d%s  |  %s\n" % [d["level"], leader_tag, d["job_title"]]
		+ "Gear: %s  |  HP: %d/%d  |  ATK: %d\n" % [d["gear_name"], d["hp"], d["max_hp"], d["atk"]]
		+ "%s: %d FC   |   Wallet: %d FC\n" % [d["debt_name"], d["debt"], d["wallet"]]
		+ "Unrefined Farr: %d (%d FC)  |  Wt: %.0f/%.0f%s" % [d["unrefined_units"], d["unrefined_value"], wt, max_wt, overburden]
	)
	hp_bar.max_value = d["max_hp"]
	hp_bar.value = d["hp"]
	weight_bar.max_value = max_wt
	weight_bar.value = wt

	var t_name: String = d["target_name"]
	target_panel.visible = (t_name != "")
	if t_name != "":
		target_label.text = "%s   (%d / %d HP)" % [t_name, d["target_hp"], d["target_max_hp"]]
		target_bar.max_value = d["target_max_hp"]
		target_bar.value = d["target_hp"]

	skill1_btn.text = "1: Auto-Atk [%s]" % ("ON" if d["auto_attacking"] else "OFF")
	var cd2: float = d["skill2_cd"]
	skill2_btn.text = ("%s (%.1fs)" % [d["skill2_label"], cd2]) if cd2 > 0.0 else str(d["skill2_label"])
	var cd3: float = d["skill3_cd"]
	skill3_btn.text = ("%s (%.1fs)" % [d["skill3_label"], cd3]) if cd3 > 0.0 else str(d["skill3_label"])
	var sig_active := bool(d["sig_active"])
	skill4_btn.text = ("%s [ON]" % d["skill4_label"]) if sig_active else str(d["skill4_label"])

	var mining: bool = d["is_mining"]
	mining_panel.visible = mining
	if mining:
		mining_label.text = "Mining %s... (Move to cancel)" % d["mining_vein_name"]
		mining_bar.value = float(d["mining_progress"]) * 100.0


func _on_event_logged(msg: String) -> void:
	log_label.text = "> " + msg
