class_name RefineryStation
extends StaticBody3D
## Base Refinery & Debt Office terminal.
## Clicking this station walks the player over and refines all Unrefined Farr,
## applying the proceeds toward Faction Debt and Wallet Credits.

@export var station_name := "Refinery & Debt Terminal"
@export var interact_distance := 3.0

@onready var label_3d: Label3D = $Label3D


func _ready() -> void:
	add_to_group("refinery_station")
	label_3d.text = "%s\n[Click to Extract & Pay Debt]" % station_name
