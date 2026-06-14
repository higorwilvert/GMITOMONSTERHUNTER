extends StaticBody2D
class_name Platform

const TILE_SIZE := 48
const TERRAIN_TEXTURE := "res://assets/pixel_adventure/Terrain/Terrain (16x16).png"
const KENNEY_TILEMAP := "res://assets/kenney_platformer/tilemap.png"
const KENNEY_TILE_SIZE := 18
const KENNEY_TILE_GAP := 1
const KENNEY_TILE_COLUMNS := 20
const KENNEY_TILE_SCALE := Vector2(2.7, 2.7)
const SWEET_TOP_LEFT_TILE := "res://assets/kenney_food/Tiles/tile_0004.png"
const SWEET_TOP_TILE := "res://assets/kenney_food/Tiles/tile_0005.png"
const SWEET_TOP_ALT_TILE := "res://assets/kenney_food/Tiles/tile_0006.png"
const SWEET_TOP_RIGHT_TILE := "res://assets/kenney_food/Tiles/tile_0007.png"
const SWEET_FILL_LEFT_TILE := "res://assets/kenney_food/Tiles/tile_0052.png"
const SWEET_FILL_TILE := "res://assets/kenney_food/Tiles/tile_0053.png"
const SWEET_FILL_ALT_TILE := "res://assets/kenney_food/Tiles/tile_0054.png"
const SWEET_FILL_RIGHT_TILE := "res://assets/kenney_food/Tiles/tile_0055.png"
const SWEET_UPPER_LEFT_TILE := "res://assets/kenney_food/Tiles/tile_0036.png"
const SWEET_UPPER_TILE := "res://assets/kenney_food/Tiles/tile_0037.png"
const SWEET_UPPER_ALT_TILE := "res://assets/kenney_food/Tiles/tile_0038.png"
const SWEET_UPPER_RIGHT_TILE := "res://assets/kenney_food/Tiles/tile_0039.png"

var platform_size := Vector2.ZERO
var terrain_theme := "moon"
var slippery := false



func setup(top_left: Vector2, size: Vector2, theme: String, is_slippery := false) -> void:
	position = top_left + size * 0.5
	platform_size = size
	terrain_theme = theme
	slippery = is_slippery
	collision_layer = 1
	collision_mask = 0
	_build_collision()
	_build_visuals()

func is_slippery() -> bool:
	return slippery


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = platform_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	if terrain_theme == "moon":
		_build_sweet_moon_visuals()
		return
	if terrain_theme == "moon_upper":
		_build_sweet_upper_visuals()
		return
	if terrain_theme == "ice":
		_build_kenney_ice_visuals()
		return
	var texture := load(TERRAIN_TEXTURE)
	var region := _theme_region()
	var cols := int(ceil(platform_size.x / TILE_SIZE))
	var rows := int(ceil(platform_size.y / TILE_SIZE))
	for y in range(rows):
		for x in range(cols):
			var tile := Sprite2D.new()
			tile.texture = texture
			tile.region_enabled = true
			tile.region_rect = region
			tile.scale = Vector2(3, 3)
			tile.position = Vector2(
				-platform_size.x * 0.5 + TILE_SIZE * 0.5 + x * TILE_SIZE,
				-platform_size.y * 0.5 + TILE_SIZE * 0.5 + y * TILE_SIZE
			)
			tile.modulate = _theme_tint()
			add_child(tile)


func _build_sweet_moon_visuals() -> void:
	var cols := int(ceil(platform_size.x / TILE_SIZE))
	var rows := int(ceil(platform_size.y / TILE_SIZE))
	for y in range(rows):
		for x in range(cols):
			var tile := Sprite2D.new()
			tile.texture = load(_sweet_tile_path(x, y, cols))
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.scale = Vector2(2.7, 2.7)
			tile.position = Vector2(
				-platform_size.x * 0.5 + TILE_SIZE * 0.5 + x * TILE_SIZE,
				-platform_size.y * 0.5 + TILE_SIZE * 0.5 + y * TILE_SIZE
			)
			tile.modulate = Color(1.0, 0.94, 0.98, 1.0)
			add_child(tile)


