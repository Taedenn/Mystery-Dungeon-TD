extends CharacterBody2D

@export var speed = 100
@export var sleepy_start := true
@export var damage := 5

@onready var _animated_sprite = $PlayerAnimations
@onready var walk = $walk
@onready var attack = $attack
@onready var sleep = $sleep
@onready var wake = $wake
@onready var hb = $healthbar
@onready var dc = $Day_Cycle
@onready var nc = $Night_Cycle
@onready var md = $Midday
@onready var area2d = $player_area

@onready var full = $"../../CanvasLayer/BoxContainer/PanelContainer/Full"
@onready var ouch = $"../../CanvasLayer/BoxContainer/PanelContainer/Ouch"
@onready var half = $"../../CanvasLayer/BoxContainer/PanelContainer/Half"
@onready var low = $"../../CanvasLayer/BoxContainer/PanelContainer/Low"
@onready var knockout = $"../../CanvasLayer/BoxContainer/PanelContainer/KnockOut"
@onready var UI = $"../../CanvasLayer"

@onready var projectile = preload("res://scenes/razor_leaf.tscn")
@onready var Enemies = preload("res://scripts/Enemy.gd")

var bg_music := AudioStreamPlayer.new()
var sound_player := AudioStreamPlayer.new()
var rng = RandomNumberGenerator.new()

var shooting = false
var is_attacking = false
var freeze_input = true
var left_tutorial_area = false

var direction = "down"

var max_health = 100
var health = 100
var num = 0

func _ready():
	self.add_to_group("player", true)
	area2d.add_to_group("player", true)
	
	if sleepy_start:
		hb.visible = false
		walk.visible = false
		attack.visible = false
		wake.visible = false
		sleep.visible = true
		_animated_sprite.play("sleep")	
	else:
		hb.visible = true
		wake.visible = false
		attack.visible= false
		sleep.visible = false
		walk.visible = true
		freeze_input = false
	
	hb.init_health(health)
	full.visible = true
	ouch.visible = false
	half.visible = false
	low.visible = false
	knockout.visible = false
	
	add_child(bg_music)
	add_child(sound_player)
	bg_music.stream = load("res://music/003 - Welcome to the World of Pokémon!.mp3")
	bg_music.play()
	bg_music.autoplay = true

func background_music_day():
	var rand = num
	while num == rand:
		rand = rng.randi_range(1, 7)
	num = rand
	match num:
		1: bg_music.stream = load("res://music/041 - Quicksand Cave.mp3")
		2: bg_music.stream = load("res://music/052 - Dusk Forest.mp3")
		3: bg_music.stream = load("res://music/055 - Treeshroud Forest.mp3")
		4: bg_music.stream = load("res://music/056 - Brine Cave.mp3")
		5: bg_music.stream = load("res://music/058 - Hidden Land.mp3")
		6: bg_music.stream = load("res://music/078 - Mystifying Forest.mp3")
		7: bg_music.stream = load("res://music/085 - Sky Peak Snowfield.mp3")
	bg_music.play()
	bg_music.autoplay = true

func background_music_night():
	match num:
		1: bg_music.stream = load("res://music/042 - Quicksand Pit.mp3")
		2: bg_music.stream = load("res://music/053 - Deep Dusk Forest.mp3")
		3: bg_music.stream = load("res://music/054 - The Power of Darkness.mp3")
		4: bg_music.stream = load("res://music/057 - Lower Brine Cave.mp3")
		5: bg_music.stream = load("res://music/059 - Hidden Highland.mp3")
		6: bg_music.stream = load("res://music/094 - In the Nightmare.mp3")
		7: bg_music.stream = load("res://music/086 - Sky Peak Final Pass.mp3")
	bg_music.play()
	bg_music.autoplay = true

func get_input():
	if not freeze_input:
		var input_direction = Input.get_vector("left", "right", "up", "down")
		velocity = input_direction * speed

