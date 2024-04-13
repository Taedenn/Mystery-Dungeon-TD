extends StaticBody2D

@export var health := 10
@export var recoil := 5
@export var aura := 10

@onready var _animated_sprite = $AnimationPlayer
@onready var idle = $idle
@onready var attack = $attack
@onready var attack_anim = $attack_anim
@onready var collisionArea = $CollisionArea
@onready var attackAura = $Attack_Aura
@onready var attackAuraShape = $Attack_Aura/CollisionShape2D

var taking_damage = false
var time_since_last_tick = 1.0

const DAMAGE_TICK_INTERVAL = 0.8

func _ready():
	attackAuraShape.disabled = true
	self.add_to_group("structures")
	collisionArea.add_to_group("structures")
	attackAura.add_to_group("hazards")
	idle.visible = true
	attack.visible = false
	attack_anim.visible = false

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

func _on_attack_delay_timeout():
	attackAuraShape.disabled = false
	idle.visible = false
	attack.visible = true
	attack_anim.visible = true
	_animated_sprite.play("attack")
	await _animated_sprite.animation_finished
	attack.visible = false
	attack_anim.visible = false
	idle.visible = true
	attackAuraShape.disabled = true


func _on_collision_area_area_entered(area):
	if area.is_in_group("enemies"):
		taking_damage = true


func _on_collision_area_area_exited(area):
	if area.is_in_group("enemies"):
		taking_damage = false
