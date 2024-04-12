class_name SpendMaterialsRule
extends BuildingRule
## Validates that a spender node has a resource container that contains the need amount of base items
## and spends the resources if the object is placed on signal bus

## How many of each type need to be spent for the building rule to pass
@export var materials_to_spend : Array[BaseItemStack] = []

var mat_container : ItemContainer :
	get:
		if(mat_container == null && _spender != null):
			mat_container = _get_material_container_from_spender(_spender)
			
		return mat_container
		
var _bus : BuildingSignalBus
var _spender : Node

func setup(params : RuleValidationParameters) -> bool:
	if(not _pre_setup_validation(params)): return false
	
	_spender = params.placer
	_bus = params.building_signal_bus
	var successful_connection = _bus.connect("object_placed", _on_object_placed) == 0
	return successful_connection

## Checks to see if there are enough resources to build item
func validate_condition() -> RuleResult:
	assert(_spender != null)
	# Find the resource owning script and get the resource count for each type 
	# needed. Verify that each type has at least the count requested. If
	# any resource is not sufficient, return false
	mat_container = _get_material_container_from_spender(_spender)
	
	var missing_resources : Array[BaseItemStack] = _check_missing_resources()
	
	if(missing_resources.size() > 0):
		var failed_message : String = "Not Enough Materials: "
		
		# Needs to set resource names for them to show up in the string
		for missing in missing_resources:
			failed_message += "\n" + str(missing.type.display_name) + " : " + str(missing.count)
		
		return RuleResult.new(false, failed_message)
		
	# Connect Signal to Building System so Resources are spent when build is complete
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
	
## Remove resources from the spender's inventory
func _spend_resources(_spender : Node):
	# Find the corresponding material type key and subtract the count from the material container
	for material in materials_to_spend:
		var spent = mat_container.try_remove(material.type, material.count)
		
		assert(spent == material.count)
	
func tear_down():
	# Disconnect system to stop receiving callbacks
	_bus.disconnect("object_placed", _on_object_placed)
	
## Checks the resouce mat_container to see if it has enough of each resource type
## Returns ItemStacks that contain the amount missing for each type
func _check_missing_resources() -> Array[BaseItemStack]:
	var missing_resources : Array[BaseItemStack] = []
	
	for needed_resource in materials_to_spend:
		var had_count : int = mat_container.get_count(needed_resource.type)
		
		if(had_count < needed_resource.count):
			var missing_stack = BaseItemStack.new()
			missing_stack.type = needed_resource.type
			missing_stack.count = needed_resource.count - had_count
			missing_resources.append(missing_stack)
			
	return missing_resources
	
## Finds an ItemContainer from the user node [br]
## Starts by checking if the user is an ItemContainer
## and then checking each child recursively [br]
## Returns the first one found that can hold the spend rule
## items to spend
func _get_material_container_from_spender(p_spender : Node) -> Node:
	var resources_materials
	
	# Finds an item container that supports all of the items from the spend rule
	if(p_spender is ItemContainer && _can_container_hold_spend_items(p_spender)):
		resources_materials = p_spender
	else:
		for child in p_spender.find_children("", "ItemContainer"):
			if(child is ItemContainer):
				if(_can_container_hold_spend_items(child)):
					resources_materials = child
				
	if(resources_materials == null):
		push_error("Cannot find a valid ItemContainer in building system user or children that can hold all spend items")
		
	return resources_materials

## Checks a container to see if it can hold each materials_to_spend type in this SpendMaterialsRule
func _can_container_hold_spend_items(container : ItemContainer) -> bool:
	var supports_all_items : bool = true
	
	for item in materials_to_spend:
		var supports = container.does_it_allow(item.type)

		supports_all_items = supports
		
		if(supports_all_items != true):
			break
	
	return supports_all_items

func _pre_setup_validation(params : RuleValidationParameters) -> bool:
	var no_problems = true
	
	if(materials_to_spend == null):
		push_error("Materials to Spend is not defined in rule " + resource_path)
		no_problems = false
	
	if(materials_to_spend.size() == 0):
		push_error("No materials to spend set in array for rule " + resource_path)
		no_problems = false
		
	if(params.building_signal_bus == null):
		push_error("No signal bus in params to receive placement callback " + resource_path)
		no_problems = false
		
	if(params.placer == null):
		push_error("There is no placer in the RuleValidationParameters which means no inventory can be found to spend resources from.")
		no_problems = false
		
	return no_problems
	
	
