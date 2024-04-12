class_name RectCollisionTestingSetup
extends Object
## Contains the setup data for an Area 2D that has been created specifically for
## testing it's contained Rect shape in shape.collide or collision checks.

var shape_owner: Node2D
var shapes : Array[Shape2D]
var area_2d: Area2D
var collision_shape: CollisionShape2D
var rect_shape: RectangleShape2D

var test_area_name = "IndicatorSetupTestingArea"

var _debug_area_colors = [
	Color.BISQUE * TRANSPARENCY_LEVEL,
	Color.BURLYWOOD * TRANSPARENCY_LEVEL,
	Color.ANTIQUE_WHITE * TRANSPARENCY_LEVEL,
	Color.BLANCHED_ALMOND * TRANSPARENCY_LEVEL
]

var _debug_mode = true # Used in development to show shapes

const TRANSPARENCY_LEVEL = Color(1,1,1,0.1)

func _init(
	p_shape_owner: Node2D,
	p_shapes : Array[Shape2D],
	owner_testing_rect: Rect2
):
	shape_owner = p_shape_owner
	shapes = p_shapes
	rect_shape = _create_rect_shape(owner_testing_rect.size)
	_area_setup(owner_testing_rect)
	collision_shape.shape = rect_shape

## Sets up area_2d and collision_shape
func _area_setup(p_area_rect : Rect2):
	# Testing Area Creation
	area_2d = Area2D.new()
	area_2d.collision_mask = 0
	area_2d.collision_layer = 0
	shape_owner.add_child(area_2d)
	# TODO NEED THE TRANSFORM OF THE ORIGINAL SHAPE SO THAT THE NEW ONE HAS SAME ROTATION AND SKEW
	# area_2d.global_transform = Transform2D(0, Vector2.ONE, 0, area_2d.global_position) # Position based on parent owner
	area_2d.name = test_area_name
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = rect_shape
	area_2d.add_child(collision_shape)
	collision_shape.debug_color = _debug_area_colors[0]
	
	toggle_debug(false) # Hide by default

func _create_rect_shape(p_rect_size: Vector2) -> RectangleShape2D:
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = p_rect_size
	return rect_shape

func free_nodes():
	if weakref(area_2d).get_ref():
		area_2d.free()

	if weakref(collision_shape).get_ref():
		collision_shape.free()

func toggle_debug(p_show : bool):
	if(p_show):
		area_2d.show()
	else:
		area_2d.hide()
