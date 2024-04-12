class_name BuildingSystem
extends Node
## Can enter a build preview mode to show an instance of what an object
## will look like once placed into the scene. Uses tile collision indicators
## through the tile collision indicator manager to give visual information
## to the player about valid or invalid placement into the scene. When
## the build action is pressed, it will use the placement validator to check
## base rules and rules set in the placeable resource to see if
## putting the object into the scene at the current preview location is
## valid. If valid, the object will be placed into the 2d world at the
## placed_objects_parent. A signal will be emitted for whether the build succeeds or fails.

signal building_mode_changed(is_building : bool)

@export_group("External Dependencies")
## The node considered to be in control of the building system.
## Common example would be the player character
@export var placer: Node

## Node that represents the position to show the building preview indicators
## and the location that new placed objects will go
@export var positioner: Node2D

## The tileset that the building syste	m intends to place objects
## onto. Used in calculating sizes of preview collision indicators.
@export var tilemap: TileMap:
	set(value):
		## Sets reference to tilemap, size of tiles in the tilemap's tileset
		tilemap = value
		is_building = false
		
		if(rule_check_indicator_manager):
			rule_check_indicator_manager._tile_map = tilemap

## The node that will serve as the parent for the objects placed into the
## 2D world whether that is the 'level' node or some other category
@export var placed_objects_parent: Node2D

@export_group("Settings")
## Template for creating tile collision indicators to test collisions in rule checks
## against. It should contain a RuleCheckIndicator at the scene root.
@export var rule_check_indicator_template: PackedScene

## Handles checking to see if the placement of a building is valid
## Given all rules setup in the validator
@export var placement_validator: PlacementValidator = PlacementValidator.new()

## Resource of building signals for communicating success and failed of placements
@export var building_signal_bus = BuildingSignalBus.new()

## Adjustment color for any preview sprites to indicate that the
## instance is a preview and not actually a interactable object
## in the game
@export var preview_modulate_color: Color = Color(.6, .6, 1, 0.8)

## The z index value to set preview instances to in order to control
## their rendering order
@export var preview_instance_z_index = 100

## Amount to rotate objects with every step of call to left or right rotation
@export var rotate_increment_degrees = 90.0

## Allows the building system to rotate objects left and right during build mode
@export var enable_rotate = false

## Allows the building system to flip objects horizontally during build mode
@export var enable_flip_horizontal = false

## Allows the building system to flip objects vertically during build mode
@export var enable_flip_vertical = false

## Whether to allow multi build by hold the build button down
## as the positiooner is moved over other tiles
@export var drag_multi_build = false

@export_group("Input Actions")
## Action names that exits build mode
@export var exit_build_mode_action: StringName = "ui_cancel"

## Action names that triggers placing the preview object into
## the game scene if requirements are met
@export var build_action: StringName = "ui_accept"

## the preview instance to the right when triggered
@export var rotate_right_action: StringName = "rotate_right"
## Names of actions that the building system will rotate
## the preview instance to the left when triggered
@export var rotate_left_action: StringName = "rotate_left"

## Actions that flip the preview instance horizontally during build mode
@export var flip_horizontally_action: StringName = "flip_horizontal"

## Actions that flip the preview instance vertically during build mode
@export var flip_vertically_action: StringName = "flip_vertical"

@export_group("Debug")
## When in build preview mode, show the shape of the area where rule tile indicators
## are generated for. All rule tile indicators should be within the bounds of the
## rect
@export var show_debug_shapes = false :
	set(value):
		show_debug_shapes = value
		
		# Update manager whenever building system value is changed
		if(rule_check_indicator_manager != null):
			rule_check_indicator_manager.show_debug = show_debug_shapes

## The active shapes used for setting up tile collision_indicators.
## By default, the placement shape will be shrunk by 1 px in size from
## the original collider shape on the preview instance be considered
## for placement into the game world.
var placement_shapes: Array[CollisionShape2D]

## Active polygons used for setting up tile collision indicators
var placement_polygons: Array[CollisionPolygon2D]

## Handles creation and deletion of tile collision indicators. This node2D should
## be placed under the positioner
var rule_check_indicator_manager: RuleCheckIndicatorManager :
	set(value):
		rule_check_indicator_manager = value

## The layer to show buildable / unbuildable preview tiles over
var preview_layer: int

