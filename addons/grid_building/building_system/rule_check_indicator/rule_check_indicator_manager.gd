class_name RuleCheckIndicatorManager
extends Node2D
## Handles the creation and management of RuleCheckIndicators for
## rule tests on a given tilemap

signal indicators_changed(indicators: Array[RuleCheckIndicator])

const DEFAULT_NAME = "RuleCheckIndicatorManager"

## All indicators managed by the manager which are used
## for testing collisions and positions against rules
var indicators: Array[RuleCheckIndicator] = []:
	set(value):
		if value == indicators:
			return

		indicators = value
		indicators_changed.emit(indicators)

## The template to generate RuleCheckIndicators from
## for rule collision and position testing against scene
## objects and TileMaps
var rule_indicator_template: PackedScene

## The TileMap that the manager injects into RuleCheckIndicators
## to test rules against
var _tile_map: TileMap:
	set(value):
		_tile_map = value

		if _tile_map != null:
			_tile_size = _tile_map.tile_set.tile_size

## The size of tiles in the TileMap
var _tile_size: Vector2i

## An instance of the RuleCheckIndicator template used
## for determining which tile spaces should have
## a RuleCheckIndicator added for
var _testing_indicator: RuleCheckIndicator

## Positions tested to see if they should have a
## RuleCheckIndicator added
var _tested_tile_positions: Array[Vector2]

## Tile positions that already have a tile indicator created
var _used_shapes: Array[Shape2D] = []

## Dictionary linking placement objects to an array of tile collision indicators
var _starting_scale: Vector2
var _starting_rotation: float

## [ DEBUG ] If on, the manager will draw debug shapes and print output messages
var show_debug: bool = false:
	set(value):
		if show_debug == value:
			return

		show_debug = value

## List of current contact points to use in _draw debug
var indicator_contact_positions: Array = []

## Dictionary with Key-Value Pair shape_owner : RectCollisionTestingSetup
var indicator_creation_testing_parameters: Array[IndicatorCollisionTestSetup] = []


## Sets the indicator manager up for a new game level
func _init(
	p_tile_map: TileMap = null, p_indicator_template: PackedScene = null, p_show_debug: bool = false
):
	_tile_map = p_tile_map
	rule_indicator_template = p_indicator_template
	
	if(rule_indicator_template):
		_instance_testing_indicator(rule_indicator_template)
		
	show_debug = p_show_debug
	name = DEFAULT_NAME


func _ready():
	_starting_rotation = rotation
	_starting_scale = scale
	tree_exited.connect(_on_tree_exited)

	validate_ready()


## Creates indicators for a test object and children where collision objects with shapes are found
## that have collision masks matching the collision rules. In case of overlapping rules, 1 indicator
## will be created and shared between the rules that match those shapes[br][br]
## Returns all of the created tile collision indicators
func setup_indicators_for_object(
	p_test_object: Node2D, p_tile_check_rules: Array[TileCheckRule]
) -> Array[RuleCheckIndicator]:
	var collision_objects: Array[CollisionObject2D] = _find_collision_objects(p_test_object)

	if collision_objects.size() > 0:
		var generated_indicators = _generate_indicators(collision_objects, p_tile_check_rules)
		track_indicators(generated_indicators)

	return indicators


## Gets the indicators that have a tile_pos inside of the tile_pos array
func get_tile_indicators(p_tiles_pos: Array[Vector2i]) -> Array[RuleCheckIndicator]:
	return indicators.filter(func(indicator): return p_tiles_pos.has(indicator.tile_pos))


## Get the currently tracked indicators that are in collision
func get_colliding_indicators() -> Array[RuleCheckIndicator]:
	var colliding_indicators: Array[RuleCheckIndicator] = []

	for indicator in indicators:
		if(indicator == null):
			push_warning("Skipping null indicator")
			
		if indicator.is_colliding():
			colliding_indicators.append(indicator)

	return colliding_indicators


## From all of the active collision indicators, this represents
## an array of unique node2Ds that collide with at least
## one of the indicators
func get_colliding_nodes() -> Array[Node2D]:
	var col_nodes: Array[Node2D] = []

	for indicator in indicators:
		for i in indicator.get_collision_count():
			var collider = indicator.get_collider(i)

			if not col_nodes.has(collider):
				col_nodes.append(collider)

	return col_nodes


