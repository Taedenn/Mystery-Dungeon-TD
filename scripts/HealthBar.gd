extends ProgressBar


@onready var timer = $damageStutter
@onready var damage_bar = $damagebar

var health = 0 : set = _set_health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	
	if health < prev_health:
		timer.start()
	else: 
		damage_bar.value = health

func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health
	
func add_max_health(_health):
	max_value += _health
	damage_bar.max_value += _health

func _on_damage_stutter_timeout():
	damage_bar.value = health
