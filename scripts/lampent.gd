extends "res://scripts/structure.gd"

@export var aura := 10

@onready var idle = $idle
@onready var attack_anim = $attack
@onready var _animated_sprite = $AnimationPlayer
@onready var ember = preload("res://scenes/ember_attack.tscn")

var attack_proc = false
var lock_on = false
var targets = []

func _ready():
	name = "Lampent"
	idle.visible = true
	attack_anim.visible = false

func attack():
	if attack_proc and lock_on and targets.size() > 0:
		idle.visible = false
		attack_anim.visible = true
		_animated_sprite.play("attack")
		await _animated_sprite.animation_finished
		attack_anim.visible = false
		idle.visible = true
		
		var projectile = ember.instantiate()
		if targets.size() > 0:
			if targets[0] != null:
				projectile.target = targets[0]
				projectile.name = "Lampent"
				add_child(projectile)
		
		attack_proc = false

func _on_attack_delay_timeout():
	attack_proc = true
	attack()

func _on_attack_aura_area_entered(area):
	if area.is_in_group("enemies"):
		if area not in targets:
			targets.append(area)
		lock_on = true
		attack()

func _on_attack_aura_area_exited(area):
	if area.is_in_group("enemies"):
		if area in targets:
			targets.erase(area)
		if targets.size() == 0:
			lock_on = false
		else:
			attack()
