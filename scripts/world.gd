class_name WorldZoneManager
extends NavigationRegion3D
## 9-Map World Zone Manager:
## Dynamically loads and populates any of the 9 World Maps defined in `GameData.MAPS`:
## - 3 Faction HQ Maps (`svel_hq`, `order_hq`, `legion_hq`)
## - 3 Faction Basic Leveling Ground Maps (`svel_basic`, `order_basic`, `legion_basic`)
## - 2 Contested Upper-Level Grinding Maps (`contested_steppes`, `contested_cauldron`)
## - 1 Central PvPvE Farr Mining War Ground (`farr_mining_ground`)

signal map_loaded(map_id: String, map_data: Dictionary)

const REFINERY_SCENE := preload("res://scenes/refinery_station.tscn")
const VENDOR_NPC_SCENE := preload("res://scenes/vendor_npc.tscn")
const FARR_VEIN_SCENE := preload("res://scenes/farr_vein.tscn")
const WARP_PORTAL_SCENE := preload("res://scenes/warp_portal.tscn")
const ENEMY_UNIT_SCENE := preload("res://scenes/enemy_unit.tscn")

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
		if child is RefineryStation or child is VendorNpc or child is FarrVein or child is EnemyUnit:
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
	_spawn_map_entities(mdata)
	bake_navigation_mesh(false)
	map_loaded.emit(current_map_id, mdata)
	return mdata


func _apply_map_atmosphere(mdata: Dictionary) -> void:
	var ground_mesh := get_node_or_null("Ground/MeshInstance3D") as MeshInstance3D
	if ground_mesh:
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = mdata.get("ground_color", Color(0.2, 0.22, 0.25))
		gmat.roughness = 0.9
		ground_mesh.material_override = gmat

	var env_node := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment if get_parent() else null
	if env_node and env_node.environment and env_node.environment.sky:
		var sky_mat := env_node.environment.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			sky_mat.sky_top_color = mdata.get("sky_top", Color(0.12, 0.15, 0.22))
			sky_mat.sky_horizon_color = mdata.get("sky_horizon", Color(0.28, 0.32, 0.40))
			sky_mat.ground_horizon_color = mdata.get("sky_horizon", Color(0.22, 0.25, 0.32)).darkened(0.25)


func _spawn_map_entities(mdata: Dictionary) -> void:
	# 1. Refineries
	var refineries: Array = mdata.get("refineries", [])
	for r in refineries:
		var ref := REFINERY_SCENE.instantiate() as RefineryStation
		ref.station_name = str(r.get("name", "Refinery Terminal"))
		ref.position = r.get("pos", Vector3.ZERO)
		_map_container.add_child(ref)

	# 2. Physical 3D NPCs (Potion, Weapon, Armor, Utility, Rebirth)
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

	# 4. Physical 3D Warp Portals
	var portals: Array = mdata.get("portals", [])
	for p in portals:
		var portal := WARP_PORTAL_SCENE.instantiate()
		portal.set("portal_title", str(p.get("title", "Zone Warp Gate")))
		portal.set("target_map_id", str(p.get("target", "farr_mining_ground")))
		portal.set("portal_color", p.get("col", Color(0.35, 0.85, 1.0)))
		portal.position = p.get("pos", Vector3.ZERO)
		_map_container.add_child(portal)

	# 5. Mobs, Elites, Mini-Bosses & Forsworn World Bosses
	var enemies: Array = mdata.get("enemies", [])
	for e in enemies:
		var enemy := ENEMY_UNIT_SCENE.instantiate() as EnemyUnit
		enemy.enemy_name = str(e.get("name", "Hostile Unit"))
		enemy.level = int(e.get("lv", 5))
		enemy.max_hp = int(e.get("hp", 200))
		enemy.attack_damage = int(e.get("atk", 15))
		enemy.attack_range = float(e.get("range", 2.3))
		enemy.aggro_radius = float(e.get("aggro", 7.0))
		enemy.bounty_reward = int(e.get("bounty", 150))
		enemy.drop_farr_units = int(e.get("farr_u", 12))
		enemy.drop_farr_value = int(e.get("farr_v", 250))
		enemy.body_color = e.get("body", Color(0.68, 0.22, 0.25))
		enemy.accent_color = e.get("accent", Color(1.0, 0.4, 0.2))
		var esc := float(e.get("scale", 1.0))
		enemy.scale = Vector3(esc, esc, esc)
		var epos: Vector3 = e.get("pos", Vector3.ZERO)
		enemy.position = epos
		_map_container.add_child(enemy)
		enemy.home_position = enemy.global_position
