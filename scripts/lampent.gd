extends "res://scripts/structure.gd"

@export var aura := 0

@onready var idle = $idle
@onready var attack_anim = $attack
@onready var _animated_sprite = $AnimationPlayer
@onready var attack_timer = $attack_delay
@onready var projectiles = $projectiles
@onready var ember = preload("res://scenes/ember_attack.tscn")

var attack_proc = false
var lock_on = false
var targets = []
var movespeed = 175
var aurascale = 0
var piercescale = 0
var pierce = 2

func _ready():
	super._ready()
	name = "Lampent"
	idle.visible = true
	attack_anim.visible = false
	
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

func attack():
	if not attack_proc or not lock_on or targets.size() == 0:
		return
	else:
		idle.visible = false
		attack_anim.visible = true
		_animated_sprite.play("attack")
		await _animated_sprite.animation_finished
		attack_anim.visible = false
		idle.visible = true


		var projectile = ember.instantiate()
		if targets.size() > 0:
			projectile.targets = targets.duplicate()
			projectile.name = "Lampent"
			projectile.move_speed = movespeed
			projectile.aura += aurascale
			projectile.pierce_cap += piercescale
			if projectiles.get_children().size() < 5:
				projectiles.add_child(projectile)
		
		attack_proc = false

func _on_attack_delay_timeout():
	attack_proc = true
	
	if targets.size() == 0:
		lock_on = false
	
	attack()

func _on_attack_aura_area_entered(area):
	if area.is_in_group("enemies"):
		lock_on = true
		attack()
		if area not in targets:
			targets.append(area)
		
func _on_attack_aura_area_exited(area):
	if area.is_in_group("enemies"):
		if area in targets:
			targets.erase(area)
		
		for t in targets:
			if self.global_position.distance_squared_to(t.global_position) > 250000:
				targets.erase(t)

func _upgrade():
	self.health_display.levelup()
	self.max_health += 10
	self.health += 10
	movespeed += 5
	aurascale += 1
	piercescale += 0.5
	pierce += piercescale
