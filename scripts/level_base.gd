extends Node2D

@export var level_id := 1

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const BOSS_SCENE := preload("res://scenes/BossDrVazio.tscn")
const PLATFORM_SCRIPT := preload("res://scripts/platform.gd")
const MOVING_PLATFORM_SCRIPT := preload("res://scripts/moving_platform.gd")
const HAZARD_SCRIPT := preload("res://scripts/hazard.gd")
const CHECKPOINT_SCRIPT := preload("res://scripts/checkpoint.gd")
const COLLECTIBLE_SCRIPT := preload("res://scripts/collectible.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const LADDER_SCRIPT := preload("res://scripts/ladder.gd")

var theme := "moon"
var world_width := 3400
var level_bottom := 860
var spawn_position := Vector2(100, 560)
var player
var music_player: AudioStreamPlayer
var tutorial_hint_label: Label


func _ready() -> void:
	add_to_group("levels")
	_configure_level()
	_play_level_music()
	GameState.set_checkpoint(spawn_position)
	_add_background()
	_build_level()
	_spawn_player()
	if level_id == 1:
		_add_tutorial_overlay()
	if level_id == 3:
		_add_boss()


func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player) and player.global_position.y > level_bottom:
		player.fall_out()
	if level_id == 1 and player != null and is_instance_valid(player):
		_update_tutorial_hint()


func _configure_level() -> void:
	match level_id:
		2:
			theme = "volcano"
			world_width = 4300
			level_bottom = 920
			spawn_position = Vector2(100, 640)
		3:
			theme = "ice"
			world_width = 5100
			level_bottom = 940
			spawn_position = Vector2(100, 640)
		_:
			theme = "moon"
			world_width = 5900
			level_bottom = 960
			spawn_position = Vector2(100, 640)


func _build_level() -> void:
	match level_id:
		2:
			_build_level_two()
		3:
			_build_level_three()
		_:
			_build_level_one()


func _build_level_one() -> void:
	_add_platform(Rect2(0, 690, 900, 270))
	_add_platform(Rect2(1150, 690, 820, 270))
	_add_platform(Rect2(2200, 690, 880, 270))
	_add_platform(Rect2(3350, 690, 900, 270))
	_add_platform(Rect2(4700, 690, 1150, 270))

	_add_upper_platform(Rect2(930, 420, 760, 48))
	_add_upper_platform(Rect2(2250, 420, 850, 48))
	_add_upper_platform(Rect2(3550, 420, 780, 48))
	_add_upper_platform(Rect2(4680, 420, 600, 48))

	_add_ladder(Vector2(880, 420), 6)
	_add_ladder(Vector2(2200, 420), 6)
	_add_ladder(Vector2(3500, 420), 6)
	_add_ladder(Vector2(4630, 420), 6)

	_add_checkpoint(Vector2(3750, 690))
	_add_enemy(Vector2(620, 690), 130, 860, false, 55, "green")
	_add_enemy(Vector2(1420, 690), 1170, 1940, false, 62, "purple")
	_add_enemy(Vector2(1780, 690), 1170, 1940, false, 58, "green")
	_add_enemy(Vector2(2480, 690), 2220, 3060, false, 66, "purple")
	_add_enemy(Vector2(2920, 690), 2220, 3060, false, 70, "green")
	_add_enemy(Vector2(3700, 690), 3380, 4230, false, 74, "purple")
	_add_enemy(Vector2(4100, 690), 3380, 4230, false, 76, "green")
	_add_enemy(Vector2(5120, 690), 4730, 5820, false, 82, "green")
	_add_enemy(Vector2(5600, 690), 4730, 5820, false, 88, "purple")
	_add_enemy(Vector2(1240, 420), 950, 1660, false, 60, "purple")
	_add_enemy(Vector2(2650, 420), 2280, 3070, false, 72, "green")
	_add_enemy(Vector2(3900, 420), 3580, 4300, false, 80, "purple")
	_add_enemy(Vector2(5010, 420), 4700, 5260, false, 84, "green")
	_add_enemy(Vector2(1850, 310), 1710, 2140, true, 72, "bat")
	_add_enemy(Vector2(3250, 305), 3060, 3490, true, 78, "bat")
	_add_enemy(Vector2(4450, 330), 4310, 4670, true, 82, "bat")

	for point in [
		Vector2(260, 620), Vector2(430, 620), Vector2(730, 620),
		Vector2(1020, 350), Vector2(1200, 350), Vector2(1460, 350),
		Vector2(1250, 620), Vector2(1530, 620), Vector2(1850, 620),
		Vector2(2340, 350), Vector2(2580, 350), Vector2(2880, 350),
		Vector2(2380, 620), Vector2(2680, 620), Vector2(2980, 620),
		Vector2(3600, 350), Vector2(3860, 350), Vector2(4160, 350),
		Vector2(3500, 620), Vector2(3780, 620), Vector2(4100, 620),
		Vector2(4780, 350), Vector2(5050, 350), Vector2(5220, 350),
		Vector2(4940, 620), Vector2(5260, 620), Vector2(5620, 620)
	]:
		_add_collectible(point, "sweet")
	_add_collectible(Vector2(1600, 350), "energy")
	_add_collectible(Vector2(4050, 350), "energy")
	_add_collectible(Vector2(4000, 620), "heart")
	_add_collectible(Vector2(5650, 620), "can")


