extends CanvasLayer
## Data-driven HUD supporting:
## - Physical 3D HQ Vendor NPCs (ShopPanel only opens when standing next to an NPC at HQ sides!)
## - Inventory & Equipment Window [I]:
##   * Automatic HP / FP / SP Charger Storage (adjustable % thresholds pulling from Bag stacks)
##   * 6 Equipment Slots (WEAPON, HELMET, UPPER, LOWER, GLOVES, SHOES)
##   * Multi-Bag System (Bag 1 to Bag 5, 8 slots per bag) + Auto-Arrange [O]

@export var camera_rig_path: NodePath
@export var player_path: NodePath

@onready var cam_button: Button = $TopBar/CamModeButton
@onready var proj_button: Button = $TopBar/ProjButton
@onready var faction_button: Button = $TopBar/FactionButton
@onready var class_button: Button = $TopBar/ClassButton
@onready var branch_button: Button = $TopBar/BranchButton
@onready var inv_button: Button = $TopBar/ShopButton
@onready var level_button: Button = $TopBar/LevelButton
@onready var hq_button: Button = $TopBar/HqButton

@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_title: Label = $ShopPanel/VBox/ShopTitle
@onready var npc_btn_0: Button = $ShopPanel/VBox/NpcPotionBtn
@onready var npc_btn_1: Button = $ShopPanel/VBox/NpcWeaponBtn
@onready var npc_btn_2: Button = $ShopPanel/VBox/NpcEquipBtn
@onready var npc_btn_3: Button = $ShopPanel/VBox/NpcUtilityBtn

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

# Programmatically built Inventory & Equipment Panel [I]
var _inv_panel: PanelContainer
var _auto_hp_btn: Button
var _auto_fp_btn: Button
var _auto_sp_btn: Button
var _equip_slot_btns: Dictionary = {}
var _talic_slot_btn: Button
var _talic_upgrade_btn: Button
var _bag_tab_btns: Array[Button] = []
var _auto_arrange_btn: Button
var _bag_slot_btns: Array[Button] = []
var _reset_meter_btn: Button
var _weapon_stance_btn: Button
var _rf_buff_btn: Button
var _map_top_btn: Button
var _map_panel: PanelContainer
var _map_btns: Dictionary = {}
var _settings_top_btn: Button
var _settings_panel: PanelContainer
var _opt_tab_mode_btn: Button
var _opt_auto_target_btn: Button
var _opt_float_dmg_btn: Button
var _opt_sfx_vol_btn: Button
var _opt_test_sfx_btn: Button
var _opt_cam_sens_btn: Button
var _opt_save_now_btn: Button
var _story_top_btn: Button
var _story_panel: PanelContainer
var _story_leader_portrait: TextureRect
var _story_header_lbl: Label
var _story_dialogue_lbl: Label
var _story_progress_lbl: Label
var _story_complete_btn: Button
var _story_warp_btn: Button
var _codex_portrait: TextureRect
var _codex_title_lbl: Label
var _codex_bio_lbl: Label
var _codex_prev_btn: Button
var _codex_next_btn: Button
var _portrait_cache: Dictionary = {}
var _log_lines: Array[String] = []

var _beacon_panel: PanelContainer
var _beacon_title: Label
var _beacon_wave_btn: Button
var _beacon_boss_btn: Button
var _beacon_clear_btn: Button


func _ready() -> void:
	_build_inventory_window()
	_build_world_map_window()
	_build_story_window()
	_build_settings_window()
	_build_combat_meter_controls()
	_build_beacon_window()

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
		inv_button.text = "Equip & Bags [I]"
		inv_button.pressed.connect(func() -> void: _inv_panel.visible = not _inv_panel.visible)
		level_button.pressed.connect(func() -> void: _player.dev_boost_level())
		hq_button.pressed.connect(func() -> void: _player.teleport_to_hq())

		npc_btn_0.pressed.connect(func() -> void: _player.execute_vendor_action(0))
		npc_btn_1.pressed.connect(func() -> void: _player.execute_vendor_action(1))
		npc_btn_2.pressed.connect(func() -> void: _player.execute_vendor_action(2))
		npc_btn_3.pressed.connect(func() -> void: _player.execute_vendor_action(3))

		skill1_btn.pressed.connect(func() -> void: _player.use_skill(1))
		skill2_btn.pressed.connect(func() -> void: _player.use_skill(2))
		skill3_btn.pressed.connect(func() -> void: _player.use_skill(3))
		skill4_btn.pressed.connect(func() -> void: _player.use_skill(4))
		pot_hp_btn.pressed.connect(func() -> void: _player.use_potion("HP", false))
		pot_fp_btn.pressed.connect(func() -> void: _player.use_potion("FP", false))
		pot_sp_btn.pressed.connect(func() -> void: _player.use_potion("SP", false))
		scroll_btn.pressed.connect(func() -> void: _player.use_teleport_scroll())
		_player._emit_state()


