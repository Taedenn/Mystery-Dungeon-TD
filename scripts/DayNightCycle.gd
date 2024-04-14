extends CanvasModulate

const NIGHT_COLOR = Color("#6a6ac0")
const DAY_COLOR = Color("#ffffea")

@export var TIME_SCALE = 0.0005

var time = 0

var nightfall = false
var sunrise = true
var tutorial_end = false

var fadeIn = true
var fadeTimer: Timer

@onready var nf = $Nightfall
@onready var sr = $Sunrise
@onready var md = $Midday

func _ready():
	fadeTimer = Timer.new()
	fadeTimer.one_shot = true
	fadeTimer.wait_time = 0.5
	add_child(fadeTimer)
	
	fadeTimer.connect("timeout", _on_fade_timer_timeout)
	fadeTimer.start()

func _on_fade_timer_timeout():
	fadeIn = false

func _process(delta:float) -> void:
	if fadeIn:
		self.color = self.color.lerp(Color.BLACK, fadeTimer.time_left / fadeTimer.wait_time)
		return
		
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


func _on_tutorial_end_area_entered(_area):
	if not tutorial_end:
		md.start()
		sunrise = true
		nightfall = false
		tutorial_end = true


func _on_midday_timeout():
	nf.start()
	sunrise = false
	nightfall = true
