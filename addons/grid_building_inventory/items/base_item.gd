extends Resource

class_name BaseItem

## The gameplay name representation for the item name
@export var display_name : String

## The display image that represents the item in ui
@export var icon : Texture2D

## Marker resources that indicate which categories this
## item qualifies for. Used for comparisons. This can be any
## resource but should be stored as a file in the project so you can
## reference it between different objects that use tags
@export var tags : Array[Resource]

## The maximum number of a material that can exist in one item_stack
@export var stack_maximum : int = 1

func _init(p_display_name : String = "", p_icon : Texture2D = null, 
p_tags : Array[Resource] = [], p_stack_maximum : int = 1):
	display_name = p_display_name
	icon = p_icon
	tags = p_tags
	stack_maximum = p_stack_maximum