func _build_combat_meter_controls() -> void:
	var econ_vbox := get_node_or_null("EconomyPanel/Margin") as VBoxContainer
	if econ_vbox:
		_reset_meter_btn = Button.new()
		_reset_meter_btn.focus_mode = Control.FOCUS_NONE
		_reset_meter_btn.modulate = Color(1.0, 0.85, 0.55)
		_reset_meter_btn.text = "Reset DMG / Heal Telemetry Meter"
		_reset_meter_btn.pressed.connect(func() -> void:
			if _player and _player.has_method("reset_combat_telemetry"):
				_player.reset_combat_telemetry()
		)
		econ_vbox.add_child(_reset_meter_btn)

	var skill_bar := get_node_or_null("SkillBar") as HBoxContainer
	if skill_bar:
		_rf_buff_btn = Button.new()
		_rf_buff_btn.focus_mode = Control.FOCUS_NONE
		_rf_buff_btn.modulate = Color(0.55, 1.0, 0.72)
		_rf_buff_btn.text = "9: RF Buffs [B]"
		_rf_buff_btn.pressed.connect(func() -> void:
			if _player and _player.has_method("cast_rf_buff_suite"):
				_player.cast_rf_buff_suite()
		)
		skill_bar.add_child(_rf_buff_btn)

		_weapon_stance_btn = Button.new()
		_weapon_stance_btn.focus_mode = Control.FOCUS_NONE
		_weapon_stance_btn.modulate = Color(0.75, 0.92, 1.0)
		_weapon_stance_btn.text = "Weap [Z]: Native"
		_weapon_stance_btn.pressed.connect(func() -> void:
			if _player and _player.has_method("cycle_weapon_stance"):
				_player.cycle_weapon_stance()
		)
		skill_bar.add_child(_weapon_stance_btn)


func _build_world_map_window() -> void:
	var top_bar := get_node_or_null("TopBar") as HBoxContainer
	if top_bar:
		_map_top_btn = Button.new()
		_map_top_btn.focus_mode = Control.FOCUS_NONE
		_map_top_btn.modulate = Color(1.0, 0.88, 0.45)
		_map_top_btn.text = "World Map (9 Zones) [M]"
		_map_top_btn.pressed.connect(func() -> void: _map_panel.visible = not _map_panel.visible)
		top_bar.add_child(_map_top_btn)

	_map_panel = PanelContainer.new()
	_map_panel.visible = false
	_map_panel.offset_left = 605.0
	_map_panel.offset_top = 155.0
	_map_panel.offset_right = 1195.0
	_map_panel.offset_bottom = 670.0
	add_child(_map_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_map_panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.88, 0.42)
	title.text = "=== 9-MAP WORLD ZONE ATLAS & WARP GATE [M] ===\n(3 Faction HQs + 3 Basic Leveling + 2 Contested Upper + 1 Central Mining Ground)"
	vbox.add_child(title)

	for map_id in GameData.MAP_ORDER:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_map: String = map_id
		btn.pressed.connect(func() -> void:
			if _player and _player.has_method("travel_to_map"):
				if _player.travel_to_map(captured_map):
					_map_panel.visible = false
		)
		vbox.add_child(btn)
		_map_btns[map_id] = btn


func _build_settings_window() -> void:
	var top_bar := get_node_or_null("TopBar") as HBoxContainer
	if top_bar:
		_settings_top_btn = Button.new()
		_settings_top_btn.focus_mode = Control.FOCUS_NONE
		_settings_top_btn.modulate = Color(0.78, 0.95, 1.0)
		_settings_top_btn.text = "Settings [Esc]"
		_settings_top_btn.pressed.connect(func() -> void: _settings_panel.visible = not _settings_panel.visible)
		top_bar.add_child(_settings_top_btn)

	_settings_panel = PanelContainer.new()
	_settings_panel.visible = false
	_settings_panel.offset_left = 605.0
	_settings_panel.offset_top = 155.0
	_settings_panel.offset_right = 1140.0
	_settings_panel.offset_bottom = 520.0
	add_child(_settings_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_settings_panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.65, 0.95, 1.0)
	title.text = "=== IN-GAME OPTIONS & AUDIO SETTINGS [Esc] ==="
	vbox.add_child(title)

	_opt_tab_mode_btn = Button.new()
	_opt_tab_mode_btn.focus_mode = Control.FOCUS_NONE
	_opt_tab_mode_btn.modulate = Color(1.0, 0.92, 0.45)
	_opt_tab_mode_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("cycle_tab_target_mode"):
			_player.cycle_tab_target_mode()
	)
	vbox.add_child(_opt_tab_mode_btn)

	_opt_auto_target_btn = Button.new()
	_opt_auto_target_btn.focus_mode = Control.FOCUS_NONE
	_opt_auto_target_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("toggle_auto_target_on_kill"):
			_player.toggle_auto_target_on_kill()
	)
	vbox.add_child(_opt_auto_target_btn)

	_opt_float_dmg_btn = Button.new()
	_opt_float_dmg_btn.focus_mode = Control.FOCUS_NONE
	_opt_float_dmg_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("toggle_floating_dmg_setting"):
			_player.toggle_floating_dmg_setting()
	)
	vbox.add_child(_opt_float_dmg_btn)

	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 6)
	vbox.add_child(sfx_row)

	_opt_sfx_vol_btn = Button.new()
	_opt_sfx_vol_btn.focus_mode = Control.FOCUS_NONE
	_opt_sfx_vol_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_sfx_vol_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("cycle_sfx_volume"):
			_player.cycle_sfx_volume()
	)
	sfx_row.add_child(_opt_sfx_vol_btn)

	_opt_test_sfx_btn = Button.new()
	_opt_test_sfx_btn.focus_mode = Control.FOCUS_NONE
	_opt_test_sfx_btn.modulate = Color(0.65, 1.0, 0.72)
	_opt_test_sfx_btn.text = "Preview Skill SFX"
	_opt_test_sfx_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("test_sfx_sound"):
			_player.test_sfx_sound()
	)
	sfx_row.add_child(_opt_test_sfx_btn)

	_opt_cam_sens_btn = Button.new()
	_opt_cam_sens_btn.focus_mode = Control.FOCUS_NONE
	_opt_cam_sens_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("cycle_cam_sensitivity"):
			_player.cycle_cam_sensitivity()
	)
	vbox.add_child(_opt_cam_sens_btn)

	_opt_save_now_btn = Button.new()
	_opt_save_now_btn.focus_mode = Control.FOCUS_NONE
	_opt_save_now_btn.modulate = Color(0.55, 0.95, 1.0)
	_opt_save_now_btn.text = "Save Character & Settings Now"
	_opt_save_now_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("save_game"):
			_player.save_game()
			_on_event_logged("Character progress & In-Game Settings saved!")
	)
	vbox.add_child(_opt_save_now_btn)


