extends CharacterBody2D

@export var player_tutorial_end := false
@export var health := 10
@export var damage := 5

const DAMAGE_TICK_INTERVAL = 0.8
const ATTACK_INTERVAL = 0.1

@onready var player = $"../Player"
@onready var _animated_enemy = $EnemyAnimations
@onready var hb = $healthbar
@onready var walk = $walk
@onready var hurt = $hurt

var direction = position
var player_in_range = false
var damage_tick = true
var dir = "down"
var time_since_last_tick = 1.0
var attack_cooldown_timer = 0.0
var speed = 50
var is_hurt = false
var is_vulnerable = true

func _ready():
	walk.visible = true
	hurt.visible = false
	self.add_to_group("enemies")
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
	if player_tutorial_end:
		if player_in_range:
			time_since_last_tick += delta
			attack_cooldown_timer += delta
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
		queue_free()
	
func _on_collider_area_entered(area):
	if area.is_in_group("player"):
		player_in_range = true
		player.speed = 70
	elif area.is_in_group("hazards"):
		set_health(5)


func _on_collider_area_exited(area):
	if area.is_in_group("player"):
		time_since_last_tick = 1.0
		player.speed = 100
		player_in_range = false

func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		player_tutorial_end = true
