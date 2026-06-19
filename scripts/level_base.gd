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
const SPIKE_TRAP_SCRIPT := preload("res://scripts/spike_trap.gd")
const TURRET_SCRIPT := preload("res://scripts/enemy_turret.gd")

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
	if not GameState.music_enabled_changed.is_connected(_on_music_enabled_changed):
		GameState.music_enabled_changed.connect(_on_music_enabled_changed)
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
			world_width = 7600
			level_bottom = 1040
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
	_add_world_label(Vector2(110, 480), "Planeta Vulcânico")
	_fix_level_two_background()
	_add_hazard(Rect2(0, 715, 4300, 500), "lava")
	_add_lava_particles(0, 4300, 715)
	_add_spike_trap(Vector2(750,  372), 96,  2.0, 1.0)
	_add_spike_trap(Vector2(1250, 332), 144, 2.5, 1.2)
	_add_spike_trap(Vector2(1780, 342), 96,  1.8, 0.9)
	_add_spike_trap(Vector2(2280, 322), 144, 3.0, 1.5)
	_add_spike_trap(Vector2(2850, 332), 96,  2.0, 1.0)
	_add_spike_trap(Vector2(3400, 342), 144, 1.5, 0.8)
	_add_platform(Rect2(0,    680, 500, 96))
	_add_platform(Rect2(650,  620, 300, 64))
	_add_platform(Rect2(1110, 570, 300, 64))
	_add_moving_platform(Rect2(1530, 625, 260, 48), Vector2(260, -120), 2.4)
	_add_platform(Rect2(2050, 610, 420, 64))
	_add_platform(Rect2(2680, 545, 290, 64))
	_add_moving_platform(Rect2(3180, 630, 250, 48), Vector2(0, -180), 2.1)
	_add_platform(Rect2(3650, 640, 500, 96))
	_add_platform(Rect2(700,  420, 300, 48))
	_add_platform(Rect2(1150, 380, 280, 48))
	_add_platform(Rect2(1700, 390, 260, 48))
	_add_platform(Rect2(2200, 370, 300, 48))
	_add_platform(Rect2(2750, 380, 260, 48))
	_add_platform(Rect2(3250, 390, 280, 48))
	_add_platform(Rect2(3750, 380, 300, 48))
	_add_ladder(Vector2(650,  410), 5)
	_add_ladder(Vector2(1110, 350), 5)
	_add_ladder(Vector2(2150, 370), 5)
	_add_ladder(Vector2(3700, 370), 6)
	_add_checkpoint(Vector2(2130, 610))
	_add_platform(Rect2(2378,  20,  1000, 40)) 
	_add_ladder(Vector2(2330, 20), 6)
	_add_platform(Rect2(3378, -300,  60,  350))  
	_add_spike_trap(Vector2(2878, -28), 96, 2.0, 1.0) 
	_add_turret(Vector2(3300, 20), 1.8, 600.0)  
	_add_collectible(Vector2(3320, -30), "heart")  
	_add_enemy(Vector2(250,  640), 20,   480,  false, 90,  "green")
	_add_enemy(Vector2(750,  580), 660,  930,  false, 95,  "purple")
	_add_enemy(Vector2(1200, 530), 1120, 1360, false, 100, "green")
	_add_enemy(Vector2(2200, 570), 2060, 2460, false, 105, "purple")
	_add_enemy(Vector2(2800, 505), 2690, 2960, false, 108, "green")
	_add_enemy(Vector2(3800, 600), 3660, 4130, false, 112, "purple")
	_add_enemy(Vector2(800,  380), 710,  980,  false, 95,  "purple")
	_add_enemy(Vector2(1280, 340), 1160, 1420, false, 100, "green")
	_add_enemy(Vector2(2300, 330), 2210, 2490, false, 105, "purple")
	_add_enemy(Vector2(3350, 350), 3260, 3520, false, 110, "green")
	_add_enemy(Vector2(3850, 340), 3760, 4040, false, 115, "purple")
	_add_enemy(Vector2(1000, 300), 700,  1400, true, 100, "bat")
	_add_enemy(Vector2(2500, 290), 2100, 2950, true, 108, "bat")
	_add_enemy(Vector2(3500, 300), 3200, 3900, true, 115, "bat")
	for point in [
		Vector2(150,  610), Vector2(420,  610),
		Vector2(750,  550), Vector2(1050, 550),
		Vector2(1200, 500), Vector2(1500, 500),
		Vector2(1650, 350), Vector2(1950, 350),
		Vector2(2150, 540), Vector2(2450, 540),
		Vector2(2250, 330), Vector2(2600, 330),
		Vector2(2750, 475), Vector2(3050, 475),
		Vector2(3300, 350), Vector2(3600, 350),
		Vector2(3720, 570), Vector2(4000, 570),
		Vector2(3850, 340), Vector2(4080, 340)
	]:
		_add_collectible(point, "sweet")
	_add_collectible(Vector2(1750, 350), "energy")
	_add_collectible(Vector2(3200, 350), "energy")
	_add_collectible(Vector2(3950, 570), "heart")


