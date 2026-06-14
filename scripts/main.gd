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
var debug_layer
var debug_god_button: Button
var debug_fly_button: Button
var pause_music_button: Button
var music_player
var cutscene_music_player: AudioStreamPlayer
var cutscene_key := ""
var cutscene_steps := []
var cutscene_index := 0
var cutscene_done := Callable()
var cutscene_label: Label
var cutscene_button: Button
var cutscene_title_label: Label
var cutscene_subtitle_label: Label
var cutscene_step_label: Label
var cutscene_can_slots: Array[TextureRect] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ensure_input_actions()
	GameState.level_completed.connect(_on_level_completed)
	GameState.player_died.connect(_on_player_died)
	GameState.music_enabled_changed.connect(_on_music_enabled_changed)
	_play_music()
	_show_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_menu"):
		_toggle_debug_menu()
		return
	if event.is_action_pressed("debug_refill"):
		GameState.debug_refill()
	if event.is_action_pressed("debug_fly"):
		GameState.toggle_debug_fly()
		_refresh_debug_buttons()
	if event.is_action_pressed("debug_level_1"):
		_debug_start_level(1)
	elif event.is_action_pressed("debug_level_2"):
		_debug_start_level(2)
	elif event.is_action_pressed("debug_level_3"):
		_debug_start_level(3)
	if event.is_action_pressed("pause") and current_level_node != null and cutscene_steps.is_empty() and defeat_layer == null:
		_toggle_pause()
	if event.is_action_pressed("jump") and not cutscene_steps.is_empty():
		_advance_cutscene()


func _play_music() -> void:
	if DisplayServer.get_name() == "headless" or not GameState.music_enabled:
		return
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		music_player.stream = load("res://assets/audio/music/time_for_adventure.mp3")
		music_player.volume_db = -12.0
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(music_player)
	if not music_player.playing:
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

	root.add_child(_make_button("INICIAR", Vector2(515, 300), Callable(self, "_start_intro")))
	root.add_child(_make_button("DEBUG", Vector2(515, 370), Callable(self, "_show_debug_menu")))
	root.add_child(_make_button("CREDITOS", Vector2(515, 440), Callable(self, "_show_credits")))
	root.add_child(_make_button("SAIR", Vector2(515, 510), Callable(get_tree(), "quit")))


func _show_credits() -> void:
	_show_cutscene("credits", Callable(self, "_show_menu"), [
		"Projeto baseado no documento Game Design de GMITO.",
		"Assets: Kenney, Pixel Adventure, Brackeys Platformer Assets e personagem Gmito customizado.",
		"Licencas e creditos estao preservados na pasta assets do projeto."
	])


func _start_intro() -> void:
	_show_cutscene("intro", Callable(self, "_start_level").bind(1))


func _make_button(text: String, pos: Vector2, callback: Callable, button_size := Vector2(250, 54)) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	return button


