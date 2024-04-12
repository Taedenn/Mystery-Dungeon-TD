class_name IndicatorCollisionTestSetup
extends Object
## Full test setup for a collision object that has had testing rects
## setup for shape collision checking in testing
## for where to create RuleCheckIndicators for

var collision_object : CollisionObject2D
var tile_map : TileMap
var rect_collision_test_setups : Array[RectCollisionTestingSetup]
var tile_size : Vector2
var show_debug : bool

var tile_size_scale_multiplier = 2.0

func _init(p_collision_object : CollisionObject2D, p_tile_map : TileMap):
	collision_object = p_collision_object
	tile_map = p_tile_map
	tile_size = tile_map.tile_set.tile_size
	rect_collision_test_setups = _create_rect_tests_for_collision_object(collision_object)
	validate_setup()

func free_testing_nodes():
	for test_setup in rect_collision_test_setups:
		test_setup.free_nodes()

func validate_setup() -> bool:
	var no_problems = true
	
	if(rect_collision_test_setups == null || rect_collision_test_setups.size() == 0):
		push_warning("Test params have no RectCollisionTestingSetups. Collision object probably has no CollisionShape2D or CollisionPolygon2D children. Check scene for those.")
		no_problems = false
	
	if(tile_size.is_zero_approx()):
		push_warning("Tile size of 0,0 should not work for tile map games. Set tile size to valid value")
		no_problems = false
	
	return no_problems

## Creates a hidden debug area for where RuleCheckIndicators are generated within the bounds of
##
## Returns a dictionary containing the generated area, collision_shape, and rect_shape
func _create_rect_tests_for_collision_object(p_collision_object : CollisionObject2D) -> Array[RectCollisionTestingSetup]:
	var owner_test_params_set : Array[RectCollisionTestingSetup] = []
	
	# Get the shape owners and then create tests for each shape owners shape rects
	var shape_owner_ids = p_collision_object.get_shape_owners()
		
	for shape_owner_id in shape_owner_ids:
		var shape_owner_node =  p_collision_object.shape_owner_get_owner(shape_owner_id)
		var owner_shape_count = p_collision_object.shape_owner_get_shape_count(shape_owner_id)
		var owned_shapes : Array[Shape2D] = []
		
		for shape_index in range(0, owner_shape_count, 1):
			var found_shape = p_collision_object.shape_owner_get_shape(shape_owner_id, shape_index)
			owned_shapes.append(found_shape)
		
		var owner_testing_rect = _get_testing_rect_for_owner(shape_owner_node)
		
		var rect_test_parameters = RectCollisionTestingSetup.new(
			shape_owner_node,
			owned_shapes,
			owner_testing_rect
		)
		
		owner_test_params_set.append(rect_test_parameters)
	
	return owner_test_params_set

## Adjusts the rect for the shape owners shape or polygon to be testing size
##
## Returns the adjusted rect
func _get_testing_rect_for_owner(p_shape_owner : Node2D) -> Rect2:
	if(p_shape_owner is CollisionShape2D):
		var shape = p_shape_owner.shape
		
		if(shape == null):
			push_error("Shape owner " + p_shape_owner.name + " has no shape set.")
			return Rect2()
		
		var shape_rect = p_shape_owner.shape.get_rect()
		# shape_rect.position = Vector2.ZERO
		var adjusted_rect = _adjust_rect_to_testing_size(shape_rect, p_shape_owner.global_transform)
		return adjusted_rect
	elif(p_shape_owner is CollisionPolygon2D):
		var polygon : PackedVector2Array = p_shape_owner.polygon
		var polygon_rect : Rect2 = BuildingShapeUtils.points_array_to_rect_2d(polygon, p_shape_owner.position)
		var adjusted_rect = _adjust_rect_to_testing_size(polygon_rect, p_shape_owner.global_transform)
		return adjusted_rect
	else:
		push_error("Class type of " + str(p_shape_owner.get_path()) + " is not supported. Type " + str(p_shape_owner.get_class()))
		return Rect2()

## Grows the sides of the rect to the edge of the tiles that they are over and returns the modified rect
func _adjust_rect_to_testing_size(p_base_rect : Rect2, p_shape_owner_global_transform : Transform2D) -> Rect2:
	var origin = p_shape_owner_global_transform.get_origin()
	var adjusted_rect = p_base_rect
	
	# If Complex shape make the rectangle cover full width and height as a square
	if(p_shape_owner_global_transform.get_skew() != 0 || p_shape_owner_global_transform.get_rotation() != 0):
		adjusted_rect = BuildingShapeUtils.grow_rect2_to_square(adjusted_rect)
		
	# Works but imperfect method to stretch bounds to test all squares that could contain squares (tests extra squares)
	adjusted_rect.size += tile_size * tile_size_scale_multiplier

	return adjusted_rect

func toggle_debug(p_show : bool):
	for rect_setup in rect_collision_test_setups:
		rect_setup.toggle_debug(p_show)
