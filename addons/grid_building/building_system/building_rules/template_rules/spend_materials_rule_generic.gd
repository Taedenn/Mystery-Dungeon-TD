extends BuildingRule

## Generic spend material rule that allows you to define whatever classes you want to
## spend the resources. Therefore, no need to use the building system inventory classes
## However, certain properties and methods will be expected
##
## Resource Stacks to Spend - Should have type and count propertiees
## Resource Types - optional display_name property, otherwise will use resource_name for display
## _spender_container - Expected to be on the user node target of the building_system (can be any node2d)
## For the inventory, this should contain some implementation of the following
##
## try_add or add - Parameters: type : Resource, count : int
## try_remove or remove - Parameters: type : Resource, count : int
## get_count - Parameters: type : Resource  - Returns: int
##
## Alternative, inherit from the virtual class VirtualItemContainer
## and implement the methods
class_name SpendMaterialsRuleGeneric

## How many of each type need to be spent for the building rule to pass
## Resource should have fields type and count defined
@export var resource_stacks_to_spend : Array[ResourceStack] = []

## Used to find the inventory on the spender passed in as a setup parameter
## so that the rule knows where to spend the resource_stacks_to_spend from
@export var locator : NodeLocator

## The target container to search for materials to spend
var _spender_container : Object :
	get:
		if(_spender_container == null && _spender != null):
			_spender_container = _get_material_container_from_user(_spender)
			
		return _spender_container
	
var _spender : Node
var _bus : BuildingSignalBus

func _init(
		p_resource_stacks_to_spend : Array[ResourceStack] = [],
		p_locator : NodeLocator = NodeLocator.new()):
	resource_stacks_to_spend = p_resource_stacks_to_spend
	locator = p_locator

func setup(params : RuleValidationParameters) -> bool:
	if(not _pre_setup_validation(params)): return false
	_spender = params.placer
	_spender_container = _get_material_container_from_user(_spender)
	_bus = params.building_signal_bus
	_bus.connect("object_placed", _on_object_placed)
	return _post_setup_validation()

func tear_down():
	if(_bus != null):
		_bus.disconnect("object_placed", _on_object_placed)
		_bus = null

## Checks to see if there are enough resources to build item
func validate_condition() -> RuleResult:
	# Reset system before validating
	
	# Find the resource owning script and get the resource count for each type 
	# needed. Verify that each type has at least the count requested. If
	# any resource is not sufficient, return false
	var missing_resources_stacks : Array[ResourceStack] = check_missing_resources(_spender_container)
	
	if(missing_resources_stacks.size() > 0):
		var failed_message : String = "Not Enough Materials: "
		
		# Needs to set resource names for them to show up in the string
		for missing_stack in missing_resources_stacks:
			if(missing_stack.type == null):
				push_error("Missing a null resource type of count " + str(missing_stack.count) + " at " + missing_stack.resource_path)
				continue
			
			# Try to find display_name property, else default back to resource name for display
			var material_name = _get_material_name(missing_stack.type)
			
			failed_message += "\n" + material_name + " : " + str(missing_stack.count)
		
		return RuleResult.new(false, failed_message)
	else:
		return RuleResult.new(true, "All expected spend resource requirements met.")
			
## After building is placed, remove expected resources from the target
## inventory
func _on_object_placed(p_placer : Node, p_placed : Node2D):
	if(_spender == null):
		push_error("Null spender. Cannot spend resources!")
		return
	elif(p_placer != _spender):
		push_warning("The spender " +  str(_spender.get_path()) + " during rule setup is not the object " + str(p_placer.get_path()) + " which actually placed the object. Did the building system change it's user during this time? Resources will be spent on the original spender that was set for this rule instead of the current object")
		
	_spend_resources(_spender)
	
## Remove resources from the target inventory
## Returns if all resources spent successfully or not
func _spend_resources(p_spender : Node) -> bool:
	# Find the corresponding material type key and subtract the count from the material container
	for material in resource_stacks_to_spend:
		var spent = 0
		
		if(_spender_container.has_method("try_remove")):
			spent += _spender_container.try_remove(material.type, material.count)
		elif(_spender_container.has_method("remove")):
			spent += _spender_container.remove(material.type, material.count)
		else:
			print_debug("_spender_container does not have try_remove or remove methods. Required for SpendMaterialsRuleGeneric")
			return false
		
		if(spent == material.count):
			return true
		else:
			push_error("Expected to spend " + str(material.count) + " of type [" + material.type.resource_path + "] but actually spent " + str(spent))
			return false
	
	return false
	
## Checks the resouce _spender_container to see if it has enough of each resource type
## Returns ItemStacks that contain the amount missing for each type
func check_missing_resources(p_spender_container) -> Array[ResourceStack]:
	if(p_spender_container == null):
		push_error("No spender container to check for missing resources.")
		return []
	
	var missing_resources : Array[ResourceStack] = []
	
	for needed_resource in resource_stacks_to_spend:
		# Interface: Inventory target should have get_count
		var had_count : int = p_spender_container.get_count(needed_resource.type)
		
		if(had_count < needed_resource.count):
			var missing_count = needed_resource.count - had_count
			var missing_stack = ResourceStack.new(needed_resource.type, missing_count)
			missing_resources.append(missing_stack)
			
	return missing_resources
	
## Finds the container for the spendable materials by
## searching either for the matching node by name or class name
## Starts at the user node of the building system and then checks children
## nodes recursively
func _get_material_container_from_user(user : Node) -> Node:
	var resources_materials_container = locator.locate_container(user)
				
	if(resources_materials_container == null):
		var fail_message = "Cannot find a resource container in "
		fail_message += str(_spender.get_path())
		fail_message += " : Method "
		fail_message += str(locator.SEARCH_METHOD.find_key(locator.method))
		fail_message += " : To Find "
		fail_message += locator.search_string
		
		push_error(fail_message)
		
	return resources_materials_container

func _pre_setup_validation(params : RuleValidationParameters) -> bool:
	var no_problems = true
	
	if(resource_stacks_to_spend == null):
		push_error("Materials to Spend is not defined in rule " + resource_path)
		no_problems = false
	
	if(resource_stacks_to_spend.size() == 0):
		push_error("No materials to spend set in array for rule " + resource_path)
		no_problems = false
		
	if(params.building_signal_bus == null):
		push_error("No signal bus in params to receive placement callback " + resource_path)
		no_problems = false
		
	if(params.placer == null):
		push_error("There is no placer in the RuleValidationParameters which means no inventory can be found to spend resources from.")
		no_problems = false
		
	for stack in resource_stacks_to_spend:
		if(stack.type == null):
			push_warning("Spend resource type is null: " + stack.resource_path)
			no_problems = false
		
	return no_problems

func _post_setup_validation() -> bool:
	var no_problems = true
	
	if(_spender_container == null):
		push_error("No spender container found during setup. Does " + str(_spender.get_path()) + " have a valid container for removing resources?")
		no_problems = false
		
	if(_bus == null):
		push_error("No bus set in rule")
		no_problems = false
	elif(not _bus.is_connected("object_placed", _on_object_placed)):
		push_error("On object placed is not connected to bus " + _bus.resource_path)
		no_problems = false
		
	if(_spender_container == null):
		push_error("There is no spender container. Are the locator settings correct for finding the inventory item container on the placer node? Check rule locator resource.")
	
	return no_problems

func _get_material_name(p_material : Resource) -> String:
	var material_name : String
	
	var display_name = p_material.get("display_name")

	if(display_name != null && display_name != ""):
		material_name = display_name
	else:
		material_name = p_material.resource_name

	return material_name
