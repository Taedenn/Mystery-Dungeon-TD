class_name EmberSpawner
extends Node2D

@onready var origin := get_node("Origin") as Marker2D
@onready var shared_area := get_node("SharedArea") as Area2D
@onready var img := preload("res://attacks/lampent_ember.png")
var bullets : Array = []
var bounding_box : Rect2

# ================================ Lifecycle ================================ #


func _physics_process(delta: float) -> void:
	var used_transform = Transform2D()
	var bullets_queued_for_destruction = []
	
	for i in range(0, bullets.size()):
		
		var bullet = bullets[i] as Bullet
		bullets_queued_for_destruction.append(bullet)

		var offset : Vector2 = (
			bullet.movement_vector.normalized() * bullet.speed * delta
		)
		# Move the bullet and the collision
		bullet.current_position += offset
		used_transform.origin = bullet.current_position
	
		
func _draw():
	for i in range(0, bullets.size()):
		var bullet = bullets[i]
		
		var texture = ImageTexture.create_from_image(img)
		draw_texture(texture, bullet.current_position)
		_draw()
# ================================= Public ================================== #

# Register a new bullet in the array with the optimization logic
func spawn_bullet(i_movement: Vector2, speed := 100) -> void:
	
	var bullet : Bullet = Bullet.new()
	bullet.movement_vector = i_movement
	bullet.speed = speed
	bullet.current_position  = origin.position
	
	_configure_collision_for_bullet(bullet)
	
	bullets.append(bullet)
	
# Adds the collision data to the bullet
func _configure_collision_for_bullet(bullet: Bullet) -> void:
	
	# Define the shape's position
	var used_transform := Transform2D(0, position)
	used_transform.origin = bullet.current_position

	# Create the shape
	var _circle_shape = PhysicsServer2D.circle_shape_create()
	PhysicsServer2D.shape_set_data(_circle_shape, 4)
	
	# Add the shape to the shared area
	PhysicsServer2D.area_add_shape(
		shared_area.get_rid(), _circle_shape, used_transform
	)
	
	# Register the generated id to the bullet
	bullet.shape_id = _circle_shape
