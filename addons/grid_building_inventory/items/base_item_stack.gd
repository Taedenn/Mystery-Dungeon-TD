extends Resource

class_name BaseItemStack

@export var type : BaseItem
@export var count : int

func _init(p_type : BaseItem = null, p_count : int = 0):
    type = p_type
    count = p_count