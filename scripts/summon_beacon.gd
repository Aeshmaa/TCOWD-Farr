class_name SummonBeacon
extends StaticBody3D
## Interactive 3D Monument in each zone that summons monster grinding packs
## and awakens the Zone's dedicated Pit Boss!

signal summon_triggered(kind: String, message: String)

@export var beacon_name := "Rift Summon Beacon"
@export var zone_id := "svel_hq"
@export var interact_distance := 3.6
@export var beacon_color := Color(0.4, 0.9, 1.0)

@onready var label_3d: Label3D = $Label3D
@onready var crystal_mesh: MeshInstance3D = $FloatingCore
@onready var light_beam: MeshInstance3D = $LightBeam

var _spin_phase := 0.0


func _ready() -> void:
	add_to_group("summon_beacon")
	_apply_visuals()


func _process(delta: float) -> void:
	_spin_phase += delta * 2.2
	if crystal_mesh:
		crystal_mesh.rotation.y += delta * 1.5
		crystal_mesh.position.y = 1.95 + sin(_spin_phase) * 0.18
	if light_beam:
		var beam_mat := light_beam.material_override as StandardMaterial3D
		if beam_mat:
			beam_mat.albedo_color.a = 0.35 + sin(_spin_phase * 2.0) * 0.15


func _apply_visuals() -> void:
	if label_3d:
		label_3d.text = "★ %s ★\n[Click to Summon Monsters / Pit Boss]" % beacon_name
		label_3d.modulate = beacon_color.lightened(0.3)

	if crystal_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = beacon_color
		mat.emission_enabled = true
		mat.emission = beacon_color
		mat.emission_energy_multiplier = 2.4
		mat.roughness = 0.2
		crystal_mesh.material_override = mat

	if light_beam:
		var b_mat := StandardMaterial3D.new()
		b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b_mat.albedo_color = Color(beacon_color.r, beacon_color.g, beacon_color.b, 0.4)
		light_beam.material_override = b_mat


func get_pit_boss_name() -> String:
	var mdata: Dictionary = GameData.MAPS.get(zone_id, {})
	var pb: Dictionary = mdata.get("pit_boss", {})
	return str(pb.get("name", "Zone Pit Boss"))


func summon_monster_wave(player: Node3D) -> int:
	var world_mgr := get_tree().get_first_node_in_group("world_zone_manager") as WorldZoneManager
	if world_mgr == null:
		return 0
	var count := world_mgr.spawn_summoned_wave(zone_id, global_position)
	summon_triggered.emit("WAVE", "Summoned %d hostile monsters around the Beacon!" % count)
	return count


func summon_pit_boss(player: Node3D) -> bool:
	var world_mgr := get_tree().get_first_node_in_group("world_zone_manager") as WorldZoneManager
	if world_mgr == null:
		return false
	var success := world_mgr.awaken_pit_boss(zone_id)
	if success:
		summon_triggered.emit("BOSS", "Awakened Pit Boss [%s] in the Boss Pit!" % get_pit_boss_name())
	return success
