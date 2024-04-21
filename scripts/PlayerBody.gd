extends CharacterBody2D

@export var speed = 100
@export var sleepy_start := true
@export var damage := 5
@export var engine_speed := 1
@export var max_health := 100
@export var regen := 2

# local scene
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
@onready var health_display = $HealthDisplay
@onready var camera = $Camera2D

# main
@onready var full = $"../../CanvasLayer/PanelContainer/Full"
@onready var ouch = $"../../CanvasLayer/PanelContainer/Ouch"
@onready var half = $"../../CanvasLayer/PanelContainer/Half"
@onready var low = $"../../CanvasLayer/PanelContainer/Low"
@onready var knockout = $"../../CanvasLayer/PanelContainer/KnockOut"
@onready var UI = $"../../CanvasLayer/HBoxContainer/BoxContainer"
@onready var playerUI = $"../../CanvasLayer/PanelContainer"
@onready var scroll = $"../sigil/Scroll"
@onready var stopwatch = $"../../CanvasLayer/HBoxContainer/BoxContainer/BoxContainer/Stopwatch/Time"
@onready var InvenButton = $"../../CanvasLayer/HBoxContainer/VBoxContainer/Tab/OpenClose"

# preload/autoload
@onready var global_data = get_node("/root/global")
@onready var DialogueBoxStartScene = preload("res://scenes/dialogue_box.tscn")
@onready var Enemies = preload("res://scripts/Enemy.gd")

var bg_music := AudioStreamPlayer.new()
var sound_player := AudioStreamPlayer.new()
var rng = RandomNumberGenerator.new()

var is_attacking = false
var freeze_input = true
var left_tutorial_area = false
var is_dead = false
var dialogue_finished = false

var direction = "down"

var health
var num = 0
var dialogue

signal died

func _ready():
	Engine.time_scale = engine_speed
	self.add_to_group("player", true)
	area2d.add_to_group("player", true)
	
	if sleepy_start:
		scroll.visible = true
		hb.visible = false
		walk.visible = false
		attack.visible = false
		wake.visible = false
		sleep.visible = true
		_animated_sprite.play("sleep")
		dialogue = DialogueBoxStartScene.instantiate()
		dialogue.messages = [
			"If you're reading this, you're finally awake...",  
			"I'm protecting you from the others noticing your presence... But once you leave this area they'll start coming for you at night...",
			"You can generate defenses using Gold... I've left some behind for you. Good luck."]
		dialogue.connect("label_finished", _on_label_finished)

	else:
		scroll.visible = false
		hb.visible = true
		wake.visible = false
		attack.visible= false
		sleep.visible = false
		walk.visible = true
		freeze_input = false
	
	health = max_health
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
			await $PlayerAnimations.animation_finished
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
		await $PlayerAnimations.animation_finished
		is_attacking = false
		
	else:
		if not is_attacking and current_anim != "walk_" + direction:
			_animated_sprite.play("walk_" + direction)
			attack.visible = false
			walk.visible = true

func _input(_event):
	if not freeze_input:
		if Input.is_action_just_pressed("open_build"):
			if UI.visible:
				UI.visible = false
				playerUI.visible = false
			else:
				UI.visible = true
				playerUI.visible = true
		if Input.is_action_just_pressed("ff"):
			if engine_speed == 1:
				engine_speed = 2
			else:
				engine_speed = 1
			Engine.time_scale = engine_speed
			
		if Input.is_action_just_pressed("zoom_in"):
			if camera.zoom >= Vector2(2, 2) and camera.zoom	< Vector2(4, 4):
				camera.zoom = camera.zoom + Vector2(0.5, 0.5)
				
		if Input.is_action_just_pressed("zoom_out"):
			if camera.zoom <= Vector2(4, 4) and camera.zoom > Vector2(2, 2):
				camera.zoom = camera.zoom - Vector2(0.5, 0.5)

func _physics_process(_delta):
	if not freeze_input:
		if not is_attacking:
			get_input()
			move_and_collide(velocity * _delta)

		if Input.is_action_just_pressed("attack"):
			is_attacking = true
			
		if health <= 0:
			is_dead = true
			freeze_input = true
			
		update_animation()
		
	elif is_dead:
		emit_signal("died")
		update_animation()
		get_tree().change_scene_to_file("res://scenes/death_scene.tscn")

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
	else:
		full.visible = false
		ouch.visible = false
		half.visible = false
		low.visible = false
		knockout.visible = true
		health = 0
		hb._set_health(0)

func _on_regen_timeout():
	if health < max_health and health > 0:
		_set_health(-regen)

func wake_up():
	wake.visible = true
	sleep.visible = false
	_animated_sprite.play("wake")
	await $PlayerAnimations.animation_finished
	wake.visible = false
	walk.visible = true
	
	add_child(dialogue)

func _on_label_finished():
	freeze_input = false
	hb.visible = true
	scroll.visible = false
	InvenButton.disabled = false
	dialogue = DialogueBoxStartScene.instantiate()
	dialogue.messages = ["(Press ESC for controls.)"]
	dialogue.timed_message = true
	dialogue.read_time = 2.5
	add_child(dialogue)

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
	if area.is_in_group("healing"):
		if health < max_health and health > 0:
			var healing = area.get_parent().heal
			if healing != null:
				health_display.display(healing)
				_set_health(-healing)
				var healing_tower = get_base_name(area.get_parent().get_name())
				var heal_track = { healing_tower: global_data.tower_damage.get(healing_tower) + healing}
				global_data.tower_damage.merge(heal_track, true)

func _on_tutorial_end_area_entered(_area):
	if not left_tutorial_area:
		background_music_day()
		md.start()
		left_tutorial_area = true

func _on_midday_timeout():
	bg_music.stop()
	background_music_night()
	nc.start()

func _on_open_close_pressed():
	if UI.visible:
		UI.visible = false
		playerUI.visible = false
	else:
		UI.visible = true
		playerUI.visible = true

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