## Resets the manager to its default state and frees
## all tracked indicators and debug areas
func clear():
	free_indicators(indicators)

	for data in indicator_creation_testing_parameters:
		data.free_testing_nodes()

	indicator_creation_testing_parameters.clear()
	_tested_tile_positions.clear()
	indicator_contact_positions.clear()
	indicators.clear()
	_used_shapes.clear()

	# Reset rotation and scale
	rotation = _starting_rotation
	scale = _starting_scale
	
	queue_redraw()


## Adds an array of indicators to the manager's indicators array
## Returns the updated array
func track_indicators(p_indicators: Array[RuleCheckIndicator]) -> Array[RuleCheckIndicator]:
	if p_indicators == null || p_indicators.size() == 0:
		return indicators

	indicators.append_array(p_indicators)
	indicators_changed.emit(indicators)
	return indicators


## Removes an array of indicators to the manager's indicators array
## Returns the updated array. Frees the indicators, emits signal
## for changed array.
func free_indicators(
	p_indicators: Array[RuleCheckIndicator]
) -> Array[RuleCheckIndicator]:
	if p_indicators == null || p_indicators.size() == 0:
		return indicators

	for indicator in p_indicators:
		if(weakref(indicator).get_ref() != null):
			indicator.free()
		
	indicators = indicators.filter(func(x): x != null)
	indicators_changed.emit(indicators)
	return indicators

## Creates a set of RuleCheckIndicators with assigned rules to each one
func _generate_indicators(
	p_col_objects: Array[CollisionObject2D], p_tile_check_rules: Array[TileCheckRule]
) -> Array[RuleCheckIndicator]:
	var generated_indicators: Array[RuleCheckIndicator] = []
	if rule_indicator_template == null:
		push_error(
			"Cannot generate RuleCheckIndicators from a null rule_indicator_template. Make sure the template is set properly."
		)
		return []

	_instance_testing_indicator(rule_indicator_template)
	var pos_rules_dict = _map_tile_positions_to_rules(p_col_objects, p_tile_check_rules)

	for pos in pos_rules_dict.keys():
		var indicator_rules: Array[TileCheckRule] = []
		indicator_rules.append_array(pos_rules_dict[pos])
		var new_indicator = rule_indicator_template.instantiate()
		_setup_indicator_as_child(new_indicator, pos, indicator_rules)
		generated_indicators.append(new_indicator)

	_testing_indicator.free()
	return generated_indicators


## Creates a dictionary of tile positions and the rules that have a matching mask to the
## collision check at that location
func _map_tile_positions_to_rules(
	p_col_objects: Array[CollisionObject2D], p_tile_check_rules: Array[TileCheckRule]
) -> Dictionary:
	var dict = {}

	for rule in p_tile_check_rules:
		var found_positions = _get_collision_tile_positions_with_mask(
			p_col_objects, rule.apply_to_objects_mask
		)

		for pos in found_positions:
			if dict.has(pos):
				dict[pos].append(rule)
			else:
				dict[pos] = [rule]

	return dict


## Get all of the tile offset positions which match collision against the mask
func _get_collision_tile_positions_with_mask(
	p_col_objects: Array[CollisionObject2D], p_collision_mask: int
) -> Dictionary:
	var colliding_tile_positions: Dictionary = {}

	for col_obj in p_col_objects:
		if not PhysicsMatchingUtils2D.object_has_matching_layer(col_obj, p_collision_mask):
			continue
		var test_params: IndicatorCollisionTestSetup = _get_or_create_test_params(col_obj)

		var collision_tile_offsets: Dictionary = _get_tile_offsets_for_test_collisions(test_params)

		for pos in collision_tile_offsets:
			colliding_tile_positions[pos] = pos
	return colliding_tile_positions


