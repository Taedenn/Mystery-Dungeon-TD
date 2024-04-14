extends Label

@onready var display_timer = $DisplayTimer
var damage_amount

func display(damage : float):
	damage_amount = int(damage)
	text = str(damage_amount)
	display_timer.start()

func _on_display_timer_timeout():
	text = ""