func _build_level_two() -> void:
	_add_world_label(Vector2(110, 480), "Planeta Vulcanico")
	_add_platform(Rect2(0, 680, 500, 96))
	_add_platform(Rect2(650, 620, 300, 64))
	_add_platform(Rect2(1110, 570, 260, 64))
	_add_moving_platform(Rect2(1530, 625, 260, 48), Vector2(260, -120), 2.4)
	_add_platform(Rect2(2050, 610, 420, 64))
	_add_platform(Rect2(2680, 545, 290, 64))
	_add_moving_platform(Rect2(3180, 630, 250, 48), Vector2(0, -180), 2.1)
	_add_platform(Rect2(3650, 640, 500, 96))

	_add_hazard(Rect2(520, 715, 120, 58), "lava")
	_add_hazard(Rect2(970, 715, 130, 58), "lava")
	_add_hazard(Rect2(1380, 715, 140, 58), "lava")
	_add_hazard(Rect2(2470, 715, 190, 58), "lava")
	_add_hazard(Rect2(3440, 715, 190, 58), "lava")

	_add_checkpoint(Vector2(2130, 610))
	_add_enemy(Vector2(800, 620), 670, 920, false, 95)
	_add_enemy(Vector2(2210, 610), 2070, 2440, false, 105)
	_add_enemy(Vector2(2830, 545), 2700, 2960, false, 110)

	for point in [
		Vector2(235, 610), Vector2(345, 610), Vector2(720, 540), Vector2(855, 540),
		Vector2(1180, 495), Vector2(1300, 495), Vector2(1600, 520), Vector2(1775, 420),
		Vector2(2165, 535), Vector2(2350, 535), Vector2(2760, 470), Vector2(2900, 470),
		Vector2(3240, 470), Vector2(3360, 400), Vector2(3800, 565), Vector2(3970, 565)
	]:
		_add_collectible(point, "sweet")
	_add_collectible(Vector2(1800, 455), "energy")
	_add_collectible(Vector2(3340, 450), "energy")
	_add_collectible(Vector2(4020, 565), "heart")
	_add_collectible(Vector2(4070, 585), "can")