func _get_tile_offsets_for_test_collisions(p_test_data: IndicatorCollisionTestSetup) -> Dictionary:
	if _testing_indicator == null:
		push_warning(
			"No testing indicator set. Impossible to find shape collisions. Returning empty dictionary"
		)
		return {}

	var collision_positions: Dictionary = {}

	# Account for offset test position
	var test_pos = p_test_data.collision_object.global_position

	for rect_test_setup in p_test_data.rect_collision_test_setups:
		var collision_shape = rect_test_setup.collision_shape
		var transformed_rect: Rect2 = (
			collision_shape.shape.get_rect() * collision_shape.global_transform
		)
		var test_tile_positions = get_rect_tile_positions(
			collision_shape.global_position, transformed_rect.size
		)
		indicator_contact_positions.clear()

		# Get surrounding whenever a match is found
		for tile in test_tile_positions:
			var local_tile_pos = _tile_map.map_to_local(tile)
			var testing_tile_global_pos: Vector2 = _tile_map.to_global(local_tile_pos)
			_testing_indicator.global_position = testing_tile_global_pos
			# Test against each of the shapes of the collision object at locations defined by the rect_test
			for test_shape in rect_test_setup.shapes:
				var collision_result = _does_indicator_overlap_shape(
					_testing_indicator, test_shape, rect_test_setup.shape_owner
				)

				if collision_result == true:
					if collision_positions.has(tile):
						collision_positions[tile].append(p_test_data.collision_object)
					else:
						collision_positions[tile] = [p_test_data.collision_object]

			var offset_from_manager = testing_tile_global_pos - global_position
			_tested_tile_positions.append(offset_from_manager)
			# break

	return collision_positions


## Sets _testing_indicator with a new instance of the p_template PackedScene parameter.
## The testing indicator becomes a child of this RuleCheckIndicatorManager
##
## By default - Instantiates the rule_indicator_template of this manager, but you can
## pass in an optional p_template to instance a different template
##
## Returns the instance of the testing indicator
func _instance_testing_indicator(p_template: PackedScene = null) -> RuleCheckIndicator:
	var selected_packed_scene : PackedScene
	var instance
	var rci_root : RuleCheckIndicator

	if p_template == null:
		selected_packed_scene = rule_indicator_template
	elif(p_template != null):
		selected_packed_scene = p_template
	else:
		push_warning("No rule check indicator set in manager rule_indicator_template or passed as p_template. Cannot instance a testing indicator.")
		return null # No template
	
	instance = selected_packed_scene.instantiate()
	rci_root = instance as RuleCheckIndicator
		
	if(rci_root == null):
		push_error("Rule check indicator not found. Check script in packed scene scene root. Path :: " + str(selected_packed_scene.resource_path))
		return null
		
	if weakref(_testing_indicator).get_ref():
		_testing_indicator.free()
		
	_testing_indicator = rci_root
	add_child(_testing_indicator)
	
	_testing_indicator.setup(_tile_map, [])
	return _testing_indicator


## Gets tile positions from a center position and each tile that can fit in the transform adjusted rect size
func get_rect_tile_positions(
	p_global_center_position: Vector2, p_transformed_rect_size: Vector2
) -> Array[Vector2i]:
	var tile_positions: Array[Vector2i] = []

	var center_tile = _tile_map.local_to_map(_tile_map.to_local(p_global_center_position))
	var center_remainder = Vector2(
		fmod(p_global_center_position.x, _tile_size.x),
		fmod(p_global_center_position.y, _tile_size.y)
	)

	var tiles_wide: int = ceil(p_transformed_rect_size.x / _tile_size.x)
	var tiles_high: int = ceil(p_transformed_rect_size.y / _tile_size.y)

	var tiles_left = floor(tiles_wide / 2.0)
	var tiles_right = round(tiles_wide / 2.0)
	var tiles_up = floor(tiles_high / 2.0)
	var tiles_down = round(tiles_high / 2.0)

	for x_offset in range(-tiles_left, tiles_right, 1):
		for y_offset in range(-tiles_up, tiles_down):
			var tile_coords = center_tile + Vector2i(x_offset, y_offset)
			tile_positions.append(tile_coords)

	return tile_positions

