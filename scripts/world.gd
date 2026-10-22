class_name WorldZoneManager
extends NavigationRegion3D
## 30-Map World Zone Manager:
## Dynamically loads, generates expansive 3D terrain, procedural height landforms
## (elevated terraces, walkable ramps, rolling hills, sunken trenches), and populates
## all 30 World Maps defined in `GameData.MAPS`:
## - Expansive 3D Terrain: Perimeter Mountain Cliffs (230m x 230m), Themed Architectural Landmarks
## - Multi-tier Walkable Height Variation: Raised Plateaus, Stepped Terraces & 14-deg Walkable Ramps
## - Dedicated Boss Pit Arena with pillars, braziers, and zone Pit Boss
## - 3D Interactive Monster Summon Beacon (Summon Grinding Waves / Awaken Pit Boss)
## - 23 Distinct Biome Themes with authentic procedural meshes and atmospheric distance fog

signal map_loaded(map_id: String, map_data: Dictionary)

const REFINERY_SCENE := preload("res://scenes/refinery_station.tscn")
const VENDOR_NPC_SCENE := preload("res://scenes/vendor_npc.tscn")
const FARR_VEIN_SCENE := preload("res://scenes/farr_vein.tscn")
const WARP_PORTAL_SCENE := preload("res://scenes/warp_portal.tscn")
const ENEMY_UNIT_SCENE := preload("res://scenes/enemy_unit.tscn")
const SUMMON_BEACON_SCENE := preload("res://scenes/summon_beacon.tscn")
const COMBAT_VFX := preload("res://scripts/combat_vfx.gd")

var current_map_id := ""
var _map_container: Node3D = null


func _ready() -> void:
	add_to_group("world_zone_manager")
	_cleanup_legacy_static_entities()
	_ensure_container()
	if current_map_id == "":
		load_map("svel_hq")


func _ensure_container() -> void:
	if _map_container == null or not is_instance_valid(_map_container):
		_map_container = Node3D.new()
		_map_container.name = "MapEntities"
		add_child(_map_container)


func _cleanup_legacy_static_entities() -> void:
	for child in get_children():
		if child is RefineryStation or child is VendorNpc or child is FarrVein or child is EnemyUnit or child.is_in_group("summon_beacon"):
			child.queue_free()
		elif child.name == "PillarNW" or child.name == "PillarNE" or child.name == "RuinedWall":
			child.queue_free()
	var p := get_parent()
	if p:
		for sibling in p.get_children():
			if sibling is EnemyUnit:
				sibling.queue_free()


func load_map(map_id: String) -> Dictionary:
	_ensure_container()
	var target_id := map_id if GameData.MAPS.has(map_id) else "svel_hq"
	current_map_id = target_id
	var mdata: Dictionary = GameData.MAPS[target_id]

	# Clear previous map entities and any dropped ore bags
	for c in _map_container.get_children():
		_map_container.remove_child(c)
		c.queue_free()
	if get_parent():
		for s in get_parent().get_children():
			if s is DroppedOreBag:
				s.queue_free()

	_apply_map_atmosphere(mdata)
	_spawn_map_terrain(mdata)
	_spawn_map_entities(mdata)
	if is_inside_tree():
		bake_navigation_mesh(false)
	map_loaded.emit(current_map_id, mdata)
	return mdata


func _apply_map_atmosphere(mdata: Dictionary) -> void:
	var ground_mesh := get_node_or_null("Ground/MeshInstance3D") as MeshInstance3D
	var ground_col := get_node_or_null("Ground/CollisionShape3D") as CollisionShape3D
	if ground_mesh and ground_mesh.mesh is BoxMesh:
		(ground_mesh.mesh as BoxMesh).size = Vector3(250.0, 1.0, 250.0)
	if ground_col and ground_col.shape is BoxShape3D:
		(ground_col.shape as BoxShape3D).size = Vector3(250.0, 1.0, 250.0)

	if ground_mesh:
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = mdata.get("ground_color", Color(0.2, 0.22, 0.25))
		gmat.roughness = 0.88
		ground_mesh.material_override = gmat

	var p := get_parent()
	if p:
		var env_node := p.get_node_or_null("WorldEnvironment") as WorldEnvironment
		if env_node and env_node.environment:
			var env: Environment = env_node.environment
			if env.sky:
				var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
				if sky_mat:
					sky_mat.sky_top_color = mdata.get("sky_top", Color(0.12, 0.15, 0.22))
					sky_mat.sky_horizon_color = mdata.get("sky_horizon", Color(0.28, 0.32, 0.40))
					sky_mat.ground_horizon_color = mdata.get("sky_horizon", Color(0.22, 0.25, 0.32)).darkened(0.25)

			# Atmospheric distance fog for epic scale
			env.fog_enabled = true
			env.fog_light_color = mdata.get("sky_horizon", Color(0.28, 0.32, 0.40))
			env.fog_density = 0.0055
			env.fog_sky_affect = 0.45

			var hcol: Color = mdata.get("sky_horizon", Color(0.4, 0.45, 0.5))
			env.ambient_light_color = hcol.lerp(Color.WHITE, 0.25)
			env.ambient_light_energy = 0.75

		var sun := p.get_node_or_null("Sun") as DirectionalLight3D
		if sun:
			var horizon_col: Color = mdata.get("sky_horizon", Color(1.0, 0.95, 0.85))
			sun.light_color = horizon_col.lerp(Color.WHITE, 0.4)
			sun.light_energy = 1.15


# ------------------------------------------------------------------------------
# EXPANSIVE 3D TERRAIN GENERATION (PERIMETER CLIFFS + HEIGHT LANDFORMS + BOSS PIT + LANDMARKS)
# ------------------------------------------------------------------------------
func _spawn_map_terrain(mdata: Dictionary) -> void:
	var terrain_root := Node3D.new()
	terrain_root.name = "MapTerrain"
	_map_container.add_child(terrain_root)

	var theme := str(mdata.get("terrain_theme", "TECH_ARK"))
	var ground_col: Color = mdata.get("ground_color", Color(0.2, 0.22, 0.25))
	var rock_mat := _build_rock_material(theme, ground_col)

	# 1. Perimeter Ring Mountain Cliffs (Enclosing 230m x 230m boundaries)
	_build_perimeter_cliffs(terrain_root, rock_mat)

	# 2. Multi-Tier Walkable Height Features (Plateaus, Ramps, Rolling Hills)
	_build_height_features(terrain_root, theme, rock_mat, ground_col, mdata)

	# 3. Dedicated Boss Pit Arena Platform & Ring Monoliths
	var boss_pit_data: Dictionary = mdata.get("boss_pit", {})
	if not boss_pit_data.is_empty():
		_build_boss_pit_arena(terrain_root, boss_pit_data, theme, mdata)

	# 4. Themed Architectural Landmarks
	_build_themed_landmarks(terrain_root, theme, rock_mat, mdata)

	# 5. Natural Biome Scatter Props (Boulders, Ore Outcrops, Debris)
	_build_scatter_props(terrain_root, theme, ground_col, mdata)


