extends StaticBody2D

@onready var player = $"../../World/Player"
@onready var soul_shard_material = preload("res://materials/soul_shard.tres")
@onready var item_display = $"../../CanvasLayer/HBoxContainer/BoxContainer/BoxContainer/BaseItemDisplay"

var detection_radius = 100
var pickup_radius = 5
var move_speed = 100
var merger
@export var magnet := false

func _ready():
	merger = get_parent()

func _process(delta):
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < detection_radius or magnet:
		move_towards_player(delta)
		
	if distance_to_player < pickup_radius:
		pick_up_shard()
		
func move_towards_player(delta):
	var direction = (player.global_position - global_position).normalized()
	var velocity = direction * move_speed * delta
	global_position += velocity
	
func pick_up_shard():
	var inventory = $"../../World/Player/Camera2D/ItemContainer"
	var shard_item = soul_shard_material
	var added_amount = inventory.try_add(shard_item, 1)
	item_display.update_inventory_display()
	
	if added_amount > 0:
		merger.removal_service_soul_shard(self)
		queue_free()
		