func update_animation():
	if velocity.length() == 0:
		if not is_attacking:
			_animated_sprite.stop()
			return
		else:
			attack.visible = true
			walk.visible = false
			_animated_sprite.play("attack_" + direction)
			# shoot()
			await $PlayerAnimations.animation_finished
			shooting = false
			is_attacking = false
			return
	
	if velocity.y > 0:
		if velocity.x != 0:
			direction = "down_right" if velocity.x > 0 else "down_left"
		else: 
			direction = "down"
	elif velocity.y < 0:
		if velocity.x != 0:
			direction = "up_right" if velocity. x > 0 else "up_left"
		else:
			direction = "up"
	elif velocity.x > 0: direction = "right"
	elif velocity.x < 0: direction = "left"
	else: direction = "down"

	var current_anim = _animated_sprite.get_current_animation()

	if is_attacking and current_anim != "attack_" + direction:
		_animated_sprite.play("attack_" + direction, false)
		attack.visible = true
		walk.visible = false
		# shoot()
		await $PlayerAnimations.animation_finished
		shooting = false
		is_attacking = false
		
	else:
		if not is_attacking and current_anim != "walk_" + direction:
			_animated_sprite.play("walk_" + direction)
			attack.visible = false
			walk.visible = true

func shoot():
	if not shooting:
		shooting = true
		var bullet = projectile.instantiate()
		get_parent().add_child(bullet)
		var pos = position
		pos.y += 46
		bullet.shoot(pos)

func _physics_process(_delta):
	if not freeze_input:
		if not is_attacking:
			get_input()
			move_and_collide(velocity * _delta)

		if Input.is_action_just_pressed("attack"):
			is_attacking = true
			
		if Input.is_action_just_pressed("open_build"):
			if UI.visible:
				UI.visible = false
			else:
				UI.visible = true
			
		if health <= 0:
			freeze_input = true
			Enemies.player_tutorial_end = false
			# play death scene
			get_tree().reload_current_scene()
			
		update_animation()

func _set_health(d):
	if health - d > 0:
		health -= d
		hb._set_health(health)
		if health > max_health * (4.0/5.0) and health <= max_health:
			full.visible = true
			ouch.visible = false
			half.visible = false
			low.visible = false
			knockout.visible = false
		elif health > max_health * (3.0/5.0) and health < max_health * (4.0/5.0):
			full.visible = false
			ouch.visible = true
			half.visible = false
			low.visible = false
			knockout.visible = false
		elif health > max_health * (2.0/5.0) and health < max_health * (3.0/5.0):
			full.visible = false
			ouch.visible = false
			half.visible = true
			low.visible = false
			knockout.visible = false
		elif health > max_health * (1.0/5.0) and health < max_health * (2.0/5.0):
			full.visible = false
			ouch.visible = false
			half.visible = false
			low.visible = true
			knockout.visible = false
		elif health >= 0 and health < max_health * (1.0/5.0):
			full.visible = false
			ouch.visible = false
			half.visible = false
			low.visible = false
			knockout.visible = true
	elif health - d <= 0: 
		hb._set_health(0)

func _on_regen_timeout():
	if health < 100 and health > 0:
		health += 2
		hb._set_health(health)

func wake_up():
	wake.visible = true
	sleep.visible = false
	_animated_sprite.play("wake")
	await $PlayerAnimations.animation_finished
	wake.visible = false
	walk.visible = true
	hb.visible = true
	freeze_input = false

func _on_sleeping_timeout():
	if sleepy_start:
		wake_up()
	
func _on_day_cycle_timeout():
	bg_music.stop()
	background_music_night()
	nc.start()

func _on_night_cycle_timeout():
	bg_music.stop()
	background_music_day()
	dc.start()


func _on_player_area_area_entered(area):
	if area.is_in_group("enemies"):
		pass


func _on_tutorial_end_area_entered(_area):
	if not left_tutorial_area:
		background_music_day()
		md.start()
		left_tutorial_area = true


func _on_midday_timeout():
	bg_music.stop()
	background_music_night()
	nc.start()
