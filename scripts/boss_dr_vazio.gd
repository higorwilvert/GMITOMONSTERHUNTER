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
var invulnerable_timer := 0.0
var visual: Sprite2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("boss")
	_build_collision()
	_build_visuals()
	_build_hit_area()


func setup(left: float, right: float, player_ref: Node) -> void:
	left_limit = left
	right_limit = right
	target_player = player_ref


func _physics_process(delta: float) -> void:
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		visual.modulate = Color(1, 1, 1, 0.45 if int(invulnerable_timer * 12.0) % 2 == 0 else 1.0)
	else:
		visual.modulate = Color.WHITE

	velocity.y += 1400.0 * delta
	velocity.x = direction * move_speed
	move_and_slide()
	if global_position.x < left_limit:
		direction = 1
	elif global_position.x > right_limit:
		direction = -1
	if is_on_wall():
		direction *= -1
	visual.flip_h = direction > 0

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot_timer = 1.45
		_shoot()


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(78, 84)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -42)
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	visual = Sprite2D.new()
	visual.texture = load("res://assets/space_bonus/random_shooter-sheet.png")
	visual.region_enabled = true
	visual.region_rect = Rect2(0, 0, 218, 218)
	visual.scale = Vector2(0.48, 0.48)
	visual.position = Vector2(0, -58)
	add_child(visual)


func _build_hit_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(94, 96)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -48)
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
	if invulnerable_timer > 0:
		return
	player.bounce()
	health -= 1
	invulnerable_timer = 0.75
	if health <= 0:
		defeated.emit()
		queue_free()


func _shoot() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var shot := PROJECTILE_SCRIPT.new()
	var dir: Vector2 = (target_player.global_position + Vector2(0, -28) - (global_position + Vector2(0, -52))).normalized()
	get_parent().add_child(shot)
	shot.setup(global_position + Vector2(direction * 42, -52), dir)
