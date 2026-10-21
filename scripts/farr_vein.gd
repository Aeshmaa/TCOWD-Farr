class_name FarrVein
extends StaticBody3D
## Interactable Farr Ore Node.
## Supports grades (Low / Rich / Megavein), visual state updates (Full / Half / Depleted),
## and automatic respawn after depletion.

signal vein_updated(vein: FarrVein)

@export var vein_name := "Farr Vein"
@export var max_units := 5
@export var yield_per_cycle := 10
@export var weight_per_unit := 2.0
@export var value_per_unit := 25
@export var mine_duration := 2.2
@export var respawn_seconds := 12.0
@export var interact_distance := 2.4
@export var crystal_color := Color(0.95, 0.68, 0.15, 1.0)

@onready var mesh_inst: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D

var remaining_units: int
var _respawn_timer := 0.0
var _mat: StandardMaterial3D


func _ready() -> void:
	add_to_group("farr_vein")
	remaining_units = max_units
	_mat = StandardMaterial3D.new()
	mesh_inst.material_override = _mat
	_refresh_visuals()


func _process(delta: float) -> void:
	if remaining_units <= 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			remaining_units = max_units
			_refresh_visuals()
			vein_updated.emit(self)
		else:
			label_3d.text = "%s\n[Depleted - %ds]" % [vein_name, ceili(_respawn_timer)]


func can_mine() -> bool:
	return remaining_units > 0


## Extracts one cycle of ore. Returns Dictionary with { "units": int, "weight": float, "value": int }.
func extract_one_cycle() -> Dictionary:
	if remaining_units <= 0:
		return {"units": 0, "weight": 0.0, "value": 0}
	remaining_units -= 1
	if remaining_units <= 0:
		_respawn_timer = respawn_seconds
	_refresh_visuals()
	vein_updated.emit(self)
	return {
		"units": yield_per_cycle,
		"weight": yield_per_cycle * weight_per_unit,
		"value": yield_per_cycle * value_per_unit,
	}


func _refresh_visuals() -> void:
	var ratio := float(remaining_units) / float(max(max_units, 1))
	if remaining_units <= 0:
		_mat.albedo_color = Color(0.28, 0.28, 0.3, 1.0)
		_mat.emission_enabled = false
		mesh_inst.scale = Vector3(0.7, 0.35, 0.7)
		label_3d.modulate = Color(0.65, 0.65, 0.65)
	elif ratio <= 0.5:
		_mat.albedo_color = crystal_color.darkened(0.2)
		_mat.emission_enabled = true
		_mat.emission = crystal_color
		_mat.emission_energy_multiplier = 0.9
		mesh_inst.scale = Vector3(0.88, 0.72, 0.88)
		label_3d.modulate = Color(1.0, 0.88, 0.45)
		label_3d.text = "%s (Half)\n[%d / %d]" % [vein_name, remaining_units, max_units]
	else:
		_mat.albedo_color = crystal_color
		_mat.emission_enabled = true
		_mat.emission = crystal_color
		_mat.emission_energy_multiplier = 1.7
		mesh_inst.scale = Vector3.ONE
		label_3d.modulate = Color(1.0, 0.92, 0.55)
		label_3d.text = "%s\n[%d / %d]" % [vein_name, remaining_units, max_units]
