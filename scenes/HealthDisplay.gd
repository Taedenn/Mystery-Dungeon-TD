extends Label

@onready var display_timer = $DisplayTimer
var amount

func display(damage : float):
	amount = int(damage)
	text = str(amount)
	display_timer.start()

func _on_display_timer_timeout():
	text = ""
