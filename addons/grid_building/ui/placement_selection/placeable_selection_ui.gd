extends Control
# Example placement UI For setting buildable scenes
# in the building system.

@export_group("External Dependencies")
## System to call building calls on
@export var building_system : BuildingSystem
@export var placeable_item_list_template : PackedScene

@export_group("Settings")
## Input actions which open the selection UI
@export var open_actions : Array[StringName] = []

## Show immediately on ready or not
@export var show_at_start : bool = false

## Placeables will be filtered into individual tag categories for placement
## Expects display_name and texture properties
@export var category_tags : Array[CategoricalTag]

@export var placeables : Array[Placeable] = [] :
	set(value):
		if(placeables != value):
			placeables = value
			
## Whether the category titles should show or not for clicking categories
@export var show_category_tab_names : bool = true

## Hide the selection ui when a item is chosen
@export var hide_ui_on_selection : bool = false

@export_group("Internal Nodes")
## Target for showing and hiding in the UI
@export var ui_root : Control

## Handles category selection for the menu
@export var tab_container : TabContainer

func _ready():
	if(!show_at_start):
		ui_root.hide()
	
	_setup_tabs()

func _input(event : InputEvent):
	for action in open_actions:
		if(event.is_action_pressed(action)):
			if(ui_root.visible):
				ui_root.hide()
			else:
				ui_root.show()

## Generate tabs for each category and populate each tab menu with placeable objects
func _setup_tabs():
	# Clear existing
	for tab in tab_container.get_children():
		tab_container.remove_child(tab)
		tab.queue_free()

	# One tab per category
	for tag_index in range(0, category_tags.size(), 1):
		var tag = category_tags[tag_index]
		var matched : Array[Placeable] = _get_placeables_with_tag(tag)
		
		# Fill tab with matching placeables
		var category_item_list : ItemList = _create_placeable_item_list(matched)
		
		category_item_list.name = tag.display_name
		
		tab_container.add_child(category_item_list)
		tab_container.set_tab_icon(tag_index, tag.icon)
		
		if(!show_category_tab_names):
			# Hide tab names
			tab_container.set_tab_title(tag_index, "")
		
		# Signals
		category_item_list.connect("item_selected", _on_list_item_selected)
		
# Returns all placeables that have the matching tag resource
func _get_placeables_with_tag(tag : Resource) -> Array[Placeable]:
	var matched : Array[Placeable] = []
	
	for placeable in placeables:
		if(placeable == null):
			push_error("Null placeable in selection ui arrays. Reassign or remove it.")
			continue
		
		for p_tag in placeable.tags:
			if(p_tag == tag):
				matched.append(placeable)
	
	return matched
		
func _create_placeable_item_list(tagged_placeables : Array[Placeable]) -> ItemList:
	var item_list : ItemList = placeable_item_list_template.instantiate() 
	
	for placeable in tagged_placeables:
		item_list.add_item(placeable.display_name, placeable.icon)

	return item_list

func _on_list_item_selected(index : int):
	# Get current selection
	var current_list : ItemList = tab_container.get_current_tab_control() as ItemList
	
	# Match on name and texture
	for placeable in placeables:
		if(placeable.display_name == current_list.get_item_text(index) && 
			placeable.icon == current_list.get_item_icon(index)):
				building_system.set_buildable_preview(placeable)
				
				# Unselect and hide
				current_list.deselect(index)
				
				if(hide_ui_on_selection):
					ui_root.hide()
					
				break

## Adds placeable options to the UI and updates the corresponding visuals
func add_placeables(new_placeables : Array[Placeable]):
	for new_p in new_placeables:
		if(not placeables.has(new_p)):
			# Add it since it's not already in the UI
			placeables.append(new_p)
			
			# Add it to each matching category
			for i in range(0, category_tags.size(), 1):
				if(new_p.tags.has(category_tags[i])):
					var cat_item_list : ItemList = tab_container.get_child(i) as ItemList
					cat_item_list.add_item(new_p.display_name, new_p.texture)
			
	
## Removes placeable options from the UI and updates the corresponding visuals
func remove_placeables(rem_placeables : Array[Placeable]):
	for rem_p in rem_placeables:
		if(placeables.has(rem_p)):
			# Remove matching from the placeables array
			placeables.erase(rem_p)
			
			# Remove it from each matching category
			for i in range(0, category_tags.size(), 1):
				if(rem_p.tags.has(category_tags[i])):
					var cat_item_list : ItemList = tab_container.get_child(i) as ItemList
					
					for list_i in range(0, cat_item_list.item_count, 1):
						if(cat_item_list.get_item_text(list_i) == rem_p.display_name && cat_item_list.get_item_icon(list_i) == rem_p.texture):
							# Match so remove
							cat_item_list.remove_item(list_i)
