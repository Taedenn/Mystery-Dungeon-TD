extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$Label.text = str("FPS: ", Engine.get_frames_per_second())
