extends Node2D

@onready var check = $Check
var enemy_script = preload("res://scripts/Enemy.gd")
var soul = preload("res://scripts/soul_shard.gd")
var children
var enemy_instances
var soul_stones
var remove_child = CharacterBody2D
var remove_shard = StaticBody2D

func _ready():
	enemy_instances = []
	soul_stones = []
	children = []

func removal_service(node):
	remove_child = node
	if enemy_instances.has(remove_child):
		enemy_instances.erase(remove_child)
		
func removal_service_soul_shard(shard):
	remove_child = shard
	if soul_stones.has(remove_child):
		soul_stones.erase(remove_child)

func _on_check_timeout():
	children = get_children()
	for child in children:
		if child.get_script() == enemy_script and not enemy_instances.has(child):
			enemy_instances.append(child)
		elif child.get_script() == soul and not soul_stones.has(child):
			soul_stones.append(child)
			
	if enemy_instances.size() > 150:
		var first = enemy_instances.pop_back()
		var second = enemy_instances.pop_front()
		if children.has(first) and children.has(second):
			first.set_health(-second.health)
			second.queue_free()
			enemy_instances.append(first)

func _on_nightfall_timeout():
	for s in soul_stones:
		var soul_stone = soul_stones.pop_front()
		if children.has(soul_stone):
			soul_stone.magnet = true
			soul_stones.erase(soul_stone)
		else:
			soul_stones.erase(soul_stone)
