extends Label

@onready var player = $"../../../../../../World/Player"
@onready var global_data = get_node("/root/global")

var time_elapsed := 0.0
var counter = 1
var is_stopped := true

func _ready():
	player.connect("died", _player_death)

func _process(delta: float) -> void:
	if !is_stopped:
		time_elapsed += delta
		update_label()

func update_label() -> void:
	var total_centiseconds = int(time_elapsed * 100)
	var centiseconds = total_centiseconds % 100
	var total_seconds = total_centiseconds / 100
	var seconds = total_seconds % 60
	var total_minutes = total_seconds / 60
	var minutes = total_minutes % 60
	
	var formatted_time = "%d:%02d:%02d" % [minutes, seconds, centiseconds]
	text = formatted_time

func reset() -> void:
	time_elapsed = 0.0
	is_stopped = false

func stop() -> void:
	is_stopped = true

func start() -> void: 
	is_stopped = false

func _player_death():
	stop()
	if text != null:
		global_data.time = str(text)