func _load_portrait_texture(res_path: String) -> Texture2D:
	if res_path == "":
		return null
	if _portrait_cache.has(res_path):
		return _portrait_cache[res_path]
	var abs_path := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var tex := ImageTexture.create_from_image(img)
			_portrait_cache[res_path] = tex
			return tex
	if ResourceLoader.exists(res_path):
		var loaded := load(res_path) as Texture2D
		if loaded != null:
			_portrait_cache[res_path] = loaded
			return loaded
	return null


func _build_story_window() -> void:
	var top_bar := get_node_or_null("TopBar") as HBoxContainer
	if top_bar:
		_story_top_btn = Button.new()
		_story_top_btn.focus_mode = Control.FOCUS_NONE
		_story_top_btn.modulate = Color(1.0, 0.82, 0.95)
		_story_top_btn.text = "Story & Lore [N]"
		_story_top_btn.pressed.connect(func() -> void:
			_story_panel.visible = not _story_panel.visible
			if _story_panel.visible:
				_map_panel.visible = false
				_settings_panel.visible = false
		)
		top_bar.add_child(_story_top_btn)

	_story_panel = PanelContainer.new()
	_story_panel.visible = false
	_story_panel.offset_left = 540.0
	_story_panel.offset_top = 95.0
	_story_panel.offset_right = 1255.0
	_story_panel.offset_bottom = 735.0
	add_child(_story_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_story_panel.add_child(vbox)

	var banner := Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate = Color(1.0, 0.88, 0.45)
	banner.text = "=== FACTION SOVEREIGN STORY CAMPAIGN (CHAPTERS I–V) & ILLUSTRATED LORE CODEX [N] ==="
	vbox.add_child(banner)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	vbox.add_child(top_row)

	_story_leader_portrait = TextureRect.new()
	_story_leader_portrait.custom_minimum_size = Vector2(175.0, 215.0)
	_story_leader_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_story_leader_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	top_row.add_child(_story_leader_portrait)

	var story_col := VBoxContainer.new()
	story_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_col.add_theme_constant_override("separation", 5)
	top_row.add_child(story_col)

	_story_header_lbl = Label.new()
	_story_header_lbl.modulate = Color(0.65, 0.95, 1.0)
	_story_header_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_col.add_child(_story_header_lbl)

	_story_dialogue_lbl = Label.new()
	_story_dialogue_lbl.modulate = Color(0.96, 0.94, 0.88)
	_story_dialogue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_dialogue_lbl.custom_minimum_size = Vector2(490.0, 115.0)
	story_col.add_child(_story_dialogue_lbl)

	_story_progress_lbl = Label.new()
	_story_progress_lbl.modulate = Color(1.0, 0.9, 0.48)
	_story_progress_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_col.add_child(_story_progress_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	story_col.add_child(btn_row)

	_story_complete_btn = Button.new()
	_story_complete_btn.focus_mode = Control.FOCUS_NONE
	_story_complete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_complete_btn.modulate = Color(0.55, 1.0, 0.68)
	_story_complete_btn.text = "Complete Chapter & Claim Sovereign Rewards"
	_story_complete_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("complete_current_story_chapter"):
			_player.complete_current_story_chapter()
	)
	btn_row.add_child(_story_complete_btn)

	_story_warp_btn = Button.new()
	_story_warp_btn.focus_mode = Control.FOCUS_NONE
	_story_warp_btn.modulate = Color(1.0, 0.88, 0.45)
	_story_warp_btn.text = "Warp to Mission Zone"
	_story_warp_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("warp_to_story_chapter_zone"):
			_player.warp_to_story_chapter_zone()
			_story_panel.visible = false
	)
	btn_row.add_child(_story_warp_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var codex_banner := Label.new()
	codex_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	codex_banner.modulate = Color(1.0, 0.78, 0.92)
	codex_banner.text = "--- ILLUSTRATED WORLD LORE ARCHIVE: SOVEREIGNS & FORSWORN WORLD BOSSES ---"
	vbox.add_child(codex_banner)

	var codex_row := HBoxContainer.new()
	codex_row.add_theme_constant_override("separation", 10)
	vbox.add_child(codex_row)

	_codex_portrait = TextureRect.new()
	_codex_portrait.custom_minimum_size = Vector2(175.0, 200.0)
	_codex_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_codex_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	codex_row.add_child(_codex_portrait)

	var codex_col := VBoxContainer.new()
	codex_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_col.add_theme_constant_override("separation", 5)
	codex_row.add_child(codex_col)

	_codex_title_lbl = Label.new()
	_codex_title_lbl.modulate = Color(1.0, 0.88, 0.45)
	_codex_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	codex_col.add_child(_codex_title_lbl)

	_codex_bio_lbl = Label.new()
	_codex_bio_lbl.modulate = Color(0.9, 0.92, 0.96)
	_codex_bio_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_codex_bio_lbl.custom_minimum_size = Vector2(490.0, 120.0)
	codex_col.add_child(_codex_bio_lbl)

	var codex_nav := HBoxContainer.new()
	codex_nav.add_theme_constant_override("separation", 6)
	codex_col.add_child(codex_nav)

	_codex_prev_btn = Button.new()
	_codex_prev_btn.focus_mode = Control.FOCUS_NONE
	_codex_prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codex_prev_btn.text = "< Previous Lore Entry"
	_codex_prev_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("cycle_codex_entry"):
			_player.cycle_codex_entry(-1)
	)
	codex_nav.add_child(_codex_prev_btn)

	_codex_next_btn = Button.new()
	_codex_next_btn.focus_mode = Control.FOCUS_NONE
	_codex_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codex_next_btn.text = "Next Lore Entry >"
	_codex_next_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("cycle_codex_entry"):
			_player.cycle_codex_entry(1)
	)
	codex_nav.add_child(_codex_next_btn)


