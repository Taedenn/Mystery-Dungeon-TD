extends StaticBody2D

@export var health := 40
@export var max_health := 40
@export var recoil := 5

@onready var collisionArea = $CollisionArea
@onready var health_display = $HealthDisplay
@onready var global_data = get_node("/root/global")

var taking_damage = false
var damage = 0
var time_since_last_tick = 1.0
var is_vulnerable = true

var vuln : Timer
var is_vuln = false
var damage_proc = 0

const DAMAGE_TICK_INTERVAL = 0.8

func _ready():
	self.add_to_group("structures")
	collisionArea.add_to_group("structures")

func set_health(d):
	if health - d > 0:
		health -= d
	else:
		queue_free()

func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		var enemy = area.get_parent()
		damage = enemy.damage
		
		taking_damage = true
		if is_vuln:
			damage_proc = area.get_parent().damage
			set_health(damage_proc)
			vuln.start()
			is_vuln = false
			
	if area.is_in_group("healing"):
		if health < max_health and health > 0:
			var healing = area.get_parent().structure_heal
			if healing != null and health + healing <= max_health:
				health_display.display(healing)
				health += healing
				
				var healing_tower = get_base_name(area.get_parent().get_name())
				var heal_track = { healing_tower: global_data.tower_damage.get(healing_tower) + healing}
				global_data.tower_damage.merge(heal_track, true)

func _on_collision_area_area_exited(area):
	if area.is_in_group("enemies"):
		taking_damage = false

func get_base_name(string: String) -> String:
	var base_name = string
	# Check if the name ends with a number
	var last_char = string[string.length() - 1]
	while last_char.is_valid_int():
		# Remove the last character
		base_name = base_name.left(base_name.length() - 1)
		# Check the next last character
		last_char = base_name[base_name.length() - 1]
	return base_name
	
func take_damage():
	if taking_damage and is_vuln:
		set_health(damage_proc)
		vuln.start()
		is_vuln = false

func onvulntimeout():
	is_vuln = true
	take_damage()