func _build_rock_material(theme: String, ground_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.85
	match theme:
		"TECH_ARK":
			mat.albedo_color = Color(0.20, 0.23, 0.28)
			mat.metallic = 0.45
			mat.roughness = 0.55
		"ARK_SUPERCORE":
			mat.albedo_color = Color(0.16, 0.19, 0.25)
			mat.metallic = 0.6
			mat.roughness = 0.4
		"FROZEN_SCRAP":
			mat.albedo_color = Color(0.28, 0.36, 0.44)
			mat.roughness = 0.70
		"HOLY_TEMPLE":
			mat.albedo_color = Color(0.55, 0.52, 0.44)
			mat.roughness = 0.65
		"SKY_SANCTUM":
			mat.albedo_color = Color(0.82, 0.78, 0.68)
			mat.roughness = 0.45
		"DESERT_RUINS":
			mat.albedo_color = Color(0.54, 0.37, 0.22)
		"CATACOMB_CRYPT":
			mat.albedo_color = Color(0.35, 0.28, 0.24)
			mat.roughness = 0.88
		"OBSIDIAN_CITADEL":
			mat.albedo_color = Color(0.12, 0.10, 0.15)
			mat.roughness = 0.75
		"VOLCANIC_BASIN":
			mat.albedo_color = Color(0.18, 0.12, 0.10)
		"MAGMA_CALDERA":
			mat.albedo_color = Color(0.15, 0.09, 0.08)
			mat.roughness = 0.90
		"PERSEPOLIS_STEPPES":
			mat.albedo_color = Color(0.46, 0.36, 0.26)
		"VAR_ROOTS":
			mat.albedo_color = Color(0.32, 0.24, 0.16)
			mat.roughness = 0.85
		"SCORCHED_CAULDRON":
			mat.albedo_color = Color(0.14, 0.08, 0.12)
		"DAEVA_CRYPT":
			mat.albedo_color = Color(0.13, 0.07, 0.14)
			mat.roughness = 0.80
		"CRACK_MINING":
			mat.albedo_color = Color(0.26, 0.24, 0.20)
		"LOWER_CRATER":
			mat.albedo_color = Color(0.20, 0.17, 0.14)
			mat.roughness = 0.92
		"BREACH_RIDGE":
			mat.albedo_color = Color(0.30, 0.26, 0.21)
		"AETHER_SKY":
			mat.albedo_color = Color(0.60, 0.72, 0.85)
			mat.metallic = 0.3
			mat.roughness = 0.5
		"LUMINESCENT_AQUIFER":
			mat.albedo_color = Color(0.18, 0.25, 0.27)
			mat.roughness = 0.75
		"BEAST_HIGHLAND":
			mat.albedo_color = Color(0.36, 0.28, 0.22)
		"OUTCAST_WASTELAND":
			mat.albedo_color = Color(0.34, 0.26, 0.18)
			mat.roughness = 0.90
		"SKY_FRACTURE":
			mat.albedo_color = Color(0.30, 0.35, 0.46)
			mat.roughness = 0.65
		"BORDER_TRENCHES":
			mat.albedo_color = Color(0.24, 0.20, 0.18)
		_:
			mat.albedo_color = ground_color.darkened(0.25)
	return mat


func _build_perimeter_cliffs(parent: Node3D, rock_mat: StandardMaterial3D) -> void:
	var cliff_group := Node3D.new()
	cliff_group.name = "PerimeterCliffs"
	parent.add_child(cliff_group)

	var bound := 115.0
	var step := 14.5
	var coords := []
	var c := -116.0
	while c <= 116.0:
		coords.append(c)
		c += step

	# North & South walls
	for x in coords:
		_add_cliff_rock(cliff_group, Vector3(x, 0.0, -bound), rock_mat, 0)
		_add_cliff_rock(cliff_group, Vector3(x, 0.0, bound), rock_mat, 1)

	# East & West walls
	for z in coords:
		_add_cliff_rock(cliff_group, Vector3(-bound, 0.0, z), rock_mat, 2)
		_add_cliff_rock(cliff_group, Vector3(bound, 0.0, z), rock_mat, 3)


func _add_cliff_rock(parent: Node3D, pos: Vector3, mat: StandardMaterial3D, seed_idx: int) -> void:
	var rock := StaticBody3D.new()
	var h := 12.0 + sin(pos.x * 0.3 + pos.z * 0.5 + seed_idx) * 3.5
	var w := 15.0 + cos(pos.x * 0.2 + pos.z * 0.4) * 2.5
	var d := 10.0 + sin(pos.z * 0.3) * 2.0

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(w, h, d)
	box_mesh.material = mat
	mesh_inst.mesh = box_mesh
	mesh_inst.position = Vector3(0.0, h * 0.5 - 0.5, 0.0)
	rock.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(w, h, d)
	col.shape = box_shape
	col.position = Vector3(0.0, h * 0.5 - 0.5, 0.0)
	rock.add_child(col)

	rock.position = pos
	rock.rotation.y = (pos.x + pos.z) * 0.05
	parent.add_child(rock)


# ------------------------------------------------------------------------------
# MULTI-TIER WALKABLE HEIGHT LANDFORMS (PLATEAUS, STEPS, RAMPS, ROLLING HILLS)
# ------------------------------------------------------------------------------
func _build_height_features(parent: Node3D, theme: String, rock_mat: StandardMaterial3D, ground_col: Color, mdata: Dictionary) -> void:
	var h_root := Node3D.new()
	h_root.name = "HeightFeatures"
	parent.add_child(h_root)

	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = ground_col.lerp(rock_mat.albedo_color, 0.45)
	pmat.roughness = 0.85

	match theme:
		"AETHER_SKY", "SKY_FRACTURE":
			# Floating Tiered Sky Platforms with energy ramps and bridge
			_add_walkable_plateau(h_root, Vector3(-55.0, 0.0, 45.0), Vector3(38.0, 2.6, 28.0), pmat, 8.0, true)
			_add_walkable_plateau(h_root, Vector3(55.0, 0.0, -45.0), Vector3(38.0, 2.6, 28.0), pmat, 8.0, true)
			_add_walkable_plateau(h_root, Vector3(58.0, 0.0, 48.0), Vector3(32.0, 3.4, 26.0), pmat, 7.0, true)
			_add_walkable_bridge(h_root, Vector3(-36.0, 2.6, 45.0), Vector3(-12.0, 0.0, 40.0), 5.5, pmat, Color(0.3, 0.9, 1.0))
			_add_walkable_hill(h_root, Vector3(-45.0, 0.0, -50.0), 14.0, 1.6, pmat)

		"MAGMA_CALDERA", "SCORCHED_CAULDRON", "VOLCANIC_BASIN":
			# Volcanic Basalt Ridges and Sunken Magma Terraces
			_add_walkable_plateau(h_root, Vector3(-58.0, 0.0, -35.0), Vector3(42.0, 2.8, 26.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(58.0, 0.0, 35.0), Vector3(42.0, 2.8, 26.0), pmat, 8.0, false)
			_add_walkable_hill(h_root, Vector3(-45.0, 0.0, 48.0), 16.0, 1.8, pmat)
			_add_walkable_hill(h_root, Vector3(45.0, 0.0, -52.0), 16.0, 1.8, pmat)

		"CRACK_MINING", "LOWER_CRATER", "BREACH_RIDGE":
			# Mining Terraces, Fortified Sniper Ridge, and Lower Excavation Shelves
			_add_walkable_plateau(h_root, Vector3(-62.0, 0.0, 0.0), Vector3(32.0, 3.2, 54.0), pmat, 9.0, true)
			_add_walkable_plateau(h_root, Vector3(62.0, 0.0, 0.0), Vector3(32.0, 3.2, 54.0), pmat, 9.0, true)
			_add_walkable_hill(h_root, Vector3(0.0, 0.0, -65.0), 18.0, 2.2, pmat)
			_add_walkable_hill(h_root, Vector3(0.0, 0.0, 65.0), 18.0, 2.2, pmat)

		"BEAST_HIGHLAND", "PERSEPOLIS_STEPPES", "VAR_ROOTS":
			# Grand Steppe Terraces & Rolling Highland Bluffs
			_add_walkable_plateau(h_root, Vector3(-52.0, 0.0, 52.0), Vector3(46.0, 2.8, 36.0), pmat, 9.0, false)
			_add_walkable_plateau(h_root, Vector3(52.0, 0.0, -52.0), Vector3(46.0, 2.8, 36.0), pmat, 9.0, false)
			_add_walkable_hill(h_root, Vector3(55.0, 0.0, 45.0), 18.0, 2.0, pmat)
			_add_walkable_hill(h_root, Vector3(-55.0, 0.0, -45.0), 18.0, 2.0, pmat)

		"BORDER_TRENCHES", "OUTCAST_WASTELAND", "DESERT_RUINS":
			# Desert Dunes and Trench Embankments
			_add_walkable_plateau(h_root, Vector3(-60.0, 0.0, -40.0), Vector3(40.0, 2.4, 30.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(60.0, 0.0, 40.0), Vector3(40.0, 2.4, 30.0), pmat, 8.0, false)
			_add_walkable_hill(h_root, Vector3(-40.0, 0.0, 50.0), 16.0, 1.8, pmat)
			_add_walkable_hill(h_root, Vector3(40.0, 0.0, -50.0), 16.0, 1.8, pmat)

		"CATACOMB_CRYPT", "DAEVA_CRYPT", "LUMINESCENT_AQUIFER":
			# Subterranean Vault Terraces & Sunken Crypt Plazas
			_add_walkable_plateau(h_root, Vector3(-50.0, 0.0, -45.0), Vector3(36.0, 2.4, 32.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(50.0, 0.0, 45.0), Vector3(36.0, 2.4, 32.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(-50.0, 0.0, 45.0), Vector3(36.0, 2.4, 32.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(50.0, 0.0, -45.0), Vector3(36.0, 2.4, 32.0), pmat, 8.0, false)

		"TECH_ARK", "ARK_SUPERCORE", "FROZEN_SCRAP":
			# Industrial Mezzanines & Glacial Shelves
			_add_walkable_plateau(h_root, Vector3(-56.0, 0.0, 42.0), Vector3(40.0, 2.6, 28.0), pmat, 8.0, true)
			_add_walkable_plateau(h_root, Vector3(56.0, 0.0, -42.0), Vector3(40.0, 2.6, 28.0), pmat, 8.0, true)
			_add_walkable_hill(h_root, Vector3(-48.0, 0.0, -50.0), 15.0, 1.7, pmat)
			_add_walkable_hill(h_root, Vector3(48.0, 0.0, 50.0), 15.0, 1.7, pmat)

		"HOLY_TEMPLE", "SKY_SANCTUM":
			# Sanctum Podium Terraces with Ceremonial Ramps
			_add_walkable_plateau(h_root, Vector3(-52.0, 0.0, 48.0), Vector3(38.0, 2.5, 32.0), pmat, 9.0, true)
			_add_walkable_plateau(h_root, Vector3(52.0, 0.0, -48.0), Vector3(38.0, 2.5, 32.0), pmat, 9.0, true)
			_add_walkable_hill(h_root, Vector3(-45.0, 0.0, -45.0), 16.0, 1.6, pmat)
			_add_walkable_hill(h_root, Vector3(45.0, 0.0, 45.0), 16.0, 1.6, pmat)

		_:
			# Default balanced rolling terraces
			_add_walkable_plateau(h_root, Vector3(-55.0, 0.0, 45.0), Vector3(38.0, 2.5, 28.0), pmat, 8.0, false)
			_add_walkable_plateau(h_root, Vector3(55.0, 0.0, -45.0), Vector3(38.0, 2.5, 28.0), pmat, 8.0, false)
			_add_walkable_hill(h_root, Vector3(48.0, 0.0, 48.0), 15.0, 1.6, pmat)
			_add_walkable_hill(h_root, Vector3(-48.0, 0.0, -48.0), 15.0, 1.6, pmat)


func _add_walkable_plateau(parent: Node3D, center_pos: Vector3, size: Vector3, mat: StandardMaterial3D, ramp_width: float = 8.0, add_rails: bool = false) -> void:
	var h: float = size.y
	var plateau_body := StaticBody3D.new()

	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = size
	col.shape = bshape
	col.position = Vector3(0.0, h * 0.5, 0.0)
	plateau_body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = size
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, h * 0.5, 0.0)
	plateau_body.add_child(mesh_inst)

	plateau_body.position = center_pos
	parent.add_child(plateau_body)

	# Add 2 Walkable Ramps on opposite sides (North/South)
	var ramp_run := h * 4.2 # ~13.4 degree slope, gentle and fully walkable
	# Ramp 1 (South Edge leading down towards +Z)
	var r1_start := center_pos + Vector3(0.0, 0.0, size.z * 0.5 + ramp_run)
	var r1_end := center_pos + Vector3(0.0, h, size.z * 0.5)
	_add_walkable_ramp(parent, r1_start, r1_end, ramp_width, mat)

	# Ramp 2 (North Edge leading down towards -Z)
	var r2_start := center_pos + Vector3(0.0, 0.0, -size.z * 0.5 - ramp_run)
	var r2_end := center_pos + Vector3(0.0, h, -size.z * 0.5)
	_add_walkable_ramp(parent, r2_start, r2_end, ramp_width, mat)

	if add_rails:
		var rail_mat := StandardMaterial3D.new()
		rail_mat.albedo_color = Color(0.3, 0.85, 1.0)
		rail_mat.emission_enabled = true
		rail_mat.emission = Color(0.3, 0.85, 1.0)
		rail_mat.emission_energy_multiplier = 1.2
		_add_box_obstacle(parent, center_pos + Vector3(-size.x * 0.5, h + 0.35, 0.0), Vector3(0.4, 0.7, size.z), Vector3.ZERO, rail_mat)
		_add_box_obstacle(parent, center_pos + Vector3(size.x * 0.5, h + 0.35, 0.0), Vector3(0.4, 0.7, size.z), Vector3.ZERO, rail_mat)


func _add_walkable_ramp(parent: Node3D, start_pos: Vector3, end_pos: Vector3, width: float, mat: StandardMaterial3D, rail_col: Variant = null) -> void:
	var delta_vec := end_pos - start_pos
	var horiz_dist := Vector2(delta_vec.x, delta_vec.z).length()
	if horiz_dist < 0.1:
		return
	var length := delta_vec.length()
	var mid_pos := (start_pos + end_pos) * 0.5

	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(width, 0.35, length)
	col.shape = bshape
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(width, 0.35, length)
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var t := Transform3D()
	t.origin = mid_pos
	t = t.looking_at(end_pos, Vector3.UP)
	body.transform = t
	parent.add_child(body)

	# Low curb markers along the ramp sides
	var curb_mat := StandardMaterial3D.new()
	curb_mat.albedo_color = mat.albedo_color.lightened(0.2)
	var curb_l := MeshInstance3D.new()
	var c_box := BoxMesh.new()
	c_box.size = Vector3(0.3, 0.25, length)
	curb_l.mesh = c_box
	curb_l.material_override = curb_mat
	curb_l.position = Vector3(-width * 0.5, 0.2, 0.0)
	body.add_child(curb_l)

	var curb_r := MeshInstance3D.new()
	curb_r.mesh = c_box
	curb_r.material_override = curb_mat
	curb_r.position = Vector3(width * 0.5, 0.2, 0.0)
	body.add_child(curb_r)


func _add_walkable_hill(parent: Node3D, center_pos: Vector3, radius: float, height: float, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()

	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = height
	cshape.radius = radius * 0.8
	col.shape = cshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = height
	cyl.top_radius = radius * 0.55
	cyl.bottom_radius = radius
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(mesh_inst)

	body.position = center_pos
	parent.add_child(body)


func _add_walkable_bridge(parent: Node3D, start_pos: Vector3, end_pos: Vector3, width: float, mat: StandardMaterial3D, rail_col: Color) -> void:
	_add_walkable_ramp(parent, start_pos, end_pos, width, mat, rail_col)


func _build_boss_pit_arena(parent: Node3D, boss_pit_data: Dictionary, theme: String, mdata: Dictionary) -> void:
	var bpos: Vector3 = boss_pit_data.get("pos", Vector3(0.0, 0.0, -30.0))
	var radius: float = float(boss_pit_data.get("radius", 8.0))
	var pname: String = str(boss_pit_data.get("name", "Zone Boss Pit"))

	var arena_root := Node3D.new()
	arena_root.name = "BossPitArena"
	parent.add_child(arena_root)

	# 1. Base Arena Circular Floor
	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius + 0.8
	cyl.height = 0.25
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.13, 0.16)
	fmat.roughness = 0.85
	floor_mesh.mesh = cyl
	floor_mesh.material_override = fmat
	floor_mesh.position = Vector3(0.0, 0.1, 0.0)
	floor_body.add_child(floor_mesh)

	var fcol := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = radius
	cshape.height = 0.25
	fcol.shape = cshape
	fcol.position = Vector3(0.0, 0.1, 0.0)
	floor_body.add_child(fcol)
	floor_body.position = bpos
	arena_root.add_child(floor_body)

	# 2. Glowing Inner Rune Disk
	var rune_mesh := MeshInstance3D.new()
	var r_cyl := CylinderMesh.new()
	r_cyl.top_radius = radius * 0.45
	r_cyl.bottom_radius = radius * 0.48
	r_cyl.height = 0.05
	var rmat := StandardMaterial3D.new()
	var glow_col: Color = mdata.get("sky_horizon", Color(1.0, 0.6, 0.2))
	rmat.albedo_color = glow_col.darkened(0.3)
	rmat.emission_enabled = true
	rmat.emission = glow_col
	rmat.emission_energy_multiplier = 1.4
	rune_mesh.mesh = r_cyl
	rune_mesh.material_override = rmat
	rune_mesh.position = bpos + Vector3(0.0, 0.24, 0.0)
	arena_root.add_child(rune_mesh)

	# 3. 8 Perimeter Monolithic Arena Pillars with glowing braziers
	var pillar_count := 8
	var p_rad := radius - 0.4
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.22, 0.22, 0.25)
	pmat.roughness = 0.8

	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = glow_col
	b_mat.emission_enabled = true
	b_mat.emission = glow_col
	b_mat.emission_energy_multiplier = 2.8

	for i in range(pillar_count):
		var ang := i * (TAU / float(pillar_count))
		var px := bpos.x + cos(ang) * p_rad
		var pz := bpos.z + sin(ang) * p_rad

		var pillar_body := StaticBody3D.new()
		var pcol := CollisionShape3D.new()
		var pcshape := CylinderShape3D.new()
		pcshape.height = 5.2
		pcshape.radius = 0.55
		pcol.shape = pcshape
		pcol.position = Vector3(0.0, 2.6, 0.0)
		pillar_body.add_child(pcol)

		var p_mesh := MeshInstance3D.new()
		var cyl_p := CylinderMesh.new()
		cyl_p.height = 5.0
		cyl_p.top_radius = 0.5
		cyl_p.bottom_radius = 0.65
		p_mesh.mesh = cyl_p
		p_mesh.material_override = pmat
		p_mesh.position = Vector3(0.0, 2.5, 0.0)
		pillar_body.add_child(p_mesh)

		# Brazier cap
		var b_mesh := MeshInstance3D.new()
		var b_box := BoxMesh.new()
		b_box.size = Vector3(1.1, 0.4, 1.1)
		b_mesh.mesh = b_box
		b_mesh.material_override = pmat
		b_mesh.position = Vector3(0.0, 5.1, 0.0)
		pillar_body.add_child(b_mesh)

		# Glowing Fire / Core Sphere
		var f_mesh := MeshInstance3D.new()
		var f_sph := SphereMesh.new()
		f_sph.radius = 0.35
		f_sph.height = 0.7
		f_mesh.mesh = f_sph
		f_mesh.material_override = b_mat
		f_mesh.position = Vector3(0.0, 5.5, 0.0)
		pillar_body.add_child(f_mesh)

		# Omni lights on 4 cardinal pillars
		if i % 2 == 0:
			var light := OmniLight3D.new()
			light.light_color = glow_col
			light.light_energy = 1.3
			light.omni_range = 14.0
			light.position = Vector3(0.0, 5.6, 0.0)
			pillar_body.add_child(light)

		pillar_body.position = Vector3(px, 0.0, pz)
		arena_root.add_child(pillar_body)

	# 4. 3D Floating Pit Arena Label
	var lbl := Label3D.new()
	lbl.text = "★ %s ★\n[Boss Pit Arena]" % pname
	lbl.font_size = 28
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1.0, 0.88, 0.42)
	lbl.position = bpos + Vector3(0.0, 4.2, 0.0)
	arena_root.add_child(lbl)


# ------------------------------------------------------------------------------
# THEMED ARCHITECTURAL LANDMARKS (23 DISTINCT BIOMES)
# ------------------------------------------------------------------------------
func _build_themed_landmarks(parent: Node3D, theme: String, rock_mat: StandardMaterial3D, mdata: Dictionary) -> void:
	var lm_root := Node3D.new()
	lm_root.name = "ThemedLandmarks"
	parent.add_child(lm_root)

	match theme:
		"TECH_ARK":
			_add_box_obstacle(lm_root, Vector3(-24.0, 3.5, 4.0), Vector3(18.0, 1.2, 8.0), Vector3(0.2, 0.5, 0.35), rock_mat)
			_add_box_obstacle(lm_root, Vector3(24.0, 3.5, -12.0), Vector3(16.0, 1.2, 8.0), Vector3(-0.3, -0.6, -0.25), rock_mat)
			_add_tech_pylon(lm_root, Vector3(-16.0, 0.0, -18.0), Color(0.35, 0.95, 1.0))
			_add_tech_pylon(lm_root, Vector3(16.0, 0.0, -18.0), Color(0.35, 0.95, 1.0))
			_add_tech_pylon(lm_root, Vector3(-22.0, 0.0, 20.0), Color(0.35, 0.95, 1.0))
			_add_tech_pylon(lm_root, Vector3(22.0, 0.0, 20.0), Color(0.35, 0.95, 1.0))

		"ARK_SUPERCORE":
			_add_server_blade_rack(lm_root, Vector3(-24.0, 0.0, -14.0), 9.0, 12.0, Color(0.3, 0.95, 1.0))
			_add_server_blade_rack(lm_root, Vector3(24.0, 0.0, -14.0), 9.0, 12.0, Color(0.3, 0.95, 1.0))
			_add_tech_pylon(lm_root, Vector3(-14.0, 0.0, 18.0), Color(0.2, 1.0, 0.8))
			_add_tech_pylon(lm_root, Vector3(14.0, 0.0, 18.0), Color(0.2, 1.0, 0.8))
			_add_box_obstacle(lm_root, Vector3(0.0, 2.5, -2.0), Vector3(8.0, 5.0, 4.0), Vector3.ZERO, rock_mat)

		"AETHER_SKY":
			_add_floating_island_disc(lm_root, Vector3(-28.0, 5.5, -10.0), 10.0, 1.6, rock_mat, Color(0.4, 0.9, 1.0))
			_add_floating_island_disc(lm_root, Vector3(28.0, 6.0, -12.0), 11.0, 1.6, rock_mat, Color(0.4, 0.9, 1.0))
			_add_floating_boulder(lm_root, Vector3(0.0, 7.5, 20.0), Vector3(4.5, 3.2, 4.0), rock_mat, Color(0.35, 0.85, 1.0))
			_add_tech_pylon(lm_root, Vector3(-18.0, 0.0, 18.0), Color(0.4, 0.9, 1.0))
			_add_tech_pylon(lm_root, Vector3(18.0, 0.0, 18.0), Color(0.4, 0.9, 1.0))

		"FROZEN_SCRAP":
			_add_ice_spire(lm_root, Vector3(-28.0, 0.0, -10.0), 14.0, 2.2)
			_add_ice_spire(lm_root, Vector3(28.0, 0.0, -15.0), 16.0, 2.4)
			_add_ice_spire(lm_root, Vector3(-20.0, 0.0, 25.0), 11.0, 1.8)
			_add_ice_spire(lm_root, Vector3(22.0, 0.0, 22.0), 13.0, 2.0)
			_add_box_obstacle(lm_root, Vector3(0.0, 2.0, 16.0), Vector3(12.0, 1.5, 5.0), Vector3(0.1, 0.3, 0.1), rock_mat)

		"HOLY_TEMPLE":
			var col_mat := StandardMaterial3D.new()
			col_mat.albedo_color = Color(0.85, 0.82, 0.74)
			col_mat.roughness = 0.55
			_add_temple_column(lm_root, Vector3(-12.0, 0.0, 4.0), col_mat)
			_add_temple_column(lm_root, Vector3(12.0, 0.0, 4.0), col_mat)
			_add_temple_column(lm_root, Vector3(-12.0, 0.0, -12.0), col_mat)
			_add_temple_column(lm_root, Vector3(12.0, 0.0, -12.0), col_mat)
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(1.0, 0.88, 0.45))

		"SKY_SANCTUM":
			var s_mat := StandardMaterial3D.new()
			s_mat.albedo_color = Color(0.92, 0.89, 0.82)
			s_mat.roughness = 0.4
			_add_temple_column(lm_root, Vector3(-18.0, 0.0, 8.0), s_mat, 10.0)
			_add_temple_column(lm_root, Vector3(18.0, 0.0, 8.0), s_mat, 10.0)
			_add_temple_column(lm_root, Vector3(-18.0, 0.0, -16.0), s_mat, 10.0)
			_add_temple_column(lm_root, Vector3(18.0, 0.0, -16.0), s_mat, 10.0)
			_add_celestial_halo(lm_root, Vector3(0.0, 8.5, 0.0), 6.5, Color(1.0, 0.85, 0.4))
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(1.0, 0.95, 0.65))

		"DESERT_RUINS":
			_add_ancient_obelisk(lm_root, Vector3(-24.0, 0.0, -12.0), rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(24.0, 0.0, -12.0), rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(-18.0, 0.0, 26.0), rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(18.0, 0.0, 26.0), rock_mat)
			_add_box_obstacle(lm_root, Vector3(-8.0, 1.2, 8.0), Vector3(10.0, 2.4, 2.5), Vector3(0.0, 0.4, 0.0), rock_mat)

		"CATACOMB_CRYPT":
			_add_royal_sarcophagus(lm_root, Vector3(-20.0, 0.0, -10.0), 0.3, rock_mat, Color(0.4, 0.9, 0.6))
			_add_royal_sarcophagus(lm_root, Vector3(20.0, 0.0, -10.0), -0.3, rock_mat, Color(0.4, 0.9, 0.6))
			_add_ancient_obelisk(lm_root, Vector3(-14.0, 0.0, 18.0), rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(14.0, 0.0, 18.0), rock_mat)
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(0.3, 0.9, 0.7))

		"OBSIDIAN_CITADEL":
			_add_obsidian_monolith(lm_root, Vector3(-26.0, 0.0, 4.0), 13.0, rock_mat)
			_add_obsidian_monolith(lm_root, Vector3(26.0, 0.0, 4.0), 12.0, rock_mat)
			_add_obsidian_monolith(lm_root, Vector3(-18.0, 0.0, -18.0), 15.0, rock_mat)
			_add_obsidian_monolith(lm_root, Vector3(18.0, 0.0, -18.0), 14.0, rock_mat)
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(0.95, 0.25, 0.35))

		"VOLCANIC_BASIN":
			_add_box_obstacle(lm_root, Vector3(-22.0, 3.5, 14.0), Vector3(12.0, 7.0, 10.0), Vector3(0.1, 0.4, 0.1), rock_mat)
			_add_box_obstacle(lm_root, Vector3(22.0, 3.5, 14.0), Vector3(14.0, 7.0, 9.0), Vector3(-0.15, -0.3, 0.0), rock_mat)
			_add_box_obstacle(lm_root, Vector3(-25.0, 4.0, -15.0), Vector3(14.0, 8.0, 10.0), Vector3(0.2, 0.2, 0.1), rock_mat)
			_add_box_obstacle(lm_root, Vector3(25.0, 4.0, -15.0), Vector3(15.0, 8.0, 11.0), Vector3(-0.2, 0.5, 0.0), rock_mat)

		"MAGMA_CALDERA", "SCORCHED_CAULDRON":
			_add_magma_fissure(lm_root, Vector3(-22.0, 0.05, 0.0), 24.0, 3.2, Color(1.0, 0.35, 0.08))
			_add_magma_fissure(lm_root, Vector3(22.0, 0.05, 0.0), 24.0, 3.2, Color(1.0, 0.35, 0.08))
			_add_obsidian_monolith(lm_root, Vector3(-24.0, 0.0, 12.0), 16.0, rock_mat)
			_add_obsidian_monolith(lm_root, Vector3(24.0, 0.0, 12.0), 15.0, rock_mat)
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(1.0, 0.3, 0.1))

		"DAEVA_CRYPT":
			_add_obsidian_monolith(lm_root, Vector3(-22.0, 0.0, 8.0), 16.0, rock_mat)
			_add_obsidian_monolith(lm_root, Vector3(22.0, 0.0, 8.0), 16.0, rock_mat)
			_add_royal_sarcophagus(lm_root, Vector3(-16.0, 0.0, -14.0), 0.4, rock_mat, Color(0.85, 0.2, 0.95))
			_add_royal_sarcophagus(lm_root, Vector3(16.0, 0.0, -14.0), -0.4, rock_mat, Color(0.85, 0.2, 0.95))
			_add_sacred_fire_altar(lm_root, Vector3(0.0, 0.0, 18.0), Color(0.85, 0.2, 0.95))

		"LUMINESCENT_AQUIFER":
			_add_bioluminescent_fungus(lm_root, Vector3(-20.0, 0.0, -8.0), 5.5, 3.2, Color(0.2, 0.95, 0.85))
			_add_bioluminescent_fungus(lm_root, Vector3(20.0, 0.0, -8.0), 6.5, 3.8, Color(0.2, 0.95, 0.85))
			_add_bioluminescent_fungus(lm_root, Vector3(-14.0, 0.0, 16.0), 4.5, 2.8, Color(0.25, 0.9, 0.6))
			_add_bioluminescent_fungus(lm_root, Vector3(14.0, 0.0, 16.0), 5.0, 3.0, Color(0.25, 0.9, 0.6))
			_add_ice_spire(lm_root, Vector3(0.0, 0.0, 22.0), 10.0, 1.8)

		"BEAST_HIGHLAND":
			_add_fossil_ribcage(lm_root, Vector3(0.0, 0.0, -10.0), 22.0, 6, rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(-24.0, 0.0, 10.0), rock_mat)
			_add_ancient_obelisk(lm_root, Vector3(24.0, 0.0, 10.0), rock_mat)

		"OUTCAST_WASTELAND":
			_add_scavenger_watchtower(lm_root, Vector3(-22.0, 0.0, -14.0), 8.5, rock_mat, Color(1.0, 0.7, 0.2))
			_add_scavenger_watchtower(lm_root, Vector3(22.0, 0.0, -14.0), 8.5, rock_mat, Color(1.0, 0.7, 0.2))
			_add_trench_sandbag_revetment(lm_root, Vector3(-12.0, 0.0, 16.0), 14.0, 1.8, rock_mat)
			_add_trench_sandbag_revetment(lm_root, Vector3(12.0, 0.0, 16.0), 14.0, 1.8, rock_mat)

		"SKY_FRACTURE":
			_add_floating_boulder(lm_root, Vector3(-20.0, 6.0, -10.0), Vector3(5.0, 4.0, 4.5), rock_mat, Color(0.7, 0.5, 1.0))
			_add_floating_boulder(lm_root, Vector3(20.0, 7.0, -10.0), Vector3(5.5, 4.5, 4.0), rock_mat, Color(0.7, 0.5, 1.0))
			_add_celestial_halo(lm_root, Vector3(0.0, 9.0, 0.0), 7.0, Color(0.65, 0.45, 1.0))
			_add_ice_spire(lm_root, Vector3(-16.0, 0.0, 18.0), 12.0, 2.0)
			_add_ice_spire(lm_root, Vector3(16.0, 0.0, 18.0), 12.0, 2.0)

		"VAR_ROOTS":
			_add_tree_root_arch(lm_root, Vector3(0.0, 0.0, -8.0), 18.0, 7.5, rock_mat)
			var p_stone := StandardMaterial3D.new()
			p_stone.albedo_color = Color(0.60, 0.50, 0.38)
			_add_temple_column(lm_root, Vector3(-20.0, 0.0, 8.0), p_stone, 8.0)
			_add_temple_column(lm_root, Vector3(20.0, 0.0, 8.0), p_stone, 8.0)

		"BORDER_TRENCHES":
			_add_trench_sandbag_revetment(lm_root, Vector3(-24.0, 0.0, -10.0), 18.0, 2.0, rock_mat)
			_add_trench_sandbag_revetment(lm_root, Vector3(24.0, 0.0, -10.0), 18.0, 2.0, rock_mat)
			_add_scavenger_watchtower(lm_root, Vector3(0.0, 0.0, 22.0), 8.0, rock_mat, Color(1.0, 0.6, 0.2))

		"PERSEPOLIS_STEPPES":
			var p_stone := StandardMaterial3D.new()
			p_stone.albedo_color = Color(0.60, 0.50, 0.38)
			p_stone.roughness = 0.8
			_add_temple_column(lm_root, Vector3(-22.0, 0.0, 6.0), p_stone, 8.5)
			_add_temple_column(lm_root, Vector3(22.0, 0.0, 6.0), p_stone, 8.5)
			_add_temple_column(lm_root, Vector3(-22.0, 0.0, -16.0), p_stone, 8.5)
			_add_temple_column(lm_root, Vector3(22.0, 0.0, -16.0), p_stone, 8.5)
			_add_box_obstacle(lm_root, Vector3(0.0, 0.4, 0.0), Vector3(18.0, 0.8, 14.0), Vector3.ZERO, p_stone)

		"CRACK_MINING", "LOWER_CRATER", "BREACH_RIDGE":
			_add_central_farr_megaspire(lm_root, Vector3(0.0, 0.0, 2.0))
			_add_mining_rig_tower(lm_root, Vector3(-28.0, 0.0, 2.0))
			_add_mining_rig_tower(lm_root, Vector3(28.0, 0.0, 2.0))
			_add_mining_rig_tower(lm_root, Vector3(0.0, 0.0, -28.0))
			_add_mining_rig_tower(lm_root, Vector3(0.0, 0.0, 32.0))


