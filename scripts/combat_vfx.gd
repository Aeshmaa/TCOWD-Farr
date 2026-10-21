class_name CombatVfx
extends Node3D
## Spawns 3D visual effects for Ranged Projectiles, Force Bolts, Melee Slash Arcs,
## AoE Skill Shockwaves, and RF-Style Rising Buff Aura Rings.

enum Kind {
	PROJECTILE,
	MELEE_SLASH,
	AOE_RING,
	BUFF_AURA,
}

var kind: Kind = Kind.PROJECTILE
var start_pos: Vector3 = Vector3.ZERO
var target_pos: Vector3 = Vector3.ZERO
var target_node: Node3D = null
var follow_node: Node3D = null
var vfx_color: Color = Color(1.0, 0.85, 0.3)
var duration: float = 0.25
var elapsed: float = 0.0
var radius: float = 3.0

var _mesh_inst: MeshInstance3D
var _sub_mesh_inst: MeshInstance3D
var _mat: StandardMaterial3D
var _sub_mat: StandardMaterial3D


static func spawn_projectile(
	context: Node,
	from_world: Vector3,
	to_target: Node3D,
	col: Color,
	is_force_orb: bool = false,
	is_heavy_shell: bool = false
) -> void:
	if context == null or not context.is_inside_tree():
		return
	var root := context.get_tree().current_scene
	if root == null:
		return

	var vfx: Node3D = (load("res://scripts/combat_vfx.gd") as Script).new()
	vfx.kind = Kind.PROJECTILE
	vfx.start_pos = from_world
	vfx.target_node = to_target
	vfx.target_pos = to_target.global_position + Vector3(0.0, 1.0, 0.0) if (to_target and is_instance_valid(to_target)) else (from_world + Vector3(0.0, 0.0, -5.0))
	vfx.vfx_color = col
	var dist := from_world.distance_to(vfx.target_pos)
	vfx.duration = clampf(dist / 28.0, 0.10, 0.38)
	root.add_child(vfx)
	vfx.global_position = from_world
	vfx._build_projectile_mesh(is_force_orb, is_heavy_shell)


static func spawn_melee_slash(
	context: Node,
	attacker_pos: Vector3,
	victim_pos: Vector3,
	col: Color,
	scale_mult: float = 1.0
) -> void:
	if context == null or not context.is_inside_tree():
		return
	var root := context.get_tree().current_scene
	if root == null:
		return

	var vfx: Node3D = (load("res://scripts/combat_vfx.gd") as Script).new()
	vfx.kind = Kind.MELEE_SLASH
	vfx.start_pos = attacker_pos + Vector3(0.0, 1.05, 0.0)
	vfx.target_pos = victim_pos + Vector3(0.0, 1.05, 0.0)
	vfx.vfx_color = col
	vfx.duration = 0.22
	vfx.radius = scale_mult
	root.add_child(vfx)
	var mid: Vector3 = vfx.start_pos.lerp(vfx.target_pos, 0.55)
	vfx.global_position = mid
	vfx._build_melee_slash_mesh(scale_mult)
	var dir: Vector3 = vfx.target_pos - vfx.start_pos
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		vfx.look_at(vfx.global_position + dir.normalized(), Vector3.UP)


static func spawn_aoe_blast(
	context: Node,
	center_world: Vector3,
	blast_radius: float,
	col: Color
) -> void:
	if context == null or not context.is_inside_tree():
		return
	var root := context.get_tree().current_scene
	if root == null:
		return

	var vfx: Node3D = (load("res://scripts/combat_vfx.gd") as Script).new()
	vfx.kind = Kind.AOE_RING
	vfx.start_pos = center_world + Vector3(0.0, 0.12, 0.0)
	vfx.vfx_color = col
	vfx.radius = maxf(blast_radius, 2.0)
	vfx.duration = 0.45
	root.add_child(vfx)
	vfx.global_position = vfx.start_pos
	vfx._build_aoe_mesh()


static func spawn_buff_aura(
	context: Node3D,
	col: Color
) -> void:
	if context == null or not context.is_inside_tree():
		return
	var root := context.get_tree().current_scene
	if root == null:
		return

	var vfx: Node3D = (load("res://scripts/combat_vfx.gd") as Script).new()
	vfx.kind = Kind.BUFF_AURA
	vfx.follow_node = context
	vfx.vfx_color = col
	vfx.duration = 0.85
	root.add_child(vfx)
	vfx.global_position = context.global_position + Vector3(0.0, 0.15, 0.0)
	vfx._build_buff_aura_mesh()


