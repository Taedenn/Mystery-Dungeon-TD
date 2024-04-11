extends Node2D
@onready var enemy = null
@export var damage := 5
@onready var ap = $AnimationPlayer
@onready var area2d = $ProjectileArea
# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("hazards")
	area2d.add_to_group("hazards")

func shoot(pos):
	position = pos
	ap.play("attack")
	await ap.animation_finished
	queue_free()

func _process(_delta):
	pass


func _on_projectile_area_area_entered(area):
	if area.is_in_group("enemies"):
		queue_free()