func _add_box_obstacle(parent: Node3D, pos: Vector3, size: Vector3, rot: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = size
	col.shape = bshape
	col.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = size
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(mesh_inst)

	body.position = pos
	body.rotation = rot
	parent.add_child(body)


func _add_tech_pylon(parent: Node3D, pos: Vector3, neon_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = 6.0
	cshape.radius = 0.6
	col.shape = cshape
	col.position = Vector3(0.0, 3.0, 0.0)
	body.add_child(col)

	var p_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 6.0
	cyl.top_radius = 0.45
	cyl.bottom_radius = 0.7
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.20, 0.24, 0.28)
	pmat.metallic = 0.6
	pmat.roughness = 0.4
	p_mesh.mesh = cyl
	p_mesh.material_override = pmat
	p_mesh.position = Vector3(0.0, 3.0, 0.0)
	body.add_child(p_mesh)

	var neon_mesh := MeshInstance3D.new()
	var n_cyl := CylinderMesh.new()
	n_cyl.height = 4.5
	n_cyl.top_radius = 0.5
	n_cyl.bottom_radius = 0.55
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = neon_col
	nmat.emission_enabled = true
	nmat.emission = neon_col
	nmat.emission_energy_multiplier = 2.2
	neon_mesh.mesh = n_cyl
	neon_mesh.material_override = nmat
	neon_mesh.position = Vector3(0.0, 3.0, 0.0)
	body.add_child(neon_mesh)

	body.position = pos
	parent.add_child(body)


func _add_ice_spire(parent: Node3D, pos: Vector3, height: float, radius: float) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = height
	cshape.radius = radius
	col.shape = cshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(radius * 2.0, height, radius * 2.0)
	var imat := StandardMaterial3D.new()
	imat.albedo_color = Color(0.45, 0.85, 1.0, 0.88)
	imat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	imat.roughness = 0.15
	imat.emission_enabled = true
	imat.emission = Color(0.3, 0.7, 0.95)
	imat.emission_energy_multiplier = 0.8
	mesh_inst.mesh = prism
	mesh_inst.material_override = imat
	mesh_inst.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(mesh_inst)

	body.position = pos
	body.rotation.y = pos.x * 0.1
	parent.add_child(body)


func _add_temple_column(parent: Node3D, pos: Vector3, mat: StandardMaterial3D, h: float = 7.0) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = h
	cshape.radius = 0.75
	col.shape = cshape
	col.position = Vector3(0.0, h * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = h
	cyl.top_radius = 0.65
	cyl.bottom_radius = 0.8
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, h * 0.5, 0.0)
	body.add_child(mesh_inst)

	# Capital slab
	var cap := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.8, 0.5, 1.8)
	cap.mesh = bmesh
	cap.material_override = mat
	cap.position = Vector3(0.0, h + 0.25, 0.0)
	body.add_child(cap)

	body.position = pos
	parent.add_child(body)


