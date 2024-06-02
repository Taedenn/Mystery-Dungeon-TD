extends PanelContainer

class_name BaseItemDisplay

@export var item_texture : TextureRect
@export var item_label : Label
@export var amount_label : Label

@onready var item_container = $"../../../../../World/Player/Camera2D/ItemContainer"
@onready var soul_shard_material = preload("res://materials/gimmie_coin.tres")

var resource_type : BaseItem :
	set(new_type):
		resource_type = new_type
		item_texture.texture = new_type.icon
	
func _ready():
	update_inventory_display()
	
func update_count(count : int):
	item_label.text = str(count)
	
func update_inventory_display():
	var material_type = soul_shard_material
	var material_count = item_container.get_count(material_type)
	amount_label.text = str(material_count)


func _on_update_timeout():
	update_inventory_display()
