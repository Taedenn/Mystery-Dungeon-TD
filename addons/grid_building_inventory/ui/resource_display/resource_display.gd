extends MarginContainer
# Displays the resources being held by the item container

@export var item_display_template : PackedScene
@export var resource_holder : Node
@export var grid_container : GridContainer
@export var remove_0_count_display : bool = false
@export var locator : NodeLocator

var displays : Array[BaseItemDisplay]
var shown_container : ItemContainer

func _ready():
	_setup_for_materials()
	shown_container.item_count_changed.connect(_on_container_material_count_changed)
	
func _setup_for_materials():
	## Find the item containers in the resource_holder and children nodes recursively
	shown_container = locator.locate_container(resource_holder)
	
	# Set current resources to display
	for type in shown_container.get_item_types():
		var count = shown_container.get_count(type)
		_create_display(type, count)
	
func _create_display(type : BaseItem, count : int) -> void:
	var new_display : BaseItemDisplay = item_display_template.instantiate() as BaseItemDisplay
	grid_container.add_child(new_display)
	new_display.resource_type = type
	new_display.update_count(count)
	displays.append(new_display)

func _on_container_material_count_changed(type : BaseItem, new_count : int) -> void:
	# Find existing item display for type
	var current_display : BaseItemDisplay
	
	# Find existing display and update the count if one is found
	for display in displays:
		if(display.resource_type == type):
			current_display = display
			current_display.update_count(new_count)
			
			if(remove_0_count_display && new_count == 0):
				displays.erase(current_display)
				current_display.queue_free()
				break
	
	# If none exist, create a new one
	if(new_count > 0 && current_display == null):
		_create_display(type, new_count)
