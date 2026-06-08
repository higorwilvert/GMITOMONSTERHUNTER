extends CharacterBody2D

const GRAVITY := 1500.0
const SPEED := 285.0
const AIR_ACCEL := 760.0
const GROUND_ACCEL := 1350.0
const ICE_ACCEL := 260.0
const JUMP_VELOCITY := -560.0
const DASH_SPEED := 760.0
const DASH_DURATION := 0.16
const DASH_COST := 33.0
const CLIMB_SPEED := 230.0

var facing := 1
var has_double_jump := true
var dash_timer := 0.0
var invincible_timer := 0.0
var defeated := false
var ladder_contacts := 0
var climbing := false
var current_slippery_floor := false
var spawn_position := Vector2.ZERO
var camera: Camera2D
var animated_sprite: AnimatedSprite2D
var jump_sound: AudioStreamPlayer2D
var hurt_sound: AudioStreamPlayer2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	spawn_position = global_position
	if GameState.checkpoint_position != Vector2.ZERO:
		spawn_position = GameState.checkpoint_position
		global_position = spawn_position
	_build_collision()
	_build_sprite()
	_build_camera()
	_build_audio()
	GameState.checkpoint_changed.connect(_on_checkpoint_changed)


func _physics_process(delta: float) -> void:
	if invincible_timer > 0.0:
		invincible_timer -= delta
		animated_sprite.modulate = Color(1, 1, 1, 0.45 if int(invincible_timer * 14.0) % 2 == 0 else 1.0)
	else:
		animated_sprite.modulate = Color.WHITE

	var wants_climb := ladder_contacts > 0 and Input.get_axis("climb_up", "climb_down") != 0.0
	if climbing or wants_climb:
		_handle_ladder_movement()
	elif dash_timer > 0.0:
		dash_timer -= delta
		velocity.x = facing * DASH_SPEED
		velocity.y = 0
	else:
		_apply_gravity(delta)
		_apply_horizontal_movement(delta)
		_handle_jump()
		_handle_dash()

	move_and_slide()
	_update_floor_state()
	_update_animation()


func set_spawn(position_to_use: Vector2) -> void:
	spawn_position = position_to_use
	GameState.set_checkpoint(spawn_position)


func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if camera == null:
		return
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom


func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO) -> void:
	if defeated:
		return
	if invincible_timer > 0.0:
		return
	var died: bool = GameState.damage_player(amount)
	if died:
		_freeze_after_defeat()
		return
	hurt_sound.play()
	invincible_timer = 1.1
	var knockback_dir: float = sign(global_position.x - source_position.x)
	if knockback_dir == 0:
		knockback_dir = -facing
	velocity.x = knockback_dir * 320.0
	velocity.y = -320.0


func fall_out() -> void:
	if defeated:
		return
	var died: bool = GameState.damage_player(1)
	if died:
		_freeze_after_defeat()
	else:
		_respawn()


func bounce() -> void:
	climbing = false
	velocity.y = JUMP_VELOCITY * 0.72
	has_double_jump = true


func enter_ladder() -> void:
	ladder_contacts += 1


func exit_ladder() -> void:
	ladder_contacts = max(ladder_contacts - 1, 0)
	if ladder_contacts == 0:
		climbing = false


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		has_double_jump = true


func _apply_horizontal_movement(delta: float) -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		facing = sign(input_axis)
	var target_speed := input_axis * SPEED
	var accel := AIR_ACCEL
	if is_on_floor():
		accel = ICE_ACCEL if current_slippery_floor else GROUND_ACCEL
	velocity.x = move_toward(velocity.x, target_speed, accel * delta)


func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		has_double_jump = true
		jump_sound.play()
	elif has_double_jump:
		velocity.y = JUMP_VELOCITY * 0.92
		has_double_jump = false
		jump_sound.play()


func _handle_dash() -> void:
	if not Input.is_action_just_pressed("dash"):
		return
	if GameState.spend_energy(DASH_COST):
		climbing = false
		dash_timer = DASH_DURATION
		velocity.x = facing * DASH_SPEED
		velocity.y = 0


func _handle_ladder_movement() -> void:
	climbing = true
	dash_timer = 0.0
	has_double_jump = true
	var climb_axis := Input.get_axis("climb_up", "climb_down")
	var input_axis := Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		facing = sign(input_axis)
	velocity.x = input_axis * SPEED * 0.55
	velocity.y = climb_axis * CLIMB_SPEED
	if Input.is_action_just_pressed("jump"):
		climbing = false
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
	elif Input.is_action_just_pressed("dash"):
		climbing = false
		_handle_dash()


func _update_floor_state() -> void:
	current_slippery_floor = false
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		if collision.get_normal().y < -0.65:
			var collider := collision.get_collider()
			if collider != null and collider.has_method("is_slippery") and collider.is_slippery():
				current_slippery_floor = true


func _update_animation() -> void:
	animated_sprite.flip_h = facing < 0
	if climbing:
		animated_sprite.play("idle")
	elif dash_timer > 0.0:
		animated_sprite.play("run")
	elif not is_on_floor():
		animated_sprite.play("jump")
	elif abs(velocity.x) > 15:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")


func _respawn() -> void:
	hurt_sound.play()
	invincible_timer = 1.25
	_move_to_checkpoint()
	GameState.restore_energy(GameState.max_dash_energy)


func revive_from_checkpoint() -> void:
	defeated = false
	visible = true
	set_physics_process(true)
	invincible_timer = 1.25
	_move_to_checkpoint()
	GameState.restore_energy(GameState.max_dash_energy)


func _freeze_after_defeat() -> void:
	defeated = true
	climbing = false
	velocity = Vector2.ZERO
	hurt_sound.play()
	visible = false
	set_physics_process(false)


func _move_to_checkpoint() -> void:
	ladder_contacts = 0
	climbing = false
	global_position = GameState.checkpoint_position if GameState.checkpoint_position != Vector2.ZERO else spawn_position
	velocity = Vector2.ZERO


func _on_checkpoint_changed(position: Vector2) -> void:
	spawn_position = position


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34, 56)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -28)
	collision.shape = shape
	add_child(collision)


func _build_sprite() -> void:
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = _make_sprite_frames()
	animated_sprite.position = Vector2(0, -35)
	animated_sprite.scale = Vector2(1.18, 1.18)
	add_child(animated_sprite)
	animated_sprite.play("idle")


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_frame("idle", load("res://assets/player/rotations/east.png"))
	frames.set_animation_speed("idle", 1.0)

	frames.add_animation("run")
	for i in range(8):
		var path := "res://assets/player/animations/Running-b310a182/east/frame_%03d.png" % i
		frames.add_frame("run", load(path))
	frames.set_animation_speed("run", 12.0)

	frames.add_animation("jump")
	for i in range(8):
		var path := "res://assets/player/animations/Jumping-461c5191/east/frame_%03d.png" % i
		frames.add_frame("jump", load(path))
	frames.set_animation_speed("jump", 10.0)
	return frames


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(0, -100)
	camera.zoom = Vector2(1.2, 1.2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.enabled = true
	add_child(camera)
	camera.make_current()


func _build_audio() -> void:
	jump_sound = AudioStreamPlayer2D.new()
	jump_sound.stream = load("res://assets/audio/sounds/jump.wav")
	jump_sound.volume_db = -7.0
	add_child(jump_sound)

	hurt_sound = AudioStreamPlayer2D.new()
	hurt_sound.stream = load("res://assets/audio/sounds/hurt.wav")
	hurt_sound.volume_db = -8.0
	add_child(hurt_sound)
