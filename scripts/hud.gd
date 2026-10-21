extends CanvasLayer
## Data-driven HUD supporting:
## - HP / FP / SP Bars + Potion Belt ([5] HP, [6] FP, [7] SP, [8] Teleport Scroll)
## - Faction Currency (CYC / DRC / SGL) & Order+Druj Shared vs. Sveleitre Chassis Gear
## - 4 HQ Vendor NPCs Window ([P] key or "HQ Vendors [P]" button)

@export var camera_rig_path: NodePath
@export var player_path: NodePath

@onready var cam_button: Button = $TopBar/CamModeButton
@onready var proj_button: Button = $TopBar/ProjButton
@onready var faction_button: Button = $TopBar/FactionButton
@onready var class_button: Button = $TopBar/ClassButton
@onready var branch_button: Button = $TopBar/BranchButton
@onready var shop_button: Button = $TopBar/ShopButton
@onready var level_button: Button = $TopBar/LevelButton
@onready var hq_button: Button = $TopBar/HqButton

@onready var shop_panel: PanelContainer = $ShopPanel
@onready var npc_potion_btn: Button = $ShopPanel/VBox/NpcPotionBtn
@onready var npc_weapon_btn: Button = $ShopPanel/VBox/NpcWeaponBtn
@onready var npc_equip_btn: Button = $ShopPanel/VBox/NpcEquipBtn
@onready var npc_utility_btn: Button = $ShopPanel/VBox/NpcUtilityBtn

@onready var target_panel: PanelContainer = $TargetPanel
@onready var target_label: Label = $TargetPanel/VBox/TargetLabel
@onready var target_bar: ProgressBar = $TargetPanel/VBox/TargetBar

@onready var economy_label: Label = $EconomyPanel/Margin/EconomyLabel
@onready var hp_bar: ProgressBar = $EconomyPanel/Margin/HpBar
@onready var fp_bar: ProgressBar = $EconomyPanel/Margin/FpBar
@onready var sp_bar: ProgressBar = $EconomyPanel/Margin/SpBar
@onready var weight_bar: ProgressBar = $EconomyPanel/Margin/WeightBar

@onready var skill1_btn: Button = $SkillBar/Skill1
@onready var skill2_btn: Button = $SkillBar/Skill2
@onready var skill3_btn: Button = $SkillBar/Skill3
@onready var skill4_btn: Button = $SkillBar/Skill4
@onready var pot_hp_btn: Button = $SkillBar/PotHP
@onready var pot_fp_btn: Button = $SkillBar/PotFP
@onready var pot_sp_btn: Button = $SkillBar/PotSP
@onready var scroll_btn: Button = $SkillBar/ScrollBtn

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
		shop_button.pressed.connect(func() -> void: shop_panel.visible = not shop_panel.visible)
		level_button.pressed.connect(func() -> void: _player.dev_boost_level())
		hq_button.pressed.connect(func() -> void: _player.teleport_to_hq())

		npc_potion_btn.pressed.connect(func() -> void: _player.npc_buy_potions())
		npc_weapon_btn.pressed.connect(func() -> void: _player.npc_buy_ammo_force())
		npc_equip_btn.pressed.connect(func() -> void: _player.npc_buy_equipment_bracket())
		npc_utility_btn.pressed.connect(func() -> void: _player.npc_buy_utility_scrolls())

		skill1_btn.pressed.connect(func() -> void: _player.use_skill(1))
		skill2_btn.pressed.connect(func() -> void: _player.use_skill(2))
		skill3_btn.pressed.connect(func() -> void: _player.use_skill(3))
		skill4_btn.pressed.connect(func() -> void: _player.use_skill(4))
		pot_hp_btn.pressed.connect(func() -> void: _player.use_potion("HP", false))
		pot_fp_btn.pressed.connect(func() -> void: _player.use_potion("FP", false))
		pot_sp_btn.pressed.connect(func() -> void: _player.use_potion("SP", false))
		scroll_btn.pressed.connect(func() -> void: _player.use_teleport_scroll())
		_player._emit_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shop"):
		shop_panel.visible = not shop_panel.visible


func _on_mode_changed(mode_name: String, proj_name: String) -> void:
	cam_button.text = "CAM [C]: " + mode_name
	proj_button.text = "VIEW [V]: " + proj_name


func _on_player_state(d: Dictionary) -> void:
	var code: String = d["currency_code"]
	faction_button.text = "Race [F]: %s (%s)" % [d["faction"], code]
	class_button.text = "Class [J]: %s" % d["job_title"]
	var wt: float = d["weight"]
	var max_wt: float = d["max_weight"]
	var overburden := " [OVERBURDENED]" if wt >= max_wt * 0.8 else ""
	var leader_tag := " [ARCHON]" if d["is_leader"] else ""
	economy_label.text = (
		"Lv.%d%s  |  %s  |  ATK: %d\n" % [d["level"], leader_tag, d["job_title"], d["atk"]]
		+ "Gear: %s\n" % d["gear_name"]
		+ "HP: %d/%d   |   FP: %d/%d   |   SP: %d/%d\n" % [d["hp"], d["max_hp"], d["fp"], d["max_fp"], d["sp"], d["max_sp"]]
		+ "%s: %d %s   |   Wallet: %d %s (%s)\n" % [d["debt_name"], d["debt"], code, d["wallet"], code, d["currency_name"]]
		+ "Ammo/Force: %d   |   Farr: %d (%d %s)   |   Wt: %.0f/%.0f%s" % [
			d["ammo"], d["unrefined_units"], d["unrefined_value"], code, wt, max_wt, overburden
		]
	)
	hp_bar.max_value = d["max_hp"]
	hp_bar.value = d["hp"]
	fp_bar.max_value = d["max_fp"]
	fp_bar.value = d["fp"]
	sp_bar.max_value = d["max_sp"]
	sp_bar.value = d["sp"]
	weight_bar.max_value = max_wt
	weight_bar.value = wt

	var t_name: String = d["target_name"]
	target_panel.visible = (t_name != "")
	if t_name != "":
		target_label.text = "%s   (%d / %d HP)" % [t_name, d["target_hp"], d["target_max_hp"]]
		target_bar.max_value = d["target_max_hp"]
		target_bar.value = d["target_hp"]

	skill1_btn.text = "1: Atk [%s]" % ("ON" if d["auto_attacking"] else "OFF")
	var cd2: float = d["skill2_cd"]
	skill2_btn.text = ("%s (%.1fs)" % [d["skill2_label"], cd2]) if cd2 > 0.0 else str(d["skill2_label"])
	var cd3: float = d["skill3_cd"]
	skill3_btn.text = ("%s (%.1fs)" % [d["skill3_label"], cd3]) if cd3 > 0.0 else str(d["skill3_label"])
	var sig_active := bool(d["sig_active"])
	skill4_btn.text = ("%s [ON]" % d["skill4_label"]) if sig_active else str(d["skill4_label"])

	pot_hp_btn.text = "5: HP Pot (%d)" % d["hp_potions"]
	pot_fp_btn.text = "6: FP Pot (%d)" % d["fp_potions"]
	pot_sp_btn.text = "7: SP Pot (%d)" % d["sp_potions"]
	scroll_btn.text = "8: Scroll (%d)" % d["scrolls"]

	var mining: bool = d["is_mining"]
	mining_panel.visible = mining
	if mining:
		mining_label.text = "Mining %s... (Move to cancel)" % d["mining_vein_name"]
		mining_bar.value = float(d["mining_progress"]) * 100.0


func _on_event_logged(msg: String) -> void:
	log_label.text = "> " + msg
