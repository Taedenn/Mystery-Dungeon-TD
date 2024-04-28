extends "res://scripts/structure.gd"


@onready var idle = $twirl
@onready var _animated_sprite = $AnimationPlayer
@onready var heal_range = $HealPulse
@onready var heal_delay = $Attack_Cooldown

var heal_pulse = true

@export var aura := 0
@export var heal := 10
@export var structure_heal := 5

func _ready():
	idle.visible = true
	heal_range.add_to_group("healing")
	_animated_sprite.play("twirl")
	await _animated_sprite.animation_finished
	heal_pulse = false
	
	var upgrade = Timer.new()
	upgrade.wait_time = 30
	upgrade.connect("timeout", _upgrade)
	upgrade.autostart = true
	upgrade.one_shot = false
	add_child(upgrade)

func _on_attack_cooldown_timeout():
	_animated_sprite.play("twirl")
	await _animated_sprite.animation_finished
	heal_pulse = false
	
func _upgrade():
	self.health_display.levelup()
	self.max_health += 10
	self.health += 10
	if heal_delay.wait_time - 0.25 > 0:
		heal_delay.wait_time -= 0.25
