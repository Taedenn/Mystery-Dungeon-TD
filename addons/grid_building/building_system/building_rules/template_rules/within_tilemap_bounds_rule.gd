class_name WithinTilemapBoundsRule
extends TileCheckRule
## Checks that all tile collision indicators in the preview are over valid
## tiles

## Message to be passed along when the tile validates as successful
@export var success_message : String = "Placement is within map bounds"

## Message to be passed along when the rule requirement were not met
@export var failed_message : String = "Tried placing outside of valid map area"

@export var no_indicators_message = "No tile collision indicators to check for within tilemap bounds."

func setup(params : RuleValidationParameters) -> bool:
	return true

## For each tilemap indicator, check the tilemap to see if the tilemap at it's position is used on any layer or not
func validate_condition() -> RuleResult:
	if(indicators.size() == 0):
		return RuleResult.new(true, no_indicators_message)
	
	var failing_indicators = get_failing_indicators(indicators)
	
	if(failing_indicators.size() > 0):
		return RuleResult.new(false, failed_message)
	else:
		return RuleResult.new(true, success_message)

## Runs the rule against an array of indicators and
## Returns the failing indicators
func get_failing_indicators(p_indicators : Array[RuleCheckIndicator]) -> Array[RuleCheckIndicator]:
	var failing_indicators : Array[RuleCheckIndicator] = []
	
	for indicator in p_indicators:
		if(!is_over_valid_tile(indicator)):
			failing_indicators.append(indicator)
	
	return failing_indicators

## Checks whether the indicator is over a tile that has any tile data at all
## A tile with no tile data does not have a sprite set and is an unused tile
## Returns true if TileData is found or false if not
func is_over_valid_tile(p_indicator : RuleCheckIndicator) -> bool:
	p_indicator.force_shapecast_update()
	var tile_map : TileMap = p_indicator.tilemap
	var tile_under : Vector2i = tile_map.local_to_map(tile_map.to_local(p_indicator.global_position))
	
	for layer in tile_map.get_layers_count():
		var tile_data : TileData = tile_map.get_cell_tile_data(layer, tile_under)
		
		if(tile_data != null):
			return true
			
	return false
