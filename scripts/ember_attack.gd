extends StaticBody2D

@export var aura := 5
var pierce = 0
var targets
var target
var move_speed = 100


func _ready():
	$CollisionArea.add_to_group("hazards")
	name = "Lampent"
	
	if targets == null:
		queue_free()
	
	if targets.size() > 0:
		target = targets[0]
	else:
		queue_free()

func _process(delta):
	if pierce > 3:
		queue_free()
	if target in targets:
		if target != null:
			move_towards_target(delta)
		else:
			if targets.size() > 0:
				if target == targets[0]:
					targets.erase(target)
				if targets.size() == 0:
					queue_free()
				else:
					target = targets[0]
			else:
				queue_free()
	elif targets.size() == 0:
		queue_free()
	else:
		target = targets[0]
		
func move_towards_target(delta):
	var direction = (target.global_position - global_position).normalized()
	var velocity = direction * move_speed * delta
	global_position += velocity

func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		pierce += 1
		if area == target:
			targets.erase(target)
			if targets.size() == 0:
				queue_free()
			else:
				target = targets[0]
		elif area in targets:
			targets.erase(area)
			if targets.size() == 0:
				queue_free()
		elif targets.size() == 0:
			queue_free()
