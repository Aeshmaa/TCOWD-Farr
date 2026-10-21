class_name DroppedOreBag
extends StaticBody3D
## Unrefined Farr dropped on death ("Chinvat Bridge judgment").
## Click on the bag to walk up and recover the dropped ore.

@export var interact_distance := 2.2

var units := 0
var weight := 0.0
var value := 0

@onready var label_3d: Label3D = $Label3D


func _ready() -> void:
	add_to_group("dropped_ore_bag")
	_update_label()


func setup(p_units: int, p_weight: float, p_value: int) -> void:
	units = p_units
	weight = p_weight
	value = p_value
	if is_node_ready():
		_update_label()


func _update_label() -> void:
	if label_3d:
		label_3d.text = "Dropped Farr Bag\n[%d Unrefined | Click to Loot]" % units
