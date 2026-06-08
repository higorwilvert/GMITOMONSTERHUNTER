extends CharacterBody2D
class_name Enemy

signal defeated

const GRAVITY := 1200.0
const BAT_SHEET := "res://assets/kenney_platformer/tilemap-characters_packed.png"

var patrol_left := 0.0
var patrol_right := 0.0
var move_speed := 80.0
var direction := -1
var flying := false
var enemy_variant := "green"
var origin_y := 0.0
var time := 0.0
var hit_area: Area2D
var animated_sprite: AnimatedSprite2D


func setup(start_position: Vector2, left_limit: float, right_limit: float, is_flying := false, speed := 80.0, variant := "green") -> void:
	global_position = start_position
	patrol_left = left_limit
	patrol_right = right_limit
	flying = is_flying
	enemy_variant = variant
	move_speed = speed
	origin_y = start_position.y
	collision_layer = 4
	collision_mask = 1 if not flying else 0
	add_to_group("enemies")
	_build_collision()
	_build_visuals()
	_build_hit_area()


func _physics_process(delta: float) -> void:
	time += delta
	if flying:
		global_position.x += direction * move_speed * delta
		global_position.y = origin_y + sin(time * 2.2) * 28.0
	else:
		velocity.y += GRAVITY * delta
		velocity.x = direction * move_speed
		move_and_slide()
	if global_position.x < patrol_left:
		direction = 1
	elif global_position.x > patrol_right:
		direction = -1
	if is_on_wall():
		direction *= -1
	_update_visual_flip()


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42, 34) if flying else Vector2(66, 42)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -17) if flying else Vector2(0, -21)
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	if flying:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.sprite_frames = _make_bat_frames()
		animated_sprite.position = Vector2(0, -24)
		animated_sprite.scale = Vector2(2.7, 2.7)
		animated_sprite.name = "Visual"
		add_child(animated_sprite)
		animated_sprite.play("fly")
		return

	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = _make_slime_frames()
	animated_sprite.position = Vector2(0, -32)
	animated_sprite.scale = Vector2(3.0, 3.0)
	animated_sprite.name = "Visual"
	add_child(animated_sprite)
	animated_sprite.play("move")


func _make_slime_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("move")
	var texture_path := "res://assets/brackeys_sprites/slime_green.png"
	if enemy_variant == "purple":
		texture_path = "res://assets/brackeys_sprites/slime_purple.png"
	var texture := load(texture_path)
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * 24, 0, 24, 24)
		frames.add_frame("move", atlas)
	frames.set_animation_speed("move", 8.0)
	return frames


func _make_bat_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("fly")
	var texture := load(BAT_SHEET)
	for column in [9, 10, 11]:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(column * 18, 54, 18, 18)
		frames.add_frame("fly", atlas)
	frames.set_animation_speed("fly", 8.0)
	return frames


func _build_hit_area() -> void:
	hit_area = Area2D.new()
	hit_area.collision_layer = 4
	hit_area.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(54, 48) if flying else Vector2(78, 58)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -24) if flying else Vector2(0, -29)
	collision.shape = shape
	hit_area.add_child(collision)
	add_child(hit_area)
	hit_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var body_velocity = body.get("velocity")
	var stomp_height := 16.0 if flying else 24.0
	if body.has_method("bounce") and body_velocity is Vector2 and body_velocity.y > 0 and body.global_position.y < global_position.y - stomp_height:
		body.bounce()
		defeated.emit()
		queue_free()
	elif body.has_method("take_damage"):
		body.take_damage(1, global_position)


func _update_visual_flip() -> void:
	var sprite := get_node_or_null("Visual")
	if sprite != null:
		sprite.flip_h = direction > 0
