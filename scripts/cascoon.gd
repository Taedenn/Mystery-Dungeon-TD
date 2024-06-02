extends "res://scripts/structure.gd"

@onready var idle = $idle
@onready var attack_anim = $recoil
@onready var _animated_sprite = $AnimationPlayer
var is_touching = false

func _ready():
	super._ready()
	idle.visible = true
	attack_anim.visible = false
	$CollisionArea.add_to_group("structures")
	
	var upgrade = Timer.new()
	upgrade.wait_time = 30
	upgrade.connect("timeout", _upgrade)
	upgrade.autostart = true
	upgrade.one_shot = false
	add_child(upgrade)
	
	vuln = Timer.new()
	vuln.wait_time = 0.8
	vuln.connect("timeout", onvulntimeout)
	vuln.autostart = true
	vuln.one_shot = true
	add_child(vuln)
	vuln.start()

func _recoil():
	while is_touching:
		idle.visible = false
		attack_anim.visible = true
		_animated_sprite.play("recoil")
		await _animated_sprite.animation_finished
		attack_anim.visible = false
		idle.visible = true

func _on_collision_area_area_entered_override(area):
	if area.is_in_group("enemies"):
		is_touching = true
		_recoil()


func _on_collision_area_area_exited_override(area):
	if area.is_in_group("enemies"):
		is_touching = false

func _upgrade():
	self.health_display.levelup()
	self.max_health += 15
	self.health += 15
	recoil += 2
