extends Node2D

@onready var DialogueBoxStartScene = preload("res://scenes/dialogue_box.tscn")
@onready var pause = preload("res://scenes/pause_menu.tscn")
@onready var portrait = $CanvasLayer/PanelContainer
@onready var sleep = $CanvasLayer/sleep
@onready var _animated_sprite = $CanvasLayer/PlayerAnimations
@onready var global_data = get_node("/root/global")
@export var time = 0

var bg_music = AudioStreamPlayer.new()
var dialogue

func _ready():
	add_child(bg_music)
	bg_music.stream = load("res://music/067 - Down a Dark Path.mp3")
	bg_music.play()
	bg_music.autoplay = true
	

	sleep.visible = true
	_animated_sprite.play("sleep")
	portrait.visible = true
	
	dialogue = DialogueBoxStartScene.instantiate()
	dialogue.messages = ["Oh Dear...",
		"I knew this might happen...",
		"Keep trying, little one. I'm sure you'll make it to the end."] 
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _on_label_finished)
	add_child(dialogue)

func _input(_event):
	if Input.is_action_just_pressed("exit_game"):
		var pause_menu = pause.instantiate()
		add_child(pause_menu)

func abbreviateNumber(number: float) -> String:
	var abbreviatedNumber: String
	if number >= 1000000.0:
		abbreviatedNumber = str(number / 1000000.0).left(5) + "M"
	elif number >= 1000.0:
		abbreviatedNumber = str(number / 1000.0).left(5) + "K"
	else:
		abbreviatedNumber = str(number)
	return abbreviatedNumber

func _on_label_finished():
	dialogue = DialogueBoxStartScene.instantiate()
	var string = "Survived: " + global_data.time + "  Gold Earned: " + abbreviateNumber(global_data.gold) + "\n"
	var hpg = 0.0
	var dpg = 0.0
	for key in global_data.tower_dict.keys():
		var amount = global_data.tower_dict[key]
		var damage = global_data.tower_damage[key]
		var dps = 0.0
		
		if amount != 0:
			dps = damage / amount
			
		if key == "Blissey":
			hpg = dps / 4.0
		elif key == "Xatu":
			dpg = dps / 2.0
		elif key == "Lampent":
			dpg = dps / 3.0
		elif key == "Cascoon":
			dpg = dps
		
		if key == "Blissey":
			string += "%s:   placed: %s   healing: %s   h/gold: %s\n" % [key, amount, abbreviateNumber(damage), abbreviateNumber(hpg)]
		else:
			string += "%s:   placed: %s   damage: %s   d/gold: %s\n" % [key, amount, abbreviateNumber(damage), abbreviateNumber(dpg)]
	
	dialogue.messages = [string]
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _change_scene)
	add_child(dialogue)
	
func _change_scene():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