## During build mode, this is the current selected item to build.
## It moves with the mouse cursor and has no collision until
## it is placed in the game world.
var preview_instance: Node2D

## The status of the system whether it is in build mode or not
var is_building: bool = false:
	set(value):
		if value != is_building:
			is_building = value

			# Cleanup
			if value == false:
				_exit_build_cleanup()

			building_mode_changed.emit(value)

## The selected placeable resource which contains a scene to be
## instantiated
var selected_placeable: Placeable

## Node that serves as the parent for all active collision_indicators
var indicators_group: Node2D

## Whether the system is current drag building or not
var is_drag_building: bool:
	get:
		var is_dragging = _grid_drag != null
		return is_dragging

## The position adjustment to move the preview compared to it's editor location while
## previewing and placing
var _preview_offset: Vector2

## Whether the build button is held down or not
var _build_drag_event: InputEventScreenDrag

var _indicator_generation_area

## Tracks the position and time between when build is held and released
var _grid_drag: GridPathingComponent:
	set(value):
		if weakref(_grid_drag).get_ref():
			_grid_drag.disconnect("targeting_new_tile", _on_grid_pathing_targeting_new_tile)

		_grid_drag = value

		if _grid_drag != null:
			_grid_drag.connect("targeting_new_tile", _on_grid_pathing_targeting_new_tile)


func _init(
	p_positioner: Node2D = null,
	p_tilemap: TileMap = null,
	p_placed_objects_parent: Node2D = null,
	p_placement_validator: PlacementValidator = null,
	p_rule_check_indicator_template: PackedScene = null
):
	positioner = p_positioner
	tilemap = p_tilemap
	placed_objects_parent = p_placed_objects_parent
	placement_validator = p_placement_validator
	rule_check_indicator_template = p_rule_check_indicator_template

func _ready():
	building_signal_bus.tile_map_changed.connect(_on_tile_map_changed)
	_validate_input_map()

## Cleanup placement validator before exiting the building system from
## the game scene
func _exit_tree():
	if placement_validator != null:
		placement_validator.tear_down()

## Run checks to see if anything is not set up properly
func _validate_setup() -> bool:
	var no_problems_found = true

	if placed_objects_parent == null:
		no_problems_found = false
		push_warning(
			(
				"Building System "
				+ name
				+ " has no placed_objects_parent. Set one so that objects can place into the world properly."
			)
		)

	if tilemap == null:
		push_error(
			"Building system requires a tilemap set in order to place objects into the game world."
		)
		no_problems_found = false

	if placement_validator == null:
		no_problems_found = false
		push_warning("No placement_validator set in the building system at path " + str(get_path()))

	if build_action == "ui_accept":
		push_warning("Building system build action is ui_accept. You should set this to a custom action after testing.")

	return no_problems_found


## Call this when the system should target a new game level or scene to set new refernces
## The tilemap will target it's builds on the new tilemap
## and successfully placed objects will go under the placed objects parent
func change_level_setup(
	p_build_tilemap: TileMap, p_placed_objects_parent: Node2D, p_system_placer: Node2D
):
	self.tilemap = p_build_tilemap
	self.placed_objects_parent = p_placed_objects_parent
	self.placer = p_system_placer

## The size of each tile on the TileMap
func get_tile_size():
	return tilemap.tile_set.tile_size

## Checks all of the placeable object's build rules
## to determine if the building can be placed in the positioner's
## location given any game state requirements defined in the build rules
func try_build(emit_failed_signal = true) -> bool:
	# Check if build requirements met
	var validation_results: ValidationResults = placement_validator.validate_rules()
	var build_attempt_params = BuildAttemptParameters.new(
		preview_instance, selected_placeable, is_drag_building
	)

	building_signal_bus.validation_ran.emit(validation_results, build_attempt_params)

	if validation_results.is_successful:
		var placed_obj: Node2D = _build()
		return true

	return false


