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
		"I knew this might happen, and unfortunately I must say, there is no end in sight for you.",
		"Keep trying, little one. I'm sure you'll make it to the end."] 
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _on_label_finished)
	add_child(dialogue)

func _input(_event):
	if Input.is_action_just_pressed("exit_game"):
		var pause_menu = pause.instantiate()
		add_child(pause_menu)
	
func _on_label_finished():
	dialogue = DialogueBoxStartScene.instantiate()
	var string = "Survived: " + global_data.time + "  Gold Earned: " + str(global_data.gold) + "\n"
	var hpg = 0
	var dpg = 0
	for key in global_data.tower_dict.keys():
		if key == "Blissey":
			string += key + ":     amount: " + str(global_data.tower_dict[key]) + "   healing: " + str(global_data.tower_damage[key])
			if global_data.tower_dict[key] != 0:
				hpg = global_data.tower_damage[key] / (global_data.tower_dict[key]*4)
			string += "   hpg: " + str(hpg) + "\n"
		elif key == "Xatu":
			string += key + ":       amount: " + str(global_data.tower_dict[key]) + "   damage: " + str(global_data.tower_damage[key])
			if global_data.tower_dict[key] != 0:
				dpg = global_data.tower_damage[key] / (global_data.tower_dict[key]*2)
			string += "   dpg: " + str(dpg) + "\n"
		elif key == "Lampent":
			string += key + ":   amount: " + str(global_data.tower_dict[key]) + "   damage: " + str(global_data.tower_damage[key])
			if global_data.tower_dict[key] != 0:
				dpg = global_data.tower_damage[key] / (global_data.tower_dict[key]*3)
			string += "   dpg: " + str(dpg) + "\n"
		elif key == "Cascoon":
			string += key + ":   amount: " + str(global_data.tower_dict[key]) + "   damage: " + str(global_data.tower_damage[key])
			if global_data.tower_dict[key] != 0:
				dpg = global_data.tower_damage[key] / (global_data.tower_dict[key])
			string += "   dpg: " + str(dpg) + "\n"
		else:
			string += key + ":   amount: " + str(global_data.tower_dict[key]) + "   damage: " + str(global_data.tower_damage[key])
	dialogue.messages = [string]
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _change_scene)
	add_child(dialogue)
	
func _change_scene():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