func _build_sweet_upper_visuals() -> void:
	var cols := int(ceil(platform_size.x / TILE_SIZE))
	var rows := int(ceil(platform_size.y / TILE_SIZE))
	for y in range(rows):
		for x in range(cols):
			var tile := Sprite2D.new()
			tile.texture = load(_sweet_upper_tile_path(x, cols))
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.scale = Vector2(2.7, 2.7)
			tile.position = Vector2(
				-platform_size.x * 0.5 + TILE_SIZE * 0.5 + x * TILE_SIZE,
				-platform_size.y * 0.5 + TILE_SIZE * 0.5 + y * TILE_SIZE
			)
			tile.modulate = Color(1.0, 0.94, 0.98, 1.0)
			add_child(tile)


func _build_kenney_ice_visuals() -> void:
	var texture: Texture2D = load(KENNEY_TILEMAP)
	var cols: int = int(ceil(platform_size.x / TILE_SIZE))
	var rows: int = max(1, int(round(platform_size.y / TILE_SIZE)))
	for y in range(rows):
		for x in range(cols):
			var tile := Sprite2D.new()
			tile.texture = texture
			tile.region_enabled = true
			tile.region_rect = _kenney_tile_region(_ice_ground_tile(x, y, cols, rows))
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.scale = KENNEY_TILE_SCALE
			tile.position = Vector2(
				-platform_size.x * 0.5 + TILE_SIZE * 0.5 + x * TILE_SIZE,
				-platform_size.y * 0.5 + TILE_SIZE * 0.5 + y * TILE_SIZE
			)
			add_child(tile)


func _sweet_tile_path(x: int, y: int, cols: int) -> String:
	if cols <= 1:
		return SWEET_TOP_TILE if y == 0 else SWEET_FILL_TILE
	if y == 0:
		if x == 0:
			return SWEET_TOP_LEFT_TILE
		if x == cols - 1:
			return SWEET_TOP_RIGHT_TILE
		return SWEET_TOP_ALT_TILE if x % 2 == 0 else SWEET_TOP_TILE
	if x == 0:
		return SWEET_FILL_LEFT_TILE
	if x == cols - 1:
		return SWEET_FILL_RIGHT_TILE
	return SWEET_FILL_ALT_TILE if (x + y) % 2 == 0 else SWEET_FILL_TILE


func _sweet_upper_tile_path(x: int, cols: int) -> String:
	if cols <= 1:
		return SWEET_UPPER_TILE
	if x == 0:
		return SWEET_UPPER_LEFT_TILE
	if x == cols - 1:
		return SWEET_UPPER_RIGHT_TILE
	return SWEET_UPPER_ALT_TILE if x % 2 == 0 else SWEET_UPPER_TILE


func _theme_region() -> Rect2:
	match terrain_theme:
		"volcano":
			return Rect2(0, 64, 16, 16)
		"ice":
			return Rect2(128, 64, 16, 16)
		"metal":
			return Rect2(0, 0, 16, 16)
		_:
			return Rect2(0, 0, 16, 16)


func _theme_tint() -> Color:
	match terrain_theme:
		"volcano":
			return Color(1.0, 0.68, 0.54, 1.0)
		"ice":
			return Color(0.78, 0.95, 1.0, 1.0)
		"moon":
			return Color(0.9, 0.92, 1.0, 1.0)
		_:
			return Color.WHITE


func _ice_ground_tile(x: int, y: int, cols: int, rows: int) -> int:
	if y == 0:
		return _tile_from_columns(x, cols, [80, 81, 82, 83])
	if y == rows - 1:
		return _tile_from_columns(x, cols, [140, 141, 142, 143])
	return _tile_from_columns(x, cols, [120, 121, 122, 123])


func _tile_from_columns(x: int, cols: int, tile_ids: Array[int]) -> int:
	if cols <= 1:
		return tile_ids[1]
	if x == 0:
		return tile_ids[0]
	if x == cols - 1:
		return tile_ids[3]
	return tile_ids[2] if x % 2 == 0 else tile_ids[1]


func _kenney_tile_region(tile_id: int) -> Rect2:
	var col: int = tile_id % KENNEY_TILE_COLUMNS
	var row: int = int(tile_id / KENNEY_TILE_COLUMNS)
	var step: int = KENNEY_TILE_SIZE + KENNEY_TILE_GAP
	return Rect2(col * step, row * step, KENNEY_TILE_SIZE, KENNEY_TILE_SIZE)
	
