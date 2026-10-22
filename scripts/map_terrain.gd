@tool
class_name MapTerrain
extends Node3D
## Editable heightmap terrain for one FARR map.
##
## HOW TO EDIT (no coding needed):
##  1. Open a map scene from res://maps/ in the Godot editor, select the `Terrain` node.
##  2. SHAPE: paint the grayscale PNG in `heightmap` with any image editor (Krita, GIMP, Photoshop,
##     Aseprite...). Black = height 0, white = `height_scale` metres. Save it - Godot re-imports and the
##     terrain rebuilds. (Keep the centre ~45 m radius fairly flat: mobs, NPCs and veins stand there.)
##  3. LOOK: swap any texture / tint in the Look group. Everything is world-space so it never stretches.
##  4. Tick `rebuild_now` after changing the heightmap file outside of Godot if it does not refresh.
##
## Collision uses a HeightMapShape3D (cheap + exact). `height_at(x, z)` is used by the game to snap
## NPCs, mobs, veins and the player to the ground.

const SHADER := preload("res://assets/shaders/terrain.gdshader")

@export_group("Shape")
## Width/depth of the terrain in metres (the playable arena is inside the cliff ring at +-115 m).
@export var size := 250.0:
	set(v):
		size = v
		_queue_rebuild()
## Grayscale heightmap (square). Black = 0 m, white = height_scale m.
@export var heightmap: Texture2D:
	set(v):
		heightmap = v
		_queue_rebuild()
## Height in metres of a pure-white pixel.
@export var height_scale := 18.0:
	set(v):
		height_scale = v
		_queue_rebuild()
## Mesh/collision grid vertices per side (higher = smoother, heavier).
@export_range(33, 321, 8) var resolution := 169:
	set(v):
		resolution = v
		_queue_rebuild()
## Smoothing passes applied to the loaded heightmap (removes 8-bit stair-stepping).
@export_range(0, 6) var smooth_passes := 2:
	set(v):
		smooth_passes = v
		_queue_rebuild()

@export_group("Look")
@export var ground_albedo: Texture2D:
	set(v):
		ground_albedo = v
		_apply_material()
@export var ground_normal: Texture2D:
	set(v):
		ground_normal = v
		_apply_material()
## Optional second ground texture mixed in as patches (sand over rock, moss over stone...).
@export var accent_albedo: Texture2D:
	set(v):
		accent_albedo = v
		_apply_material()
@export var cliff_albedo: Texture2D:
	set(v):
		cliff_albedo = v
		_apply_material()
@export var ground_tint := Color.WHITE:
	set(v):
		ground_tint = v
		_apply_material()
@export var accent_tint := Color.WHITE:
	set(v):
		accent_tint = v
		_apply_material()
@export var cliff_tint := Color.WHITE:
	set(v):
		cliff_tint = v
		_apply_material()
@export_range(0.0, 1.0) var accent_amount := 0.35:
	set(v):
		accent_amount = v
		_apply_material()
@export var ground_tile_metres := 7.0:
	set(v):
		ground_tile_metres = v
		_apply_material()
@export var cliff_tile_metres := 9.0:
	set(v):
		cliff_tile_metres = v
		_apply_material()
@export_range(0.0, 1.0) var roughness := 0.92:
	set(v):
		roughness = v
		_apply_material()

@export_group("Glow Cracks (lava / Farr fissures)")
@export var glow_color := Color(1.0, 0.35, 0.05):
	set(v):
		glow_color = v
		_apply_material()
## Cracks glow where terrain is lower than this world-Y. -999 disables.
@export var glow_below_height := -999.0:
	set(v):
		glow_below_height = v
		_apply_material()
@export_range(0.0, 8.0) var glow_strength := 0.0:
	set(v):
		glow_strength = v
		_apply_material()

@export_group("Tools")
@export var rebuild_now := false:
	set(v):
		if v:
			build()
		rebuild_now = false

var _heights := PackedFloat32Array()
var _res := 0
var _mesh_inst: MeshInstance3D
var _body: StaticBody3D
var _mat: ShaderMaterial
var _rebuild_pending := false


func _ready() -> void:
	build()


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_do_deferred_rebuild")


func _do_deferred_rebuild() -> void:
	_rebuild_pending = false
	build()


## World-space terrain height at (x, z) in this node's local XZ plane (bilinear). 0 outside.
func height_at(x: float, z: float) -> float:
	if _res < 2 or _heights.is_empty():
		return 0.0
	var gx := (x / size + 0.5) * float(_res - 1)
	var gz := (z / size + 0.5) * float(_res - 1)
	if gx < 0.0 or gz < 0.0 or gx > _res - 1 or gz > _res - 1:
		return 0.0
	var x0 := int(floor(gx))
	var z0 := int(floor(gz))
	var x1 := mini(x0 + 1, _res - 1)
	var z1 := mini(z0 + 1, _res - 1)
	var fx := gx - x0
	var fz := gz - z0
	var h00 := _heights[z0 * _res + x0]
	var h10 := _heights[z0 * _res + x1]
	var h01 := _heights[z1 * _res + x0]
	var h11 := _heights[z1 * _res + x1]
	return lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz) + global_position.y