func _add_sacred_fire_altar(parent: Node3D, pos: Vector3, fire_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := BoxShape3D.new()
	cshape.size = Vector3(2.5, 1.6, 2.5)
	col.shape = cshape
	col.position = Vector3(0.0, 0.8, 0.0)
	body.add_child(col)

	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(2.5, 1.6, 2.5)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.32, 0.30, 0.28)
	smat.roughness = 0.8
	b_mesh.mesh = b_box
	b_mesh.material_override = smat
	b_mesh.position = Vector3(0.0, 0.8, 0.0)
	body.add_child(b_mesh)

	# Fire Sphere & Omni Light
	var f_mesh := MeshInstance3D.new()
	var f_sph := SphereMesh.new()
	f_sph.radius = 0.65
	f_sph.height = 1.3
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = fire_col
	f_mat.emission_enabled = true
	f_mat.emission = fire_col
	f_mat.emission_energy_multiplier = 3.2
	f_mesh.mesh = f_sph
	f_mesh.material_override = f_mat
	f_mesh.position = Vector3(0.0, 2.1, 0.0)
	body.add_child(f_mesh)

	var light := OmniLight3D.new()
	light.light_color = fire_col
	light.light_energy = 1.6
	light.omni_range = 12.0
	light.position = Vector3(0.0, 2.2, 0.0)
	body.add_child(light)

	body.position = pos
	parent.add_child(body)


