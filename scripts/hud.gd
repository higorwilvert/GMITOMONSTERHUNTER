extends CanvasLayer

const FONT := "res://assets/fonts/PixelOperator8.ttf"
const FONT_BOLD := "res://assets/fonts/PixelOperator8-Bold.ttf"
const UI_ALL := "res://assets/pixel_ui_pack_3/All.png"
const UI_00 := "res://assets/pixel_ui_pack_3/00.png"

var health_label: Label
var health_fill: ColorRect
var score_label: Label
var level_label: Label
var dash_fill: ColorRect
var dash_value_label: Label
var health_fill_width := 108.0
var dash_fill_width := 204.0


func _ready() -> void:
	layer = 10
	_build_ui()
	GameState.health_changed.connect(_on_health_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.energy_changed.connect(_on_energy_changed)
	GameState.level_changed.connect(_on_level_changed)
	_on_health_changed(GameState.health, GameState.max_health)
	_on_score_changed(GameState.score)
	_on_energy_changed(GameState.dash_energy, GameState.max_dash_energy)
	_on_level_changed(GameState.current_level, GameState.get_level_name())


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var bar_shadow := ColorRect.new()
	bar_shadow.color = Color(0, 0, 0, 0.38)
	bar_shadow.position = Vector2(0, 78)
	bar_shadow.size = Vector2(1280, 8)
	root.add_child(bar_shadow)

	var bar := ColorRect.new()
	bar.color = Color(0.018, 0.021, 0.04, 0.96)
	bar.position = Vector2(0, 0)
	bar.size = Vector2(1280, 78)
	root.add_child(bar)

	var top_line := ColorRect.new()
	top_line.color = Color(0.33, 0.75, 1.0, 0.95)
	top_line.position = Vector2(0, 0)
	top_line.size = Vector2(1280, 3)
	root.add_child(top_line)

	var bottom_line := ColorRect.new()
	bottom_line.color = Color(0.7, 0.35, 1.0, 1.0)
	bottom_line.position = Vector2(0, 74)
	bottom_line.size = Vector2(1280, 4)
	root.add_child(bottom_line)

	_build_health_panel(root)
	_build_score_panel(root)
	_build_dash_panel(root)
	_build_level_panel(root)


func _build_health_panel(root: Control) -> void:
	var panel := _make_panel(Vector2(16, 11), Vector2(286, 54), Color(0.07, 0.09, 0.17, 0.96), Color(0.31, 0.48, 0.83, 1.0))
	root.add_child(panel)

	var title := _make_label(Vector2(0, 5), Vector2(286, 18), "GMITO", 14, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var label := _make_label(Vector2(18, 32), Vector2(50, 17), "VIDA", 11, true)
	panel.add_child(label)

	var frame := TextureRect.new()
	frame.texture = _atlas(UI_00, Rect2(0, 32, 54, 14))
	frame.position = Vector2(74, 29)
	frame.size = Vector2(128, 22)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	panel.add_child(frame)

	var fill_back := ColorRect.new()
	fill_back.color = Color(0.06, 0.08, 0.11, 1.0)
	fill_back.position = Vector2(84, 35)
	fill_back.size = Vector2(health_fill_width, 10)
	panel.add_child(fill_back)

	health_fill = ColorRect.new()
	health_fill.color = Color(0.35, 1.0, 0.46, 1.0)
	health_fill.position = fill_back.position
	health_fill.size = fill_back.size
	panel.add_child(health_fill)

	health_label = _make_label(Vector2(212, 31), Vector2(52, 19), "", 13, true)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(health_label)


func _build_score_panel(root: Control) -> void:
	var panel := _make_panel(Vector2(318, 11), Vector2(226, 54), Color(0.08, 0.075, 0.15, 0.96), Color(0.88, 0.55, 0.32, 1.0))
	root.add_child(panel)

	var sweet_icon := TextureRect.new()
	sweet_icon.texture = load("res://assets/kenney_food/Tiles/tile_0056.png")
	sweet_icon.position = Vector2(334, 25)
	sweet_icon.size = Vector2(32, 32)
	sweet_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sweet_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	root.add_child(sweet_icon)

	var label := _make_label(Vector2(374, 18), Vector2(138, 18), "DOCES", 13, true)
	root.add_child(label)

	score_label = _make_label(Vector2(374, 40), Vector2(138, 20), "", 16, true)
	root.add_child(score_label)


func _build_dash_panel(root: Control) -> void:
	var panel := _make_panel(Vector2(560, 11), Vector2(330, 54), Color(0.055, 0.08, 0.14, 0.96), Color(0.28, 0.8, 0.95, 1.0))
	root.add_child(panel)

	var title := _make_label(Vector2(578, 18), Vector2(82, 18), "DASH", 13, true)
	root.add_child(title)

	var frame := TextureRect.new()
	frame.texture = _atlas(UI_00, Rect2(0, 32, 54, 14))
	frame.position = Vector2(652, 32)
	frame.size = Vector2(222, 24)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(frame)

	var fill_back := ColorRect.new()
	fill_back.color = Color(0.06, 0.08, 0.11, 1.0)
	fill_back.position = Vector2(661, 38)
	fill_back.size = Vector2(dash_fill_width, 11)
	root.add_child(fill_back)

	dash_fill = ColorRect.new()
	dash_fill.color = Color(0.3, 0.88, 1.0, 1.0)
	dash_fill.position = fill_back.position
	dash_fill.size = Vector2(dash_fill_width, 11)
	root.add_child(dash_fill)

	dash_value_label = _make_label(Vector2(578, 39), Vector2(60, 18), "", 14, false)
	root.add_child(dash_value_label)


func _build_level_panel(root: Control) -> void:
	var panel := _make_panel(Vector2(906, 11), Vector2(358, 54), Color(0.07, 0.06, 0.12, 0.96), Color(0.68, 0.42, 1.0, 1.0))
	root.add_child(panel)

	var stage := _make_label(Vector2(925, 18), Vector2(318, 18), "FASE", 13, true)
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(stage)

	level_label = _make_label(Vector2(925, 39), Vector2(318, 20), "", 16, true)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(level_label)


func _make_panel(pos: Vector2, size: Vector2, bg: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_label(pos: Vector2, size: Vector2, text: String, font_size: int, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_override("font", load(FONT_BOLD if bold else FONT))
	label.add_theme_font_size_override("font_size", font_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _atlas(path: String, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(path)
	texture.region = region
	return texture


func _on_health_changed(value: int, max_value: int) -> void:
	health_label.text = "%d/%d" % [value, max_value]
	var ratio: float = clamp(float(value) / float(max_value), 0.0, 1.0)
	health_fill.size = Vector2(health_fill_width * ratio, health_fill.size.y)
	if ratio <= 0.34:
		health_fill.color = Color(1.0, 0.25, 0.28, 1.0)
	elif ratio <= 0.67:
		health_fill.color = Color(1.0, 0.76, 0.22, 1.0)
	else:
		health_fill.color = Color(0.35, 1.0, 0.46, 1.0)


func _on_score_changed(value: int) -> void:
	score_label.text = "%03d" % value


func _on_energy_changed(value: float, max_value: float) -> void:
	var ratio: float = clamp(value / max_value, 0.0, 1.0)
	dash_fill.size = Vector2(dash_fill_width * ratio, dash_fill.size.y)
	dash_value_label.text = "%d%%" % int(round(ratio * 100.0))
	if ratio <= 0.25:
		dash_fill.color = Color(1.0, 0.25, 0.28, 1.0)
	elif ratio <= 0.55:
		dash_fill.color = Color(1.0, 0.76, 0.22, 1.0)
	else:
		dash_fill.color = Color(0.3, 0.88, 1.0, 1.0)


func _on_level_changed(_level_id: int, level_name: String) -> void:
	level_label.text = level_name
