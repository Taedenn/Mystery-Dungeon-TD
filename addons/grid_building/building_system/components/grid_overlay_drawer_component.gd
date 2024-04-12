class_name GridOverlayDrawerComponent
extends Node
## Child component of building system that draws a visible grid over the tile_map usesd area
## so players can see where the tiles border each other
## [[ DEPRECATED: Use TileMapBuildingOverlay Instead. It's better :) ]]

## Whether the grid overlay is allowed to be visible while the building system is building
@export var show_overlay_while_building : bool = true :
	set(value):
		show_overlay_while_building = value
		
		# Hide if not show_overlay_while_building
		if(grid_overlay):
			if(!value):
				grid_overlay.hide()
			elif(building_system.is_building):
				grid_overlay.show()

## Tilable texture that will be shown over each tile_map tile. It should match the tile size of the map.
@export var grid_overlay_tile_texture : Texture2D

## Self modulate color to apply to the tile texture that multiplies the original color to 
## end up with a new color
@export var texture_modulate_color : Color = Color.WHITE

## Layers which should receive lighting on the draw texture rect
@export_flags_2d_render var light_mask = 1

## The parent building system that this component should attach to
@onready var building_system : BuildingSystem = get_parent()

## Active tile_map from the building system
@export var tile_map : TileMap

var source_id : int

## The used spaces on the tile_map (1 tile = 1 size value for x / y)
var used_rect : Rect2

## The texture rect created by this component to overlay above the tiilemap
var grid_overlay : TextureRect

var _seperate_canvas_layer : CanvasLayer

func _ready():
	push_warning("Deprecated. You should switch to GridOverlayDrawerComponent which overlays tiles directly onto the tilemap.")
	building_system.connect("building_mode_changed", _on_building_mode_changed)
	
func _on_building_mode_changed(is_building : bool):
	if(tile_map == null):
		_setup_for_tile_map()
	
	if(show_overlay_while_building && is_building):
		grid_overlay.show()
	else:
		grid_overlay.hide()

func _setup_for_tile_map():
	tile_map = building_system.tilemap
	
	if(tile_map == null):
		# Get the show_overlay_while_building tile_map
		tile_map = building_system.tilemap

	# Create layer if it doesn't exist
	used_rect = tile_map.get_used_rect()
	
	# Create grid overlay from texture
	if(grid_overlay == null):
		grid_overlay = TextureRect.new()
		grid_overlay.stretch_mode = TextureRect.STRETCH_TILE
		grid_overlay.texture = grid_overlay_tile_texture
		grid_overlay.self_modulate = texture_modulate_color
		
		# Setup lighting
		grid_overlay.light_mask = light_mask
	
	var tile_size : Vector2 = tile_map.tile_set.tile_size
	grid_overlay.size = used_rect.size * tile_size
	
	# Position in top left corner of the tile_map
	var tile_map_offset = Vector2(
		tile_map.position.x / tile_size.x,
		tile_map.position.y / tile_size.y
	)
	
	grid_overlay.position = Vector2(
		used_rect.position.x * tile_size.x,
		used_rect.position.y * tile_size.y
		)
		
	tile_map.add_child(grid_overlay)
