extends "res://scripts/structure.gd"

@onready var idle = $idle
@onready var attack_anim = $recoil
@onready var _animated_sprite = $AnimationPlayer
var is_touching = false

func _ready():
	idle.visible = true
	attack_anim.visible = false
	$CollisionArea.add_to_group("structures")

func _process(_delta):
	if is_touching:
		idle.visible = false
		attack_anim.visible = true
		_animated_sprite.play("recoil")
		await _animated_sprite.animation_finished
		attack_anim.visible = false
		idle.visible = true

func _on_collision_area_area_entered_override(area):
	if area.is_in_group("enemies"):
		is_touching = true


func _on_collision_area_area_exited_override(area):
	if area.is_in_group("enemies"):
		is_touching = false
