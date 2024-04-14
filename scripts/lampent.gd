extends "res://scripts/structure.gd"

@export var aura := 10

@onready var idle = $idle
@onready var attack_anim = $attack
@onready var _animated_sprite = $AnimationPlayer
@onready var ember = preload("res://scenes/ember_attack.tscn")

var attack_proc = false
var lock_on = false
var target

func _ready():
	idle.visible = true
	attack_anim.visible = false

func attack():
	if attack_proc and lock_on and target != null:
		idle.visible = false
		attack_anim.visible = true
		_animated_sprite.play("attack")
		await _animated_sprite.animation_finished
		attack_anim.visible = false
		idle.visible = true
		
		# instantiate()
		var projectile = ember.instantiate()
		
		projectile.global_position = Vector2(0 , 0)
		if target != null:
			projectile.target = target
			add_child(projectile)
		
		attack_proc = false

func _on_attack_delay_timeout():
	attack_proc = true
	attack()

func _on_attack_aura_area_entered(area):
	if area.is_in_group("enemies"):
		target = area
		if target != null:
			lock_on = true
			attack()
		else:
			lock_on = false

func _on_attack_aura_area_exited(area):
	if area.is_in_group("enemies"):
		target = null
		lock_on = false