func _show_cutscene(key: String, done: Callable, override_steps := []) -> void:
	_clear_game()
	_clear_ui()
	get_tree().paused = false
	if music_player != null:
		music_player.stop()
	cutscene_key = key
	cutscene_steps = override_steps if not override_steps.is_empty() else CUTSCENES.get(key, [])
	cutscene_index = 0
	cutscene_done = done
	_play_cutscene_music(key)

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
	texture.modulate = _cutscene_texture_tint(key)
	root.add_child(texture)

	var shade := ColorRect.new()
	shade.color = _cutscene_shade_color(key)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	_add_cutscene_energy_lines(root, key)
	if key == "final":
		_add_victory_confetti(root)

	var header := Panel.new()
	header.position = Vector2(86, 62)
	header.size = Vector2(1108, 118)
	header.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.09, 0.88), _cutscene_accent_color(key), 3))
	root.add_child(header)

	cutscene_title_label = Label.new()
	cutscene_title_label.text = _cutscene_title(key)
	cutscene_title_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	cutscene_title_label.add_theme_font_size_override("font_size", 31 if key != "final" else 38)
	cutscene_title_label.position = Vector2(122, 82)
	cutscene_title_label.size = Vector2(650, 46)
	root.add_child(cutscene_title_label)

	cutscene_subtitle_label = Label.new()
	cutscene_subtitle_label.text = _cutscene_subtitle(key)
	cutscene_subtitle_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	cutscene_subtitle_label.add_theme_font_size_override("font_size", 18)
	cutscene_subtitle_label.modulate = Color(0.82, 0.88, 1.0, 0.94)
	cutscene_subtitle_label.position = Vector2(124, 130)
	cutscene_subtitle_label.size = Vector2(680, 30)
	root.add_child(cutscene_subtitle_label)

	_add_cutscene_can_progress(root, key)

	var portrait_panel := Panel.new()
	portrait_panel.position = Vector2(126, 265)
	portrait_panel.size = Vector2(250, 270)
	portrait_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.03, 0.035, 0.065, 0.94), Color(0.28, 0.82, 1.0, 1.0), 3))
	root.add_child(portrait_panel)

	var portrait := TextureRect.new()
	portrait.texture = _cutscene_portrait_texture(key)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(156, 298)
	portrait.size = Vector2(190, 190)
	portrait.modulate = Color.WHITE if key != "final" else Color(1.0, 1.0, 0.82, 1.0)
	root.add_child(portrait)

	var portrait_caption := Label.new()
	portrait_caption.text = _cutscene_portrait_caption(key)
	portrait_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_caption.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	portrait_caption.add_theme_font_size_override("font_size", 17)
	portrait_caption.position = Vector2(126, 492)
	portrait_caption.size = Vector2(250, 24)
	root.add_child(portrait_caption)

	var box := Panel.new()
	box.position = Vector2(410, 265)
	box.size = Vector2(744, 270)
	box.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.028, 0.045, 0.95), _cutscene_accent_color(key), 3))
	root.add_child(box)

	cutscene_step_label = Label.new()
	cutscene_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cutscene_step_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	cutscene_step_label.add_theme_font_size_override("font_size", 16)
	cutscene_step_label.modulate = Color(0.74, 0.86, 1.0, 0.9)
	cutscene_step_label.position = Vector2(1018, 286)
	cutscene_step_label.size = Vector2(100, 24)
	root.add_child(cutscene_step_label)

	cutscene_label = Label.new()
	cutscene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cutscene_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	cutscene_label.add_theme_font_size_override("font_size", 28 if key == "final" else 24)
	cutscene_label.position = Vector2(452, 335)
	cutscene_label.size = Vector2(640, 112)
	root.add_child(cutscene_label)

	var hint := Label.new()
	hint.text = "ESPACO tambem avanca"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	hint.add_theme_font_size_override("font_size", 15)
	hint.modulate = Color(0.74, 0.78, 0.88, 0.76)
	hint.position = Vector2(734, 542)
	hint.size = Vector2(380, 24)
	root.add_child(hint)

	cutscene_button = _make_button("PROXIMO", Vector2(898, 590), Callable(self, "_advance_cutscene"), Vector2(256, 58))
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


func _cutscene_texture_tint(key: String) -> Color:
	match key:
		"after_1":
			return Color(1.0, 0.72, 0.58, 1.0)
		"after_2":
			return Color(0.64, 0.82, 1.0, 1.0)
		"final":
			return Color(0.78, 0.96, 1.0, 1.0)
		_:
			return Color(0.72, 0.76, 1.0, 1.0)


func _cutscene_shade_color(key: String) -> Color:
	return Color(0, 0, 0, 0.28) if key == "final" else Color(0, 0, 0, 0.48)


func _cutscene_accent_color(key: String) -> Color:
	match key:
		"after_1":
			return Color(1.0, 0.48, 0.2, 1.0)
		"after_2":
			return Color(0.32, 0.82, 1.0, 1.0)
		"final":
			return Color(1.0, 0.88, 0.28, 1.0)
		_:
			return Color(0.68, 0.42, 1.0, 1.0)


func _cutscene_title(key: String) -> String:
	match key:
		"intro":
			return "CHAMADO DE ACUCAR-7"
		"after_1":
			return "LATA 1 RECUPERADA"
		"after_2":
			return "LATA 2 RECUPERADA"
		"final":
			return "MISSAO CUMPRIDA"
		"credits":
			return "CREDITOS"
		_:
			return "GMITO"


func _cutscene_subtitle(key: String) -> String:
	match key:
		"intro":
			return "A energia da estacao depende das 3 latas perdidas."
		"after_1":
			return "Proximo destino: Planeta Vulcanico."
		"after_2":
			return "Ultimo destino: Planeta Congelado."
		"final":
			return "Dr. Vazio caiu. A galaxia voltou a brilhar."
		"credits":
			return "Assets e licencas preservados na pasta do projeto."
		_:
			return ""


func _cutscene_portrait_texture(key: String) -> Texture2D:
	match key:
		"after_1", "after_2", "final":
			return load("res://assets/energy_can_spin/frame_00.png")
		_:
			return load("res://assets/player/rotations/east.png")