func _build_level_three() -> void:
	_add_world_label(Vector2(110, 485), "Planeta Congelado")
	_add_world_label(Vector2(4050, 505), "Ventos frios e plataformas moveis")
	_add_world_label(Vector2(6180, 500), "Arena do Dr. Vazio")

	_add_platform(Rect2(0, 680, 760, 280), true)
	_add_platform(Rect2(980, 700, 650, 260), true)
	_add_platform(Rect2(1920, 680, 600, 280), true)
	_add_platform(Rect2(2820, 690, 720, 270), true)
	_add_platform(Rect2(3920, 670, 640, 290), true)
	_add_platform(Rect2(5600, 690, 500, 270), true)
	_add_platform(Rect2(6260, 680, 1180, 280), true)

	_add_platform(Rect2(760, 420, 760, 52), true)
	_add_platform(Rect2(1680, 405, 760, 52), true)
	_add_platform(Rect2(2920, 420, 760, 52), true)
	_add_platform(Rect2(4380, 390, 700, 52), true)
	_add_platform(Rect2(5850, 430, 360, 52), true)

	_add_moving_platform(Rect2(1620, 590, 260, 48), Vector2(220, -120), 2.35, true)
	_add_moving_platform(Rect2(2520, 610, 250, 48), Vector2(0, -170), 2.2, true)
	_add_moving_platform(Rect2(3600, 570, 260, 48), Vector2(260, -125), 2.4, true)
	_add_moving_platform(Rect2(5080, 610, 260, 48), Vector2(280, -150), 2.15, true)

	_add_ladder(Vector2(705, 420), 6)
	_add_ladder(Vector2(1625, 405), 7)
	_add_ladder(Vector2(2865, 420), 6)
	_add_ladder(Vector2(4325, 390), 7)

	_add_hazard(Rect2(780, 780, 180, 70), "ice_spikes")
	_add_hazard(Rect2(1660, 790, 230, 70), "ice_spikes")
	_add_hazard(Rect2(2540, 790, 260, 70), "ice_spikes")
	_add_hazard(Rect2(3560, 785, 340, 70), "ice_spikes")
	_add_hazard(Rect2(5100, 795, 460, 70), "ice_spikes")
	_add_hazard(Rect2(6105, 780, 145, 70), "ice_spikes")

	_add_checkpoint(Vector2(2910, 690))
	_add_checkpoint(Vector2(5650, 690))

	_add_enemy(Vector2(520, 680), 100, 720, false, 92, "purple")
	_add_enemy(Vector2(1220, 420), 800, 1500, false, 88, "green")
	_add_enemy(Vector2(1440, 700), 1020, 1600, false, 108, "purple")
	_add_enemy(Vector2(2140, 680), 1940, 2480, false, 112, "green")
	_add_enemy(Vector2(2320, 405), 1710, 2420, false, 105, "purple")
	_add_enemy(Vector2(3190, 690), 2850, 3520, false, 118, "purple")
	_add_enemy(Vector2(3440, 420), 2960, 3660, false, 110, "green")
	_add_enemy(Vector2(4270, 670), 3950, 4540, false, 124, "purple")
	_add_enemy(Vector2(4720, 390), 4410, 5060, false, 112, "green")
	_add_enemy(Vector2(5860, 690), 5620, 6080, false, 128, "purple")
	_add_enemy(Vector2(1040, 330), 790, 1510, true, 100, "bat")
	_add_enemy(Vector2(2030, 310), 1700, 2420, true, 112, "bat")
	_add_enemy(Vector2(3060, 315), 2860, 3670, true, 116, "bat")
	_add_enemy(Vector2(4140, 520), 3940, 4560, true, 118, "bat")
	_add_enemy(Vector2(5300, 500), 5070, 5580, true, 126, "bat")

	for point in [
		Vector2(250, 610), Vector2(420, 610), Vector2(620, 610),
		Vector2(850, 350), Vector2(1040, 350), Vector2(1320, 350),
		Vector2(1110, 630), Vector2(1340, 630), Vector2(1560, 630),
		Vector2(1740, 335), Vector2(1940, 335), Vector2(2220, 335),
		Vector2(1990, 610), Vector2(2220, 610), Vector2(2440, 610),
		Vector2(2640, 500), Vector2(2860, 610), Vector2(3130, 610),
		Vector2(3020, 350), Vector2(3300, 350), Vector2(3600, 350),
		Vector2(3980, 600), Vector2(4260, 600), Vector2(4520, 600),
		Vector2(4470, 320), Vector2(4780, 320), Vector2(5040, 320),
		Vector2(5220, 500), Vector2(5630, 620), Vector2(5900, 620),
		Vector2(5910, 360), Vector2(6100, 360), Vector2(6350, 610),
		Vector2(7100, 610), Vector2(7320, 610)
	]:
		_add_collectible(point, "sweet")
	_add_collectible(Vector2(1510, 350), "energy")
	_add_collectible(Vector2(3710, 350), "energy")
	_add_collectible(Vector2(6040, 360), "energy")
	_add_collectible(Vector2(5740, 620), "heart")


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
	if DisplayServer.get_name() == "headless":
		return
	var music_path := _level_music_path()
	if music_path.is_empty():
		return
	music_player = AudioStreamPlayer.new()
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.stream = load(music_path)
	if music_player.stream != null and "loop" in music_player.stream:
		music_player.stream.loop = true
	music_player.volume_db = -10.0
	add_child(music_player)
	if GameState.music_enabled:
		music_player.play()


