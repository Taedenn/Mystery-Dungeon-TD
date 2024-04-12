class_name ItemContainer
extends Node
## A simple inventory which allows adding and removal of resources of type BaseItem
## You can limit the items that store in this container with allowed_tags

## Emitted whenever the count of a material type changes in the container
signal item_count_changed(type : BaseItem, new_count : int)

## Emitted when a material type is completly removed from the container
signal item_stack_removed(stack : BaseItemStack)

## Allowed types to be stored in the container
@export var allowed_tags : Array[Resource]

## Material stack slots for the materials container
## Should not be accessed directly. Use try_add and try_remove instead
@export var _slots : Array[BaseItemStack] = [] :
	set(value):
		if(_slots == value):
			return
		
		var _old_slots = _slots
		_slots = value

		if(_old_slots != null):
			# Get old counts and new counts. Emit where changed
			var changed_count_stacks : Array[BaseItemStack] = get_item_counts_where_different(_old_slots, _slots)

			for changed_count in changed_count_stacks:
				item_count_changed.emit(changed_count.type, changed_count.count)

## Whether to allow muitiple stacks of the same type in the container or not
@export var allow_multiple_stacks : bool = true

## Whether to allow partial adding to the container with a remainder kept outside of the container
@export var allow_add_overflow : bool = false

## If set, will limit the container by the maximum stacks to be the number
## of possible spaces
@export var has_unlimited_space : bool = true

## Limits the maximum number of stacks that can be created in the container
@export var maximum_stacks : int = 10

func _ready():
	_remove_empty_stacks()

func has_room(type : BaseItem, amount : int) -> bool:
	if(not does_it_allow(type)):
		push_warning("Container does not allow type " + type.resource_path)
		return false
	
	if(has_unlimited_space):
		return true
	
	var positions = find_positions_of_type(type, _slots)
	var available_stack_slots : int = 0
	
	if(allow_multiple_stacks):
		available_stack_slots = maximum_stacks - _slots.size()
	else:
		available_stack_slots = 0
		
	var free_space_for_type : int = 0
	
	# Add space in existing stacks
	for position in positions:
		free_space_for_type += type.stack_maximum - _slots[position].count
		
	# Add space in free slots
	free_space_for_type += available_stack_slots * type.stack_maximum
	
	# Is there enough space for the amount or not
	if(free_space_for_type >= amount):
		return true
	else:
		return false
		
## Counts all materials of a type in the container
func get_count(type : BaseItem, p_stacks : Array[BaseItemStack] = _slots) -> int:
	var positions = find_positions_of_type(type, p_stacks)
	var total_count : int = 0
	
	for position in positions:
		total_count += p_stacks[position].count
		
	# If it does not allow the type, there should not be the type in the container
	if(not does_it_allow(type)):
		assert(total_count == 0)
	
	return total_count

## Add an amount of a material type to the materials container
## Creates a new entry if no materials of the type already exist in the dictionary
## Returns the amount that was added to the container
func try_add(type : BaseItem, amount : int) -> int:
	# Parameter validation
	if(amount < 0):
		push_warning("Trying to add a negative amount to " + self.name)
		return 0
	if(not does_it_allow(type)):
		var path : String
		
		if(type):
			path = type.resource_path
		else:
			path = "<Null Resource>"
		
		push_warning("Container does not allow type " + path)
		return 0
	
	var positions = find_positions_of_type(type, _slots)
	var remaining : int = amount
	
	if(allow_add_overflow or has_room(type, amount)):
		# Proceed with add starting with filling existing stacks from first to last
		for position in positions:
			# Add the lesser of the remaining stack space and the amount needed to add to the container
			var stack_add : int = min(remaining, type.stack_maximum - _slots[position].count)
			_slots[position].count += stack_add
			remaining -= stack_add
		
		# Continue with making new stacks if necessary
		var available_stack_slots : int = 0
		
		if(has_unlimited_space):
			# Basically unlimited
			available_stack_slots = 100000000000000
		elif(allow_multiple_stacks):
			available_stack_slots = maximum_stacks - _slots.size()
		else:
			available_stack_slots = 0
			
		for stack_num in available_stack_slots:
			if(remaining == 0):
				break
			
			var new_stack_size : int = min(remaining, type.stack_maximum)
			var new_stack : BaseItemStack = BaseItemStack.new()
			new_stack.count = new_stack_size
			new_stack.type = type
			_slots.append(new_stack)
			remaining -= new_stack_size
	
		item_count_changed.emit(type, get_count(type))
			
	assert(amount >= remaining)
	return amount - remaining
	
