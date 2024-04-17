extends CanvasLayer


func _enter_tree():
	get_tree().paused = true

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().quit()


func _on_continue_button_pressed():
	get_tree().paused = false
	queue_free()
