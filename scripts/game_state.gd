extends Node

signal health_changed(value, max_value)
signal score_changed(value)
signal energy_changed(value, max_value)
signal level_changed(level_id, level_name)
signal checkpoint_changed(position)
signal player_died
signal level_completed(level_id)
signal music_enabled_changed(enabled)

const LEVEL_NAMES := {
	1: "Lua Acucarada",
	2: "Planeta Vulcanico",
	3: "Planeta Congelado"
}

const LEVEL_SCENES := {
	1: "res://scenes/Level1.tscn",
	2: "res://scenes/Level2.tscn",
	3: "res://scenes/Level3.tscn"
}

var max_health := 3
var health := 3
var score := 0
var max_dash_energy := 100.0
var dash_energy := 100.0
var current_level := 1
var checkpoint_position := Vector2.ZERO
var collected_cans := 0
var music_enabled := true
var debug_god_mode := false
var debug_fly_mode := false


func _ready() -> void:
	ensure_input_actions()


func ensure_input_actions() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("climb_up", [KEY_W, KEY_UP])
	_add_keys("climb_down", [KEY_S, KEY_DOWN])
	_add_keys("jump", [KEY_SPACE])
	_add_keys("dash", [KEY_SHIFT])
	_add_keys("interact", [KEY_E])
	_add_keys("pause", [KEY_ESCAPE])
	_add_keys("debug_menu", [KEY_F3])
	_add_keys("debug_fly", [KEY_F4])
	_add_keys("debug_refill", [KEY_F5])
	_add_keys("debug_level_1", [KEY_1])
	_add_keys("debug_level_2", [KEY_2])
	_add_keys("debug_level_3", [KEY_3])


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var exists := false
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode == key:
				exists = true
		if not exists:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = key
			InputMap.action_add_event(action, key_event)


func reset_game() -> void:
	health = max_health
	score = 0
	dash_energy = max_dash_energy
	current_level = 1
	checkpoint_position = Vector2.ZERO
	collected_cans = 0
	_emit_all()


func start_level(level_id: int) -> void:
	current_level = level_id
	health = _health_limit()
	dash_energy = max_dash_energy
	checkpoint_position = Vector2.ZERO
	level_changed.emit(current_level, get_level_name())
	health_changed.emit(health, _health_limit())
	energy_changed.emit(dash_energy, max_dash_energy)


func get_level_name() -> String:
	return LEVEL_NAMES.get(current_level, "Fase")


func get_level_scene(level_id: int) -> String:
	return LEVEL_SCENES.get(level_id, "")


func set_checkpoint(position: Vector2) -> void:
	checkpoint_position = position
	checkpoint_changed.emit(checkpoint_position)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func heal(amount: int) -> void:
	health = min(_health_limit(), health + amount)
	health_changed.emit(health, _health_limit())


func restore_energy(amount: float) -> void:
	dash_energy = min(max_dash_energy, dash_energy + amount)
	energy_changed.emit(dash_energy, max_dash_energy)


func spend_energy(amount: float) -> bool:
	if dash_energy < amount:
		return false
	dash_energy -= amount
	energy_changed.emit(dash_energy, max_dash_energy)
	return true


func damage_player(amount: int) -> bool:
	if debug_god_mode:
		health = max(health, _health_limit())
		health_changed.emit(health, _health_limit())
		return false
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		player_died.emit()
		return true
	return false


func revive_player() -> void:
	health = _health_limit()
	dash_energy = max_dash_energy
	health_changed.emit(health, _health_limit())
	energy_changed.emit(dash_energy, max_dash_energy)


func debug_refill() -> void:
	health = _health_limit()
	dash_energy = max_dash_energy
	health_changed.emit(health, _health_limit())
	energy_changed.emit(dash_energy, max_dash_energy)


func toggle_debug_god() -> bool:
	debug_god_mode = not debug_god_mode
	debug_refill()
	return debug_god_mode


func toggle_debug_fly() -> bool:
	debug_fly_mode = not debug_fly_mode
	return debug_fly_mode


func toggle_music_enabled() -> bool:
	set_music_enabled(not music_enabled)
	return music_enabled


func set_music_enabled(enabled: bool) -> void:
	if music_enabled == enabled:
		return
	music_enabled = enabled
	music_enabled_changed.emit(music_enabled)


func _health_limit() -> int:
	return 9 if debug_god_mode else max_health


func complete_level(level_id: int) -> void:
	collected_cans = max(collected_cans, level_id)
	level_completed.emit(level_id)


func _emit_all() -> void:
	health_changed.emit(health, max_health)
	score_changed.emit(score)
	energy_changed.emit(dash_energy, max_dash_energy)
	level_changed.emit(current_level, get_level_name())