func _level_music_path() -> String:
	match level_id:
		1:
			return "res://assets/music_pack/moonlit_vale.ogg"
		2:
			return "res://assets/music_pack/legends_of_the_flame.ogg"
		3:
			return "res://assets/music_pack/frostbound_path.ogg"
		_:
			return ""


func _on_music_enabled_changed(enabled: bool) -> void:
	if music_player == null:
		return
	if enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()


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
			return 
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


@warning_ignore("shadowed_variable_base_class")
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
	boss.global_position = Vector2(6820, 680)
	add_child(boss)
	boss.setup(6360, 7240, player, 780.0)
	boss.defeated.connect(_on_boss_defeated)
	_add_world_label(Vector2(6540, 500), "Dr. Vazio")

func _on_boss_defeated() -> void:
	_add_collectible(Vector2(7300, 610), "can")
	_add_world_label(Vector2(6940, 500), "A lata final apareceu")

func _add_world_label(position_to_use: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = position_to_use
	label.size = Vector2(460, 44)
	label.add_theme_font_override("font", load("res://assets/fonts/PixelOperator8-Bold.ttf"))
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 1, 0.92)
	add_child(label)
	
func _add_spike_trap(top_left: Vector2, width: float, interval := 2.0, duration := 1.2) -> void:
	var trap := SPIKE_TRAP_SCRIPT.new()
	add_child(trap)
	trap.setup(top_left, Vector2(width, 48), interval, duration)

func _add_lava_particles(x: float, width: float, y: float) -> void:
	var particles := GPUParticles2D.new()
	particles.position = Vector2(x + width * 0.5, y)
	particles.amount = int(width / 8)
	particles.lifetime = 1.5
	particles.explosiveness = 0.0
	particles.randomness = 0.8
	particles.z_index = -1
	particles.one_shot = false
	particles.emitting = true
	particles.visibility_rect = Rect2(-width * 0.5, -300, width, 400)
	@warning_ignore("shadowed_variable_base_class")
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(width * 0.5, 4, 0)
	material.direction = Vector3(0, -1, 0)
	material.spread = 18.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 2.5
	material.scale_max = 5.5
	material.color = Color(1.0, 0.45, 0.0, 0.85)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.0, 1.0))
	gradient.set_color(1, Color(0.8, 0.05, 0.0, 0.0))
	var grad_texture := GradientTexture1D.new()
	grad_texture.gradient = gradient
	material.color_ramp = grad_texture
	particles.process_material = material
	add_child(particles)

func _fix_level_two_background() -> void:
	# Camada de fundo (ceu vulcanico cobrindo a faixa preta)
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -25
	add_child(bg_layer)

	var sky := ColorRect.new()
	sky.color = Color(0.18, 0.08, 0.06, 1.0)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_layer.add_child(sky)

	# Cenario de montanha
	var layer := CanvasLayer.new()
	layer.layer = -19
	add_child(layer)

	var scenery := Sprite2D.new()
	scenery.texture = load("res://assets/parallax/desert/desert_mountain.png")
	scenery.position = Vector2(640, 340)
	scenery.scale = Vector2(1.4, 1.4)
	scenery.modulate = Color(1.0, 0.55, 0.45, 0.7)
	layer.add_child(scenery)

	# Cobre o chao cinza com lava
	var floor_cover := ColorRect.new()
	floor_cover.color = Color(0.72, 0.08, 0.0, 1.0)
	floor_cover.position = Vector2(0, 710)
	floor_cover.size = Vector2(4300, 400)
	floor_cover.z_index = -2
	add_child(floor_cover)
	
func _add_turret(pos: Vector2, interval := 2.0, distance := 500.0) -> void:
	var turret := TURRET_SCRIPT.new()
	add_child(turret)
	turret.setup(pos, player, interval, distance)
	turret.defeated.connect(_on_turret_defeated_level_two)
	
func _on_turret_defeated_level_two() -> void:
	_add_collectible(Vector2(4100, 600), "can")
	_add_world_label(Vector2(3900, 500), "A lata apareceu!")