## Sets the current preview object for building to
## the preview_scene passed. It does this by
## instantiating a copy in the scene under the grid targeter
## pointer node2d but without any collision.
##
## Returns whether a preview instance was successfully set or not
func set_buildable_preview(placeable: Placeable) -> bool:
	if not _validate_setup():
		return false
	if not _validate_placeable(placeable):
		return false

	_setup_rule_check_indicator_manager()

	selected_placeable = placeable

	if not _validate_ready_to_build():
		return false
	
	placement_validator.tear_down()
	placement_shapes = []
	
	if is_instance_valid(preview_instance):
		preview_instance.free()

	preview_instance = _generate_preview_scene(placeable)

	# Clear indicators from old object
	rule_check_indicator_manager.clear()

	# Make sure that build mode code runs
	is_building = true

	var rule_validation_params = RuleValidationParameters.new(
		placer, preview_instance, selected_placeable, building_signal_bus
	)

	placement_validator.setup(rule_check_indicator_manager, rule_validation_params)

	return true

## Places an instance of the buildable scene into the game world at
## the given location. Returns true if placement is successful
func _build() -> Node2D:
	if(selected_placeable == null):
		push_error("No selected_placeable set to build. Returning null")
		return null
	
	var scene: PackedScene = selected_placeable.packed_scene
	var instance: Node2D = scene.instantiate()
	placed_objects_parent.add_child(instance)
	instance.owner = placed_objects_parent
	instance.global_position = preview_instance.global_position
	instance.global_rotation = preview_instance.global_rotation
	instance.global_scale = preview_instance.global_scale

	# Set the name root base to the packed scene root base
	instance.name = scene._bundled["names"][0]
	building_signal_bus.object_placed.emit(placer, instance)
	return instance

## Removing build mode nodes and sprites from the active scene
func _exit_build_cleanup():
	if preview_instance:
		preview_instance.free()
		rule_check_indicator_manager.clear()

## Update the preview buildable location to the mouse location
func _unhandled_input(event: InputEvent):
	if InputMap.has_action(build_action) && event.is_action_released(build_action):
		_stop_drag()
	
	if is_building:
		if InputMap.has_action(exit_build_mode_action) && event.is_action_pressed(exit_build_mode_action):
			is_building = false
			
		# Building system requires a placeable set to manipulate the scene
		if(selected_placeable == null):
			return
			
		if InputMap.has_action(build_action) && event.is_action_pressed(build_action):
			try_build()
			_start_drag() # Start drag after placement !important

		# -- ROTATION --
		if InputMap.has_action(rotate_right_action) && event.is_action_pressed(rotate_right_action):
			if selected_placeable.rotateable:
				_rotate_preview(rotate_increment_degrees)
			else:
				building_signal_bus.action_failed.emit(rotate_right_action, selected_placeable.display_name + " cannot be rotated.")

		if InputMap.has_action(rotate_left_action) && event.is_action_pressed(rotate_left_action):
			if selected_placeable.rotateable:
				_rotate_preview(-rotate_increment_degrees)
			else:
				building_signal_bus.action_failed.emit(rotate_left_action, selected_placeable.display_name + " cannot be rotated.")

		## -- FLIP H / V --
		if InputMap.has_action(flip_horizontally_action) && event.is_action_pressed(flip_horizontally_action):
			if selected_placeable.flippable_h:
				preview_instance.scale.x *= -1
				rule_check_indicator_manager.scale.x *= -1
			else:
				building_signal_bus.action_failed.emit(
					flip_horizontally_action,
					selected_placeable.display_name + " cannot be flipped horizontally."
				)

		if InputMap.has_action(flip_vertically_action) && event.is_action_pressed(flip_vertically_action):
			if selected_placeable.flippable_v:
				preview_instance.scale.y *= -1
				rule_check_indicator_manager.scale.y *= -1
			else:
				building_signal_bus.action_failed.emit(
					flip_vertically_action,
					selected_placeable.display_name + " cannot be flipped vertically."
				)


func _align_preview_to_grid(collision_shape_global_position: Vector2):
	var tile_size = get_tile_size()
	# Set offset
	_preview_offset.x = int(collision_shape_global_position.x) % tile_size.x
	_preview_offset.y = int(collision_shape_global_position.y) % tile_size.y
	preview_instance.global_position += _preview_offset


## Rotates the preview instance by a number of degrees
func _rotate_preview(degrees: float):
	preview_instance.rotate(deg_to_rad(degrees))
	rule_check_indicator_manager.rotate(deg_to_rad(degrees))


## When dragging over to a new tile, attempt a build with no
## failed signal callbacks
func _on_grid_pathing_targeting_new_tile(new_tile: Vector2i, old_tile: Vector2i):
	if drag_multi_build && _grid_drag != null:
		try_build()


