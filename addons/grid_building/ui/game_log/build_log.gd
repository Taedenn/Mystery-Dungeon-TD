extends Control

## Shows recent build messages from the build system

@export var message_log : RichTextLabel
@export var building_signal_bus : BuildingSignalBus :
	set(value):
		# If a new building system, disconnect from old one and connect to the new one's signals
		if(building_signal_bus != null):
			building_signal_bus.disconnect("validation_ran", _on_validation_ran)
			building_signal_bus.disconnect("object_placed", _on_object_placed)
			building_signal_bus.disconnect("action_failed", _on_action_failed)		

		building_signal_bus = value
		building_signal_bus.connect("validation_ran", _on_validation_ran)
		building_signal_bus.connect("object_placed", _on_object_placed)
		building_signal_bus.connect("action_failed", _on_action_failed)	
		
@export var failed_color : Color = Color.LIGHT_CORAL
@export var success_color : Color = Color.LIGHT_BLUE

## Show the base messages from ValidationResults
@export var show_validation_message : bool = false

## Show the reasons for a build failing
@export var print_failed_reasons : bool = true

## Should printing still happen for drag build. Warning: This may generate
## a lot of messages
@export var print_on_drag_build : bool = false

## When a build validations succeeds, print all of the success reason messages to the log
@export var print_success_reasons : bool = false

## If set, will show this when the build log starts
@export_multiline var on_ready_message : String = ""

## How to start off a logged successful build message
@export var built_message_start : String = "Built "

## How to start off a logged failed build message
@export var failed_message_start : String = "Building a "

## How to end a logged failed build message
@export var failed_wording : String = "failed"

## List bullet style
@export var failed_reasons_bullet : String = "•"
		
func _ready():
	_validate_ready_to_use()
	clear_log()
	
	if(on_ready_message != null && on_ready_message != ""):
		message_log.append_text(on_ready_message + "\n")
	
func clear_log():
	message_log.clear()
	
func _on_validation_ran(p_results : ValidationResults, p_attempt_parameters : BuildAttemptParameters):
	if(p_attempt_parameters.is_drag_build && not print_on_drag_build):
		return # Skip printing for drag builds
	
	if(p_results.is_successful):
		message_log.push_color(success_color)
	else:
		message_log.push_color(failed_color)
		
	_append_validation_results(p_results)
		
	message_log.pop()
	
func _append_validation_results(validation_results : ValidationResults):
	var successful = validation_results.is_successful
	
	if(show_validation_message):
		message_log.append_text(validation_results.message + "\n")
	
	if(not successful && print_failed_reasons):
		_print_reasons(validation_results.rule_results)
		
	if(successful && print_success_reasons):
		_print_reasons(validation_results.rule_results, false)

## Prints the reasons for each rule result to the message log
func _print_reasons(p_rule_results : Array[RuleResult], p_failed_only : bool = true):
	message_log.push_list(0, RichTextLabel.LIST_DOTS, false, failed_reasons_bullet)
	
	for rule_result in p_rule_results:
		var is_successful = rule_result.is_successful
		
		if(p_failed_only && is_successful):
			continue
			
		message_log.append_text(rule_result.reason + "\n")

	message_log.pop()

func _on_object_placed(p_placer : Node, p_placed : Node2D):
	message_log.append_text(built_message_start + p_placed.name + ".\n")

func _on_action_failed(action_name : StringName, reason : String):
	message_log.push_color(failed_color)
	message_log.append_text(reason + "\n")
	message_log.pop()

func _validate_ready_to_use() -> bool:
	var no_setup_errors = true
	
	if(building_signal_bus == null):
		push_error("Game log " + str(get_path()) + " can't operate without a building_signal_bus assigned.")
		no_setup_errors = false

	return no_setup_errors
