class_name PlacementValidator
extends Resource
## Runs tests for each rule using RuleCheckIndicators
## to determine if placement in the targeted location is
## valid if all rules validate successfully

signal validation_finished(results: ValidationResults)

## Rules that are enforced whenever placing any object into the game world by default
## Exists so you don't have to add the same rule to every single object individually
@export var base_rules: Array[BuildingRule] = []

@export var all_succeeded_message: String = "All building placement validation checks passed"
@export var failed_validations_message: String = "--- Rules Failed ---"
@export var failed_message_base = "Failed Placement"

## Whether debug shapes should be shown visibly for the area(s) used to generate
## RuleCheckIndicators
@export var show_debug_shapes = false

var _validated_rules: Array[BuildingRule] = []
var _setup_rules: Array[BuildingRule] = []
var _rule_check_indicator_manager: RuleCheckIndicatorManager
var _placeable: Placeable

var _ready_for_validating_rules = false


## Checks additional rules and default placement validator rules against the build system's current stae
## Returns the validation results including details of each build rule result
func validate_rules() -> ValidationResults:
	if not _ready_for_validating_rules:
		return ValidationResults.new(
			false,
			"Placement validator has not been successfully setup. Must run setup with true result.",
			[]
		)

	var results: ValidationResults
	var rule_results: Array[RuleResult] = []
	var all_rules_setup = true

	var rules_to_check: Array[BuildingRule] = []
	_validated_rules = []

	# By default, use base always include rules for validator
	if not _placeable.ignore_base_rules:
		rules_to_check.append_array(base_rules)

	rules_to_check.append_array(_placeable.placement_rules)

	for rule in rules_to_check:
		if not rule in _validated_rules:
			var rule_result: RuleResult = rule.validate_condition()
			rule_results.append(rule_result)

			if !rule_result.is_successful:
				all_rules_setup = false

			_validated_rules.append(rule)
		else:
			push_warning("Duplicate Rule : " + rule.resource_name + " - skipping")

	if all_rules_setup:
		results = ValidationResults.new(true, all_succeeded_message, rule_results)
	else:
		results = ValidationResults.new(false, failed_validations_message, rule_results)

	emit_signal("validation_finished", results)

	return results


## Sets up the placement validator to run a test with the base and placeable
## rules[br][br]
## Returns if the setup was successful
func setup(
	p_rule_check_indicator_manager: RuleCheckIndicatorManager,
	p_rule_params: RuleValidationParameters
) -> bool:
	_placeable = p_rule_params.placeable
	_rule_check_indicator_manager = p_rule_check_indicator_manager

	if _setup_rules.size() > 0:
		tear_down()

	if not _placeable.ignore_base_rules:
		_setup_rules.append_array(base_rules)

	_setup_rules.append_array(_placeable.placement_rules)

	var failing_rules: Array[BuildingRule] = setup_rules(_setup_rules, p_rule_params)

	_ready_for_validating_rules = failing_rules.size() == 0

	return _ready_for_validating_rules

## Sets up TileCheck Rules
## Returns any failing rules
func setup_rules(
	p_rules_to_setup: Array[BuildingRule], p_rule_params: RuleValidationParameters
) -> Array[BuildingRule]:
	if(p_rules_to_setup.size() == 0):
		push_warning("Trying to setup rules but there are no rules in p_rules_to_setup. Returning")
		return []
	
	var tile_check_rules: Array[TileCheckRule] = _filter_to_tile_check_rules(p_rules_to_setup)
	var pos_rules_dict = {}

	if tile_check_rules.size() > 0:
		_pre_check_rules(tile_check_rules)
		var indicators: Array[RuleCheckIndicator] = (
			_rule_check_indicator_manager
			. setup_indicators_for_object(p_rule_params.preview_instance, tile_check_rules)
		)

	var failing_rules: Array[BuildingRule] = []

	for rule in p_rules_to_setup:
		if not rule.setup(p_rule_params):
			failing_rules.append(rule)

	return failing_rules

func _pre_check_rules(p_tile_check_rules: Array[TileCheckRule]):
	var priority_rule_dict = {}

	for rule in p_tile_check_rules:
		if priority_rule_dict.has(rule.visual_priority):
			priority_rule_dict[rule.visual_priority].append(rule)
		else:
			priority_rule_dict[rule.visual_priority] = [rule]

	for key in priority_rule_dict.keys():
		var rules_with_priority = priority_rule_dict[key].size()
		if rules_with_priority > 1:
			push_warning(
				(
					"There are "
					+ str(rules_with_priority)
					+ " rules with the same visual priority "
					+ str(key)
					+ " Consider setting different values for rules to make their display hierarchy clear "
					+ str(p_tile_check_rules[key])
				)
			)


## Filters build rules to get all collision rules from an array of building rules
func _filter_to_tile_check_rules(p_building_rules: Array[BuildingRule]) -> Array[TileCheckRule]:
	var tile_check_rules: Array[TileCheckRule] = []

	for col_rule in p_building_rules.filter(func(rule): return rule is TileCheckRule):
		tile_check_rules.append(col_rule)

	return tile_check_rules


## Adds rule groups to the test and returns if all were setup successfully
func _add_rules_to_test(
	p_building_rules: Array[BuildingRule], params: RuleValidationParameters
) -> bool:
	var all_rules_setup = true

	for rule in p_building_rules:
		var results = rule.setup(params)

		if results == true:
			_setup_rules.append(rule)
		else:
			all_rules_setup = false
			push_error("Rule " + rule.resource_path + " failed setup.")

	return all_rules_setup

## Tear down base & placeable specific rules
func tear_down():
	for rule in _setup_rules:
		rule.tear_down()

	_setup_rules.clear()
	_ready_for_validating_rules = false
