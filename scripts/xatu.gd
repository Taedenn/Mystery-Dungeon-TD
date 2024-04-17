extends StaticBody2D

@export var health := 40
@export var max_health := 40
@export var recoil := 5
@export var aura := 10

@onready var _animated_sprite = $AnimationPlayer
@onready var idle = $idle
@onready var attack = $attack
@onready var attack_anim = $attack_anim
@onready var collisionArea = $CollisionArea
@onready var attackAura = $Attack_Aura
@onready var health_display = $HealthDisplay

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


func _on_collision_area_area_exited(area):
	if area.is_in_group("enemies"):
		taking_damage = false
