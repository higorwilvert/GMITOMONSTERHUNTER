extends Node

const HUD_SCENE := preload("res://scenes/HUD.tscn")

const CUTSCENES := {
	"intro": [
		"Estacao Acucar-7 estava tranquila ate uma tempestade cosmica atingir o nucleo.",
		"As latas do Energetico Intergalactico foram espalhadas pela galaxia.",
		"Gmito entra no portal improvisado para recuperar a energia da estacao."
	],
	"after_1": [
		"Gmito recuperou a primeira lata.",
		"Parte da energia voltou para Acucar-7.",
		"O sistema detectou a proxima lata no Planeta Vulcanico."
	],
	"after_2": [
		"A segunda lata foi recuperada.",
		"A ultima energia esta no Planeta Congelado.",
		"Dr. Vazio protege a lata final e quer absorver toda a energia da galaxia."
	],
	"final": [
		"Dr. Vazio foi derrotado.",
		"Gmito recuperou a ultima lata do Energetico Intergalactico.",
		"A Estacao Acucar-7 voltou a funcionar. Gmito salvou sua casa."
	]
}

var current_level_node
var hud
var ui_layer
var pause_layer
var defeat_layer
var music_player
var cutscene_steps := []
var cutscene_index := 0
var cutscene_done := Callable()
var cutscene_label
var cutscene_button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ensure_input_actions()
	GameState.level_completed.connect(_on_level_completed)
	GameState.player_died.connect(_on_player_died)
	_play_music()
	_show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and current_level_node != null and cutscene_steps.is_empty() and defeat_layer == null:
		_toggle_pause()
	if event.is_action_pressed("jump") and not cutscene_steps.is_empty():
		_advance_cutscene()


func _play_music() -> void:
	if DisplayServer.get_name() == "headless":
		return
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/audio/music/time_for_adventure.mp3")
	music_player.volume_db = -12.0
	music_player.autoplay = true
	add_child(music_player)
	music_player.play()


