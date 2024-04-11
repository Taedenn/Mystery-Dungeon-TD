extends CanvasModulate

const NIGHT_COLOR = Color("#6a6ac0")
const DAY_COLOR = Color("#ffffea")

@export var TIME_SCALE = 0.0005

var time = 0
var nightfall = false
var sunrise = true

@onready var nf = $Nightfall
@onready var sr = $Sunrise

func _process(delta:float) -> void:
	self.time += delta * TIME_SCALE
	if nightfall:
		self.color = self.color.lerp(NIGHT_COLOR, self.time)
	if sunrise:
		self.color = self.color.lerp(DAY_COLOR, self.time)
		
	if self.time > 0.005:
		self.time = 0.0

func _on_day_cycle_timeout():
	sr.start()
	sunrise = true
	nightfall = false


func _on_night_cycle_timeout():
	nf.start()
	sunrise = false
	nightfall = true


func _on_tutorial_end_area_entered(area):
	sr.start()
	sunrise = true
	nightfall = false
