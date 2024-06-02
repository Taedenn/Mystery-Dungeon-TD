extends CharacterBody2D

@onready var sprite = $Sprite2D

@export var aura := 10
var pierce = 0
var targets
var target
var move_speed = 175
var pierce_cap : int = 1
var direction = Vector2.ZERO

const PROCESS_INTERVAL = 0.02

var time_since_last_process = 0

func _ready():
	
	time_since_last_process = randi_range(0, int(PROCESS_INTERVAL * 100)) / 100.0
	
	$CollisionArea.add_to_group("hazards")
	name = "Lampent"
	
	if targets == null:
		targets = []
	
	if targets.size() > 0:
		target = targets[0]
	else:
		queue_free()

func _physics_process(delta):
	time_since_last_process += delta
	if time_since_last_process >= PROCESS_INTERVAL:
		time_since_last_process = 0
		if target in targets and target != null:
			direction = move_towards_target()
			velocity = direction * move_speed
			move_and_slide()
			rotate_sprite(delta)
		else:
			update_target_list()
		
func move_towards_target():
	if self.global_position.distance_squared_to(target.global_position) < 250000:
		var dir = (target.global_position - self.global_position).normalized()
		return dir
	else:
		targets.erase(target)
		return Vector2.ZERO

func rotate_sprite(delta):
	var target_angle = direction.angle() - PI/2  # Adjust by 90 degrees to face bottom
	sprite.rotation = lerp_angle(sprite.rotation, target_angle, 20 * delta)  # Smooth rotation

func update_target_list():
	if targets.size() > 0:
		if target == targets[0]:
			targets.erase(target)
		if targets.size() > 0:
			target = targets[0]
		else:
			queue_free()
	else:
		queue_free()

func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		pierce += 1
		if pierce > pierce_cap:
			queue_free()
			return
			
		if area == target:
			targets.erase(target)
			update_target_list()
		elif area in targets:
			targets.erase(area)
		
		if targets.size() == 0:
			queue_free()
