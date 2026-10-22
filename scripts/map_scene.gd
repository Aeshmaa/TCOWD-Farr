@tool
class_name MapScene
extends Node3D
## Root of every res://maps/<map_id>.tscn. Holds the editable atmosphere for the map.
##
## In the editor the child `Environment` (WorldEnvironment) and `Sun` (DirectionalLight3D) give you a
## live preview. At runtime the game copies them onto the shared environment/sun and removes the
## preview nodes, so you only ever edit them here.
##
## Children layout (everything is a normal node - move/delete/duplicate freely):
##   Terrain   (MapTerrain)  - heightmap + textures
##   Props     (Node3D)      - rocks, ruins, crystals, buildings (instances of res://assets/props/*.tscn)
##   Landmarks (Node3D)      - big hand-placed set pieces
##   Lights    (Node3D)      - braziers, glowing crystals etc.

@export var map_id := ""

@export_group("Sky")
## Equirectangular .hdr from res://assets/sky/ (Poly Haven CC0). Leave empty for plain colour sky.
@export var sky_hdri: Texture2D:
	set(v):
		sky_hdri = v
		_refresh_preview()
@export_range(0.1, 4.0) var sky_energy := 1.0:
	set(v):
		sky_energy = v
		_refresh_preview()
@export var sky_tint := Color.WHITE:
	set(v):
		sky_tint = v
		_refresh_preview()

@export_group("Fog & Ambient")
@export var fog_color := Color(0.55, 0.62, 0.72):
	set(v):
		fog_color = v
		_refresh_preview()
@export_range(0.0, 0.05, 0.0005) var fog_density := 0.006:
	set(v):
		fog_density = v
		_refresh_preview()
@export_range(0.0, 2.0) var ambient_energy := 0.9:
	set(v):
		ambient_energy = v
		_refresh_preview()
@export_range(0.0, 3.0) var exposure := 1.0:
	set(v):
		exposure = v
		_refresh_preview()
@export_range(0.0, 1.0) var glow_intensity := 0.35:
	set(v):
		glow_intensity = v
		_refresh_preview()

@export_group("Sun")
@export var sun_color := Color(1.0, 0.95, 0.85):
	set(v):
		sun_color = v
		_refresh_preview()
@export_range(0.0, 4.0) var sun_energy := 1.2:
	set(v):
		sun_energy = v
		_refresh_preview()
@export_range(-90.0, 0.0) var sun_pitch_deg := -48.0:
	set(v):
		sun_pitch_deg = v
		_refresh_preview()
@export_range(-180.0, 180.0) var sun_yaw_deg := -35.0:
	set(v):
		sun_yaw_deg = v
		_refresh_preview()

@export_group("Tools")
## Click in the Godot Inspector after repainting the heightmap PNG to re-snap all Props & Landmarks to the new ground height.
@export var snap_props_to_terrain := false:
	set(v):
		if v:
			snap_all_children_to_terrain()
		snap_props_to_terrain = false

var _env_node: WorldEnvironment
var _sun_node: DirectionalLight3D


func snap_all_children_to_terrain() -> void:
	var terrain := get_node_or_null("Terrain") as MapTerrain
	if terrain == null:
		return
	terrain.build()
	for group_name in ["BossPit", "Landmarks", "Props", "Lights"]:
		var grp := get_node_or_null(group_name) as Node3D
		if grp == null:
			continue
		for child in grp.get_children():
			var n := child as Node3D
			if n == null:
				continue
			var y_off := float(n.get_meta("y_offset", 0.0))
			n.position.y = terrain.height_at(n.position.x, n.position.z) + y_off


func _ready() -> void:
	_env_node = get_node_or_null("Environment") as WorldEnvironment
	_sun_node = get_node_or_null("Sun") as DirectionalLight3D
	_refresh_preview()
	if Engine.is_editor_hint():
		return
	# Runtime: hand everything to the game's shared environment, then drop the preview nodes.
	var wm := get_tree().get_first_node_in_group("world_zone_manager")
	if wm and wm.has_method("apply_map_environment") and _env_node and _sun_node:
		wm.call("apply_map_environment", _env_node.environment, _sun_node)
		_env_node.queue_free()
		_sun_node.queue_free()


func _build_environment() -> Environment:
	var env := Environment.new()
	if sky_hdri != null:
		var sm := PanoramaSkyMaterial.new()
		sm.panorama = sky_hdri
		sm.energy_multiplier = sky_energy
		var sky := Sky.new()
		sky.sky_material = sm
		env.sky = sky
		env.background_mode = Environment.BG_SKY
	else:
		var psm := ProceduralSkyMaterial.new()
		psm.sky_top_color = fog_color.darkened(0.4)
		psm.sky_horizon_color = fog_color
		psm.ground_horizon_color = fog_color.darkened(0.2)
		psm.ground_bottom_color = fog_color.darkened(0.6)
		var sky2 := Sky.new()
		sky2.sky_material = psm
		env.sky = sky2
		env.background_mode = Environment.BG_SKY
	env.background_energy_multiplier = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_energy = ambient_energy
	env.ambient_light_color = sky_tint
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = exposure
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env.fog_sky_affect = 0.35
	env.glow_enabled = true
	env.glow_intensity = glow_intensity
	env.glow_bloom = 0.05
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.4
	return env


func _refresh_preview() -> void:
	if not is_inside_tree():
		return
	if _env_node == null:
		_env_node = get_node_or_null("Environment") as WorldEnvironment
	if _sun_node == null:
		_sun_node = get_node_or_null("Sun") as DirectionalLight3D
	if _env_node:
		_env_node.environment = _build_environment()
	if _sun_node:
		_sun_node.light_color = sun_color
		_sun_node.light_energy = sun_energy
		_sun_node.rotation_degrees = Vector3(sun_pitch_deg, sun_yaw_deg, 0.0)
		_sun_node.shadow_enabled = true
		_sun_node.directional_shadow_max_distance = 140.0
