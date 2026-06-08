extends Area2D
class_name Projectile

var direction := Vector2.LEFT
var speed := 360.0
var lifetime := 4.0


func setup(start_position: Vector2, shot_direction: Vector2) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
	collision_layer = 64
	collision_mask = 2
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _build_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 12
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(14, 0),
		Vector2(0, 10),
		Vector2(-14, 0),
		Vector2(0, -10)
	])
	poly.color = Color(0.6, 0.1, 1.0, 1.0)
	add_child(poly)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
		queue_free()