func _show_menu() -> void:
	_clear_game()
	_clear_ui()
	GameState.reset_game()
	get_tree().paused = false
	if music_player == null or not music_player.playing:
		_play_music()

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	var background := ColorRect.new()
	background.color = Color(0.03, 0.035, 0.08, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var title := Label.new()
	title.text = "GMITO: THE MONSTER HUNTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 38)
	title.position = Vector2(0, 120)
	title.size = Vector2(1280, 70)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Recupere 3 latas do Energetico Intergalactico e salve Acucar-7."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.position = Vector2(0, 205)
	subtitle.size = Vector2(1280, 36)
	root.add_child(subtitle)

	root.add_child(_make_button("INICIAR", Vector2(515, 310), Callable(self, "_start_intro")))
	root.add_child(_make_button("CREDITOS", Vector2(515, 380), Callable(self, "_show_credits")))
	root.add_child(_make_button("SAIR", Vector2(515, 450), Callable(get_tree(), "quit")))


func _show_credits() -> void:
	_show_cutscene("credits", Callable(self, "_show_menu"), [
		"Projeto baseado no documento Game Design de GMITO.",
		"Assets: Kenney, Pixel Adventure, Brackeys Platformer Assets e personagem Gmito customizado.",
		"Licencas e creditos estao preservados na pasta assets do projeto."
	])


func _start_intro() -> void:
	_show_cutscene("intro", Callable(self, "_start_level").bind(1))


func _make_button(text: String, pos: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(250, 54)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	return button


func _show_cutscene(key: String, done: Callable, override_steps := []) -> void:
	_clear_game()
	_clear_ui()
	get_tree().paused = false
	cutscene_steps = override_steps if not override_steps.is_empty() else CUTSCENES.get(key, [])
	cutscene_index = 0
	cutscene_done = done

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(root)

	var texture := TextureRect.new()
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.texture = _cutscene_texture(key)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.modulate = Color(0.65, 0.7, 0.9, 1.0)
	root.add_child(texture)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var box := Panel.new()
	box.position = Vector2(160, 450)
	box.size = Vector2(960, 155)
	root.add_child(box)

	cutscene_label = Label.new()
	cutscene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cutscene_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	cutscene_label.add_theme_font_size_override("font_size", 25)
	cutscene_label.position = Vector2(190, 480)
	cutscene_label.size = Vector2(900, 70)
	root.add_child(cutscene_label)

	cutscene_button = _make_button("PROXIMO", Vector2(870, 630), Callable(self, "_advance_cutscene"))
	root.add_child(cutscene_button)
	_render_cutscene()


func _cutscene_texture(key: String) -> Texture2D:
	match key:
		"after_1":
			return load("res://assets/parallax/desert/desert_sky.png")
		"after_2", "final":
			return load("res://assets/parallax/forest/forest_sky.png")
		_:
			return load("res://assets/parallax/moon/moon_sky.png")


func _render_cutscene() -> void:
	if cutscene_label == null:
		return
	cutscene_label.text = cutscene_steps[cutscene_index]
	cutscene_button.text = "JOGAR" if cutscene_index == cutscene_steps.size() - 1 else "PROXIMO"


func _advance_cutscene() -> void:
	if cutscene_steps.is_empty():
		return
	if cutscene_index < cutscene_steps.size() - 1:
		cutscene_index += 1
		_render_cutscene()
		return
	var done := cutscene_done
	cutscene_steps = []
	_clear_ui()
	if done.is_valid():
		done.call()


func _start_level(level_id: int) -> void:
	_clear_game()
	_clear_ui()
	get_tree().paused = false
	if music_player != null:
		music_player.stop()
	GameState.start_level(level_id)
	var scene_path := GameState.get_level_scene(level_id)
	current_level_node = load(scene_path).instantiate()
	add_child(current_level_node)
	hud = HUD_SCENE.instantiate()
	add_child(hud)


func _on_level_completed(level_id: int) -> void:
	if level_id == 1:
		_show_cutscene("after_1", Callable(self, "_start_level").bind(2))
	elif level_id == 2:
		_show_cutscene("after_2", Callable(self, "_start_level").bind(3))
	else:
		_show_cutscene("final", Callable(self, "_show_menu"))


func _on_player_died() -> void:
	if current_level_node == null or defeat_layer != null:
		return
	_show_defeat_screen()


func _show_defeat_screen() -> void:
	get_tree().paused = true
	defeat_layer = CanvasLayer.new()
	defeat_layer.layer = 40
	defeat_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(defeat_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	defeat_layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.64)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(340, 175)
	panel.size = Vector2(600, 315)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.12, 0.96)
	style.border_color = Color(0.68, 0.42, 1.0, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var title := Label.new()
	title.text = "SEM ENERGIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 34)
	title.position = Vector2(340, 220)
	title.size = Vector2(600, 50)
	root.add_child(title)

	var message := Label.new()
	message.text = "Gmito perdeu as 3 vidas.\nVolte para o ultimo checkpoint ou retorne ao menu."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	message.add_theme_font_size_override("font_size", 21)
	message.position = Vector2(390, 290)
	message.size = Vector2(500, 70)
	root.add_child(message)

	root.add_child(_make_button("CHECKPOINT", Vector2(380, 395), Callable(self, "_retry_checkpoint")))
	root.add_child(_make_button("MENU", Vector2(650, 395), Callable(self, "_show_menu")))


func _retry_checkpoint() -> void:
	if defeat_layer != null:
		defeat_layer.queue_free()
		defeat_layer = null
	if current_level_node != null and current_level_node.has_method("retry_from_checkpoint"):
		current_level_node.retry_from_checkpoint()
	get_tree().paused = false


func _toggle_pause() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_show_pause()


func _show_pause() -> void:
	get_tree().paused = true
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 30
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var title := Label.new()
	title.text = "PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 36)
	title.position = Vector2(0, 210)
	title.size = Vector2(1280, 60)
	root.add_child(title)
	root.add_child(_make_button("CONTINUAR", Vector2(515, 320), Callable(self, "_resume_game")))
	root.add_child(_make_button("MENU", Vector2(515, 390), Callable(self, "_show_menu")))


func _resume_game() -> void:
	get_tree().paused = false
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null


func _clear_game() -> void:
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null
	if hud != null:
		hud.queue_free()
		hud = null
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null
	if defeat_layer != null:
		defeat_layer.queue_free()
		defeat_layer = null


func _clear_ui() -> void:
	if ui_layer != null:
		ui_layer.queue_free()
		ui_layer = null
	cutscene_label = null
	cutscene_button = null
