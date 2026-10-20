extends NavigationRegion3D
## Greybox world. Bakes the navmesh at startup so you can move/add obstacles
## freely in the editor without remembering to re-bake.
## (You can also bake manually: select this node > "Bake NavigationMesh".)


func _ready() -> void:
	bake_navigation_mesh(false)