## Tries to spend the materials from the container but returns fail status
## if there are not enough of the material
## Returns the remainder that was removed
func try_remove(type : BaseItem, amount : int, allow_partial_remove : bool = false) -> int:
	var removed : int = 0
	
	if(not does_it_allow(type)):
		push_warning("Container does not allow type " + type.resource_path)
		return removed
	
	var match_positions : Array[int] = find_positions_of_type(type, _slots)
	var remaining : int = amount
	
	if(match_positions.size() > 0):
		var total_count : int = 0
		
		for position in match_positions:
			# Couunt how many materials in the inventory
			total_count += _slots[position].count
			
		if(not allow_partial_remove && total_count < amount):
			# Failed to spend any because partial removal not allowed
			return removed
		else:
			# Enough so spend the resources removing from each stack until total spend
			# Check from bottom to top of match_positiosn to spend last stacks first
			for x in match_positions.size():
				# Get the position in the _slots array that matched for the expected remove type
				var stack = _slots[match_positions[-x-1]]
				var current_count = stack.count
				var stack_remove : int = min(current_count, remaining)
				
				# Remove what can be removed from the stack
				stack.count -= stack_remove
				assert(stack.count >= 0)
				remaining -= stack_remove
				removed += stack_remove
				
				# Stop loop if the spending amount is spent
				if(remaining == 0):
					break
					
	if(remaining < amount):
		# Something was spent
		item_count_changed.emit(type, get_count(type))
		_remove_empty_stacks()
	
	return removed

## Returns the array positions of all stacks matching the MaterialItem type
func find_positions_of_type(type : BaseItem, p_stacks : Array[BaseItemStack]) -> Array[int]:
	var positions : Array[int] = []
	
	if(not p_stacks.is_empty()):
		for i in p_stacks.size():
			var slot : Resource = p_stacks[i]
			
			if(slot.type.icon == type.icon):
				assert(slot.type == type)

			if(slot != null && slot.type == type):
				positions.append(i)
		
	if(not does_it_allow(type)):
		assert(positions.size() == 0)
	
	return positions

## Handle any changes to the container that need to be made
## when the count of the material changes
func _remove_empty_stacks():
	# If zero count in a stack, remove the material from the dictionary
	var cleaned_arr : Array[BaseItemStack] = []
	
	# Generate a new array without null or 0 count slots
	for slot in _slots:
		if(slot != null || slot.count != 0):
			# Keep stack in new array
			cleaned_arr.append(slot)
	
	# Override the old array
	_slots = cleaned_arr
	
	for stack in cleaned_arr:
		# Emit signal for each removed stack
		emit_signal("item_stack_removed", stack)
	

## Determines whether the item type tags
## are in the list of accepted tags for this container
func does_it_allow(item : BaseItem) -> bool:
	if(item != null):
		## If there are no restrictions, return true
		if(allowed_tags.size() == 0):
			return true
		
		for allowed_tag in allowed_tags:
			# Check at least one of the tags in the allowed tags matches
			# the tags in the item
			if(item.tags.has(allowed_tag)):
				return true
				
	# No matches found
	return false

## Removes everything from the container slots
## Returns the number of item slots cleared
func clear() -> int:
	var count = _slots.size()
	_slots = []
	return count

# Returns an array of item types in the container
func get_item_types(p_stacks : Array[BaseItemStack] = _slots) -> Array[BaseItem]:
	var contained_item_types : Array[BaseItem] = []
	
	for stack in p_stacks:
		if(not contained_item_types.has(stack.type)):
			contained_item_types.append(stack.type)
	
	return contained_item_types

## Gets the number of items in the new_stacks where it is
## different than the old value
func get_item_counts_where_different(p_new : Array[BaseItemStack], p_old : Array[BaseItemStack]) -> Array[BaseItemStack]:
	var types : Array[BaseItem] = get_item_types(p_old)

	var new_types : Array[BaseItem] = get_item_types(p_new).filter(func(type): not types.has(type))
	types.append_array(new_types)

	var different_count_stacks : Array[BaseItemStack] = []

	for type in types:
		var old_value = get_count(type, p_old)
		var new_value = get_count(type, p_new)

		if(old_value != new_value):
			var new_count_stack = BaseItemStack.new(type, new_value)
			different_count_stacks.append(new_count_stack)
			
	return different_count_stacks
