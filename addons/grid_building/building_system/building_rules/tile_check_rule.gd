class_name TileCheckRule
extends BuildingRule
## Defines requirements for a rule that will checking against a tile space for physics collisions or other tile properties

## The layers to detect collision objects which RuleCheckIndicators will be generated
## to include this rule as part of their placement validity tests
@export_flags_2d_physics() var apply_to_objects_mask : int = 1

## If a RuleCheckIndicator is invalid due to multiple rules, the one
## with the highest priority and a fail display settings set will be used
## in the indicator's sprite to display
@export_range(0, 10, 1, "or_greater") var visual_priority : int = 0

## Display settings for a indicator to use with an override priority
@export var fail_visual_settings : IndicatorVisualSettings

## The current set of indicators that will be used to validate_condition against
var indicators : Array[RuleCheckIndicator]

## Runs the rule against an array of indicators
## Returns the indicators that fail the test
func get_failing_indicators(p_indicators : Array[RuleCheckIndicator]) -> Array[RuleCheckIndicator]:
	push_error("Not Implemented")
	return []

func tear_down():
	indicators.clear()
