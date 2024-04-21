extends Node

var current_scene = null
var time = ""
var gold = 0
var tower_dict = {"Cascoon": 0, "Xatu": 0, "Lampent": 0, "Blissey": 0}
var tower_damage = {"Cascoon": 0, "Xatu": 0, "Lampent": 0, "Blissey": 0}

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)
