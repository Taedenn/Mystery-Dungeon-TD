extends CharacterBody2D

@export var player_tutorial_end := false
@export var health := 10
@export var damage := 5

const DAMAGE_TICK_INTERVAL = 0.8
const ATTACK_INTERVAL = 0.1

@onready var player = $"../World/Player"
@onready var _animated_enemy = $EnemyAnimations
@onready var areaCollider = $AreaCollider
@onready var hb = $healthbar
@onready var walk = $walk
@onready var hurt = $hurt
@onready var soul_shard_scene = preload("res://scenes/soul_shard.tscn")

var direction = position
var structure = StaticBody2D

var dir = "down"
var time_since_last_tick = 1.0
var attack_cooldown_timer = 0.0
var speed = 50
var recoil = 0
var is_hurt = false
var is_vulnerable = true
var player_in_range = false
var damage_tick = true
var taking_recoil = false

func _ready():
	walk.visible = true
	hurt.visible = false
	self.add_to_group("enemies")
	areaCollider.add_to_group("enemies")
	hb.init_health(health)

func update_animations(_delta):
	var old_position = position
	direction = (player.global_position - position).normalized()
	var new_pos = position + direction
	var diff = new_pos - old_position
	if diff.y > 0.2:
		if diff.x > 0.2 or diff.x < -0.2:
			dir = "down_right" if diff.x > 0 else "down_left"
		else: 
			dir = "down"
	elif diff.y < -0.2:
		if diff.x > 0.2 or diff.x < -0.2:
			dir = "up_right" if diff. x > 0 else "up_left"
		else:
			dir = "up"
	elif diff.x > 0: dir = "right"
	elif diff.x < 0: dir = "left"
	else:
		dir = "down"
	if not is_hurt:
		walk.visible = true
		hurt.visible = false
		_animated_enemy.play("walk_" + dir)
	else:
		walk.visible = false
		hurt.visible = true
		_animated_enemy.play("hurt_" + dir)
		await _animated_enemy.animation_finished
		is_hurt = false

func _physics_process(delta):
	time_since_last_tick += delta
	attack_cooldown_timer += delta
	if taking_recoil:
		if time_since_last_tick >= DAMAGE_TICK_INTERVAL:
			set_health(recoil)
			time_since_last_tick = 0.0
			
	if player_tutorial_end:
		if player_in_range:
			if time_since_last_tick >= DAMAGE_TICK_INTERVAL:
				
				# take damage
				if player.is_attacking and is_vulnerable:
					set_health(player.damage)
					is_vulnerable = false
					
				player._set_health(damage)
				time_since_last_tick = 0.0
				
			if attack_cooldown_timer >= ATTACK_INTERVAL:
				attack_cooldown_timer = 0.0
				is_vulnerable = true
		if not is_hurt:
			velocity = direction * speed
			move_and_collide(velocity * delta)
		update_animations(delta)
	
func set_health(d):
	is_hurt = true
	if health - d > 0:
		health -= d
		hb._set_health(health)
	else:
		walk.visible = false
		hurt.visible = true
		_animated_enemy.play("hurt_" + dir)
		await _animated_enemy.animation_finished
		var soul_shard = soul_shard_scene.instantiate()
		soul_shard.position = self.position
		add_child(soul_shard)
		queue_free()
	
func _on_collider_area_entered(area):
	if area.is_in_group("player"):
		player_in_range = true
		player.speed = 70
	
	if area.is_in_group("structures"):
		structure = area.get_parent()
		recoil = structure.recoil
		taking_recoil = true

func _on_collider_area_exited(area):
	if area.is_in_group("player"):
		time_since_last_tick = 1.0
		player.speed = 100
		player_in_range = false
		
	if area.is_in_group("structures"):
		taking_recoil = false

func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		player_tutorial_end = true