## Verify that the tile indicator actually falls inside the shape zone
## For shapes like elips and square polygons, this may
## not always be the case. In other words, there can be dead zones in the
## rect and we don't want to check those for collision
func _does_indicator_overlap_shape(
	p_tile_indicator: RuleCheckIndicator, p_shape: Shape2D, p_shape_owner: Node2D
) -> bool:
	var owner_transform = p_shape_owner.global_transform
	var indicator_transform = p_tile_indicator.global_transform
	var indicator_shape: Shape2D = p_tile_indicator.shape
	var result = indicator_shape.collide(indicator_transform, p_shape, owner_transform)

	if show_debug:
		if result == true:
			var origin_rect = p_shape.get_rect() * p_shape_owner.global_transform
			var contacts = indicator_shape.collide_and_get_contacts(
				indicator_transform, p_shape, owner_transform
			)
			for contact in contacts:
				var local_contact = to_local(contact)
				var global_contact = contact * indicator_transform
				indicator_contact_positions.append(local_contact)
				
	return result


## Add indicator as a child to the manager, position it, and reference it where it needs to be tracked
func _setup_indicator_as_child(
	p_tile_indicator: RuleCheckIndicator,
	p_used_tile: Vector2i,
	p_tile_check_rules: Array[TileCheckRule]
):
	if p_tile_indicator == null:
		push_warning(
			"Trying to manage NULL RuleCheckIndicator. Instance one before using this method. Returning."
		)
		return

	var base_name = p_tile_indicator.name
	p_tile_indicator.setup(_tile_map, p_tile_check_rules)
	self.add_child(p_tile_indicator, false, 0)
	p_tile_indicator.global_position = _tile_map.to_global(_tile_map.map_to_local(p_used_tile))

	var manager_position_tile = _tile_map.local_to_map(_tile_map.to_local(global_position))
	var offset = p_used_tile - manager_position_tile

	p_tile_indicator.name = base_name + "_TileOffset_" + str(offset)
	
## Finds all CollisionObject2Ds in the root node and children
func _find_collision_objects(p_root_object: Node2D) -> Array[CollisionObject2D]:
	if p_root_object == null:
		push_warning(
			"Searching for collision objects on NULL root_object. Returning empty Array[CollisionObject2D]"
		)
		return []

	var col_objects: Array[CollisionObject2D]

	if p_root_object is CollisionObject2D:
		col_objects.append(p_root_object)

	var child_collision_objects: Array[Node] = p_root_object.find_children(
		"", "CollisionObject2D", true, false
	)

	for child in child_collision_objects:
		col_objects.append(child)

	return col_objects


## Find existing data or create new one
func _get_or_create_test_params(p_col_object: CollisionObject2D) -> IndicatorCollisionTestSetup:
	# Return existing parameters if one exists
	for existing_params in indicator_creation_testing_parameters:
		if existing_params.collision_object == p_col_object:
			return existing_params

	# One does not exist for the collision object so create and track in the indicator_creation_testing_parameters array
	var test_params = IndicatorCollisionTestSetup.new(p_col_object, _tile_map)
	test_params.toggle_debug(show_debug)
	indicator_creation_testing_parameters.append(test_params)

	return test_params


## Gets every expected tile offset in an Vector2i of tile offset positions
func _get_test_tile_offsets(tiles_wide: int, tiles_high: int) -> Array[Vector2i]:
	var test_tiles_array: Array[Vector2i] = []

	for tile_horiz in tiles_wide:
		for tile_high in tiles_high:
			test_tiles_array.append(Vector2i(tile_horiz, tile_high))

	return test_tiles_array


func _draw():
	if show_debug:
		var circle_diameter: float = (_tile_size.x + _tile_size.y) / 16.0
		var test_color = Color.GREEN_YELLOW * Color(1, 1, 1, 0.5)

		for position in _tested_tile_positions:
			draw_circle(position, circle_diameter, test_color)

		for debug_contact in indicator_contact_positions:
			draw_circle(debug_contact, circle_diameter / 1.25, Color.ORANGE)


## Checks for known potential problems with the manager's setup
## Returns true if there are no problems (is_ready), and false if there are problems
func validate_ready() -> bool:
	var is_ready = true

	if _tile_map == null:
		push_warning("Tilemap not set in " + str(get_path()))
		is_ready = false
	elif _tile_map.tile_set == null:
		push_warning("Tilemap has no tile set in " + str(get_path()))
		is_ready = false

	if rule_indicator_template == null:
		push_warning("There is no RuleCheckIndicator template to show placement tiles")
		is_ready = false
		
	return is_ready

func _on_tree_exited():
	if(show_debug):
		print_debug("Rule Check Indicator Manager leaving tree")
