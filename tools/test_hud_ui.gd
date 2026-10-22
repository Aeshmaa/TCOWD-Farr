extends SceneTree
## Test UI windows and capture screenshots
func _init() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	var hud = main.get_node_or_null("HUD")
	if not hud:
		print("ERROR: No HUD node found!")
		quit(1)
		return

	# 1. Test Dev drawer open
	var dev_toggle = hud.get_node("MenuTray/DevToggleBtn")
	dev_toggle.emit_signal("pressed")
	await process_frame
	var img_dev := root.get_viewport().get_texture().get_image()
	img_dev.save_png("/tmp/hud_dev_drawer.png")
	print("Saved /tmp/hud_dev_drawer.png")

	# Close dev drawer
	dev_toggle.emit_signal("pressed")

	# 2. Test Bags [I] window
	var inv_btn = hud.get_node("MenuTray/ShopButton")
	inv_btn.emit_signal("pressed")
	await process_frame
	var img_inv := root.get_viewport().get_texture().get_image()
	img_inv.save_png("/tmp/hud_inventory_window.png")
	print("Saved /tmp/hud_inventory_window.png")

	# Close Bags
	inv_btn.emit_signal("pressed")

	# 3. Test Map [M] window
	var map_btn = hud.get_node("ZoneNavPanel/Margin/VBox/BtnRow/ZoneMapBtn")
	map_btn.emit_signal("pressed")
	await process_frame
	var img_map := root.get_viewport().get_texture().get_image()
	img_map.save_png("/tmp/hud_map_window.png")
	print("Saved /tmp/hud_map_window.png")

	print("ALL HUD UI WINDOW TESTS COMPLETED SUCCESSFULLY!")
	quit(0)
