extends Area2D
class_name Collectible

var kind := "sweet"
var level_id := 1
var sprite: Node2D
var hover_time := 0.0


func setup(item_position: Vector2, item_kind: String, owner_level_id: int) -> void:
	position = item_position
	kind = item_kind
	level_id = owner_level_id
	collision_layer = 32
	collision_mask = 2
	add_to_group("collectibles")
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _build_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 24
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	if kind == "can":
		var can_sprite := AnimatedSprite2D.new()
		can_sprite.sprite_frames = _make_can_frames()
		can_sprite.scale = Vector2(0.2, 0.2)
		can_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite = can_sprite
		add_child(sprite)
		can_sprite.play("spin")
		return

	var static_sprite := Sprite2D.new()
	sprite = static_sprite
	match kind:
		"energy":
			static_sprite.texture = load("res://assets/kenney_food/Tiles/tile_0083.png")
			static_sprite.scale = Vector2(2.5, 2.5)
		"heart":
			static_sprite.texture = load("res://assets/space_bonus/hp.png")
			static_sprite.scale = Vector2(0.68, 0.68)
		_:
			static_sprite.texture = load(_sweet_texture_path())
			static_sprite.scale = Vector2(2.25, 2.25)
	add_child(sprite)


func _make_can_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("spin")
	for i in range(8):
		var path := "res://assets/energy_can_spin/frame_%02d.png" % i
		frames.add_frame("spin", load(path))
	frames.set_animation_speed("spin", 7.0)
	frames.set_animation_loop("spin", true)
	return frames


func _process(delta: float) -> void:
	hover_time += delta
	if sprite != null:
		sprite.position.y = sin(hover_time * 3.0) * 4.0


func _sweet_texture_path() -> String:
	var options := [
		"res://assets/kenney_food/Tiles/tile_0056.png",
		"res://assets/kenney_food/Tiles/tile_0058.png",
		"res://assets/kenney_food/Tiles/tile_0043.png"
	]
	var index := int(abs(position.x + position.y)) % options.size()
	return options[index]


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"energy":
			GameState.restore_energy(70)
		"heart":
			GameState.heal(1)
		"can":
			GameState.complete_level(level_id)
		_:
			GameState.add_score(1)
	queue_free()
