extends Node
## Registers the default input actions at startup (autoload "InputSetup").


func _enter_tree() -> void:
	_add_key("move_forward", KEY_W)
	_add_key("move_forward", KEY_UP)
	_add_key("move_back", KEY_S)
	_add_key("move_back", KEY_DOWN)
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_mouse("move_click", MOUSE_BUTTON_LEFT)

	# Camera orbit: Right-Click, Middle-Click, OR Hold [Space] + move trackpad cursor (MacBook friendly!)
	_add_mouse("cam_rotate", MOUSE_BUTTON_RIGHT)
	_add_mouse("cam_rotate", MOUSE_BUTTON_MIDDLE)
	_add_key("cam_rotate", KEY_SPACE)

	# Keyboard 360° orbit & tilt (MacBook friendly!)
	_add_key("cam_orbit_left", KEY_Q)
	_add_key("cam_orbit_right", KEY_E)
	_add_key("cam_tilt_up", KEY_T)
	_add_key("cam_tilt_down", KEY_G)

	# Keyboard zoom in / out: [-] / [=] or [Z] / [X]
	_add_key("cam_zoom_in", KEY_EQUAL)
	_add_key("cam_zoom_in", KEY_Z)
	_add_key("cam_zoom_out", KEY_MINUS)
	_add_key("cam_zoom_out", KEY_X)

	_add_key("cam_mode_cycle", KEY_C)
	_add_key("cam_projection_toggle", KEY_V)
	_add_key("cam_reset", KEY_R)
	_add_key("faction_cycle", KEY_F)
	_add_key("simulate_death", KEY_K)
	_add_key("target_cycle", KEY_TAB)
	_add_key("skill_1", KEY_1)
	_add_key("skill_2", KEY_2)
	_add_key("skill_3", KEY_3)
	_add_key("skill_4", KEY_4)


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


func _add_key(action: StringName, keycode: Key) -> void:
	_ensure_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse(action: StringName, button: MouseButton) -> void:
	_ensure_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
