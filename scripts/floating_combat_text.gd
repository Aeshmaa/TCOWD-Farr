class_name FloatingCombatText
extends Label3D
## 3D Floating Combat Number (Damage Dealt, Skill/Crit Hit, Damage Taken, HP Heal, FP/SP Restore).
## Spawns above a 3D unit, rises smoothly with a slight horizontal spread, and fades out automatically.

var velocity := Vector3(0.0, 1.65, 0.0)
var lifetime := 1.15
var _elapsed := 0.0
var _base_color := Color.WHITE
var _initial_scale := Vector3.ONE


static func spawn(
	context_node: Node,
	world_pos: Vector3,
	text_value: String,
	color: Color,
	font_px: int = 34,
	rise_speed: float = 1.65
) -> Label3D:
	if context_node == null or not context_node.is_inside_tree():
		return null
	var tree := context_node.get_tree()
	if tree == null or tree.current_scene == null:
		return null

	var script_res: GDScript = load("res://scripts/floating_combat_text.gd")
	var node: Label3D = script_res.new()
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	node.fixed_size = false
	node.pixel_size = 0.0095
	node.font_size = font_px
	node.outline_size = 10
	node.text = text_value
	node.modulate = color
	node.outline_modulate = Color(0.04, 0.04, 0.06, 0.95)
	node._base_color = color
	node.velocity = Vector3(
		randf_range(-0.35, 0.35),
		rise_speed,
		randf_range(-0.35, 0.35)
	)
	node._initial_scale = Vector3(1.18, 1.18, 1.18)
	node.scale = node._initial_scale

	tree.current_scene.add_child(node)
	var jitter := Vector3(
		randf_range(-0.28, 0.28),
		randf_range(0.0, 0.25),
		randf_range(-0.28, 0.28)
	)
	node.global_position = world_pos + jitter
	return node


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return

	global_position += velocity * delta
	velocity.y = maxf(0.55, velocity.y - 0.75 * delta)

	# Quick punch-scale settle in the first 0.18s
	var settle_t := clampf(_elapsed / 0.18, 0.0, 1.0)
	scale = _initial_scale.lerp(Vector3.ONE, settle_t)

	# Smooth alpha fade in the final 40% of lifetime
	var fade_start := lifetime * 0.6
	if _elapsed > fade_start:
		var alpha := 1.0 - ((_elapsed - fade_start) / (lifetime - fade_start))
		modulate = Color(_base_color.r, _base_color.g, _base_color.b, clampf(alpha, 0.0, 1.0))
