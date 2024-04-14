extends StaticBody2D

@export var aura := 5

var target
@export var move_speed = 100

func _ready():
	$CollisionArea.add_to_group("hazards")

func _process(delta):
	if target != null:
		move_towards_target(delta)
	else:
		queue_free()
		
func move_towards_target(delta):
	if target != null:
		var direction = (target.global_position - global_position).normalized()
		var velocity = direction * move_speed * delta
		global_position += velocity
	else:
		queue_free()

func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		if target != null and area == target:
			queue_free()
