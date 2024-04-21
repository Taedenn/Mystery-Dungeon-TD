extends CharacterBody2D

@export var player_tutorial_end := false
@export var health := 10
@export var damage := 5
@export var drops := 1

const DAMAGE_TICK_INTERVAL = 0.8
const ATTACK_INTERVAL = 0.1

@onready var player = $"../../World/Player"
@onready var _animated_enemy = $EnemyAnimations
@onready var areaCollider = $AreaCollider
@onready var hb = $healthbar
@onready var walk = $walk
@onready var hurt = $hurt
@onready var Enemy_Container = $".."
@onready var damage_display = $DamageDisplay
@onready var soul_shard_scene = preload("res://scenes/soul_shard.tscn")
@onready var global_data = get_node("/root/global")

var direction = position
var structure = StaticBody2D
var hazard = Area2D
var check_damage = Timer

var dir = "down"
var time_since_last_tick = 1.0
var attack_cooldown_timer = 0.0
var speed = 50
var recoil = 0
var hazard_tick = 0
var is_hurt = false
var is_vulnerable = true
var player_in_range = false
var damage_tick = true
var taking_recoil = false
var dropped = false
var hazard_damage_instances = []
var recurring_hazard_instances = []
var merger

func _ready():
	walk.visible = true
	hurt.visible = false
	self.add_to_group("enemies")
	areaCollider.add_to_group("enemies")
	hb.init_health(health)
	var damage_timer = check_damage.new()
	damage_timer.wait_time = 0.1
	damage_timer.connect("timeout", _on_Timer_timeout)
	damage_timer.autostart = true
	damage_timer.one_shot = false
	add_child(damage_timer)
	damage_timer.start()
	
	merger = get_parent()

func update_animations():
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
				
	if not is_hurt:
		velocity = direction * speed
		move_and_collide(velocity * delta)
	update_animations()
	
func process_hazard_damage():
	if hazard_damage_instances.size() > 0:
		for i in range(hazard_damage_instances.size()):
			i -= 1
			if i < hazard_damage_instances.size():
				var hazard_instance = hazard_damage_instances[i]
				set_health(hazard_instance.hazard_tick)
				
				var hazard_keys = hazard_instance.keys()
				var damage_track = { hazard_instance.get(hazard_keys[0]): hazard_instance.get(hazard_keys[1]) + global_data.tower_damage.get(hazard_instance.get(hazard_keys[0]))}
				global_data.tower_damage.merge(damage_track, true)
				
				hazard_damage_instances.pop_front()
			
	if taking_recoil:
		if time_since_last_tick >= DAMAGE_TICK_INTERVAL and recurring_hazard_instances.size() > 0:
			for i in range(recurring_hazard_instances.size()):
				i -= 1
				if i < recurring_hazard_instances.size():
					var hazard_instance = recurring_hazard_instances[i]
					hazard_damage_instances.append(hazard_instance)
					time_since_last_tick = 0.0
		
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
	
func set_health(d):
	is_hurt = true
	if d > 0:
		damage_display.display(d)
	if health - d > 0:
		health -= d
		hb._set_health(health)
	else:
		walk.visible = false
		hurt.visible = true
		_animated_enemy.play("hurt_" + dir)
		await _animated_enemy.animation_finished
		if Enemy_Container != null:
			if not dropped:
				for drop in drops:
					var soul_shard = soul_shard_scene.instantiate()
					var offset = Vector2(randi_range(-8, 8), randi_range(-8, 8))
					soul_shard.global_position = global_position + offset
					Enemy_Container.add_child(soul_shard)
				dropped = true
		merger.removal_service(self)
		
		queue_free()
	
# Get the base name without the appended number
func get_base_name(string: String) -> String:
	var base_name = string
	# Check if the name ends with a number
	var last_char = string[string.length() - 1]
	while last_char.is_valid_int():
		# Remove the last character
		base_name = base_name.left(base_name.length() - 1)
		# Check the next last character
		last_char = base_name[base_name.length() - 1]
	return base_name
	
func _on_collider_area_entered(area):
	if area.is_in_group("player"):
		player_in_range = true
		player.speed = 90
		process_hazard_damage()
	
	if area.is_in_group("structures"):
		var structure_name = get_base_name(area.get_parent().get_name())
		var hazard_instance = {
			"hazard": structure_name,
			"hazard_tick": area.get_parent().recoil
		}
		hazard_damage_instances.append(hazard_instance)
		recurring_hazard_instances.append(hazard_instance)
		taking_recoil = true
		process_hazard_damage()
	
	if area.is_in_group("hazards"):
		var hazard_name = get_base_name(area.get_parent().get_name())
		var hazard_instance = {
			"hazard": hazard_name,
			"hazard_tick": area.get_parent().aura
		}
		hazard_damage_instances.append(hazard_instance)
		process_hazard_damage()

func _on_collider_area_exited(area):
	if area.is_in_group("player"):
		time_since_last_tick = 1.0
		player.speed = 100
		player_in_range = false
		
	if area.is_in_group("structures"):
		taking_recoil = false
		if recurring_hazard_instances.size() > 0:
			recurring_hazard_instances.pop_front()

func _on_tutorial_end_area_entered(area):
	if area.is_in_group("player"):
		player_tutorial_end = true

func _on_Timer_timeout():
	process_hazard_damage()
