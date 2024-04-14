extends Node2D

@onready var zubat_scene = preload("res://scenes/Zubat.tscn")
@onready var gligar_scene = preload("res://scenes/Gligar.tscn")
@onready var sableye_scene = preload("res://scenes/Sableye.tscn")
@onready var banette_scene = preload("res://scenes/Banette.tscn")
@onready var soul_shard_scene = preload("res://scenes/soul_shard.tscn")
@onready var soul_shard_material = preload("res://materials/soul_shard.tres")
@onready var dialogue_scene = preload("res://scenes/dialogue_box.tscn")
@onready var pause = preload("res://scenes/pause_menu.tscn")

@onready var world_enemies = $Enemies
@onready var player = $World/Player
@onready var item_container = $World/Player/Camera2D/ItemContainer
@onready var stopwatch = $CanvasLayer/BoxContainer/BoxContainer/Stopwatch/Time
@onready var spawner = $World/Spawners/Spawner
@onready var item_display = $CanvasLayer/BoxContainer/BoxContainer/BaseItemDisplay
@onready var seal = $World/sigil/Seal
@onready var seal_anim = $World/sigil/SealAnim
@onready var seal_ap = $World/sigil/SealAnimationPlayer

@onready var baseItemStack = [preload("res://materials/base_item_stack.tres")]
@onready var blissey_totem = preload("res://objects/blissey_placeable.tres")

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
var spawnrate = 0.7


func _ready():
	sa1 = $"World/Spawners/Spawn _Area_1/sa1"
	sa2 = $World/Spawners/Spawn_Area_2/sa2
	sa3 = $World/Spawners/Spawn_Area_3/sa3
	sa4 = $World/Spawners/Spawn_Area_4/sa4
	
	seal.visible = true
	seal_anim.visible = false
	
	# reset inventory
	var shard_item = soul_shard_material
	var material_count = item_container.get_count(shard_item)
	item_container.try_remove(shard_item, material_count)
	item_display.update_inventory_display()
	
	# print(item_container.get_count(blissey_totem, baseItemStack))

func _physics_process(_delt3a):
	if Input.is_action_just_pressed("exit_game"):
		var pause_menu = pause.instantiate()
		add_child(pause_menu)

func _on_spawner_timeout():
	if player_tutorial_end and nighttime:
		var enemy = zubat_scene.instantiate()
		
		var rand = randi_range(1, 4)
		match rand:
			1: enemy = zubat_scene.instantiate()
			2: enemy = gligar_scene.instantiate()
			3: enemy = sableye_scene.instantiate()
			4: enemy = banette_scene.instantiate()
		rand = randi_range(1, 4)
		match rand:
			1: spawn_area = sa1
			2: spawn_area = sa2
			3: spawn_area = sa3
			4: spawn_area = sa4
			
		var center = spawn_area.position
		var radius = spawn_area.shape.radius
		var angle = randf() * 2 * PI
		spawn_pos = center + Vector2(radius * cos(angle), radius * sin(angle))
		enemy.position = spawn_pos
		enemy.player_tutorial_end = true
		
		# scaling
		enemy.health += healthscaling
		world_enemies.add_child(enemy)


func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		
		if not player_tutorial_end:
			player_tutorial_end = true
			var dialogue = dialogue_scene.instantiate()
			dialogue.messages = ["It'll get dark soon... I should start building defenses...",
			"(press tab to open/close inventory, left-click to place towers, right-click to deselect)"]
			dialogue.timed_message = true
			dialogue.read_time = 1.5
			dialogue.speaking = "Me:"
			add_child(dialogue)
			
			seal.visible = false
			seal_anim.visible = true
			seal_ap.play("out")
			
			stopwatch.start()


func _on_sunrise_timeout():
	nighttime = true


func _on_nightfall_timeout():
	nighttime = false
	healthscaling += (basehealth * 0.25)
	basehealth += healthscaling
	
	spawner.wait_time = spawner.wait_time * spawnrate
	
	for x in range(5):
		var soul_shard = soul_shard_scene.instantiate()
		var offset = Vector2(randi_range(-20, 20), randi_range(-20, 20))
		soul_shard.global_position = player.global_position + offset
		world_enemies.add_child(soul_shard)


func _on_midday_timeout():
	nighttime = true