func _cutscene_portrait_caption(key: String) -> String:
	match key:
		"final":
			return "3 / 3 LATAS"
		"after_1":
			return "1 / 3 LATAS"
		"after_2":
			return "2 / 3 LATAS"
		_:
			return "GMITO"


func _cutscene_recovered_cans(key: String) -> int:
	match key:
		"after_1":
			return 1
		"after_2":
			return 2
		"final":
			return 3
		_:
			return 0


func _add_cutscene_can_progress(root: Control, key: String) -> void:
	cutscene_can_slots = []
	var count := _cutscene_recovered_cans(key)
	var label := Label.new()
	label.text = "ENERGIA"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	label.add_theme_font_size_override("font_size", 16)
	label.position = Vector2(800, 90)
	label.size = Vector2(130, 24)
	root.add_child(label)
	for i in range(3):
		var slot := TextureRect.new()
		slot.texture = load("res://assets/energy_can_spin/frame_00.png")
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.position = Vector2(950 + i * 62, 82)
		slot.size = Vector2(46, 54)
		slot.modulate = Color.WHITE if i < count else Color(0.35, 0.38, 0.48, 0.36)
		root.add_child(slot)
		cutscene_can_slots.append(slot)
	var progress := Label.new()
	progress.text = "%d / 3" % count
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	progress.add_theme_font_size_override("font_size", 18)
	progress.modulate = Color(0.9, 0.95, 1.0, 0.92)
	progress.position = Vector2(1010, 142)
	progress.size = Vector2(110, 24)
	root.add_child(progress)


func _add_cutscene_energy_lines(root: Control, key: String) -> void:
	var color := _cutscene_accent_color(key)
	for i in range(4):
		var line := ColorRect.new()
		line.color = Color(color.r, color.g, color.b, 0.18 - i * 0.025)
		line.position = Vector2(0, 212 + i * 86)
		line.size = Vector2(1280, 3)
		root.add_child(line)


func _add_victory_confetti(root: Control) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14062026
	var colors := [
		Color(1.0, 0.32, 0.25, 1.0),
		Color(1.0, 0.88, 0.22, 1.0),
		Color(0.28, 0.9, 1.0, 1.0),
		Color(0.56, 1.0, 0.36, 1.0),
		Color(0.78, 0.42, 1.0, 1.0)
	]
	for i in range(86):
		var piece := ColorRect.new()
		piece.color = colors[i % colors.size()]
		piece.position = Vector2(rng.randf_range(30, 1240), rng.randf_range(28, 620))
		piece.size = Vector2(rng.randf_range(5, 13), rng.randf_range(6, 18))
		root.add_child(piece)


