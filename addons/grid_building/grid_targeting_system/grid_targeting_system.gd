class_name GridTargetingSystem
extends Node
## Tracks the position of the mouse on the tilemap snapping to the
## center of the tile that falls inside the mouse pointer.


## Emitted when the positioners location changes
## Passes the positioner node as an argument
signal positioner_updated(positioner : Node2D)

## Object references needed for the system to function properly
@export_group("External Dependencies")
## Holds the position of the mouse on the tilemap. The positioner's
## location should always be the center point of the tile that the 
## mouse position falls inside of
@export var positioner : Node2D

## The tilemap which the GridTargetingSystem is targeting tiles from
## and using for grid snapping
@export var tilemap : TileMap :
	set(value):
		if(tilemap == value):
			return
			
		tilemap = value
		
		if(tilemap == null):
			return
			
		# Update astar object
		if(_astar_grid == null):
			_astar_grid = AStarGrid2D.new()
		
		_astar_grid.region = tilemap.get_used_rect()
		
		# Cell size of (1,1) repsents the full size of one tile on the grid
		_astar_grid.cell_size = Vector2(1,1)
		_astar_grid.update()

@export_group("Tile Targeting")
## When set, limits tile section to only the character adjacent tile that is in the direction of the cirspr location
@export var limit_to_adjacent_tiles_target : Node2D

## The number of tiles distance away from the limit target (if one is set)
## that the pointer tile can be
@export var max_tile_distance : int = 3

## Whether to allow diaganol moves on the path to the nearest target adjacent tile
@export var allow_diaganol_tile_moves = true

@export_group("Other Settings")
## If this is true, when mouse input is consumed by UI under the cursor
## then the positioner and all child objects will hide until the mouse
## is over the game world again
@export var hide_when_mouse_movement_handled : bool = true

## The tile location where the mouse is currently hovering over represented as X / Y values of the tilemap
var mouse_tile : Vector2

## Whether the mouse input was consumed by GUI already or not
var mouse_handled : bool = false

var visible : bool = true :
	set(value):
		if(visible != value):
			visible = value
			
			if(visible):
				positioner.show()
			else:
				positioner.hide()
				
## Pathfinding for a 2d Tile Grid through the AStar search algorithm
var _astar_grid : AStarGrid2D

# Sets new references that are generally scene specific
# and may need to be changed from level to level.
func change_level_setup(p_tilemap : TileMap):
	self.tilemap = p_tilemap
	
## Move the positioner to the center of the mouse tile over where the mouse is
func _process(_delta : float):
	# Query the screen to see if a GUI is in the way of the pointer
	# visible = not is_cursor_over_gui()
	
	if(tilemap != null):
		# Use the position of the mouse to determine the grid tile position that the mouse
		# is hovering over
		mouse_tile = _get_tile_from_mouse_position()
		_move_positioner()

## Performs initial setup on the AStarGrid2D for pathfinding of adjacent tiles
func _ready():
	if(_astar_grid == null):
		_astar_grid = AStarGrid2D.new()
	
	if(allow_diaganol_tile_moves):
		_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	else:
		_astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

## Triggers a check of whether mouse motion events are handled by UI
## or not to set the visibility of the positioner and child objects
## when hide_when_mouse_movement_handled is set to true
func _input(event : InputEvent):
	if(hide_when_mouse_movement_handled):
		# Expect unhandled event to show grid targeter
		if(event is InputEventMouseMotion):
			call_deferred("_update_visibility")
			mouse_handled = true

## Checks to see if mouse movement events were handled by UI
## when hide_when_mouse_movement_handled for visibility of the grid positioner
func _unhandled_input(event : InputEvent):
	if(hide_when_mouse_movement_handled):
		if(event is InputEventMouseMotion):
			mouse_handled = false

## Uses whether the mouse movement was consumed by UI
## to determine if the positioner and child objects should
## be visible or invisible. Only called when hide_when_mouse_movement_handled is true
func _update_visibility():
	# If the mouse is handled, it's over active gui
	# so hide the visibility of the grid targeting indicator
	visible = not mouse_handled
	
	# Reset until next event
	mouse_handled = true
		
## Move the positioner to adjust the shown position of any visual targeting elements
func _move_positioner():
	var pos_map_local : Vector2 
	
	if(!limit_to_adjacent_tiles_target):
		# If mouse tile, move grid indicator to position of tile
		pos_map_local = tilemap.map_to_local(mouse_tile)
	else:
		var nearest_adjacent_tile : Vector2i = _get_nearest_adjacent_tile(mouse_tile)
		pos_map_local = tilemap.map_to_local(nearest_adjacent_tile)
	
	## Adjust by tilemap position to get global position
	positioner.global_position = pos_map_local + tilemap.position
	emit_signal("positioner_updated", positioner)

## Returns the tile on the tilemap where the mouse is currently hovering over
func _get_tile_from_mouse_position():
	var mouse_pos = tilemap.get_local_mouse_position()
	return tilemap.local_to_map(mouse_pos)
			
func _get_nearest_adjacent_tile(p_mouse_tile : Vector2i) -> Vector2i:
	var target_position : Vector2 = limit_to_adjacent_tiles_target.global_position
	var target_tile : Vector2i = tilemap.local_to_map(tilemap.to_local(target_position))
	var path : PackedVector2Array = _astar_grid.get_point_path(target_tile, p_mouse_tile)
	
	# Choosethe point down the path either at the end of the max steps towards the end
	# Subtract one to account for array index
	var selected_step_index = min(path.size() - 1, max_tile_distance)
	
	return path[selected_step_index]