func build() -> void:
	_res = resolution
	_heights = _sample_heightmap()
	_build_mesh_and_collision()
	_apply_material()


func _sample_heightmap() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(_res * _res)
	var img: Image = null
	if heightmap != null:
		img = heightmap.get_image()
		if img != null and img.is_compressed():
			img.decompress()
	if img == null or img.get_width() < 2:
		return out  # flat
	var iw := img.get_width()
	var ih := img.get_height()
	for j in range(_res):
		for i in range(_res):
			var u := float(i) / float(_res - 1) * float(iw - 1)
			var v := float(j) / float(_res - 1) * float(ih - 1)
			var x0 := int(floor(u))
			var y0 := int(floor(v))
			var x1 := mini(x0 + 1, iw - 1)
			var y1 := mini(y0 + 1, ih - 1)
			var fx := u - x0
			var fy := v - y0
			var a := lerpf(img.get_pixel(x0, y0).r, img.get_pixel(x1, y0).r, fx)
			var b := lerpf(img.get_pixel(x0, y1).r, img.get_pixel(x1, y1).r, fx)
			out[j * _res + i] = lerpf(a, b, fy) * height_scale
	for _p in range(smooth_passes):
		out = _blur(out)
	return out


func _blur(src: PackedFloat32Array) -> PackedFloat32Array:
	var dst := src.duplicate()
	for j in range(1, _res - 1):
		for i in range(1, _res - 1):
			var s := 0.0
			for dj in range(-1, 2):
				for di in range(-1, 2):
					s += src[(j + dj) * _res + (i + di)]
			dst[j * _res + i] = s / 9.0
	return dst


func _build_mesh_and_collision() -> void:
	if _mesh_inst == null or not is_instance_valid(_mesh_inst):
		_mesh_inst = MeshInstance3D.new()
		_mesh_inst.name = "TerrainMesh"
		add_child(_mesh_inst)
	if _body == null or not is_instance_valid(_body):
		_body = StaticBody3D.new()
		_body.name = "TerrainBody"
		add_child(_body)
		var cs := CollisionShape3D.new()
		cs.name = "TerrainShape"
		cs.shape = HeightMapShape3D.new()
		_body.add_child(cs)

	var cell := size / float(_res - 1)
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	verts.resize(_res * _res)
	norms.resize(_res * _res)
	uvs.resize(_res * _res)
	for j in range(_res):
		for i in range(_res):
			var idx := j * _res + i
			var x := (float(i) / float(_res - 1) - 0.5) * size
			var z := (float(j) / float(_res - 1) - 0.5) * size
			verts[idx] = Vector3(x, _heights[idx], z)
			var hl := _heights[j * _res + maxi(i - 1, 0)]
			var hr := _heights[j * _res + mini(i + 1, _res - 1)]
			var hd := _heights[maxi(j - 1, 0) * _res + i]
			var hu := _heights[mini(j + 1, _res - 1) * _res + i]
			norms[idx] = Vector3(hl - hr, 2.0 * cell, hd - hu).normalized()
			uvs[idx] = Vector2(float(i) / float(_res - 1), float(j) / float(_res - 1))

	var indices := PackedInt32Array()
	indices.resize((_res - 1) * (_res - 1) * 6)
	var k := 0
	for j in range(_res - 1):
		for i in range(_res - 1):
			var a := j * _res + i
			var b := a + 1
			var c := a + _res
			var d := c + 1
			indices[k] = a
			indices[k + 1] = b
			indices[k + 2] = c
			indices[k + 3] = b
			indices[k + 4] = d
			indices[k + 5] = c
			k += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_inst.mesh = mesh

	var shape := (_body.get_node("TerrainShape") as CollisionShape3D)
	var hm := HeightMapShape3D.new()
	hm.map_width = _res
	hm.map_depth = _res
	hm.map_data = _heights
	shape.shape = hm
	shape.scale = Vector3(cell, 1.0, cell)


func _apply_material() -> void:
	if _mesh_inst == null or not is_instance_valid(_mesh_inst):
		return
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = SHADER
	_mat.set_shader_parameter("ground_albedo", ground_albedo)
	_mat.set_shader_parameter("ground_normal", ground_normal)
	_mat.set_shader_parameter("accent_albedo", accent_albedo if accent_albedo != null else ground_albedo)
	_mat.set_shader_parameter("cliff_albedo", cliff_albedo if cliff_albedo != null else ground_albedo)
	_mat.set_shader_parameter("ground_tint", ground_tint)
	_mat.set_shader_parameter("accent_tint", accent_tint)
	_mat.set_shader_parameter("cliff_tint", cliff_tint)
	_mat.set_shader_parameter("ground_scale", ground_tile_metres)
	_mat.set_shader_parameter("cliff_scale", cliff_tile_metres)
	_mat.set_shader_parameter("accent_amount", accent_amount)
	_mat.set_shader_parameter("roughness_value", roughness)
	_mat.set_shader_parameter("emission_color", glow_color)
	_mat.set_shader_parameter("emission_height", glow_below_height)
	_mat.set_shader_parameter("emission_strength", glow_strength)
	_mesh_inst.material_override = _mat
