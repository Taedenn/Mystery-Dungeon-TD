class_name ValidPlacementTileRule
extends TileCheckRule
## Checks that the each of the tiles under the indicators
## for this rule have matching custom data fields set
## on the tileset tile data

## Dictionary of expected custom data fields and values
## that must be true for tiles that this rule checks against
## in order for the rule to evaluate true
@export var expected_tile_custom_data = {}

## Message to be passed along when the tile validates as successful
@export var success_message : String = "All expected nearby tiles exist"

## Message to be passed along when the rule requirement were not met
@export var failed_message : String = "Tiles in expected tile areas are missing"

## Message to output when there are no tile collision indicators to check against the rule
@export var no_indicators_message : String = "No tile collision indicators to check for valid tile placement"

var _params : RuleValidationParameters

func _init(p_expected_tile_data : Dictionary = {}):
	expected_tile_custom_data = p_expected_tile_data

## Creates tile indicators on matching layers to test that colliding tiles
## exist in shape spaces around the object to be placed
func setup(params : RuleValidationParameters) -> bool:
	_params = params
	return _post_setup_validation()
		
		# Add all indicators to positioner Node2D
## Check each tile indicator of this test to ensure that they collide with the tilemap
func validate_condition() -> RuleResult:
	if(indicators != null && indicators.size() == 0):
		return RuleResult.new(true, no_indicators_message)
	
	var invalid_tile_count = get_failing_indicators(indicators).size()
	
	if(invalid_tile_count == 0):
		return RuleResult.new(true, success_message)
	else:
		return RuleResult.new(false, failed_message)
	
	return RuleResult.new(false, "Not implemented rule ValidPlacementTileRule")

## Runs the rule against an array of indicators and
## Returns the failing indicators
func get_failing_indicators(p_indicators : Array[RuleCheckIndicator]) -> Array[RuleCheckIndicator]:
	var failing_indicators : Array[RuleCheckIndicator] = []
	
	for indicator in p_indicators:
		if(_does_tile_have_valid_data(indicator) == false):
			# No collision means rule fails
			failing_indicators.append(indicator)

	return failing_indicators

## Frees tile indicators created for this test when the building system no longer
## is using this rule
func tear_down():
	_params = null
	indicators.clear()

## Checks if any entry into the tile_data array is not null or not
func _does_tile_have_valid_data(p_indicator : RuleCheckIndicator) -> bool:
	# All values must match at least one layer in the tile for tile to be considered valid
	var tilemap = p_indicator.tilemap
	var tile_pos = tilemap.local_to_map(tilemap.to_local(p_indicator.global_position))
	var match_count = 0

	# If any expected data, each expected data value has to be found on at least
	# one layer in each tested tile
	for key in expected_tile_custom_data:
		var found_match = false
		
		for layer in tilemap.get_layers_count():
			var found
			var tile_data : TileData = tilemap.get_cell_tile_data(layer, tile_pos)

			if(tile_data == null):
				return false

			var data_value = tile_data.get_custom_data(key)
		
			if(expected_tile_custom_data.get(key) == data_value):
				found_match = true
				break

		if(found_match == true):
			match_count += 1
				
	if(match_count == expected_tile_custom_data.size()):
		# All data checks passed
		return true
	else:
		# Missing values in tile layers
		return false

func _post_setup_validation() -> bool:
	var no_setup_problems = true
	
	if(expected_tile_custom_data.keys().size() == 0):
		push_warning("No expected tile custom data entered. This rule has nothing to evaluate." + str(resource_path))
		no_setup_problems = false
	
	return no_setup_problems

