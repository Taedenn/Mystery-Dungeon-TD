extends Node2D

@onready var DialogueBoxStartScene = preload("res://scenes/dialogue_box.tscn")
@onready var pause = preload("res://scenes/pause_menu.tscn")

@onready var portrait = $CanvasLayer/PanelContainer
@onready var sleep = $CanvasLayer/playerAnim/sleep
@onready var _animated_sprite = $CanvasLayer/playerAnim/PlayerAnimations

var play_sprite = false
var secondDialogue = true
var bg_music := AudioStreamPlayer.new()

func _ready():
	sleep.visible = false
	portrait.visible = false
	var dialogue = DialogueBoxStartScene.instantiate()
	dialogue.messages = ["Welcome to the world of Pokemon!"] 
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _on_label_finished)
	add_child(dialogue)
	
	add_child(bg_music)
	bg_music.stream = load("res://music/003 - Welcome to the World of Pokémon!.mp3")
	bg_music.play()
	bg_music.autoplay = true
		
func _physics_process(_delta):
	if play_sprite:
		sleep.visible = true
		_animated_sprite.play("sleep")
	if Input.is_action_just_pressed("exit_game"):
		var pause_menu = pause.instantiate()
		add_child(pause_menu)
		
func _on_label_finished():
	if secondDialogue:
		play_sprite = true
		secondDialogue = false
		portrait.visible = true
		var dialogue = DialogueBoxStartScene.instantiate()
		dialogue.speaking = "???"
		dialogue.messages = [
		"What's this, a charming Sprigatito! Your look suits you quite well... However, the world is not quite so kind.",  
		"You must hurry along now, and wake up before they reach you!", 
		"Farewell, little one. I hope I won't see you again too soon..."]
		dialogue.connect("label_finished", _on_label_finished)
		add_child(dialogue)
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
