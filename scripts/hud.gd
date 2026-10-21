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


func _ready() -> void:
	_build_inventory_window()

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
		"Lv.%d%s  |  %s  |  ATK: %d  |  Saved: %s\n" % [d["level"], leader_tag, d["job_title"], d["atk"], d.get("last_saved", "Auto")]
		+ "Equipped: %s\n" % d["gear_name"]
		+ "Rebirth Spawn: %s\n" % d.get("respawn_name", "HQ Default")
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

	_update_physical_vendor_panel(d["vendor_info"], code)
	_update_inventory_window(d)


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


func _on_event_logged(msg: String) -> void:
	log_label.text = "> " + msg
