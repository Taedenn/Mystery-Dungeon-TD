class_name GridPathingComponent
extends Node
## Tracks position and path during it's existence in the scene

	
## Emitted when the new tile does not match the old tile
signal targeting_new_tile(new_tile : Vector2i, old_tile : Vector2i)

@export var positioner : Node2D
@export var tilemap : TileMap

var start_position : Vector2
var current_position : Vector2
var time_held : float
var drag_distance : float

var _new_tile : Vector2i
var _last_tile : Vector2i

func _init(p_positioner : Node2D, p_tilemap : TileMap):
	positioner = p_positioner
	tilemap = p_tilemap
	start_position = positioner.global_position
	
	_last_tile = tilemap.local_to_map(tilemap.to_local(start_position))
	
func _process(delta):
	current_position = positioner.global_position
	drag_distance = start_position.distance_to(current_position)
	time_held += delta
	
	_new_tile = tilemap.local_to_map(tilemap.to_local(current_position))
	
	if(_new_tile != _last_tile):
		emit_signal("targeting_new_tile", _new_tile, _last_tile)
		_last_tile = _new_tile


