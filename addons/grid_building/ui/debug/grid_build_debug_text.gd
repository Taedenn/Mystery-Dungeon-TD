extends Control

@export var grid_targeting_system : GridTargetingSystem :
	set(value):
		if(grid_targeting_system):
			grid_targeting_system.disconnect("positioner_updated", _on_positioner_updated)
			
		grid_targeting_system = value
		
		if(grid_targeting_system):
			grid_targeting_system.connect("positioner_updated", _on_positioner_updated)

@export var building_system : BuildingSystem

@export_group("Internal Nodes")
@export var label_mouse_position : Label
@export var label_tile_location : Label
@export var label_indicator_position : Label
@export var label_tilemap_collisions_count : Label
@export var label_blocking_bodies : Label

var mouse_tile


func _input(_event : InputEvent):
	var mouse_position : Vector2 = get_viewport().get_mouse_position()
	label_mouse_position.text = "Mouse: " + str(mouse_position)
	
	show_hover_tile_location()
	
	# Display the world position of the positioner
	var display_position : Vector2 =  grid_targeting_system.positioner.global_position
	label_indicator_position.text = "Pos X : " + str(display_position.x) + " Y: " + str(display_position.y)
	
	#label_blocking_bodies.text = str(bodies_str)
	var rci_manager = building_system.rule_check_indicator_manager
	
	if(rci_manager != null):
		label_tilemap_collisions_count.text = "Indicators in Collision: " + str(rci_manager.get_colliding_indicators().size())

		# Show names of blocking bodies over the grid indicator
		var bodies : Array[Node2D] = building_system.rule_check_indicator_manager.get_colliding_nodes()
		var bodies_str : String = ""
		
		for body in bodies:
			# Sometimes a body might be removed after being detected. ex. Pickups
			# So make sure it's still valid
			if(body != null):
				bodies_str += body.name + " \n"
	
		label_blocking_bodies.text = bodies_str
	
func _on_positioner_updated(_positioner : Node2D):
	show_hover_tile_location()

# Show the active tile location for the InteractableTilemap if one exists
func show_hover_tile_location() -> void:
	if(grid_targeting_system.tilemap != null):
		var tilemap_local_mouse_position = grid_targeting_system.tilemap.get_local_mouse_position()
		
		mouse_tile = grid_targeting_system.tilemap .local_to_map(
				tilemap_local_mouse_position
			)
		label_tile_location.text = "Tile: X: " + str(mouse_tile.x) + " Y: " + str(mouse_tile.y)
	else:
		mouse_tile = null
		label_tile_location.text= "No InteractableTileset"
	
