class_name BuildingShapeUtils

## Converts an array of Vector2 position points to that stretches over all positions in the array
static func points_array_to_rect_2d(p_vector_array : PackedVector2Array, p_rect_position : Vector2) -> Rect2:
	var left_bound = p_vector_array[0].x
	var right_bound = p_vector_array[0].x
	var top_bound = p_vector_array[0].y
	var bottom_bound = p_vector_array[0].y
	
	for index in range(1, p_vector_array.size(), 1):
		if(p_vector_array[index].x < left_bound):
			left_bound = p_vector_array[index].x
		
		if(p_vector_array[index].x > right_bound):
			right_bound = p_vector_array[index].x
		
		if(p_vector_array[index].y < top_bound):
			top_bound = p_vector_array[index].y
		
		if(p_vector_array[index].y > bottom_bound):
			bottom_bound = p_vector_array[index].y
	
	var size = Vector2(
		abs(left_bound - right_bound),
		abs(top_bound - bottom_bound)
	)
	
	var generated_rect = Rect2(p_rect_position, size)

	return generated_rect


static func get_collision_object_shapes(p_collision_object : CollisionObject2D) -> Array[Shape2D]:
	var shapes_dict = {}

	var shape_owners = p_collision_object.get_shape_owners()
	
	for owner in shape_owners:
		var shape_count = p_collision_object.shape_owner_get_shape_count(owner)
		
		for shape_index in shape_count:
			var shape = p_collision_object.shape_owner_get_shape(owner, shape_index)
			shapes_dict[shape] = ""
	
	var shapes : Array[Shape2D] = []
	shapes.append_array(shapes_dict.keys())
	
	return shapes
	
## Grows a rect2 position and ends coordinates to increment values
static func grow_rect2_to_increment(p_rect : Rect2, p_increment : Vector2) -> Rect2:
	var adjusted_rect = p_rect
	var abs_size = abs(p_rect.size)
	var position = p_rect.position
	var end = p_rect.end
	var position_snapped = position.snapped(p_increment)
	adjusted_rect.position = position_snapped
	var abs_adjusted_size = abs(adjusted_rect.size)
	if(abs_adjusted_size.x < abs_size.x):
		abs_adjusted_size.x += p_increment.x
	
	if(abs_adjusted_size.y < abs_size.y):
		abs_adjusted_size.y += p_increment.y
		
	adjusted_rect.size = Vector2(
		abs_adjusted_size.x * signf(p_rect.size.x),
		abs_adjusted_size.y * signf(p_rect.size.y),
	)
		
	return adjusted_rect

# Makes a rect2 have equal sized sides as a a square and round the sizing up to be able to fit
# all tile squares inside of the original shape to be tested on
static func grow_rect2_to_square(p_rect : Rect2) -> Rect2:
	var abs_rect_size = abs(p_rect.size)
	var abs_larger_dimension = max(abs_rect_size.x, abs_rect_size.y) 
	var larger_dimension_size = Vector2(
		abs_larger_dimension * sign(p_rect.size.x),
		abs_larger_dimension * sign(p_rect.size.y)
	)
	return Rect2(p_rect.position, larger_dimension_size)

## Gets the direction difference between center to position and center to end
##
## Returns the difference vector with magnitude and direction of the 
## further point between position and end
static func get_rect2_position_offset(p_rect : Rect2) -> Vector2:
	var position = p_rect.position
	var end = p_rect.end
	var center = p_rect.get_center()
	
	var position_to_center = position - center
	var position_to_end = end - center

	var difference = position_to_center + position_to_end
	return difference

