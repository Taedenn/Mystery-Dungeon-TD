extends StaticBody2D

@export var health := 40
@export var max_health := 40
@export var recoil := 5

@onready var collisionArea = $CollisionArea
@onready var health_display = $HealthDisplay

var taking_damage = false
var time_since_last_tick = 1.0

const DAMAGE_TICK_INTERVAL = 0.8

func _ready():
	self.add_to_group("structures")
	collisionArea.add_to_group("structures")

func set_health(d):
	if health - d > 0:
		health -= d
	else:
		queue_free()

func _physics_process(delta):
	if taking_damage:
		time_since_last_tick += delta
		if time_since_last_tick >= DAMAGE_TICK_INTERVAL:
			set_health(5)
			time_since_last_tick = 0.0

func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		taking_damage = true
	if area.is_in_group("healing"):
		if health < max_health and health > 0:
			var healing = area.get_parent().structure_heal
			if healing != null and health + healing <= max_health:
				health_display.display(healing)
				health += healing

func _on_collision_area_area_exited(area):
	if area.is_in_group("enemies"):
		taking_damage = false
