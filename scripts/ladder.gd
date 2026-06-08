extends Area2D
class_name Ladder

const TILE_SIZE := 48.0
const LADDER_TOP := "res://assets/kenney_platformer/Tiles/tile_0051.png"
const LADDER_BODY := "res://assets/kenney_platformer/Tiles/tile_0071.png"


func setup(top_left: Vector2, tile_count: int) -> void:
	position = top_left
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_build_collision(tile_count)
	_build_visuals(tile_count)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _build_collision(tile_count: int) -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE * tile_count)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE * tile_count * 0.5)
	collision.shape = shape
	add_child(collision)


func _build_visuals(tile_count: int) -> void:
	for i in range(tile_count):
		var sprite := Sprite2D.new()
		sprite.texture = load(LADDER_TOP if i == 0 else LADDER_BODY)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.scale = Vector2(2.7, 2.7)
		sprite.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5 + i * TILE_SIZE)
		add_child(sprite)


func _on_body_entered(body: Node) -> void:
	if body.has_method("enter_ladder"):
		body.enter_ladder()


func _on_body_exited(body: Node) -> void:
	if body.has_method("exit_ladder"):
		body.exit_ladder()