## Creates a special copy of the placeable's packed scene that
## only includes scripts in the placeable preview_active_nodes array
func _generate_preview_scene(p_placeable: Placeable) -> Node2D:
	if not _validate_placeable(p_placeable):
		return null

	var loaded_scene: Node2D = p_placeable.packed_scene.instantiate()
	var new_instance = loaded_scene.duplicate(4)

	positioner.add_child(new_instance)
	_exclude_nodes(new_instance, p_placeable.preview_excluded_nodes)

	loaded_scene.free()

	# Set preview sprites modulate color to preview color
	new_instance.propagate_call("set_self_modulate", [preview_modulate_color])

	# Disable all physics on object by making process mode disabled
	new_instance.process_mode = PROCESS_MODE_DISABLED

	# Set the Z-Index for rendering order
	new_instance.z_index = preview_instance_z_index

	return new_instance

## Removes select nodes at exclude_paths from the parent except for the parent itself
func _exclude_nodes(p_parent: Node, p_exclude_paths: Array[NodePath]):
	for path in p_exclude_paths:
		var node = p_parent.get_node(path)

		if node == p_parent:
			push_warning("Cannot exclude self from list of children nodes")
			continue

		node.free()


func _validate_ready_to_build() -> bool:
	if tilemap == null:
		push_warning("Cannot call set_buildable_preview without tilemap property set")
		return false

	if selected_placeable == null:
		push_warning("Null placeable - cannot place object without placeable resource")
		return false

	if rule_check_indicator_manager == null:
		push_warning("Can't validate placement without having a tile collision indicator manager")
		return false

	return true


func _setup_rule_check_indicator_manager():
	if rule_check_indicator_manager != null:
		return  # Already set up

	# Pre-Validate
	if rule_check_indicator_template == null:
		push_warning(
			"Creating rule check indicator manager with no indicator template. You should set a rule_check_indicator_template in the building system first."
		)

	rule_check_indicator_manager = RuleCheckIndicatorManager.new(
		tilemap, rule_check_indicator_template, show_debug_shapes
	)
	positioner.add_child(rule_check_indicator_manager)


## Validates whether a placeable is usable by the building system
func _validate_placeable(p_placeable: Placeable) -> bool:
	var no_errors = true

	if p_placeable == null:
		push_error(
			(
				"Placeable is null. Must have an actual placeable resource to use in the building system at path "
				+ str(get_path())
			)
		)
		no_errors = false
		return no_errors

	if not p_placeable.is_valid():
		push_error("Placeable " + p_placeable.resource_path + " is not valid")
		no_errors = false

	return no_errors

## Start a new drag that lasts until the build action is released
func _start_drag():
	_grid_drag = GridPathingComponent.new(positioner, tilemap)
	_grid_drag.name = "GridPathingComponent"
	add_child(_grid_drag)

func _stop_drag():
	if(_grid_drag != null):
		_grid_drag.free()
		_grid_drag = null

func _on_tile_map_changed(p_active_tile_map : TileMap):
	tilemap = p_active_tile_map # Updates manager in setter

## Tests the input map settings of the build system to make sure they match the input map
## Returns if the validation passed or not
func _validate_input_map() -> bool:
	var validation_passed = true
	
	for action in [exit_build_mode_action, build_action]:
		if(!InputMap.has_action(action)):
			push_warning("Build or exit build action misassigned. Input map does not have action " + action + " setup action in Project -> Project Settings -> Input Map")
			validation_passed = false

	if(enable_rotate):
		for action in [rotate_left_action, rotate_right_action]:
			if(!InputMap.has_action(action)):
				push_warning("Rotate action mismatch. Input map does not have action " + action + " setup action in Project -> Project Settings -> Input Map")
				validation_passed = false

	if(enable_flip_horizontal):
		if(!InputMap.has_action(flip_horizontally_action)):
			push_warning("Flip horizontal action mismatch. Input map does not have action " + flip_horizontally_action + " setup action in Project -> Project Settings -> Input Map")
			validation_passed = false
		
	if(enable_flip_vertical):
		if(!InputMap.has_action(flip_vertically_action)):
			push_warning("Flip vertically action mismatch. Input map does not have action " + flip_vertically_action + " setup action in Project -> Project Settings -> Input Map")
			validation_passed = false

	return validation_passed
