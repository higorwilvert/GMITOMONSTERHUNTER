extends Area2D
class_name Checkpoint

var active := false
var sprite: Sprite2D


func setup(spawn_position: Vector2) -> void:
	position = spawn_position
	collision_layer = 16
	collision_mask = 2
	add_to_group("checkpoints")
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 96)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -48)
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/pixel_adventure/Items/Checkpoints/Checkpoint/Checkpoint (No Flag).png")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)
	sprite.position = Vector2(0, -44)
	sprite.scale = Vector2(1.25, 1.25)
	add_child(sprite)


func _on_body_entered(body: Node) -> void:
	if active or not body.is_in_group("player"):
		return
	active = true
	sprite.texture = load("res://assets/pixel_adventure/Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)(64x64).png")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 64, 64)
	GameState.set_checkpoint(global_position)
