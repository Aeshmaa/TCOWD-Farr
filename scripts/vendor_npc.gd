class_name VendorNpc
extends StaticBody3D
## Physical 3D HQ Vendor NPC stationed on the sides of each Faction HQ.
## Players must walk up to this NPC in the 3D world (click to walk & interact)
## to open that specific NPC's shop dialog; walking away closes the shop.

enum NpcType {
	POTION,
	WEAPON,
	ARMOR,
	UTILITY,
}

@export var npc_name := "HQ Quartermaster"
@export var npc_title := "Potion Merchant"
@export_enum("POTION", "WEAPON", "ARMOR", "UTILITY") var vendor_type := "POTION"
@export var faction_id := "sveleitre"
@export var interact_distance := 3.2
@export var body_color := Color(0.25, 0.35, 0.45, 1.0)
@export var accent_color := Color(0.35, 0.9, 1.0, 1.0)

@onready var sprite: DirectionalSprite = $Sprite
@onready var label_3d: Label3D = $Label3D
@onready var pedestal: MeshInstance3D = $Pedestal


func _ready() -> void:
	add_to_group("vendor_npc")
	_apply_visuals()


func _apply_visuals() -> void:
	if label_3d:
		label_3d.text = "%s\n<%s>\n[Click to Trade]" % [npc_name, npc_title]
		label_3d.modulate = accent_color.lightened(0.25)
	if sprite:
		sprite.body_color = body_color
		sprite.accent_color = accent_color
		sprite.texture = sprite._make_placeholder_sheet(64)
	if pedestal and pedestal.mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color.darkened(0.3)
		mat.emission_enabled = true
		mat.emission = accent_color
		mat.emission_energy_multiplier = 0.55
		pedestal.material_override = mat
