extends Node2D

@onready var zubat_scene = preload("res://scenes/Zubat.tscn")
@onready var gligar_scene = preload("res://scenes/Gligar.tscn")
@onready var sableye_scene = preload("res://scenes/Sableye.tscn")
@onready var banette_scene = preload("res://scenes/Banette.tscn")
@onready var soul_shard_scene = preload("res://scenes/gimmie_coin.tscn")
@onready var soul_shard_material = preload("res://materials/gimmie_coin.tres")
@onready var dialogue_scene = preload("res://scenes/dialogue_box.tscn")
@onready var pause = preload("res://scenes/pause_menu.tscn")
@onready var baseItemStack = [preload("res://materials/base_item_stack.tres")]

@onready var world_enemies = $Enemies
@onready var player = $World/Player
@onready var item_container = $World/Player/Camera2D/ItemContainer
@onready var stopwatch = $CanvasLayer/HBoxContainer/BoxContainer/BoxContainer/Stopwatch/Time
@onready var spawner = $World/Spawners/Spawner
@onready var item_display = $CanvasLayer/HBoxContainer/BoxContainer/BoxContainer/BaseItemDisplay
@onready var placeable_control = $CanvasLayer/HBoxContainer/BoxContainer/Catalogue/PlaceableSelectionUI

@onready var global_data = get_node("/root/global")

var itemslist

var player_tutorial_end = false

var sa1 = CollisionShape2D
var sa2 = CollisionShape2D
var sa3 = CollisionShape2D
var sa4 = CollisionShape2D
var spawn_area = CollisionShape2D
var spawn_pos = Vector2(0,0)
var nighttime = false

var basehealth = 100
var healthscaling = 0
var spawnrate = 0.6
var damage_scale = 2
var speed_scale = 1
var select = Node2D

var enemyhealth = 100
var basedamage = 2
var basespeed = 75
var children = []
@export var start_amount = 0


func _ready():
	sa1 = $"World/Spawners/Spawn _Area_1/sa1"
	sa2 = $World/Spawners/Spawn_Area_2/sa2
	sa3 = $World/Spawners/Spawn_Area_3/sa3
	sa4 = $World/Spawners/Spawn_Area_4/sa4
	
	global_data.reset()
	
	# reset inventory
	var shard_item = soul_shard_material
	var material_count = item_container.get_count(shard_item)
	item_container.try_remove(shard_item, material_count)
	item_display.update_inventory_display()
	item_container.try_add(shard_item, start_amount)
	
	# cache
	for i in range(0, 80):
		var enemy = spawn_rand_enemy()
		enemy.position = Vector2(-5000,-5000)
		enemy.freeze = false
		children.append(enemy)
		world_enemies.add_child(enemy)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED

func _input(_InputEvent):
	if Input.is_action_just_pressed("exit_game"):
		var pause_menu = pause.instantiate()
		add_child(pause_menu)
		
	if Input.is_action_just_pressed("first"):
		placeable_control._on_list_item_selected(0)
		
	if Input.is_action_just_pressed("second") and global_data.limit > 1:
		placeable_control._on_list_item_selected(1)
		
	if Input.is_action_just_pressed("third") and global_data.limit > 2:
		placeable_control._on_list_item_selected(2)
	
	if Input.is_action_just_pressed("fourth") and global_data.limit > 3:
		placeable_control._on_list_item_selected(3)
		
func _on_spawner_timeout():
	if player_tutorial_end and nighttime:
		var enemy = find_unfrozen_enemies()
		if enemy != null:
			enemy.health = enemyhealth
			enemy.damage = basedamage
			enemy.speed = basespeed
			enemy.freeze = true
			enemy.dropped = false
			enemy.position = spawn_rand_pos()
			enemy.hazard_damage_instances = []
			enemy.recurring_hazard_instances = []
			enemy.scale = Vector2(1, 1)
			enemy.process_mode = Node.PROCESS_MODE_INHERIT

func find_unfrozen_enemies():
	for enemy in children:
		if enemy != null and not enemy.freeze:
			return enemy

func spawn_rand_enemy():
	var enemy = zubat_scene.instantiate()
	
	var rand = randi_range(1, 4)
	match rand:
		1: enemy = zubat_scene.instantiate()
		2: enemy = gligar_scene.instantiate()
		3: enemy = sableye_scene.instantiate()
		4: enemy = banette_scene.instantiate()
	return enemy
	
func spawn_rand_pos():
	var rand = randi_range(1, 4)
	match rand:
		1: spawn_area = sa1
		2: spawn_area = sa2
		3: spawn_area = sa3
		4: spawn_area = sa4
	var center = spawn_area.position
	var radius = spawn_area.shape.radius
	var angle = randf() * 2 * PI
	spawn_pos = center + Vector2(radius * cos(angle), radius * sin(angle))
	return spawn_pos


func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		
		if global_data.tutorial:
			var dialogue = dialogue_scene.instantiate()
			dialogue.messages = ["It'll get dark soon... I should start building defenses...",
			"(Building towers cost Gold. You can keep track in your inventory.)"]
			dialogue.timed_message = true
			dialogue.read_time = 4 
			dialogue.speaking = "Me:"
			add_child(dialogue)
			
		player_tutorial_end = true
		stopwatch.start()


func _on_sunrise_timeout():
	nighttime = true

func _on_nightfall_timeout():
	nighttime = false
	
	healthscaling += (basehealth * 0.2)
	basehealth += healthscaling
	
	if spawner.wait_time > 0.2:
		spawner.wait_time = spawner.wait_time * spawnrate

	enemyhealth += healthscaling
	basespeed += speed_scale
	basedamage += damage_scale
	
func _on_midday_timeout():
	nighttime = true
