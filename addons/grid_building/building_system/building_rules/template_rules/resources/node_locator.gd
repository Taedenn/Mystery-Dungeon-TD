class_name NodeLocator
extends Resource
## Settings that define how an appropriate inventory node should be located.

## Options for how to find where the inventory node is located
enum SEARCH_METHOD { NODE_NAME, SCRIPT_NAME_WITH_EXTENSION, IS_IN_GROUP }

## Method for finding the inventory class that can spend the materials for this building rule
@export var method : SEARCH_METHOD = SEARCH_METHOD.NODE_NAME

## Search string to use with the search method for locating the appropriate
## inventory node
@export var search_string : String = "<Set me>"

func _init(p_search_method : SEARCH_METHOD = SEARCH_METHOD.NODE_NAME, p_search_string : String = search_string):
	method = p_search_method
	search_string = p_search_string

func locate_container(search_root : Node) -> Node:
	if(search_root == null):
		push_warning("No search root given to check. Returning null for found container.")
		return null
	
	var inventory_container : Node
	
	match method:
		SEARCH_METHOD.NODE_NAME:
			# Search by node name
			if(search_root.name == search_string):
				inventory_container = search_root
			else:
				# Return the first child node found that matches the search string
				for child in search_root.find_children(search_string, "", true, false):
					inventory_container = child
					break
		SEARCH_METHOD.SCRIPT_NAME_WITH_EXTENSION:
			# Search for node by class name			
			# Search by node name
			if(get_script_name(search_root) == search_string):
				inventory_container = search_root
			else:
				for child in search_root.find_children("", "Node", true, false):
					if(get_script_name(child) == search_string):
						inventory_container = child
						break
		SEARCH_METHOD.IS_IN_GROUP:
			if(search_root.is_in_group(search_string)):
				inventory_container = search_root
			else:
				for child in search_root.find_children("", "Node", true, false):
					if(child.is_in_group(search_string)):
						inventory_container = child
						break
						
	if(inventory_container == null):
		push_warning("Failed to find inventory container using method " + str(SEARCH_METHOD.keys()[method]) + " using string " + search_string)
					
	return inventory_container

## Finds the script name on the script attached to an object if one exists
func get_script_name(p_check : Object) -> String:
	var script = p_check.get_script()
	
	if(script == null):
		return ""
	
	var script_path : String = script.resource_path
	var split_path : PackedStringArray  = script_path.rsplit("/")
	var script_name = split_path[split_path.size() - 1]
	
	return script_name
