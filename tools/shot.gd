extends SceneTree
## Usage: godot --path . -s tools/shot.gd -- <map_id> <out.png> [cam_x cam_y cam_z look_x look_y look_z]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var map_id: String = args[0] if args.size() > 0 else "svel_hq"
	var out: String = args[1] if args.size() > 1 else "/tmp/shot.png"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	var world = main.get_node("World")
	world.load_map(map_id)
	var show_hud: bool = ("--hud" in args)
	var hud = main.get_node_or_null("HUD")
	if hud:
		hud.visible = show_hud
	var cam: Camera3D
	if not show_hud or args.size() >= 8:
		cam = Camera3D.new()
		cam.far = 500.0
		root.add_child(cam)
		cam.current = true
		var cp := Vector3(0, 24, 48)
		var lp := Vector3(0, 3, -10)
		if args.size() >= 8:
			cp = Vector3(float(args[2]), float(args[3]), float(args[4]))
			lp = Vector3(float(args[5]), float(args[6]), float(args[7]))
		cam.global_position = cp
		cam.look_at(lp, Vector3.UP)
		cam.fov = 65
	await create_timer(1.2).timeout
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved ", out, " ", img.get_size())
	quit(0)
