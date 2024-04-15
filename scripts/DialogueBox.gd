extends Node2D

@export var messages = [
	""
]

@export var speaking := "Mysterious Scroll:"

var typing_speed = 0.025
var read_time = 0.3
var timed_message = false
var display_next = false
var finished = false
signal label_finished


var current_message = 0
var display = ""
var current_char = 0


func _ready():
	$TextboxCanvas/Textbox/GridContainer/Name.text = speaking
	start_dialogue()
	
func _input(InputEvent):
	if Input.is_action_just_pressed("build") and display_next:
			start_next_dialogue()

func start_dialogue():
	$nextchar.set_wait_time(typing_speed)
	$nextchar.start()
	
func stop_dialogue():
	emit_signal("label_finished")
	queue_free()
	
func start_next_dialogue():
	if (current_message == len(messages) - 1):
		stop_dialogue()
	else: 
		current_message += 1
		display = ""
		current_char = 0
		$nextchar.start()
	
func _on_nextchar_timeout():
	if (current_char < len(messages[current_message])):
		var next_char = messages[current_message][current_char]
		display += next_char
		
		$TextboxCanvas/Textbox/GridContainer/Label.text = display
		current_char += 1
	elif (current_char == len(messages[current_message])) and timed_message:
		$nextchar.stop()
		$nextmessage.set_wait_time(read_time)
		$nextmessage.start()
	else:
		$nextchar.stop()
		display_next = true

func _on_nextmessage_timeout():
	if (current_message == len(messages) - 1):
		stop_dialogue()
	else: 
		current_message += 1
		display = ""
		current_char = 0
		$nextchar.start()
