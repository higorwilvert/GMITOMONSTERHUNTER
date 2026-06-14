extends Area2D
class_name Hazard

const KENNEY_TILEMAP := "res://assets/kenney_platformer/tilemap.png"
const KENNEY_TILE_SIZE := 18
const KENNEY_TILE_GAP := 1
const KENNEY_TILE_COLUMNS := 20
const KENNEY_TILE_SCALE := Vector2(2.7, 2.7)
const ICE_SPIKES_TILE := 68
const ICE_BASE_TILE := 154

var hazard_size := Vector2.ZERO
var hazard_type := "spikes"


func setup(top_left: Vector2, size: Vector2, kind: String) -> void:
	position = top_left + size * 0.5
	hazard_size = size
	hazard_type = kind
	collision_layer = 8
	collision_mask = 2
	add_to_group("hazards")
	_build_collision()
	_build_visuals()
	body_entered.connect(_on_body_entered)


func _build_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = hazard_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)


func _build_visuals() -> void:
	if hazard_type == "ice_spikes":
		_build_ice_spikes()
		return
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-hazard_size.x * 0.5, -hazard_size.y * 0.5),
		Vector2(hazard_size.x * 0.5, -hazard_size.y * 0.5),
		Vector2(hazard_size.x * 0.5, hazard_size.y * 0.5),
		Vector2(-hazard_size.x * 0.5, hazard_size.y * 0.5)
	])
	match hazard_type:
		"lava":
			poly.color = Color(1.0, 0.22, 0.02, 0.9)
		"ice_spikes":
			poly.color = Color(0.45, 0.95, 1.0, 0.85)
		_:
			poly.color = Color(0.9, 0.85, 0.95, 0.85)
	add_child(poly)


func _build_ice_spikes() -> void:
	var texture: Texture2D = load(KENNEY_TILEMAP)
	var spike_width := 48.0
	var cols: int = int(ceil(hazard_size.x / spike_width))
	for i in range(cols):
		var x: float = -hazard_size.x * 0.5 + spike_width * 0.5 + i * spike_width
		_add_kenney_tile(texture, ICE_BASE_TILE, Vector2(x, hazard_size.y * 0.5 - 10.0), Color(0.88, 0.98, 1.0, 1.0))
		_add_kenney_tile(texture, ICE_SPIKES_TILE, Vector2(x, hazard_size.y * 0.5 - 30.0), Color(0.8, 0.96, 1.0, 1.0))


func _add_kenney_tile(texture: Texture2D, tile_id: int, local_position: Vector2, tint := Color.WHITE) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = _kenney_tile_region(tile_id)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = KENNEY_TILE_SCALE
	sprite.position = local_position
	sprite.modulate = tint
	add_child(sprite)


func _kenney_tile_region(tile_id: int) -> Rect2:
	var col: int = tile_id % KENNEY_TILE_COLUMNS
	var row: int = int(tile_id / KENNEY_TILE_COLUMNS)
	var step: int = KENNEY_TILE_SIZE + KENNEY_TILE_GAP
	return Rect2(col * step, row * step, KENNEY_TILE_SIZE, KENNEY_TILE_SIZE)


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
