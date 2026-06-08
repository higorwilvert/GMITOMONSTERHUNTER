extends Platform
class_name MovingPlatform

var origin_position := Vector2.ZERO
var move_offset := Vector2.ZERO
var move_duration := 2.0
var time := 0.0


func setup_moving(top_left: Vector2, size: Vector2, theme: String, offset: Vector2, duration: float, is_slippery := false) -> void:
	setup(top_left, size, theme, is_slippery)
	origin_position = position
	move_offset = offset
	move_duration = max(duration, 0.1)


func _physics_process(delta: float) -> void:
	time += delta
	var t := (sin((time / move_duration) * TAU) + 1.0) * 0.5
	position = origin_position + move_offset * t

