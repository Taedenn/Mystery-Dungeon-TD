extends PanelContainer

class_name BaseItemDisplay

@export var item_texture : TextureRect
@export var item_label : Label

var resource_type : BaseItem :
	set(new_type):
		resource_type = new_type
		item_texture.texture = new_type.icon

func update_count(count : int):
	item_label.text = str(count)
