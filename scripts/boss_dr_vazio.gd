extends CharacterBody2D

signal defeated

const PROJECTILE_SCRIPT := preload("res://scripts/projectile.gd")

var health := 3
var left_limit := 0.0
var right_limit := 0.0
var direction := -1
var move_speed := 95.0
var shoot_timer := 1.2
var target_player: Node2D
var shoot_activation_distance := 680.0
var invulnerable_timer := 0.0
var defeated_state := false
var animation_lock_timer := 0.0
var visual: AnimatedSprite2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("boss")
	_build_collision()
	_build_visuals()
	_build_hit_area()


func setup(left: float, right: float, player_ref: Node, activation_distance := 680.0) -> void:
	left_limit = left
	right_limit = right
	target_player = player_ref
	shoot_activation_distance = activation_distance


func _physics_process(delta: float) -> void:
	if defeated_state:
		return
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		visual.modulate = Color(1, 1, 1, 0.45 if int(invulnerable_timer * 12.0) % 2 == 0 else 1.0)
	else:
		visual.modulate = Color.WHITE
	if animation_lock_timer > 0:
		animation_lock_timer -= delta

	velocity.y += 1400.0 * delta
	velocity.x = direction * move_speed
	move_and_slide()
	if global_position.x < left_limit:
		direction = 1
	elif global_position.x > right_limit:
		direction = -1
	if is_on_wall():
		direction *= -1
	visual.flip_h = direction < 0
	if animation_lock_timer <= 0 and (visual.animation != "walk" or not visual.is_playing()):
		visual.play("walk")

	if _target_in_attack_range():
		shoot_timer -= delta
		if shoot_timer <= 0 and invulnerable_timer <= 0:
			shoot_timer = 1.45
			_shoot()
	else:
		shoot_timer = min(shoot_timer, 0.65)


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(88, 110)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -55)
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	visual = AnimatedSprite2D.new()
	visual.sprite_frames = _make_sprite_frames()
	visual.scale = Vector2(0.72, 0.72)
	visual.position = Vector2(0, -58)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(visual)
	visual.play("walk")


func _build_hit_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(104, 118)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -59)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var body_velocity = body.get("velocity")
	if body.has_method("bounce") and body_velocity is Vector2 and body_velocity.y > 0 and body.global_position.y < global_position.y - 38:
		_take_stomp(body)
	elif body.has_method("take_damage"):
		body.take_damage(1, global_position)


func _take_stomp(player: Node) -> void:
	if invulnerable_timer > 0 or defeated_state:
		return
	player.bounce()
	health -= 1
	invulnerable_timer = 0.75
	if health <= 0:
		_die()
	else:
		animation_lock_timer = 0.4
		visual.play("hurt")


func _shoot() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	animation_lock_timer = 0.45
	var dir: Vector2 = (target_player.global_position + Vector2(0, -28) - (global_position + Vector2(0, -52))).normalized()
	if absf(dir.x) > 0.05:
		direction = -1 if dir.x < 0 else 1
	visual.flip_h = direction < 0
	visual.play("attack")
	var shot := PROJECTILE_SCRIPT.new()
	var shot_side := -1.0 if dir.x < 0 else 1.0
	get_parent().add_child(shot)
	shot.setup(global_position + Vector2(shot_side * 42.0, -52), dir)


func _target_in_attack_range() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	return absf(target_player.global_position.x - global_position.x) <= shoot_activation_distance


func _die() -> void:
	if defeated_state:
		return
	defeated_state = true
	collision_layer = 0
	collision_mask = 0
	visual.modulate = Color.WHITE
	visual.play("death")
	await get_tree().create_timer(0.75).timeout
	defeated.emit()
	queue_free()


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	_add_animation(frames, "idle", 4, 4.0, true)
	_add_animation(frames, "walk", 4, 7.0, true)
	_add_animation(frames, "attack", 4, 9.0, false)
	_add_animation(frames, "hurt", 2, 8.0, false)
	_add_animation(frames, "death", 4, 7.0, false)
	return frames


func _add_animation(frames: SpriteFrames, name: String, count: int, speed: float, loop := true) -> void:
	frames.add_animation(name)
	for i in range(count):
		var path := "res://assets/boss_dr_vazio/%s_%02d.png" % [name, i]
		frames.add_frame(name, load(path))
	frames.set_animation_speed(name, speed)
	frames.set_animation_loop(name, loop)
