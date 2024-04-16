extends Node2D

@onready var check = $Check
var enemy_script = preload("res://scripts/Enemy.gd")
var soul = preload("res://scripts/soul_shard.gd")
var children
var enemy_instances
var remove_child = CharacterBody2D

func _ready():
	enemy_instances = []
	children = []

func removal_service(node):
	remove_child = node
	if enemy_instances.has(remove_child):
		enemy_instances.erase(node)

func _on_check_timeout():
	children = get_children()
	for child in children:
		if child.get_script() == enemy_script and not enemy_instances.has(child):
			enemy_instances.append(child)
	while enemy_instances.size() > 150:
		var first = enemy_instances.pop_back()
		var second = enemy_instances.pop_front()
		if children.has(first) and children.has(second):
			first.set_health(-second.health)
			second.queue_free()
			enemy_instances.append(first)

	
