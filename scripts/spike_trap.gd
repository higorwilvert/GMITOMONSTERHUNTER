extends Area2D

var hazard_size := Vector2.ZERO
var interval := 2.0
var active_duration := 1.2
var timer := 0.0
var active := false
var collision_shape: CollisionShape2D
var visuals: Node2D
var sound: AudioStreamPlayer2D


func setup(top_left: Vector2, size: Vector2, cycle_interval := 2.0, duration := 1.2) -> void:
	position = top_left + size * 0.5
	hazard_size = size
	interval = cycle_interval
	active_duration = duration
	collision_layer = 8
	collision_mask = 2
	add_to_group("hazards")
	_build_collision()
	_build_visuals()
	_build_audio()
	body_entered.connect(_on_body_entered)
	_set_active(false)


func _process(delta: float) -> void:
	timer += delta
	if not active and timer >= interval:
		timer = 0.0
		_set_active(true)
	elif active and timer >= active_duration:
		timer = 0.0
		_set_active(false)


func _set_active(state: bool) -> void:
	active = state
	collision_shape.disabled = not state
	visuals.visible = state
	if state and sound != null:
		sound.play()


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = hazard_size
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)


func _build_visuals() -> void:
	visuals = Node2D.new()
	add_child(visuals)
	var cols: int = int(ceil(hazard_size.x / 48.0))
	for i in range(cols):
		var x := -hazard_size.x * 0.5 + 48.0 * 0.5 + i * 48.0

		var base := Polygon2D.new()
		base.polygon = PackedVector2Array([
			Vector2(-22, 10), Vector2(22, 10),
			Vector2(22, 24),  Vector2(-22, 24)
		])
		base.color = Color(0.6, 0.1, 0.0, 1.0)
		base.position = Vector2(x, 0)
		visuals.add_child(base)

		var tip := Polygon2D.new()
		tip.polygon = PackedVector2Array([
			Vector2(0,  -20),
			Vector2(-18, 10),
			Vector2(18,  10)
		])
		tip.color = Color(0.95, 0.4, 0.05, 1.0)
		tip.position = Vector2(x, 0)
		visuals.add_child(tip)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
		
func _build_audio() -> void:
	sound = AudioStreamPlayer2D.new()
	sound.stream = load("res://assets/audio/sounds/spike-up.wav") 
	sound.volume_db = -5.0
	add_child(sound)	
