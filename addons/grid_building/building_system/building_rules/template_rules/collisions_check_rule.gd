class_name CollisionsCheckRule
extends TileCheckRule
## Rule that checks for collisions and determines if the rule
## passes or fails depending on pass_on_collision's true/false value

## Whether this rule passes where there is a collision on the tile or not
@export var pass_on_collision = false

## The mask to assign to a RuleCheckIndicator to
## scan for collisions in other object or tiles physics layers
@export_flags_2d_physics() var collision_mask = 1

@export_group("Message Settings")
## Message to be passed along when the tile validates as successful
@export var success_message : String = "No placement collisions found"

## Message to be passed along when the rule requirement were not met
@export var expected_no_collisions_message : String = "Must have no collisions"

## When collision is expected (physics overlap), this message will be added to failed results
@export var expected_collisions_message : String = "Must overlap " 

## Add name of CollisionsCheckRule resource to the start of a fail / success message
@export var prepend_resource_name : bool

## Whether to show a list of layers tested in output messages
@export var append_layer_names = false
@export var layers_tested_prefix : String = " : Layers Checked: "

@export var no_indicators_message : String = "No tile collision indicators to check for collisions in placement"

var _rule_check_layer_names : Array[String]
var _params : RuleValidationParameters

func setup(params : RuleValidationParameters) -> bool:
	if(not _pre_setup_validation(params)): return false
	_params = params
	_rule_check_layer_names = PhysicsMatchingUtils2D.get_physics_layer_names_from_mask(collision_mask)
	return true

func validate_condition() -> RuleResult:
	var rule_result : RuleResult
	var do_any_have_collision = false
	
	if(indicators.size() == 0):
			return RuleResult.new(true, no_indicators_message)
	
	var output_message : String
	var is_successful = get_failing_indicators(indicators).size() == 0
	
	if(prepend_resource_name):
		output_message += resource_name + ": "
	
	if(is_successful):
		output_message += success_message
	else:
		if(pass_on_collision):
			output_message += expected_collisions_message
			
			for layer_name in PhysicsMatchingUtils2D.get_physics_layer_names_from_mask(collision_mask):
				output_message += "[" + layer_name + "] "
			
		else:
			
			output_message += expected_no_collisions_message
		
	if(append_layer_names):
		output_message += "\n" + layers_tested_prefix + str(_rule_check_layer_names)
	
	rule_result = RuleResult.new(is_successful, output_message)
		
	return rule_result

## Runs the rule against an array of indicators
## Returns the number of failing indicators
func get_failing_indicators(p_indicators : Array[RuleCheckIndicator]) -> Array[RuleCheckIndicator]:
	var failed_indicators : Array[RuleCheckIndicator] = []
	
	for indicator in p_indicators:
		indicator.collision_mask = collision_mask
		indicator.force_shapecast_update()
		
		if(pass_on_collision):
			if(not indicator.is_colliding()):
				failed_indicators.append(indicator)
		else:
			if(indicator.is_colliding()):
				failed_indicators.append(indicator)
			
	return failed_indicators

func tear_down():
	_params = null
	indicators.clear()
