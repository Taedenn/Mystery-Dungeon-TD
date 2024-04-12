class_name ResourceStack
extends Resource
## Contains a resource type and a count number of that resource

@export var type : Resource
@export var count : int = 1

func _init(p_type : Resource = null, p_count : int = 0):
	type = p_type
	count = p_count
