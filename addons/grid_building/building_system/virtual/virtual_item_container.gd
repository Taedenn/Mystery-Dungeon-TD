extends Node
## Provides virtual methods for an inventory node class that needs to work
## with SpendMaterialsRuleGeneric

## Tries to remove a number of items from the container
## Returns the actual amount removed
func try_remove(type : Resource, amount : int) -> int:
	push_warning("Trying to call unimplemented try_remove method on " + name)
	return 0
	
## Tries to add a number of an item to the container
## Returns the actual amount added
func try_add(type : Resource, amount : int) -> int:
	push_warning("Trying to call unimplemented try_add method on " + name)
	return 0
	
## Gets a number count of an item type stored in the container if any
func get_count(type : Resource) -> int:
	push_warning("Trying to call unimplemented get_count_of_item method on " + name)
	return 0
