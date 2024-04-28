extends StaticBody2D

@export var health := 40
@export var max_health := 40
@export var recoil := 5
@export var aura := 10

@onready var global_data = get_node("/root/global")
@onready var _animated_sprite = $AnimationPlayer
@onready var idle = $idle
@onready var attack = $attack
@onready var attack_anim = $attack_anim
@onready var collisionArea = $CollisionArea
@onready var attackAura = $Attack_Aura
@onready var health_display = $HealthDisplay
@onready var attack_delay = $attack_delay

var taking_damage = false
var first_attack = true
var time_since_last_tick = 1.0
var damage = 0

const DAMAGE_TICK_INTERVAL = 0.8

func _ready():
	self.add_to_group("structures")
	collisionArea.add_to_group("structures")
	attackAura.add_to_group("hazards")
	idle.visible = true
	attack.visible = false
	attack_anim.visible = false
	
	var upgrade = Timer.new()
	upgrade.wait_time = 30
	upgrade.connect("timeout", _upgrade)
	upgrade.autostart = true
	upgrade.one_shot = false
	add_child(upgrade)
	
	if first_attack:
		starting_attack()
		first_attack = false

func starting_attack():
	idle.visible = false
	attack.visible = true
	attack_anim.visible = true
	_animated_sprite.play("attack")
	await _animated_sprite.animation_finished
	attack.visible = false
	attack_anim.visible = false
	idle.visible = true

func set_health(d):
	if health - d > 0:
		health -= d
	else:
		queue_free()
		
func _physics_process(delta):
	if taking_damage:
		time_since_last_tick += delta
		if time_since_last_tick >= DAMAGE_TICK_INTERVAL:
			set_health(damage)
			time_since_last_tick = 0.0

func _on_attack_delay_timeout():
	idle.visible = false
	attack.visible = true
	attack_anim.visible = true
	_animated_sprite.play("attack")
	await _animated_sprite.animation_finished
	attack.visible = false
	attack_anim.visible = false
	idle.visible = true


func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		taking_damage = true
		var enemy = area.get_parent()
		damage = enemy.damage
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

func _upgrade():
	self.health_display.levelup()
	self.max_health += 15
	self.health += 15