func _build_level_three() -> void:
	_add_world_label(Vector2(110, 485), "Planeta Congelado")
	_add_platform(Rect2(0, 680, 500, 96), true)
	_add_platform(Rect2(650, 625, 310, 64), true)
	_add_moving_platform(Rect2(1120, 610, 250, 48), Vector2(260, -110), 2.4, true)
	_add_platform(Rect2(1600, 560, 350, 64), true)
	_add_moving_platform(Rect2(2200, 650, 240, 48), Vector2(0, -190), 2.0, true)
	_add_platform(Rect2(2700, 590, 360, 64), true)
	_add_platform(Rect2(3340, 660, 380, 96), true)
	_add_platform(Rect2(3900, 650, 920, 96), true)
	_add_platform(Rect2(4700, 520, 160, 48), true)

	_add_hazard(Rect2(520, 735, 120, 54), "ice_spikes")
	_add_hazard(Rect2(1980, 735, 190, 54), "ice_spikes")
	_add_hazard(Rect2(3090, 735, 210, 54), "ice_spikes")

	_add_checkpoint(Vector2(3380, 660))
	_add_enemy(Vector2(780, 555), 660, 940, true, 95)
	_add_enemy(Vector2(1750, 490), 1620, 1930, false, 110)
	_add_enemy(Vector2(2880, 510), 2720, 3040, true, 105)
	_add_enemy(Vector2(3540, 585), 3360, 3700, true, 120)

	for point in [
		Vector2(230, 605), Vector2(350, 605), Vector2(720, 545), Vector2(870, 545),
		Vector2(1190, 510), Vector2(1390, 420), Vector2(1670, 485), Vector2(1875, 485),
		Vector2(2250, 470), Vector2(2410, 430), Vector2(2780, 515), Vector2(2980, 515),
		Vector2(3450, 585), Vector2(3640, 585), Vector2(4010, 575), Vector2(4190, 575)
	]:
		_add_collectible(point, "sweet")
	_add_collectible(Vector2(2440, 470), "energy")
	_add_collectible(Vector2(3660, 585), "heart")


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = spawn_position
	add_child(player)
	player.set_spawn(spawn_position)
	player.set_camera_limits(0, -260, world_width, level_bottom + 40)


func retry_from_checkpoint() -> void:
	GameState.revive_player()
	if player != null and is_instance_valid(player) and player.has_method("revive_from_checkpoint"):
		player.revive_from_checkpoint()


func _play_level_music() -> void:
	if DisplayServer.get_name() == "headless" or level_id != 1:
		return
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/music_pack/moonlit_vale.ogg")
	if music_player.stream != null and "loop" in music_player.stream:
		music_player.stream.loop = true
	music_player.volume_db = -10.0
	add_child(music_player)
	music_player.play()


func _add_tutorial_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)

	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.028, 0.05, 0.88)
	panel.position = Vector2(26, 92)
	panel.size = Vector2(700, 58)
	layer.add_child(panel)

	var title := Label.new()
	title.text = "DICA"
	title.position = Vector2(48, 102)
	title.size = Vector2(90, 22)
	title.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 16)
	layer.add_child(title)

	tutorial_hint_label = Label.new()
	tutorial_hint_label.position = Vector2(48, 126)
	tutorial_hint_label.size = Vector2(650, 22)
	tutorial_hint_label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8.ttf"))
	tutorial_hint_label.add_theme_font_size_override("font_size", 16)
	layer.add_child(tutorial_hint_label)
	_update_tutorial_hint()


func _update_tutorial_hint() -> void:
	if tutorial_hint_label == null:
		return
	var x: float = player.global_position.x
	if x < 680:
		tutorial_hint_label.text = "Use A/D ou setas para andar. Pegue os doces pelo caminho."
	elif x < 1180:
		tutorial_hint_label.text = "Pressione ESPACO para pular. Use W/S ou setas na escada."
	elif x < 1980:
		tutorial_hint_label.text = "No ar, pressione ESPACO de novo para fazer pulo duplo."
	elif x < 2680:
		tutorial_hint_label.text = "Use SHIFT para gastar energia e dar um dash para frente."
	elif x < 3560:
		tutorial_hint_label.text = "Slimes causam dano. Pule em cima deles para derrotar."
	elif x < 4300:
		tutorial_hint_label.text = "Ao tocar na bandeira, o checkpoint salva seu retorno."
	elif x < 5250:
		tutorial_hint_label.text = "Use pulo duplo e dash juntos para atravessar os espacos."
	else:
		tutorial_hint_label.text = "Pegue a lata de energetico no final para concluir a fase."