func _make_emissive_mat(col: Color, alpha: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	return m


func _build_projectile_mesh(is_force_orb: bool, is_heavy_shell: bool) -> void:
	_mesh_inst = MeshInstance3D.new()
	_mat = _make_emissive_mat(vfx_color.lightened(0.25), 0.96)
	if is_force_orb or is_heavy_shell:
		var sph := SphereMesh.new()
		var r := 0.34 if is_heavy_shell else 0.24
		sph.radius = r
		sph.height = r * 2.0
		_mesh_inst.mesh = sph
	else:
		# Sleek elongated bolt / arrow / railgun slug
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.14, 0.95)
		_mesh_inst.mesh = box
	_mesh_inst.material_override = _mat
	add_child(_mesh_inst)

	# Glowing tail core
	_sub_mesh_inst = MeshInstance3D.new()
	_sub_mat = _make_emissive_mat(vfx_color, 0.55)
	var tail := BoxMesh.new()
	tail.size = Vector3(0.08, 0.08, 1.45)
	_sub_mesh_inst.mesh = tail
	_sub_mesh_inst.position = Vector3(0.0, 0.0, 0.55)
	_sub_mesh_inst.material_override = _sub_mat
	add_child(_sub_mesh_inst)


func _build_melee_slash_mesh(scale_mult: float) -> void:
	_mesh_inst = MeshInstance3D.new()
	_mat = _make_emissive_mat(vfx_color.lightened(0.2), 0.92)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.15 * scale_mult
	cyl.bottom_radius = 1.15 * scale_mult
	cyl.height = 0.08
	_mesh_inst.mesh = cyl
	_mesh_inst.rotation_degrees = Vector3(0.0, 0.0, 18.0)
	_mesh_inst.material_override = _mat
	add_child(_mesh_inst)


func _build_aoe_mesh() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mat = _make_emissive_mat(vfx_color, 0.78)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 0.12
	_mesh_inst.mesh = cyl
	_mesh_inst.material_override = _mat
	add_child(_mesh_inst)

	_sub_mesh_inst = MeshInstance3D.new()
	_sub_mat = _make_emissive_mat(vfx_color.lightened(0.35), 0.55)
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.35
	pillar.bottom_radius = 0.65
	pillar.height = 3.2
	_sub_mesh_inst.mesh = pillar
	_sub_mesh_inst.position = Vector3(0.0, 1.6, 0.0)
	_sub_mesh_inst.material_override = _sub_mat
	add_child(_sub_mesh_inst)


func _build_buff_aura_mesh() -> void:
	_mesh_inst = MeshInstance3D.new()
	_mat = _make_emissive_mat(vfx_color.lightened(0.2), 0.85)
	var ring := CylinderMesh.new()
	ring.top_radius = 1.25
	ring.bottom_radius = 1.25
	ring.height = 0.14
	_mesh_inst.mesh = ring
	_mesh_inst.material_override = _mat
	add_child(_mesh_inst)

	_sub_mesh_inst = MeshInstance3D.new()
	_sub_mat = _make_emissive_mat(vfx_color, 0.42)
	var beam := CylinderMesh.new()
	beam.top_radius = 0.85
	beam.bottom_radius = 1.1
	beam.height = 2.8
	_sub_mesh_inst.mesh = beam
	_sub_mesh_inst.position = Vector3(0.0, 1.4, 0.0)
	_sub_mesh_inst.material_override = _sub_mat
	add_child(_sub_mesh_inst)


func _process(delta: float) -> void:
	elapsed += delta
	var t := clampf(elapsed / maxf(duration, 0.05), 0.0, 1.0)

	match kind:
		Kind.PROJECTILE:
			if target_node != null and is_instance_valid(target_node):
				target_pos = target_node.global_position + Vector3(0.0, 1.05, 0.0)
			var cur := start_pos.lerp(target_pos, t)
			# Slight arc for projectiles
			cur.y += sin(t * PI) * 0.35
			global_position = cur
			var dir := target_pos - start_pos
			if dir.length_squared() > 0.001:
				look_at(global_position + dir.normalized(), Vector3.UP)
		Kind.MELEE_SLASH:
			var s := lerpf(0.45, 1.35, t)
			scale = Vector3(s, 1.0, s)
			rotation.y += delta * 14.0
			if _mat:
				_mat.albedo_color.a = (1.0 - t) * 0.9
		Kind.AOE_RING:
			var ring_scale := lerpf(0.2, radius * 2.0, t)
			if _mesh_inst:
				_mesh_inst.scale = Vector3(ring_scale, 1.0, ring_scale)
			if _sub_mesh_inst:
				var p_scale := lerpf(1.2, 0.2, t)
				_sub_mesh_inst.scale = Vector3(p_scale, 1.0 + t * 0.6, p_scale)
			if _mat:
				_mat.albedo_color.a = (1.0 - t) * 0.78
			if _sub_mat:
				_sub_mat.albedo_color.a = (1.0 - t) * 0.55
		Kind.BUFF_AURA:
			if follow_node != null and is_instance_valid(follow_node):
				global_position = follow_node.global_position
			if _mesh_inst:
				_mesh_inst.position.y = lerpf(0.15, 2.35, t)
				var r_s := lerpf(0.75, 1.35, sin(t * PI))
				_mesh_inst.scale = Vector3(r_s, 1.0, r_s)
			if _sub_mesh_inst:
				var b_s := lerpf(1.1, 0.5, t)
				_sub_mesh_inst.scale = Vector3(b_s, 1.0, b_s)
			if _mat:
				_mat.albedo_color.a = (1.0 - t) * 0.85
			if _sub_mat:
				_sub_mat.albedo_color.a = (1.0 - t) * 0.42

	if t >= 1.0:
		queue_free()
