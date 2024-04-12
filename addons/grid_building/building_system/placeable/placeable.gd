class_name Placeable
extends Resource
## An object that can be placed into the game world by instancing the packed_scene

## In game display name. Can differ from the resource_name of base resource class
@export var display_name : StringName

## The texture icon that represents this placeable in elements like UI
@export var icon : Texture2D

## The placed object in the game world
@export var packed_scene : PackedScene

## Resources that mark the placeable as belonging to certain categories or groups
@export var tags : Array[Resource]

## The rule requirements that must be met in order to place the packed_scene in the game world
@export var placement_rules : Array[BuildingRule]

## Paths to nodes that should keep their scripts when generating
## a preview instance before placement. Use this for things like
## keeping an animation script going when other scripts are removed.
@export var preview_excluded_nodes : Array[NodePath]

## Flag to ignore the default always on placement rules and use exclusively this placeable's rules only
@export var ignore_base_rules : bool = false

## Marks whether the placeable preview should be allowed to be rotated left and right
@export var rotateable : bool = false

## Marks whether the placeable preview should be allowed to be flipped horizontally
@export var flippable_h : bool = false

## Marks whether the placeable preview should be allowed to be flipped vertically
@export var flippable_v : bool = false

func _init(p_packed_scene : PackedScene = null, p_placement_rules : Array[BuildingRule] = []):
	packed_scene = p_packed_scene
	placement_rules = p_placement_rules

func is_valid() -> bool:
	var no_setup_errors = true
	
	if(packed_scene == null):
		push_error("No packed_scene for placement in placeable " + resource_path)
		no_setup_errors = false
		
	return no_setup_errors