func _add_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -20
	add_child(layer)

	var texture_rect := TextureRect.new()
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.texture = _background_texture()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.modulate = _background_tint()
	layer.add_child(texture_rect)

	var scenery := Sprite2D.new()
	scenery.texture = _scenery_texture()
	scenery.position = Vector2(world_width * 0.5, 340)
	scenery.scale = Vector2(0.85, 0.85)
	scenery.modulate = Color(1, 1, 1, 0.58)
	add_child(scenery)


func _background_texture() -> Texture2D:
	match theme:
		"volcano":
			return load("res://assets/parallax/desert/desert_sky.png")
		"ice":
			return load("res://assets/parallax/forest/forest_sky.png")
		_:
			return load("res://assets/parallax/moon/moon_sky.png")


func _scenery_texture() -> Texture2D:
	match theme:
		"volcano":
			return load("res://assets/parallax/desert/desert_mountain.png")
		"ice":
			return load("res://assets/parallax/forest/forest_mountain.png")
		_:
			return load("res://assets/parallax/moon/moon_mid.png")


func _background_tint() -> Color:
	match theme:
		"volcano":
			return Color(1.0, 0.55, 0.45, 1.0)
		"ice":
			return Color(0.6, 0.8, 1.0, 1.0)
		_:
			return Color(0.7, 0.72, 1.0, 1.0)


func _add_platform(rect: Rect2, slippery := false) -> void:
	var platform := PLATFORM_SCRIPT.new()
	add_child(platform)
	platform.setup(rect.position, rect.size, theme, slippery)


func _add_upper_platform(rect: Rect2) -> void:
	var platform := PLATFORM_SCRIPT.new()
	add_child(platform)
	platform.setup(rect.position, rect.size, "moon_upper", false)


func _add_moving_platform(rect: Rect2, offset: Vector2, duration: float, slippery := false) -> void:
	var platform := MOVING_PLATFORM_SCRIPT.new()
	add_child(platform)
	platform.setup_moving(rect.position, rect.size, theme, offset, duration, slippery)


func _add_hazard(rect: Rect2, kind: String) -> void:
	var hazard := HAZARD_SCRIPT.new()
	add_child(hazard)
	hazard.setup(rect.position, rect.size, kind)


func _add_checkpoint(position_to_use: Vector2) -> void:
	var checkpoint := CHECKPOINT_SCRIPT.new()
	add_child(checkpoint)
	checkpoint.setup(position_to_use)


func _add_collectible(position_to_use: Vector2, kind: String) -> void:
	var collectible := COLLECTIBLE_SCRIPT.new()
	add_child(collectible)
	collectible.setup(position_to_use, kind, level_id)


func _add_enemy(position_to_use: Vector2, left: float, right: float, flying := false, speed := 80.0, variant := "green") -> void:
	var enemy := ENEMY_SCRIPT.new()
	add_child(enemy)
	enemy.setup(position_to_use, left, right, flying, speed, variant)


func _add_ladder(position_to_use: Vector2, tile_count: int) -> void:
	var ladder := LADDER_SCRIPT.new()
	add_child(ladder)
	ladder.setup(position_to_use, tile_count)


func _add_food_decor(position_to_use: Vector2, tile_name: String, scale := 2.6) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/kenney_food/Tiles/%s.png" % tile_name)
	sprite.position = position_to_use
	sprite.scale = Vector2(scale, scale)
	sprite.modulate = Color(1, 1, 1, 0.88)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = -1
	add_child(sprite)


func _add_boss() -> void:
	var boss = BOSS_SCENE.instantiate()
	boss.global_position = Vector2(4330, 650)
	add_child(boss)
	boss.setup(3970, 4680, player)
	boss.defeated.connect(_on_boss_defeated)
	_add_world_label(Vector2(3920, 485), "Dr. Vazio")


func _on_boss_defeated() -> void:
	_add_collectible(Vector2(4780, 470), "can")
	_add_world_label(Vector2(4470, 430), "A lata final apareceu")


func _add_world_label(position_to_use: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_to_use
	label.size = Vector2(460, 44)
	label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 1, 0.92)
	add_child(label)
