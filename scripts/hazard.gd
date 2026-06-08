extends Area2D
class_name Hazard

var hazard_size := Vector2.ZERO
var hazard_type := "spikes"


func setup(top_left: Vector2, size: Vector2, kind: String) -> void:
	position = top_left + size * 0.5
	hazard_size = size
	hazard_type = kind
	collision_layer = 8
	collision_mask = 2
	add_to_group("hazards")
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = hazard_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-hazard_size.x * 0.5, -hazard_size.y * 0.5),
		Vector2(hazard_size.x * 0.5, -hazard_size.y * 0.5),
		Vector2(hazard_size.x * 0.5, hazard_size.y * 0.5),
		Vector2(-hazard_size.x * 0.5, hazard_size.y * 0.5)
	])
	match hazard_type:
		"lava":
			poly.color = Color(1.0, 0.22, 0.02, 0.9)
		"ice_spikes":
			poly.color = Color(0.45, 0.95, 1.0, 0.85)
		_:
			poly.color = Color(0.9, 0.85, 0.95, 0.85)
	add_child(poly)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)