func _make_panel_style(bg: Color, border: Color, border_width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _render_cutscene() -> void:
	if cutscene_label == null:
		return
	cutscene_label.text = cutscene_steps[cutscene_index]
	if cutscene_step_label != null:
		cutscene_step_label.text = "%d / %d" % [cutscene_index + 1, cutscene_steps.size()]
	if cutscene_index < cutscene_steps.size() - 1:
		cutscene_button.text = "PROXIMO"
	elif cutscene_key == "intro":
		cutscene_button.text = "JOGAR"
	elif cutscene_key == "after_1" or cutscene_key == "after_2":
		cutscene_button.text = "PROXIMA FASE"
	else:
		cutscene_button.text = "MENU"


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


func _play_cutscene_music(key: String) -> void:
	if DisplayServer.get_name() == "headless" or not GameState.music_enabled:
		return
	var music_path := _cutscene_music_path(key)
	if music_path.is_empty():
		return
	_stop_cutscene_music()
	cutscene_music_player = AudioStreamPlayer.new()
	cutscene_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	cutscene_music_player.stream = load(music_path)
	if cutscene_music_player.stream != null and "loop" in cutscene_music_player.stream:
		cutscene_music_player.stream.loop = true
	cutscene_music_player.volume_db = -8.0 if key == "final" else -13.0
	add_child(cutscene_music_player)
	cutscene_music_player.play()


func _cutscene_music_path(key: String) -> String:
	match key:
		"after_1", "after_2":
			return "res://assets/music_pack/banners_in_the_wind.ogg"
		"final":
			return "res://assets/music_pack/hymn_of_valor.ogg"
		_:
			return ""


func _stop_cutscene_music() -> void:
	if cutscene_music_player != null:
		cutscene_music_player.stop()
		cutscene_music_player.queue_free()
		cutscene_music_player = null


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


func _toggle_debug_menu() -> void:
	if debug_layer != null:
		_close_debug_menu()
	else:
		_show_debug_menu()


func _show_debug_menu() -> void:
	if debug_layer != null:
		return
	get_tree().paused = true
	debug_layer = CanvasLayer.new()
	debug_layer.layer = 60
	debug_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(debug_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	debug_layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.58)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(300, 120)
	panel.size = Vector2(680, 455)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.045, 0.09, 0.97)
	style.border_color = Color(0.28, 0.8, 0.95, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var title := Label.new()
	title.text = "DEBUG / TESTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 31)
	title.position = Vector2(300, 150)
	title.size = Vector2(680, 48)
	root.add_child(title)

	var info := Label.new()
	info.text = "F3 menu  |  1/2/3 fases  |  F4 voo  |  F5 vida/dash"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	info.add_theme_font_size_override("font_size", 17)
	info.position = Vector2(320, 205)
	info.size = Vector2(640, 30)
	root.add_child(info)

	root.add_child(_make_button("FASE 1", Vector2(350, 260), Callable(self, "_debug_start_level").bind(1), Vector2(170, 54)))
	root.add_child(_make_button("FASE 2", Vector2(555, 260), Callable(self, "_debug_start_level").bind(2), Vector2(170, 54)))
	root.add_child(_make_button("FASE 3", Vector2(760, 260), Callable(self, "_debug_start_level").bind(3), Vector2(170, 54)))

	root.add_child(_make_button("VIDA/DASH", Vector2(350, 345), Callable(self, "_debug_refill"), Vector2(170, 54)))
	debug_god_button = _make_button("", Vector2(555, 345), Callable(self, "_debug_toggle_god"), Vector2(170, 54))
	root.add_child(debug_god_button)
	debug_fly_button = _make_button("", Vector2(760, 345), Callable(self, "_debug_toggle_fly"), Vector2(170, 54))
	root.add_child(debug_fly_button)
	root.add_child(_make_button("FECHAR", Vector2(515, 455), Callable(self, "_close_debug_menu")))
	_refresh_debug_buttons()


func _close_debug_menu() -> void:
	if debug_layer != null:
		debug_layer.queue_free()
		debug_layer = null
	debug_god_button = null
	debug_fly_button = null
	get_tree().paused = pause_layer != null or defeat_layer != null


func _debug_start_level(level_id: int) -> void:
	_close_debug_menu()
	GameState.debug_refill()
	_start_level(level_id)


func _debug_refill() -> void:
	GameState.debug_refill()
	_refresh_debug_buttons()


func _debug_toggle_god() -> void:
	GameState.toggle_debug_god()
	_refresh_debug_buttons()


func _debug_toggle_fly() -> void:
	GameState.toggle_debug_fly()
	_refresh_debug_buttons()


func _refresh_debug_buttons() -> void:
	if debug_god_button != null:
		debug_god_button.text = "GOD ON" if GameState.debug_god_mode else "GOD OFF"
	if debug_fly_button != null:
		debug_fly_button.text = "VOO ON" if GameState.debug_fly_mode else "VOO OFF"


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
	pause_music_button = _make_button("", Vector2(515, 390), Callable(self, "_toggle_music"))
	root.add_child(pause_music_button)
	root.add_child(_make_button("MENU", Vector2(515, 460), Callable(self, "_show_menu")))
	_refresh_pause_music_button()


func _resume_game() -> void:
	get_tree().paused = false
	if pause_layer != null:
		pause_layer.queue_free()
		pause_layer = null
	pause_music_button = null


func _toggle_music() -> void:
	GameState.toggle_music_enabled()
	_refresh_pause_music_button()


func _refresh_pause_music_button() -> void:
	if pause_music_button != null:
		pause_music_button.text = "MUSICA ON" if GameState.music_enabled else "MUSICA OFF"


func _on_music_enabled_changed(enabled: bool) -> void:
	if enabled:
		if not cutscene_key.is_empty() and not cutscene_steps.is_empty():
			_play_cutscene_music(cutscene_key)
		elif current_level_node == null:
			_play_music()
	else:
		if music_player != null:
			music_player.stop()
		_stop_cutscene_music()
	_refresh_pause_music_button()


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
	pause_music_button = null
	if defeat_layer != null:
		defeat_layer.queue_free()
		defeat_layer = null
	if debug_layer != null:
		debug_layer.queue_free()
		debug_layer = null
	debug_god_button = null
	debug_fly_button = null


func _clear_ui() -> void:
	if ui_layer != null:
		ui_layer.queue_free()
		ui_layer = null
	_stop_cutscene_music()
	cutscene_key = ""
	cutscene_title_label = null
	cutscene_subtitle_label = null
	cutscene_step_label = null
	cutscene_label = null
	cutscene_button = null
	cutscene_can_slots = []
