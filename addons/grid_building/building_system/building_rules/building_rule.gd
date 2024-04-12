class_name BuildingRule
extends Resource
## Defines a condition for building being allowed and can check
## whether that condition is valid for a set of shape casts

## Checks a set of shape casts for building validity and
## returns whether the condition has been met or not
func validate_condition() -> RuleResult:
	var rule_result : RuleResult = RuleResult.new(false, "This is a virtual condition function and should be implemented in a class that inherits from BuildingRule")
	print_debug("This is a virtual condition function and should be implemented in a class that inherits from BuildingRule")
	return rule_result

## Any code to run before the rule validates on a preview instance
## Provides the building system as a setup parameter so the rule can check any property
## of the current state of the system while it is validating the condition if needed
## Runs when the building system sets a new placeable preview instance
## Returns if setup was successful
func setup(params : RuleValidationParameters) -> bool:
	_pre_setup_validation(params)
	push_warning("Call to unimplemented virtual setup function. Implement setup in your extended rule class.")
	return false

## Any cleanup code to run after the system changes preview instances or stops building
## Runs before the building system changes placeable preview
func tear_down():
	pass

# Validates the rule and parameters before running setup
func _pre_setup_validation(params : RuleValidationParameters) -> bool:
	var no_problems = true
	
	if(params == null):
		push_error("Null validation parameters. Can't setup without params")
		
	return no_problems
