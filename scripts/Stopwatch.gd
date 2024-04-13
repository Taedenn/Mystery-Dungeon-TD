extends Label

var time_elapsed := 0.0
var counter = 1
var is_stopped := true

func _process(delta: float) -> void:
	if !is_stopped:
		time_elapsed += delta
		$".".text = str(time_elapsed).pad_decimals(2)

func reset() -> void:
	time_elapsed = 0.0
	is_stopped = false

func stop() -> void:
	is_stopped = true

func start() -> void: 
	is_stopped = false
