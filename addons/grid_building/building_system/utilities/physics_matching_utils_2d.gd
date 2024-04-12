## Utilities for Getting Collision Shapes, Objects, and Polygons for Collision Tasks
class_name PhysicsMatchingUtils2D

# Gets all collision objects from the preview_instance including self and children for matching nodes
# Must have layers matching at least one of the mask layers from the tile collision template
static func get_matching_collision_objects(p_root : Node2D, shape_cast : ShapeCast2D, require_all_mask_layers : bool = false) -> Array[CollisionObject2D]:
	if(p_root == null):
		push_error("Root node p_node for collision object cannot be null.")
		return []
	
	var collision_objects : Array[CollisionObject2D] = []
	
	if(p_root is CollisionObject2D):
		collision_objects.append(p_root)
		
	for child in p_root.find_children("", "CollisionObject2D"):
		collision_objects.append(child)
	
	var collidable_objects : Array[CollisionObject2D] = []
	
	for col_obj in collision_objects:
		var matched = false
		
		for i in range(1,32,1):
			if(shape_cast.get_collision_mask_value(i)):
				if(col_obj.get_collision_layer_value(i)):
					matched = true
					
					if(not require_all_mask_layers):
						break
				elif(require_all_mask_layers):
					# Failed to match on needed mask layer
					matched = false	
			
		if(matched):
			collidable_objects.append(col_obj)
		
	return collidable_objects
	
## From a given instance_root, find the collision shapes attached to collision objects that have a layer that matches
## the placement mask layers of the building system
static func get_castable_shapes(instance : Node2D, shape_cast : ShapeCast2D) -> Array[CollisionShape2D]:
	# Get all nodes that are CollisionObject2D from the instance including the root node
	var collision_nodes : Array[Node] = []
	
	if(instance is CollisionObject2D):
		collision_nodes.append(instance)

	collision_nodes.append_array(instance.find_children("", "CollisionObject2D", true))
	
	var collision_objects : Array[CollisionObject2D] = []
	
	# Put all of the nodes in the collision_objects as a collision_object
	for node in collision_nodes:
		collision_objects.append(node)
	
	var matched_placement_shapes : Array[CollisionShape2D] = []

	# For each collision object, determine if the object falls into the building check mask layers
	for obj in collision_objects:
		# If it has a matching layer, add it's shape(s) to the placement shapes
		# placement_mask_layers
		# Bitwise if & returns 0 then a collision is possible
		# https://stackoverflow.com/questions/75047813/how-to-check-if-2-collisionobjects-can-collide
		for layer in range(1, 32, 1):
			# Find a match in any layer
			if(obj.get_collision_layer_value(layer) && shape_cast.get_collision_mask_value(layer)):
				var obj_shapes = obj.find_children("", "CollisionShape2D", false, true)
				
				# If collision polygons, generate a rect for each one. Later remove tile indicators for uunmatching areas
				# inside of the rectangle against the collision polygon itself
				
				matched_placement_shapes.append_array(obj_shapes)
				break

	return matched_placement_shapes
	
## Get all collision polygon 2d nodes that are children with matching layers to
## the tile indicator mask
static func get_castable_collision_polygons(instance : Node2D, shape_cast : ShapeCast2D) -> Array[CollisionPolygon2D]:
	# Get all nodes that are CollisionObject2D from the instance including the root node
	var collision_nodes : Array[Node] = []

	if(instance is CollisionPolygon2D):
		collision_nodes.append(instance)

	collision_nodes.append_array(instance.find_children("", "CollisionPolygon2D", true))

	var collision_polygons : Array[CollisionPolygon2D] = []

	# Put all of the nodes in the collision_objects as a collision_object
	for node in collision_nodes:
		collision_polygons.append(node)
		
	var matching_layer_polgyons : Array[CollisionPolygon2D] = []
	
	for col_obj in instance.find_children("", "CollisionObject2D"):
		# For each collision object, determine if the object falls into the building check mask layers
		for polygon in collision_polygons:
			# If it has a matching layer, add it's shape(s) to the placement shapes
			# placement_mask_layers
			# Bitwise if & returns 0 then a collision is possible
			# https://stackoverflow.com/questions/75047813/how-to-check-if-2-collisionobjects-can-collide
			
			for layer in range(1, 32, 1):
				# Find a match in any layer
				if(polygon.get_collision_layer_value(layer) && shape_cast.get_collision_mask_value(layer)):
					matching_layer_polgyons.append(polygon)
					break

	return matching_layer_polgyons

# Get the names of each physics layer in the given layers array
static func get_physics_layer_names(p_layers : Array[int]):
	var layer_names : Array[String] = []
	
	for layer in p_layers:
		var layer_name = ProjectSettings["layer_names/2d_physics/layer_" + str(layer)]
		layer_names.append(layer_name)

	return layer_names

## Gets the layer numbers that are active in a given mask value
static func get_layers_from_bitmask(p_bitmask : int) -> Array[int]:
	var remainder = p_bitmask
	var mask_layers : Array[int] = []

	for power in range(31, -1, -1):
		var mask_value = pow(2, power)

		if(remainder >= mask_value):
			remainder -= mask_value
			mask_layers.append(power + 1)
			
	return mask_layers

## Gets the active layer names from a given physics mask int
static func get_physics_layer_names_from_mask(p_bitmask : int) -> Array[String]:
	var mask_layers = get_layers_from_bitmask(p_bitmask)
	var layer_names = get_physics_layer_names(mask_layers)
	return layer_names

## Checks if a collision object has any active physics layers that match a given bitmask
static func object_has_matching_layer(col_obj : CollisionObject2D, p_check_mask : int) -> bool:
	var active_obj_layers = get_layers_from_bitmask(col_obj.collision_layer)
	var check_layers = get_layers_from_bitmask(p_check_mask)
	
	for layer in active_obj_layers:
		if(check_layers.has(layer)):
			return true
	
	return false
