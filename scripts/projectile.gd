extends Area2D
class_name Projectile

const PROJECTILE_TEXTURE := "res://assets/boss_projectile_green.png"

var direction := Vector2.LEFT
var speed := 430.0
var lifetime := 4.0
var visual: Sprite2D


func setup(start_position: Vector2, shot_direction: Vector2) -> void:
	global_position = start_position
	direction = shot_direction.normalized()
	rotation = direction.angle()
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
	shape.radius = 14
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-18, -13),
		Vector2(32, -13),
		Vector2(44, 0),
		Vector2(32, 13),
		Vector2(-18, 13)
	])
	glow.color = Color(0.45, 1.0, 0.12, 0.22)
	add_child(glow)

	visual = Sprite2D.new()
	visual.texture = load(PROJECTILE_TEXTURE)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2(0.42, 0.42)
	add_child(visual)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
		queue_free()
