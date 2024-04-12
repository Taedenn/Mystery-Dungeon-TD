class_name TileMapBuildingOverlay
extends Node
## Adds a tile over all TileMap spaces during build mode
## and removes them when building mode is over on the
## building signal bus.
##
## Usage Tutorial @ https://itch.io/dashboard/post/630838

@export var tile_map : TileMap
@export var building_system : BuildingSystem
@export var building_signal_bus : BuildingSignalBus

## The layer index of the tile_map which overlay
## tiles will be drawn on top of
@export var buildable_tile_map_layer = 0

## Tile set atlas to draw from (check TileMap's TileSet to get ID number)
@export var tile_set_atlas_source_id : int

## Position of the tile to draw within the tile set atlas
@export var atlas_coords = Vector2i(0,0)

## If you want to use an alternative tile rather than the origin you can
## change this to the id of the alternative tile instead of 0
@export var alternative_tile_id = 0

## What z index should the overlay layer show on?
@export var overlay_layer_z_index = 0

## Should the overlay be y sorted - Probably yes if isometric tilemap
@export var overlay_layer_sort_y = false

var overlay_tilemap_id
var drawn_coords : Array[Vector2i]

var showing : bool : 
	set(value):
		showing = value
		
		tile_map.set_layer_enabled(overlay_tilemap_id, showing)
		
		if(showing):
			var used_coords = tile_map.get_used_cells(buildable_tile_map_layer)
			update_drawn_coords(used_coords)

func _ready():
	building_system.building_mode_changed.connect(_on_building_mode_changed)
	building_signal_bus.tile_map_used_tiles_updated.connect(_on_tile_map_used_tiles_updated)
	building_signal_bus.tile_map_changed.connect(_on_tile_map_changed)
	
	var current_layers_count = tile_map.get_layers_count()
	overlay_tilemap_id = current_layers_count # highest index + 1
	tile_map.add_layer(overlay_tilemap_id)
	tile_map.set_layer_z_index(overlay_tilemap_id, overlay_layer_z_index)
	tile_map.set_layer_y_sort_enabled(overlay_tilemap_id, overlay_layer_sort_y)

func _on_building_mode_changed(p_is_building : bool):
	showing = p_is_building
	
## Update the map if the used tiles on the game map have changed
func _on_tile_map_used_tiles_updated(p_used_tiles : Array[Vector2i], p_layer : int, p_tile_map : TileMap):
	if(p_tile_map == tile_map && p_layer == buildable_tile_map_layer):
		update_drawn_coords(p_used_tiles)
		
func _get_coords_in_rect(p_tilemap_rect : Rect2) -> Array[Vector2i]:
	var tile_map_coords : Array[Vector2i] = []
	
	var start_coords = tile_map.local_to_map(p_tilemap_rect.position)
	var end_coords = tile_map.local_to_map(p_tilemap_rect.end)
	
	for x_coord in range(start_coords.x, end_coords.x, 1):
		for y_coord in range(start_coords.y, end_coords.x, 1):
			tile_map_coords.append(Vector2i(x_coord, y_coord))
	
	return tile_map_coords

func update_drawn_coords(p_draw_coords : Array[Vector2i]):
	# Clear removed coords
	for coords in drawn_coords:
		if(not p_draw_coords.has(coords)):
			tile_map.erase_cell(overlay_tilemap_id, coords)
			drawn_coords.erase(coords)
			
	for coords in p_draw_coords:
		if(not drawn_coords.has(coords)):
			tile_map.set_cell(overlay_tilemap_id, coords, tile_set_atlas_source_id, atlas_coords, alternative_tile_id)
			drawn_coords.append(coords)

func _on_tile_map_changed(p_active_tile_map : TileMap):
	tile_map = p_active_tile_map