func _build_inventory_window() -> void:
	_inv_panel = PanelContainer.new()
	_inv_panel.visible = false
	_inv_panel.offset_left = 16.0
	_inv_panel.offset_top = 290.0
	_inv_panel.offset_right = 590.0
	_inv_panel.offset_bottom = 785.0
	add_child(_inv_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_inv_panel.add_child(vbox)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.55, 0.95, 1.0)
	title.text = "=== EQUIPMENT SLOTS, AUTO-CHARGER & BAGS [I] ==="
	vbox.add_child(title)

	# 1. Automatic HP / FP / SP Charger Bar
	var charger_lbl := Label.new()
	charger_lbl.text = "Automatic HP / FP / SP Charger Storage (Click to adjust threshold):"
	charger_lbl.modulate = Color(0.95, 0.9, 0.6)
	vbox.add_child(charger_lbl)

	var charger_row := HBoxContainer.new()
	charger_row.add_theme_constant_override("separation", 6)
	vbox.add_child(charger_row)

	_auto_hp_btn = Button.new()
	_auto_hp_btn.focus_mode = Control.FOCUS_NONE
	_auto_hp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_hp_btn.pressed.connect(func() -> void: if _player: _player.cycle_auto_charger("HP"))
	charger_row.add_child(_auto_hp_btn)

	_auto_fp_btn = Button.new()
	_auto_fp_btn.focus_mode = Control.FOCUS_NONE
	_auto_fp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_fp_btn.pressed.connect(func() -> void: if _player: _player.cycle_auto_charger("FP"))
	charger_row.add_child(_auto_fp_btn)

	_auto_sp_btn = Button.new()
	_auto_sp_btn.focus_mode = Control.FOCUS_NONE
	_auto_sp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_sp_btn.pressed.connect(func() -> void: if _player: _player.cycle_auto_charger("SP"))
	charger_row.add_child(_auto_sp_btn)

	# 2. 6 Equipment Slots Grid (2 columns x 3 rows)
	var eq_lbl := Label.new()
	eq_lbl.text = "Equipment Slots (Click equipped slot to unequip to Bag):"
	eq_lbl.modulate = Color(0.95, 0.9, 0.6)
	vbox.add_child(eq_lbl)

	var eq_grid := GridContainer.new()
	eq_grid.columns = 2
	eq_grid.add_theme_constant_override("h_separation", 6)
	eq_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(eq_grid)

	for slot_name in GameData.EQUIP_SLOTS:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_slot: String = slot_name
		b.pressed.connect(func() -> void: if _player: _player.unequip_equipment_slot(captured_slot))
		eq_grid.add_child(b)
		_equip_slot_btns[slot_name] = b

	# 2b. RF-Style Farr Talic Upgrading Bar (+1 to +7)
	var talic_row := HBoxContainer.new()
	talic_row.add_theme_constant_override("separation", 6)
	vbox.add_child(talic_row)

	_talic_slot_btn = Button.new()
	_talic_slot_btn.focus_mode = Control.FOCUS_NONE
	_talic_slot_btn.pressed.connect(func() -> void: if _player: _player.cycle_upgrade_target_slot())
	talic_row.add_child(_talic_slot_btn)

	_talic_upgrade_btn = Button.new()
	_talic_upgrade_btn.focus_mode = Control.FOCUS_NONE
	_talic_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talic_upgrade_btn.modulate = Color(1.0, 0.88, 0.45)
	_talic_upgrade_btn.pressed.connect(func() -> void: if _player: _player.upgrade_selected_slot_with_talic())
	talic_row.add_child(_talic_upgrade_btn)

	# 3. Multi-Bag Tabs (Bag 1 .. Bag 5) + Auto-Arrange [O] Button
	var bag_header := HBoxContainer.new()
	bag_header.add_theme_constant_override("separation", 4)
	vbox.add_child(bag_header)

	for i in range(GameData.MAX_BAGS):
		var tb := Button.new()
		tb.focus_mode = Control.FOCUS_NONE
		var captured_bag := i
		tb.pressed.connect(func() -> void: if _player: _player.select_bag_tab(captured_bag))
		bag_header.add_child(tb)
		_bag_tab_btns.append(tb)

	_auto_arrange_btn = Button.new()
	_auto_arrange_btn.focus_mode = Control.FOCUS_NONE
	_auto_arrange_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_arrange_btn.modulate = Color(0.65, 1.0, 0.65)
	_auto_arrange_btn.text = "Auto-Arrange [O]"
	_auto_arrange_btn.pressed.connect(func() -> void: if _player: _player.auto_arrange_bags())
	bag_header.add_child(_auto_arrange_btn)

	# 4. 8 Bag Slot Buttons for the selected Bag tab (2 columns x 4 rows)
	var bag_grid := GridContainer.new()
	bag_grid.columns = 2
	bag_grid.add_theme_constant_override("h_separation", 6)
	bag_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(bag_grid)

	for i in range(GameData.BAG_SLOTS_PER_BAG):
		var sb := Button.new()
		sb.focus_mode = Control.FOCUS_NONE
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_idx := i
		sb.pressed.connect(func() -> void: if _player: _player.interact_bag_slot(captured_idx))
		bag_grid.add_child(sb)
		_bag_slot_btns.append(sb)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		_inv_panel.visible = not _inv_panel.visible
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_map_panel.visible = not _map_panel.visible
			if _map_panel.visible:
				_settings_panel.visible = false
				_story_panel.visible = false
		elif event.keycode == KEY_N:
			_story_panel.visible = not _story_panel.visible
			if _story_panel.visible:
				_map_panel.visible = false
				_settings_panel.visible = false
		elif event.keycode == KEY_ESCAPE:
			if _story_panel.visible:
				_story_panel.visible = false
			else:
				_settings_panel.visible = not _settings_panel.visible
				if _settings_panel.visible:
					_map_panel.visible = false


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
	var rf_t := float(d.get("rf_buff_timer", 0.0))
	var sh_t := float(d.get("shield_buff", 0.0))
	var buff_parts: Array[String] = []
	if rf_t > 0.0:
		buff_parts.append("%s (+22%% ATK/ASPD/DEF/HP: %.0fs)" % [str(d.get("rf_buff_short", "RF Buffs")), rf_t])
	if sh_t > 0.0:
		buff_parts.append("Tank Fortify (-40%% DMG: %.0fs)" % sh_t)
	var buff_status := "  |  ".join(buff_parts) if not buff_parts.is_empty() else "None (Press [B] or [9] for 120s RF Buffs!)"
	economy_label.text = (
		"Zone: [%s] (%s)\n" % [d.get("current_map_name", "HQ"), d.get("current_map_band", "")]
		+ "Lv.%d%s  |  %s  |  ATK: %d  |  Saved: %s\n" % [d["level"], leader_tag, d["job_title"], d["atk"], d.get("last_saved", "Auto")]
		+ "Weapon Mode [Z]: %s  |  Equipped: %s\n" % [str(d.get("weapon_mode_summary", "Native")), d["gear_name"]]
		+ "Active Buffs [B]: %s  |  Rebirth: %s\n" % [buff_status, d.get("respawn_name", "HQ Default")]
		+ "HP: %d/%d   |   FP: %d/%d   |   SP: %d/%d\n" % [d["hp"], d["max_hp"], d["fp"], d["max_fp"], d["sp"], d["max_sp"]]
		+ "%s: %d %s   |   Wallet: %d %s (%s)\n" % [d["debt_name"], d["debt"], code, d["wallet"], code, d["currency_name"]]
		+ "Ammo/Force: %d   |   Farr: %d (%d %s)   |   Wt: %.0f/%.0f%s\n" % [
			d["ammo"], d["unrefined_units"], d["unrefined_value"], code, wt, max_wt, overburden
		]
		+ "DMG Out: %d (Last: -%d | Max: -%d)  |  DMG In: %d (Last: -%d)  |  Healed: +%d HP (Last: +%d)" % [
			int(d.get("dmg_dealt_total", 0)),
			int(d.get("dmg_dealt_last", 0)),
			int(d.get("dmg_dealt_max", 0)),
			int(d.get("dmg_taken_total", 0)),
			int(d.get("dmg_taken_last", 0)),
			int(d.get("hp_healed_total", 0)),
			int(d.get("hp_healed_last", 0)),
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

	if _rf_buff_btn:
		if rf_t > 0.0:
			_rf_buff_btn.text = "9: Buffs [ON %.0fs]" % rf_t
			_rf_buff_btn.modulate = Color(0.45, 1.0, 0.55)
		else:
			_rf_buff_btn.text = "9: RF Buffs [B]"
			_rf_buff_btn.modulate = Color(1.0, 0.9, 0.45)

	if _weapon_stance_btn:
		_weapon_stance_btn.text = "Weap [Z]: %s" % str(d.get("weapon_mode_summary", "Native"))

	var mining: bool = d["is_mining"]
	mining_panel.visible = mining
	if mining:
		mining_label.text = "Mining %s... (Move to cancel)" % d["mining_vein_name"]
		mining_bar.value = float(d["mining_progress"]) * 100.0

	_update_physical_vendor_panel(d["vendor_info"], code)
	_update_beacon_panel(d.get("active_beacon"))
	_update_inventory_window(d)
	_update_world_map_window(d)
	_update_story_window(d)
	_update_settings_window(d)


func _update_story_window(d: Dictionary) -> void:
	var sinfo: Dictionary = d.get("story_info", {})
	if sinfo.is_empty():
		return
	var code: String = str(d.get("currency_code", "CYC"))
	var leader_name: String = str(sinfo.get("leader_name", "Sovereign"))
	var leader_title: String = str(sinfo.get("leader_title", ""))
	var leader_portrait: String = str(sinfo.get("leader_portrait", ""))
	var ch_idx: int = int(sinfo.get("chapter_index", 0))
	var total_ch: int = int(sinfo.get("total_chapters", 5))
	var ch: Dictionary = sinfo.get("chapter", {})

	if bool(sinfo.get("request_open", false)):
		_story_panel.visible = true
		_map_panel.visible = false
		_settings_panel.visible = false

	if _story_top_btn:
		if ch.is_empty():
			_story_top_btn.text = "Story [N]: Campaign Complete (5/5)"
		else:
			_story_top_btn.text = "Story [N]: Ch.%d/%d" % [ch_idx + 1, total_ch]

	if _story_leader_portrait:
		_story_leader_portrait.texture = _load_portrait_texture(leader_portrait)

	if ch.is_empty():
		_story_header_lbl.text = "★ %s <%s> — ALL 5 STORY CHAPTERS COMPLETED! ★" % [leader_name, leader_title]
		_story_dialogue_lbl.text = "\"You have fulfilled every decree of our Campaign across the Var. Continue contesting the Central Farr Mining Ground and hunting the Forsworn World Bosses to forge +7 Sovereign Masterwork gear.\""
		_story_progress_lbl.text = "Campaign Status: 5 / 5 Chapters Complete."
		_story_complete_btn.text = "All 5 Chapters Completed!"
		_story_warp_btn.text = "Warp to Forsworn World Bosses"
	else:
		var req_lv: int = int(ch.get("req_level", 1))
		var req_k: int = int(ch.get("req_kills", 0))
		var req_f: int = int(ch.get("req_farr", 0))
		var req_b: int = int(ch.get("req_boss", 0))
		var cur_lv: int = int(d.get("level", 1))
		var cur_k: int = int(sinfo.get("story_kills", 0))
		var cur_f: int = int(sinfo.get("story_farr_mined", 0))
		var cur_b: int = int(sinfo.get("story_boss_kills", 0))
		var target_map_id: String = str(ch.get("target_map", ""))
		var target_map_name: String = str(GameData.MAPS.get(target_map_id, {}).get("name", target_map_id))

		_story_header_lbl.text = "★ %s <%s>\n%s (Zone: %s)" % [leader_name, leader_title, str(ch.get("title", "")), target_map_name]
		_story_dialogue_lbl.text = str(ch.get("dialogue", ""))
		var boss_prog := ("  |  Boss Kills: %d/%d" % [cur_b, req_b]) if req_b > 0 else ""
		_story_progress_lbl.text = (
			"Progress -> Level: %d/%d  |  Kills: %d/%d  |  Mined Farr: %d/%d%s\n" % [cur_lv, req_lv, cur_k, req_k, cur_f, req_f, boss_prog]
			+ "Rewards -> +%d %s, -%d Debt, +%dx Farr Talic, Boost to Lv.%d" % [
				int(ch.get("reward_currency", 0)),
				code,
				int(ch.get("reward_debt_relief", 0)),
				int(ch.get("reward_talics", 1)),
				int(ch.get("reward_min_level", cur_lv)),
			]
		)
		var ready_to_turn_in := (cur_lv >= req_lv and cur_k >= req_k and cur_f >= req_f and cur_b >= req_b)
		_story_complete_btn.text = "Complete Chapter %d & Claim Rewards [READY!]" % (ch_idx + 1) if ready_to_turn_in else "Complete Chapter %d (In Progress)" % (ch_idx + 1)
		_story_complete_btn.modulate = Color(0.45, 1.0, 0.55) if ready_to_turn_in else Color(0.85, 0.85, 0.85)
		_story_warp_btn.text = "Warp -> %s" % target_map_name

	var c_entry: Dictionary = sinfo.get("codex_entry", {})
	var c_idx: int = int(sinfo.get("codex_index", 0))
	var c_tot: int = int(sinfo.get("codex_total", 1))
	if not c_entry.is_empty():
		var p_path := str(c_entry.get("portrait", c_entry.get("portrait_path", "")))
		var e_name := str(c_entry.get("name", c_entry.get("title", "")))
		var e_lore := str(c_entry.get("lore", c_entry.get("bio", "")))
		if _codex_portrait:
			_codex_portrait.texture = _load_portrait_texture(p_path)
		_codex_title_lbl.text = "[%d / %d] %s  —  %s" % [
			c_idx + 1, c_tot, e_name, str(c_entry.get("role", ""))
		]
		_codex_bio_lbl.text = e_lore


func _update_settings_window(d: Dictionary) -> void:
	if _opt_tab_mode_btn:
		_opt_tab_mode_btn.text = "[Tab] Target Priority: %s (Click to Switch)" % str(d.get("tab_target_label", "Closest to Mouse Cursor"))
	if _opt_auto_target_btn:
		var atk_on := bool(d.get("auto_target_on_kill", true))
		_opt_auto_target_btn.text = "Auto-Target Next Enemy on Kill: [%s]" % ("ON" if atk_on else "OFF")
	if _opt_float_dmg_btn:
		var fd_on := bool(d.get("show_floating_dmg", true))
		_opt_float_dmg_btn.text = "3D Floating Damage & Heal Numbers: [%s]" % ("ON" if fd_on else "OFF")
	if _opt_sfx_vol_btn:
		var vol: int = int(d.get("sfx_volume_pct", 80))
		_opt_sfx_vol_btn.text = "Special Effects (SFX) Volume: [%s]" % ("MUTED (0%)" if vol <= 0 else "%d%%" % vol)
	if _opt_cam_sens_btn:
		var sens: float = float(d.get("cam_sensitivity_mult", 1.0))
		var sens_lbl := "Normal (1.0x)" if is_equal_approx(sens, 1.0) else ("Fast (1.5x)" if sens > 1.2 else "Low (0.6x)")
		_opt_cam_sens_btn.text = "Camera Orbit Sensitivity: [%s]" % sens_lbl


func _update_world_map_window(d: Dictionary) -> void:
	var cur_map: String = str(d.get("current_map_id", "svel_hq"))
	var my_fid: String = str(d.get("faction_id", "sveleitre"))
	if _map_top_btn:
		_map_top_btn.text = "Map [M]: %s" % str(d.get("current_map_name", "HQ"))

	for map_id_var in GameData.MAP_ORDER:
		var map_id: String = str(map_id_var)
		var btn: Button = _map_btns.get(map_id)
		if btn == null:
			continue
		var mdata: Dictionary = GameData.MAPS[map_id]
		var owner_fid: String = str(mdata.get("owner_faction", "all"))
		var cat: String = str(mdata.get("category", ""))
		var is_cur: bool = (map_id == cur_map)
		var tag := ""
		if is_cur:
			tag = "  <-- [CURRENT ZONE]"
			btn.modulate = Color(0.45, 1.0, 0.55)
		elif owner_fid != "all" and owner_fid != my_fid:
			tag = "  [LOCKED - Enemy Faction]"
			btn.modulate = Color(0.6, 0.45, 0.45)
		elif cat == "MINING_WAR":
			tag = "  [ALL 3 FACTIONS ORE WAR!]"
			btn.modulate = Color(1.0, 0.72, 0.28)
		elif cat == "CONTESTED_UPPER":
			tag = "  [ALL 3 FACTIONS CONTESTED]"
			btn.modulate = Color(1.0, 0.88, 0.45)
		else:
			tag = "  [Your Faction Territory]"
			btn.modulate = Color(0.75, 0.95, 1.0)
		btn.text = "%s  —  %s%s" % [mdata["name"], mdata.get("level_band", ""), tag]


func _update_physical_vendor_panel(vinfo: Dictionary, code: String) -> void:
	if vinfo.is_empty():
		shop_panel.visible = false
		return
	shop_panel.visible = true
	var vname: String = vinfo["name"]
	var vtitle: String = vinfo["title"]
	var vtype: String = vinfo["type"]
	shop_title.text = "=== %s <%s> ===" % [vname, vtitle]

	if vtype == "POTION":
		npc_btn_0.text = "Buy HP Potion x10 -> Bag (80 %s)" % code
		npc_btn_1.text = "Buy FP Charger x10 -> Bag (80 %s)" % code
		npc_btn_2.text = "Buy SP Stim x10 -> Bag (80 %s)" % code
		npc_btn_3.text = "Buy Full Charger Pack (+10 HP/FP/SP) (210 %s)" % code
	elif vtype == "WEAPON":
		npc_btn_0.text = "Buy Ammo / Force Cell x100 -> Bag (90 %s)" % code
		npc_btn_1.text = "Buy Lv.12 Weapon (Lv.1-15 Bracket) -> Bag (140 %s)" % code
		npc_btn_2.text = "Buy Lv.20 Weapon (Lv.15-25 Bracket) -> Bag (320 %s)" % code
		npc_btn_3.text = "Buy Lv.35 Weapon (Lv.30-45 Bracket) -> Bag (750 %s)" % code
	elif vtype == "ARMOR":
		var slot_lbl: String = vinfo["armor_slot_label"]
		npc_btn_0.text = "Buy Lv.12 [%s] (Lv.1-15) -> Bag (140 %s)" % [slot_lbl, code]
		npc_btn_1.text = "Buy Lv.20 [%s] (Lv.15-25) -> Bag (320 %s)" % [slot_lbl, code]
		npc_btn_2.text = "Buy Lv.35 [%s] (Lv.30-45) -> Bag (750 %s)" % [slot_lbl, code]
		npc_btn_3.text = "Switch Armor Slot [Currently: %s]" % slot_lbl
	elif vtype == "UTILITY":
		npc_btn_0.text = "Buy Teleport Scroll x3 -> Bag (90 %s)" % code
		var next_bag: int = int(vinfo["next_bag_num"])
		if next_bag <= GameData.MAX_BAGS:
			npc_btn_1.text = "Unlock Extra Bag %d (+8 Slots) (%d %s)" % [next_bag, vinfo["next_bag_cost"], code]
		else:
			npc_btn_1.text = "All 5 Bags Unlocked (40 Slots Max)"
		npc_btn_2.text = "Sell / Salvage All Unequipped Gear in Bags"
		var q_k: int = int(vinfo.get("quest_kills", 0))
		var q_f: int = int(vinfo.get("quest_farr", 0))
		npc_btn_3.text = "Faction Quest [Kills:%d/3, Farr:%d/10] -> +1 Talic & +350 %s" % [q_k, q_f, code]
	elif vtype == "REBIRTH":
		npc_btn_0.text = "1. Bind Respawn Point Here (Rebirth NPC Coordinate)"
		npc_btn_1.text = "2. Reset Respawn to Faction HQ Default Coordinate"
		npc_btn_2.text = "3. Full Vital Restoration: 100% HP/FP/SP (50 %s)" % code
		npc_btn_3.text = "4. Save Character Progress & Position Now"
	elif vtype == "LEADER":
		npc_btn_0.text = "1. Complete Current Story Chapter & Claim Sovereign Rewards"
		npc_btn_1.text = "2. Open Illustrated Story Campaign & Lore Codex [N]"
		npc_btn_2.text = "3. Warp Directly to Active Chapter Mission Zone"
		npc_btn_3.text = "4. Sovereign Blessing: Free 100% HP / FP / SP Restore"


func _update_inventory_window(d: Dictionary) -> void:
	var ahp: int = d["auto_hp_pct"]
	var afp: int = d["auto_fp_pct"]
	var asp: int = d["auto_sp_pct"]
	_auto_hp_btn.text = "Auto-HP [%s] (%d)" % [("OFF" if ahp == 0 else "<%d%%" % ahp), d["hp_potions"]]
	_auto_fp_btn.text = "Auto-FP [%s] (%d)" % [("OFF" if afp == 0 else "<%d%%" % afp), d["fp_potions"]]
	_auto_sp_btn.text = "Auto-SP [%s] (%d)" % [("OFF" if asp == 0 else "<%d%%" % asp), d["sp_potions"]]

	var eq_slots: Dictionary = d["equipped_slots"]
	for slot_name in GameData.EQUIP_SLOTS:
		var btn: Button = _equip_slot_btns[slot_name]
		var item: Dictionary = eq_slots.get(slot_name, {})
		var slot_lbl: String = GameData.EQUIP_SLOT_LABELS.get(slot_name, slot_name)
		if item.is_empty():
			btn.text = "[%s]: (Empty)" % slot_lbl
		else:
			btn.text = "[%s]: %s" % [slot_lbl, item["name"]]

	var upg_lbl: String = d.get("upgrade_slot_label", "Weapon")
	var cur_p: int = int(d.get("upgrade_cur_plus", 0))
	var talic_cnt: int = int(d.get("talics", 0))
	_talic_slot_btn.text = "Target: [%s (+%d)]" % [upg_lbl, cur_p]
	if cur_p >= GameData.MAX_UPGRADE_PLUS:
		_talic_upgrade_btn.text = "[%s is MAX +7 Sovereign Masterwork!]" % upg_lbl
	else:
		var next_p := cur_p + 1
		var rate := int(round(float(GameData.UPGRADE_SUCCESS_RATES.get(next_p, 0.25)) * 100.0))
		_talic_upgrade_btn.text = "Slot Farr Talic -> +%d (%d%% Success) (%d Talics)" % [next_p, rate, talic_cnt]

	var unlocked: int = d["unlocked_bags"]
	var cur_tab: int = d["active_bag_tab"]
	for i in range(GameData.MAX_BAGS):
		var tb: Button = _bag_tab_btns[i]
		if i < unlocked:
			tb.text = "[Bag %d]" % (i + 1) if i == cur_tab else "Bag %d" % (i + 1)
			tb.modulate = Color(1, 0.92, 0.45) if i == cur_tab else Color(1, 1, 1)
		else:
			tb.text = "Bag %d (Locked)" % (i + 1)
			tb.modulate = Color(0.55, 0.55, 0.55)

	var bags: Array = d["bag_slots"]
	var base_idx := cur_tab * GameData.BAG_SLOTS_PER_BAG
	for i in range(GameData.BAG_SLOTS_PER_BAG):
		var sb: Button = _bag_slot_btns[i]
		var g_idx := base_idx + i
		if g_idx >= bags.size() or bags[g_idx].is_empty():
			sb.text = "%d. [ Empty Slot ]" % (i + 1)
			sb.modulate = Color(0.7, 0.75, 0.8)
		else:
			var it: Dictionary = bags[g_idx]
			if bool(it.get("stackable", false)):
				sb.text = "%d. %s (x%d)" % [i + 1, it["name"], it["count"]]
				sb.modulate = Color(0.75, 0.95, 1.0)
			else:
				var compat: bool = (it.get("equip_group", "") == d["equip_group"])
				var tag := "[Click to Equip]" if compat else "[Incompatible - Sell at NPC]"
				sb.text = "%d. %s %s" % [i + 1, it["name"], tag]
				sb.modulate = Color(0.95, 0.85, 0.45) if compat else Color(1.0, 0.55, 0.55)


# ------------------------------------------------------------------------------
# RIFT SUMMON BEACON TERMINAL WINDOW
# ------------------------------------------------------------------------------
func _build_beacon_window() -> void:
	_beacon_panel = PanelContainer.new()
	_beacon_panel.visible = false
	_beacon_panel.offset_left = 370.0
	_beacon_panel.offset_top = 180.0
	_beacon_panel.offset_right = 910.0
	_beacon_panel.offset_bottom = 440.0
	add_child(_beacon_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_beacon_panel.add_child(vbox)

	_beacon_title = Label.new()
	_beacon_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_beacon_title.modulate = Color(1.0, 0.88, 0.42)
	_beacon_title.text = "=== RIFT SUMMON BEACON TERMINAL ==="
	vbox.add_child(_beacon_title)

	var desc := Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.modulate = Color(0.85, 0.90, 0.95)
	desc.text = "Harness zone rift energy to materialize monster grinding packs or awaken the zone's Pit Boss!"
	vbox.add_child(desc)

	_beacon_wave_btn = Button.new()
	_beacon_wave_btn.focus_mode = Control.FOCUS_NONE
	_beacon_wave_btn.modulate = Color(0.40, 0.95, 1.0)
	_beacon_wave_btn.text = "★ [1] Summon Grinding Pack (3x Hostile Mobs) ★"
	_beacon_wave_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("interact_beacon_summon_wave"):
			_player.interact_beacon_summon_wave()
	)
	vbox.add_child(_beacon_wave_btn)

	_beacon_boss_btn = Button.new()
	_beacon_boss_btn.focus_mode = Control.FOCUS_NONE
	_beacon_boss_btn.modulate = Color(1.0, 0.85, 0.35)
	_beacon_boss_btn.text = "★ [2] Awaken Zone Pit Boss ★"
	_beacon_boss_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("interact_beacon_summon_boss"):
			_player.interact_beacon_summon_boss()
	)
	vbox.add_child(_beacon_boss_btn)

	_beacon_clear_btn = Button.new()
	_beacon_clear_btn.focus_mode = Control.FOCUS_NONE
	_beacon_clear_btn.modulate = Color(0.88, 0.60, 0.60)
	_beacon_clear_btn.text = "Clear Summoned Wave Mobs"
	_beacon_clear_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("interact_beacon_clear_summons"):
			_player.interact_beacon_clear_summons()
	)
	vbox.add_child(_beacon_clear_btn)

	var close_btn := Button.new()
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.text = "Close Beacon Terminal"
	close_btn.pressed.connect(func() -> void:
		if _player and _player.has_method("close_beacon_menu"):
			_player.close_beacon_menu()
		_beacon_panel.visible = false
	)
	vbox.add_child(close_btn)


func _update_beacon_panel(binfo: Variant) -> void:
	if _beacon_panel == null:
		return
	if binfo != null and binfo is Dictionary and not (binfo as Dictionary).is_empty():
		_beacon_panel.visible = true
		_beacon_title.text = "=== %s ===" % (binfo as Dictionary).get("name", "Summon Beacon")
		var pb_name: String = str((binfo as Dictionary).get("pit_boss_name", "Pit Boss"))
		_beacon_boss_btn.text = "★ [2] Awaken Zone Pit Boss: [%s] ★" % pb_name
	else:
		_beacon_panel.visible = false



func _on_event_logged(msg: String) -> void:
	_log_lines.append("> " + msg)
	while _log_lines.size() > 2:
		_log_lines.pop_front()
	log_label.text = "\n".join(_log_lines)