func _add_ancient_obelisk(parent: Node3D, pos: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(1.6, 9.0, 1.6)
	col.shape = bshape
	col.position = Vector3(0.0, 4.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.6, 8.0, 1.6)
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, 4.0, 0.0)
	body.add_child(mesh_inst)

	var tip := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(1.6, 2.0, 1.6)
	tip.mesh = prism
	tip.material_override = mat
	tip.position = Vector3(0.0, 9.0, 0.0)
	body.add_child(tip)

	body.position = pos
	parent.add_child(body)


func _add_obsidian_monolith(parent: Node3D, pos: Vector3, height: float, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(2.2, height, 1.8)
	col.shape = bshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(2.2, height, 1.8)
	mesh_inst.mesh = prism
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(mesh_inst)

	body.position = pos
	body.rotation.z = 0.08
	parent.add_child(body)


func _add_central_farr_megaspire(parent: Node3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = 14.0
	cshape.radius = 2.4
	col.shape = cshape
	col.position = Vector3(0.0, 7.0, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(4.8, 14.0, 4.8)
	var cmat := StandardMaterial3D.new()
	var col_amber := Color(1.0, 0.72, 0.16)
	cmat.albedo_color = col_amber
	cmat.emission_enabled = true
	cmat.emission = col_amber
	cmat.emission_energy_multiplier = 2.8
	cmat.roughness = 0.18
	mesh_inst.mesh = prism
	mesh_inst.material_override = cmat
	mesh_inst.position = Vector3(0.0, 7.0, 0.0)
	body.add_child(mesh_inst)

	var light := OmniLight3D.new()
	light.light_color = col_amber
	light.light_energy = 2.4
	light.omni_range = 24.0
	light.position = Vector3(0.0, 7.0, 0.0)
	body.add_child(light)

	body.position = pos
	parent.add_child(body)


func _add_mining_rig_tower(parent: Node3D, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(3.2, 10.0, 3.2)
	col.shape = bshape
	col.position = Vector3(0.0, 5.0, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = 10.0
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.8
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.24, 0.25, 0.28)
	rmat.metallic = 0.5
	rmat.roughness = 0.6
	mesh_inst.mesh = cyl
	mesh_inst.material_override = rmat
	mesh_inst.position = Vector3(0.0, 5.0, 0.0)
	body.add_child(mesh_inst)

	var w_mesh := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.4
	sph.height = 0.8
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(1.0, 0.65, 0.1)
	wmat.emission_enabled = true
	wmat.emission = Color(1.0, 0.65, 0.1)
	wmat.emission_energy_multiplier = 2.5
	w_mesh.mesh = sph
	w_mesh.material_override = wmat
	w_mesh.position = Vector3(0.0, 10.4, 0.0)
	body.add_child(w_mesh)

	body.position = pos
	parent.add_child(body)


func _add_floating_island_disc(parent: Node3D, pos: Vector3, radius: float, thickness: float, mat: StandardMaterial3D, glow_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = thickness
	cshape.radius = radius
	col.shape = cshape
	col.position = Vector3(0.0, thickness * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = thickness
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 0.8
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, thickness * 0.5, 0.0)
	body.add_child(mesh_inst)

	# Glowing thruster ring beneath
	var ring_mesh := MeshInstance3D.new()
	var r_cyl := CylinderMesh.new()
	r_cyl.height = 0.2
	r_cyl.top_radius = radius * 0.82
	r_cyl.bottom_radius = radius * 0.85
	var r_mat := StandardMaterial3D.new()
	r_mat.albedo_color = glow_col
	r_mat.emission_enabled = true
	r_mat.emission = glow_col
	r_mat.emission_energy_multiplier = 2.4
	ring_mesh.mesh = r_cyl
	ring_mesh.material_override = r_mat
	ring_mesh.position = Vector3(0.0, -0.1, 0.0)
	body.add_child(ring_mesh)

	body.position = pos
	parent.add_child(body)


func _add_floating_boulder(parent: Node3D, pos: Vector3, size: Vector3, mat: StandardMaterial3D, glow_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = size
	col.shape = bshape
	col.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = size
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(mesh_inst)

	var core := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = size.x * 0.22
	sph.height = size.y * 0.44
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = glow_col
	cmat.emission_enabled = true
	cmat.emission = glow_col
	cmat.emission_energy_multiplier = 2.0
	core.mesh = sph
	core.material_override = cmat
	core.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(core)

	body.position = pos
	body.rotation = Vector3(0.2, 0.4, 0.15)
	parent.add_child(body)


func _add_magma_fissure(parent: Node3D, pos: Vector3, length: float, width: float, glow_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(width, 0.3, length)
	col.shape = bshape
	col.position = Vector3(0.0, 0.15, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(width, 0.2, length)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = glow_col
	fmat.emission_enabled = true
	fmat.emission = glow_col
	fmat.emission_energy_multiplier = 2.8
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = fmat
	mesh_inst.position = Vector3(0.0, 0.1, 0.0)
	body.add_child(mesh_inst)

	var light := OmniLight3D.new()
	light.light_color = glow_col
	light.light_energy = 1.8
	light.omni_range = 14.0
	light.position = Vector3(0.0, 1.2, 0.0)
	body.add_child(light)

	body.position = pos
	parent.add_child(body)


func _add_fossil_ribcage(parent: Node3D, center_pos: Vector3, length: float, rib_count: int, bone_mat: StandardMaterial3D) -> void:
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.78, 0.74, 0.65)
	b_mat.roughness = 0.9

	var step := length / float(max(1, rib_count - 1))
	var half_len := length * 0.5
	for i in range(rib_count):
		var rz := -half_len + i * step
		var rib_h := 6.5 + sin(float(i) / float(rib_count) * PI) * 3.5
		var rib_w := 8.0 + sin(float(i) / float(rib_count) * PI) * 4.0

		# Left rib arch
		_add_box_obstacle(parent, center_pos + Vector3(-rib_w * 0.5, rib_h * 0.5, rz), Vector3(0.6, rib_h, 0.8), Vector3(0.0, 0.0, 0.22), b_mat)
		# Right rib arch
		_add_box_obstacle(parent, center_pos + Vector3(rib_w * 0.5, rib_h * 0.5, rz), Vector3(0.6, rib_h, 0.8), Vector3(0.0, 0.0, -0.22), b_mat)


func _add_scavenger_watchtower(parent: Node3D, pos: Vector3, height: float, mat: StandardMaterial3D, light_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(3.0, height, 3.0)
	col.shape = bshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var p_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = height
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.5
	p_mesh.mesh = cyl
	p_mesh.material_override = mat
	p_mesh.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(p_mesh)

	var plat := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(3.4, 0.4, 3.4)
	plat.mesh = b_box
	plat.material_override = mat
	plat.position = Vector3(0.0, height + 0.2, 0.0)
	body.add_child(plat)

	var light := OmniLight3D.new()
	light.light_color = light_col
	light.light_energy = 2.0
	light.omni_range = 16.0
	light.position = Vector3(0.0, height + 1.2, 0.0)
	body.add_child(light)

	body.position = pos
	parent.add_child(body)


func _add_bioluminescent_fungus(parent: Node3D, pos: Vector3, stem_h: float, cap_r: float, spore_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.height = stem_h
	cshape.radius = 0.55
	col.shape = cshape
	col.position = Vector3(0.0, stem_h * 0.5, 0.0)
	body.add_child(col)

	var stem_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = stem_h
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.6
	var s_mat := StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.24, 0.32, 0.30)
	stem_mesh.mesh = cyl
	stem_mesh.material_override = s_mat
	stem_mesh.position = Vector3(0.0, stem_h * 0.5, 0.0)
	body.add_child(stem_mesh)

	# Luminous Cap
	var cap_mesh := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = cap_r
	sph.height = cap_r * 1.2
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = spore_col
	c_mat.emission_enabled = true
	c_mat.emission = spore_col
	c_mat.emission_energy_multiplier = 2.5
	cap_mesh.mesh = sph
	cap_mesh.material_override = c_mat
	cap_mesh.position = Vector3(0.0, stem_h + cap_r * 0.4, 0.0)
	body.add_child(cap_mesh)

	var light := OmniLight3D.new()
	light.light_color = spore_col
	light.light_energy = 1.4
	light.omni_range = 10.0
	light.position = Vector3(0.0, stem_h + cap_r * 0.5, 0.0)
	body.add_child(light)

	body.position = pos
	parent.add_child(body)


func _add_server_blade_rack(parent: Node3D, pos: Vector3, height: float, width: float, led_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(width, height, 3.2)
	col.shape = bshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(width, height, 3.2)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.14, 0.16, 0.20)
	rmat.metallic = 0.7
	rmat.roughness = 0.35
	b_mesh.mesh = b_box
	b_mesh.material_override = rmat
	b_mesh.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(b_mesh)

	# Blinking LED Status Strip
	var led_mesh := MeshInstance3D.new()
	var led_box := BoxMesh.new()
	led_box.size = Vector3(width * 0.9, 0.35, 0.1)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = led_col
	lmat.emission_enabled = true
	lmat.emission = led_col
	lmat.emission_energy_multiplier = 3.0
	led_mesh.mesh = led_box
	led_mesh.material_override = lmat
	led_mesh.position = Vector3(0.0, height * 0.75, 1.62)
	body.add_child(led_mesh)

	body.position = pos
	parent.add_child(body)


func _add_royal_sarcophagus(parent: Node3D, pos: Vector3, rot_y: float, mat: StandardMaterial3D, rune_col: Color) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(3.2, 1.8, 5.5)
	col.shape = bshape
	col.position = Vector3(0.0, 0.9, 0.0)
	body.add_child(col)

	var b_mesh := MeshInstance3D.new()
	var b_box := BoxMesh.new()
	b_box.size = Vector3(3.2, 1.8, 5.5)
	b_mesh.mesh = b_box
	b_mesh.material_override = mat
	b_mesh.position = Vector3(0.0, 0.9, 0.0)
	body.add_child(b_mesh)

	var lid := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(3.2, 0.9, 5.5)
	var lid_mat := StandardMaterial3D.new()
	lid_mat.albedo_color = mat.albedo_color.lightened(0.15)
	lid_mat.emission_enabled = true
	lid_mat.emission = rune_col
	lid_mat.emission_energy_multiplier = 0.8
	lid.mesh = prism
	lid.material_override = lid_mat
	lid.position = Vector3(0.0, 2.25, 0.0)
	body.add_child(lid)

	body.position = pos
	body.rotation.y = rot_y
	parent.add_child(body)


func _add_celestial_halo(parent: Node3D, pos: Vector3, radius: float, glow_col: Color) -> void:
	var halo := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.4
	torus.outer_radius = radius
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = glow_col
	hmat.emission_enabled = true
	hmat.emission = glow_col
	hmat.emission_energy_multiplier = 3.2
	halo.mesh = torus
	halo.material_override = hmat
	halo.position = pos
	halo.rotation.x = deg_to_rad(75.0)

	var light := OmniLight3D.new()
	light.light_color = glow_col
	light.light_energy = 2.2
	light.omni_range = 18.0
	halo.add_child(light)

	parent.add_child(halo)


func _add_trench_sandbag_revetment(parent: Node3D, pos: Vector3, length: float, height: float, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(length, height, 1.8)
	col.shape = bshape
	col.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(length, height, 1.8)
	mesh_inst.mesh = bmesh
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(mesh_inst)

	body.position = pos
	parent.add_child(body)


func _add_tree_root_arch(parent: Node3D, pos: Vector3, span: float, height: float, mat: StandardMaterial3D) -> void:
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.35, 0.25, 0.16)
	rmat.roughness = 0.9

	_add_box_obstacle(parent, pos + Vector3(-span * 0.5, height * 0.5, 0.0), Vector3(2.2, height, 2.2), Vector3(0.0, 0.0, 0.25), rmat)
	_add_box_obstacle(parent, pos + Vector3(span * 0.5, height * 0.5, 0.0), Vector3(2.2, height, 2.2), Vector3(0.0, 0.0, -0.25), rmat)
	_add_box_obstacle(parent, pos + Vector3(0.0, height, 0.0), Vector3(span, 1.8, 2.0), Vector3.ZERO, rmat)


func _build_scatter_props(parent: Node3D, theme: String, ground_col: Color, mdata: Dictionary) -> void:
	var scatter_root := Node3D.new()
	scatter_root.name = "ScatterProps"
	parent.add_child(scatter_root)

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = ground_col.darkened(0.2)
	rock_mat.roughness = 0.9

	var coords := [
		Vector3(-35.0, 0.0, 32.0),
		Vector3(38.0, 0.0, 35.0),
		Vector3(-42.0, 0.0, -28.0),
		Vector3(36.0, 0.0, -38.0),
		Vector3(0.0, 0.0, -50.0),
		Vector3(0.0, 0.0, 50.0),
	]

	for i in range(coords.size()):
		var p: Vector3 = coords[i]
		var rock := MeshInstance3D.new()
		var bmesh := BoxMesh.new()
		var s := 1.6 + float(i % 3) * 0.7
		bmesh.size = Vector3(s, s * 0.7, s * 1.2)
		rock.mesh = bmesh
		rock.material_override = rock_mat
		rock.position = p + Vector3(0.0, s * 0.35, 0.0)
		rock.rotation = Vector3(0.1 * i, 0.3 * i, 0.05 * i)
		scatter_root.add_child(rock)


# ------------------------------------------------------------------------------
# MAP ENTITY SPAWNING (REFINERIES, NPCS, VEINS, PORTALS, BEACON, MOBS, PIT BOSS)
# ------------------------------------------------------------------------------
func _spawn_map_entities(mdata: Dictionary) -> void:
	# 1. Refineries
	var refineries: Array = mdata.get("refineries", [])
	for r in refineries:
		var ref := REFINERY_SCENE.instantiate() as RefineryStation
		ref.station_name = str(r.get("name", "Refinery Terminal"))
		ref.position = r.get("pos", Vector3.ZERO)
		_map_container.add_child(ref)

	# 2. Physical 3D NPCs (Potion, Weapon, Armor, Utility, Rebirth, Story Leader)
	var npcs: Array = mdata.get("npcs", [])
	for n in npcs:
		var npc := VENDOR_NPC_SCENE.instantiate() as VendorNpc
		npc.npc_name = str(n.get("name", "Vendor NPC"))
		npc.npc_title = str(n.get("title", "Merchant"))
		npc.vendor_type = str(n.get("type", "POTION"))
		npc.faction_id = str(n.get("faction", "sveleitre"))
		npc.body_color = n.get("body", Color(0.25, 0.35, 0.45))
		npc.accent_color = n.get("accent", Color(0.35, 0.9, 1.0))
		npc.position = n.get("pos", Vector3.ZERO)
		_map_container.add_child(npc)

	# 3. Farr Ore Veins
	var veins: Array = mdata.get("veins", [])
	for v in veins:
		var vein := FARR_VEIN_SCENE.instantiate() as FarrVein
		vein.vein_name = str(v.get("name", "Farr Vein"))
		vein.max_units = int(v.get("max_units", 5))
		vein.yield_per_cycle = int(v.get("yield", 10))
		vein.value_per_unit = int(v.get("val", 25))
		vein.mine_duration = float(v.get("dur", 2.0))
		vein.crystal_color = v.get("col", Color(0.95, 0.68, 0.15))
		var sc := float(v.get("scale", 1.0))
		vein.scale = Vector3(sc, sc, sc)
		vein.position = v.get("pos", Vector3.ZERO)
		_map_container.add_child(vein)

	# 4. Warp Portals
	var portals: Array = mdata.get("portals", [])
	for p in portals:
		var portal := WARP_PORTAL_SCENE.instantiate()
		portal.set("portal_title", str(p.get("title", "Zone Warp Gate")))
		portal.set("target_map_id", str(p.get("target", "svel_hq")))
		portal.set("portal_color", p.get("col", Color(0.4, 0.85, 1.0)))
		portal.position = p.get("pos", Vector3.ZERO)
		_map_container.add_child(portal)

	# 5. Interactive 3D Summon Beacon
	var beacon_data: Dictionary = mdata.get("summon_beacon", {})
	if not beacon_data.is_empty():
		var beacon := SUMMON_BEACON_SCENE.instantiate() as Node3D
		beacon.position = beacon_data.get("pos", Vector3(0.0, 0.0, 18.0))
		if beacon.has_method("set_beacon_data"):
			beacon.call("set_beacon_data", current_map_id, beacon_data.get("name", "Zone Rift Beacon"), beacon_data.get("col", Color(0.3, 0.85, 1.0)))
		_map_container.add_child(beacon)

	# 6. Hostile Mobs & Pit Boss
	var enemies: Array = mdata.get("enemies", [])
	var spawned_pit_boss := false
	for e in enemies:
		var enemy := ENEMY_UNIT_SCENE.instantiate() as EnemyUnit
		enemy.enemy_name = str(e.get("name", "Enemy Unit"))
		enemy.level = int(e.get("lv", 1))
		enemy.max_hp = int(e.get("hp", 100))
		enemy.attack_damage = int(e.get("atk", 10))
		enemy.attack_range = float(e.get("range", 2.2))
		enemy.aggro_radius = float(e.get("aggro", 6.5))
		enemy.bounty_reward = int(e.get("bounty", 80))
		enemy.drop_farr_units = int(e.get("farr_u", 6))
		enemy.drop_farr_value = int(e.get("farr_v", 120))
		enemy.body_color = e.get("body", Color(0.68, 0.22, 0.25))
		enemy.accent_color = e.get("accent", Color(1.0, 0.4, 0.2))
		var esc := float(e.get("scale", 1.0))
		enemy.scale = Vector3(esc, esc, esc)
		var is_boss := bool(e.get("is_pit_boss", false))
		enemy.is_pit_boss = is_boss
		if is_boss:
			enemy.add_to_group("pit_boss")
			spawned_pit_boss = true
		var epos: Vector3 = e.get("pos", Vector3.ZERO)
		enemy.position = epos
		_map_container.add_child(enemy)
		enemy.home_position = enemy.global_position if enemy.is_inside_tree() else enemy.position

	# If map has a dedicated pit_boss entry not already in enemies array:
	var pb_dict: Dictionary = mdata.get("pit_boss", {})
	if not spawned_pit_boss and not pb_dict.is_empty():
		awaken_pit_boss(current_map_id)


# ------------------------------------------------------------------------------
# SUMMON BEACON ACTIONS & PIT BOSS AWAKENING
# ------------------------------------------------------------------------------
func spawn_summoned_wave(zone_id: String, near_pos: Vector3) -> int:
	var mdata: Dictionary = GameData.MAPS.get(zone_id, {})
	var enemies: Array = mdata.get("enemies", [])
	var templates: Array = []
	for e in enemies:
		if not bool(e.get("is_pit_boss", false)):
			templates.append(e)
	if templates.is_empty() and enemies.size() > 0:
		templates.append(enemies[0])
	if templates.is_empty():
		return 0

	var spawned_count := 0
	var offsets := [
		Vector3(4.5, 0.0, 0.0),
		Vector3(-2.5, 0.0, 4.0),
		Vector3(-2.5, 0.0, -4.0),
	]
	for i in range(3):
		var t: Dictionary = templates[i % templates.size()]
		var enemy := ENEMY_UNIT_SCENE.instantiate() as EnemyUnit
		enemy.enemy_name = "[Summoned] " + str(t.get("name", "Hostile Unit"))
		enemy.level = int(t.get("lv", 5))
		enemy.max_hp = int(t.get("hp", 200))
		enemy.attack_damage = int(t.get("atk", 15))
		enemy.attack_range = float(t.get("range", 2.3))
		enemy.aggro_radius = float(t.get("aggro", 7.0))
		enemy.bounty_reward = int(t.get("bounty", 150))
		enemy.drop_farr_units = int(t.get("farr_u", 12))
		enemy.drop_farr_value = int(t.get("farr_v", 250))
		enemy.body_color = t.get("body", Color(0.68, 0.22, 0.25))
		enemy.accent_color = t.get("accent", Color(1.0, 0.4, 0.2))
		var esc := float(t.get("scale", 1.0))
		enemy.scale = Vector3(esc, esc, esc)
		var spawn_pos: Vector3 = near_pos + offsets[i]
		enemy.position = spawn_pos
		enemy.set_meta("is_summoned", true)
		enemy.add_to_group("summoned_wave")
		_map_container.add_child(enemy)
		enemy.home_position = enemy.global_position if enemy.is_inside_tree() else enemy.position
		spawned_count += 1
		COMBAT_VFX.spawn_aoe_blast(self, spawn_pos, 3.5, Color(0.3, 0.85, 1.0))

	return spawned_count


func awaken_pit_boss(zone_id: String) -> bool:
	var mdata: Dictionary = GameData.MAPS.get(zone_id, {})
	var pb: Dictionary = mdata.get("pit_boss", {})
	if pb.is_empty():
		return false

	var boss_name: String = str(pb.get("name", "Zone Pit Boss"))
	# Check if Pit Boss is already alive in this zone
	for n in get_tree().get_nodes_in_group("pit_boss"):
		var e := n as EnemyUnit
		if e and not e.is_dead and e.enemy_name == boss_name:
			return false

	# Check if an existing dead pit boss can be revived
	for n in get_tree().get_nodes_in_group("pit_boss"):
		var e := n as EnemyUnit
		if e and e.enemy_name == boss_name:
			e._respawn()
			COMBAT_VFX.spawn_aoe_blast(self, e.global_position, 8.0, Color(1.0, 0.85, 0.3))
			return true

	# Otherwise spawn fresh instance
	var enemy := ENEMY_UNIT_SCENE.instantiate() as EnemyUnit
	enemy.enemy_name = boss_name
	enemy.level = int(pb.get("lv", 20))
	enemy.max_hp = int(pb.get("hp", 2000))
	enemy.attack_damage = int(pb.get("atk", 40))
	enemy.attack_range = float(pb.get("range", 3.5))
	enemy.aggro_radius = float(pb.get("aggro", 9.0))
	enemy.bounty_reward = int(pb.get("bounty", 1500))
	enemy.drop_farr_units = int(pb.get("farr_u", 35))
	enemy.drop_farr_value = int(pb.get("farr_v", 1200))
	enemy.body_color = pb.get("body", Color(0.3, 0.3, 0.3))
	enemy.accent_color = pb.get("accent", Color(1.0, 0.7, 0.2))
	var esc := float(pb.get("scale", 2.5))
	enemy.scale = Vector3(esc, esc, esc)
	enemy.is_pit_boss = true
	enemy.add_to_group("pit_boss")
	var bpos: Vector3 = pb.get("pos", Vector3.ZERO)
	enemy.position = bpos
	_map_container.add_child(enemy)
	enemy.home_position = enemy.global_position if enemy.is_inside_tree() else enemy.position
	COMBAT_VFX.spawn_aoe_blast(self, bpos, 8.0, Color(1.0, 0.85, 0.3))
	return true


func clear_summoned_mobs() -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("summoned_wave"):
		if is_instance_valid(n):
			n.queue_free()
			count += 1
	return count
