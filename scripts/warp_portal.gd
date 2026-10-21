class_name WarpPortal
extends StaticBody3D
## Physical 3D Zone Warp Portal that transports the player between the 9 World Maps:
## - 3 Faction HQ Maps (svel_hq, order_hq, legion_hq)
## - 3 Faction Basic Leveling Ground Maps (svel_basic, order_basic, legion_basic)
## - 2 Contested Upper-Level Grinding Maps (contested_steppes, contested_cauldron)
## - 1 Central PvPvE Farr Mining War Ground (farr_mining_ground)

@export var portal_title := "Zone Warp Gate"
@export var target_map_id := "farr_mining_ground"
@export var portal_color := Color(0.35, 0.85, 1.0)
@export var interact_distance := 3.2

@onready var mesh_ring: MeshInstance3D = $RingMesh
@onready var mesh_core: MeshInstance3D = $CoreMesh
@onready var label_3d: Label3D = $Label3D

var _pulse_time := 0.0


func _ready() -> void:
	add_to_group("warp_portal")
	_apply_visuals()


func _process(delta: float) -> void:
	_pulse_time += delta * 2.4
	if mesh_core:
		var s := 1.0 + 0.08 * sin(_pulse_time)
		mesh_core.scale = Vector3(s, 1.0, s)


func setup_portal(title: String, dest_map_id: String, color: Color) -> void:
	portal_title = title
	target_map_id = dest_map_id
	portal_color = color
	if is_inside_tree():
		_apply_visuals()


func _apply_visuals() -> void:
	if mesh_ring:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = portal_color.darkened(0.35)
		mat.emission_enabled = true
		mat.emission = portal_color
		mat.emission_energy_multiplier = 1.6
		mat.roughness = 0.25
		mesh_ring.material_override = mat
	if mesh_core:
		var cmat := StandardMaterial3D.new()
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.albedo_color = Color(portal_color.r, portal_color.g, portal_color.b, 0.45)
		cmat.emission_enabled = true
		cmat.emission = portal_color
		cmat.emission_energy_multiplier = 2.2
		mesh_core.material_override = cmat
	if label_3d:
		var dest_info: Dictionary = GameData.MAPS.get(target_map_id, {})
		var dest_name: String = dest_info.get("name", target_map_id)
		var lv_band: String = dest_info.get("level_band", "")
		label_3d.modulate = portal_color.lightened(0.25)
		label_3d.text = "[WARP PORTAL] %s\n-> %s (%s)\n(Click to Warp)" % [portal_title, dest_name, lv_band]
