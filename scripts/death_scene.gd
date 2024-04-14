extends Node2D

@onready var DialogueBoxStartScene = preload("res://scenes/dialogue_box.tscn")
@onready var portrait = $CanvasLayer/PanelContainer
@onready var sleep = $CanvasLayer/sleep
@onready var _animated_sprite = $CanvasLayer/PlayerAnimations

func _ready():
	sleep.visible = true
	portrait.visible = false
	var dialogue = DialogueBoxStartScene.instantiate()
	dialogue.messages = ["Oh Dear...",
		"I knew this might happen, and unfortunately I must say, there is no end in sight for you.",
		"Keep trying, little one. All you can do is hope to do better."] 
	dialogue.speaking = "???"
	dialogue.connect("label_finished", _on_label_finished)
	add_child(dialogue)
		
func _physics_process(delta):
	sleep.visible = true
	_animated_sprite.play("sleep")
		
func _on_label_finished():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
