extends StaticBody2D

signal defeated

const PROJECTILE_SCRIPT := preload("res://scripts/projectile.gd")

var health := 3
var shoot_timer := 2.0
var shoot_interval := 2.0
var target_player: Node2D
var activation_distance := 500.0
var invulnerable_timer := 0.0
var defeated_state := false
var visual: Node2D
var hp_label: Label
var hurt_sound: AudioStreamPlayer2D
var death_sound: AudioStreamPlayer2D

func setup(pos: Vector2, player_ref: Node, interval := 2.0, distance := 500.0) -> void:
	global_position = pos
	target_player = player_ref
	shoot_interval = interval
	shoot_timer = interval
	activation_distance = distance
	collision_layer = 4
	collision_mask = 0
	add_to_group("enemies")
	_build_collision()
	_build_visuals()
	_build_hit_area()
	_build_audio()


func _process(delta: float) -> void:
	if defeated_state:
		return
	if target_player == null or not is_instance_valid(target_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
		return

	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		visual.modulate = Color(1, 1, 1, 0.4 if int(invulnerable_timer * 12.0) % 2 == 0 else 1.0)
	else:
		visual.modulate = Color.WHITE

	if _player_in_range():
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_timer = shoot_interval
			_shoot()


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(52, 52)
	var col := CollisionShape2D.new()
	col.position = Vector2(0, -26)
	col.shape = shape
	add_child(col)


func _build_visuals() -> void:
	visual = Node2D.new()
	add_child(visual)

	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-26, 0), Vector2(26, 0),
		Vector2(20, -18), Vector2(-20, -18)
	])
	base.color = Color(0.45, 0.08, 0.0, 1.0)
	base.position = Vector2(0, 0)
	visual.add_child(base)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-20, -18), Vector2(20, -18),
		Vector2(16, -46), Vector2(-16, -46)
	])
	body.color = Color(0.65, 0.12, 0.0, 1.0)
	visual.add_child(body)

	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([
		Vector2(-8, -46), Vector2(8, -46),
		Vector2(8, -62), Vector2(-8, -62)
	])
	barrel.color = Color(0.3, 0.05, 0.0, 1.0)
	visual.add_child(barrel)

	var eye := Polygon2D.new()
	eye.polygon = PackedVector2Array([
		Vector2(-6, -28), Vector2(6, -28),
		Vector2(6, -38), Vector2(-6, -38)
	])
	eye.color = Color(1.0, 0.6, 0.0, 1.0)
	visual.add_child(eye)

	hp_label = Label.new()
	hp_label.text = "3"
	hp_label.position = Vector2(-8, -82)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.modulate = Color(1.0, 0.4, 0.0, 1.0)
	visual.add_child(hp_label)


func _build_hit_area() -> void:
	var area := Area2D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	var col := CollisionShape2D.new()
	col.position = Vector2(0, -30)
	col.shape = shape
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var body_velocity = body.get("velocity")
	if body.has_method("bounce") and body_velocity is Vector2 and body_velocity.y > 0 and body.global_position.y < global_position.y - 30:
		_take_stomp(body)
	elif body.has_method("take_damage"):
		body.take_damage(1, global_position)


func _take_stomp(player: Node) -> void:
	if invulnerable_timer > 0 or defeated_state:
		return
	player.bounce()
	health -= 1
	invulnerable_timer = 0.6
	hp_label.text = str(health)
	hurt_sound.play()
	match health:
		2: visual.get_child(1).color = Color(0.8, 0.25, 0.0, 1.0)
		1: visual.get_child(1).color = Color(1.0, 0.5, 0.0, 1.0)
	if health <= 0:
		_die()


func _shoot() -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var dir: Vector2 = (target_player.global_position + Vector2(0, -28) - (global_position + Vector2(0, -52))).normalized()
	var shot := PROJECTILE_SCRIPT.new()
	get_parent().add_child(shot)
	shot.setup(global_position + Vector2(0, -62), dir)


func _player_in_range() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false
	return global_position.distance_to(target_player.global_position) <= activation_distance


func _die() -> void:
	defeated_state = true
	collision_layer = 0
	defeated.emit()
	death_sound.play()
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1, 0.3, 0, 0), 0.4)
	tween.tween_callback(queue_free)
	
func _build_audio() -> void:
	hurt_sound = AudioStreamPlayer2D.new()
	hurt_sound.stream = load("res://assets/audio/sounds/janela-quebrando-zumbi.wav")
	hurt_sound.volume_db = -3.0
	add_child(hurt_sound)

	death_sound = AudioStreamPlayer2D.new()
	death_sound.stream = load("res://assets/audio/sounds/escudo-quebrado-fornite_VCqLCVO.wav")
	death_sound.volume_db = -2.0
	add_child(death_sound)
