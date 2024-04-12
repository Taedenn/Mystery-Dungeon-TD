extends Node2D

var zubat_scene = preload("res://scenes/Zubat.tscn")
var gligar_scene = preload("res://scenes/Gligar.tscn")
var sableye_scene = preload("res://scenes/Sableye.tscn")
var banette_scene = preload("res://scenes/Banette.tscn")
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


func _ready():
	sa1 = $"World/Spawners/Spawn _Area_1/sa1"
	sa2 = $World/Spawners/Spawn_Area_2/sa2
	sa3 = $World/Spawners/Spawn_Area_3/sa3
	sa4 = $World/Spawners/Spawn_Area_4/sa4
	

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
		enemy.health += healthscaling
		add_child(enemy)


func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		player_tutorial_end = true


func _on_sunrise_timeout():
	nighttime = true


func _on_nightfall_timeout():
	nighttime = false
	healthscaling += (basehealth * 0.25)
	basehealth += healthscaling
	
