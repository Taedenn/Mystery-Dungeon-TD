extends "res://scripts/structure.gd"


@onready var idle = $twirl
@onready var _animated_sprite = $AnimationPlayer
@onready var heal_range = $HealPulse

var heal_pulse = true

@export var aura := 0
@export var heal := 10
@export var structure_heal := 5

func _ready():
	idle.visible = true
	heal_range.add_to_group("healing")

func _process(_delta):
	if heal_pulse:
		_animated_sprite.play("twirl")
		await _animated_sprite.animation_finished
		heal_pulse = false

func _on_attack_cooldown_timeout():
	if not heal_pulse:
		heal_pulse = true
