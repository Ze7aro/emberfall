extends Control
class_name HeartsRow

const HEART_TEXTURE := preload("res://assets/ui/icons/heart.png")
## Dedicated art for the three states; when present it is drawn as-is (no
## tint, no outline pass). Otherwise the single heart is clipped and tinted.
const HEART_ART_DIR := "res://assets/ui/hud/"
static var _art := {}

## Renders a row of heart icons from an HP value expressed in half-heart
## units (2 units = 1 heart), used both by the in-run HUD and by the small
## world-space indicator over the player.

var current_units := 6
var max_units := 6
var heart_size := 18.0
var spacing := 4.0
var filled_color := Color.WHITE
var empty_color := Color(0.30, 0.26, 0.40, 0.85)

func _init() -> void:
	# The heart art is big and drawn small: smooth it instead of nearest.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func set_hearts(current: int, max_val: int) -> void:
	if current == current_units and max_val == max_units and custom_minimum_size.x > 0.0:
		return
	current_units = current
	max_units = max_val
	var heart_count := int(ceil(max_units / 2.0))
	custom_minimum_size = Vector2(heart_count * (heart_size + spacing), heart_size)
	size = custom_minimum_size
	queue_redraw()

func _draw() -> void:
	# Dark outline pass first so the hearts read over any floor or effect.
	draw_row(self, Vector2.ZERO, heart_size, spacing, current_units, max_units, filled_color, empty_color, true)

## Static so world-space nodes (Node2D, not just Control) can draw the same
## hearts directly in their own _draw() without instancing this scene.
## States: full, half (left half filled) and empty (dark silhouette).
static func _heart_art() -> Dictionary:
	if _art.is_empty():
		for state in ["full", "half", "empty"]:
			var path := HEART_ART_DIR + "heart_%s.png" % state
			if not ResourceLoader.exists(path):
				_art = {"missing": true}
				return _art
			_art[state] = load(path)
	return _art

static func draw_row(ci: CanvasItem, origin: Vector2, size: float, gap: float, current: int, max_val: int, filled: Color, empty: Color, outlined: bool = false) -> void:
	var heart_count := int(ceil(max_val / 2.0))
	var art := _heart_art()
	if not art.has("missing"):
		for i in heart_count:
			var rect := Rect2(origin + Vector2(i * (size + gap), 0), Vector2(size, size))
			var state := "full" if current >= (i + 1) * 2 else ("half" if current >= i * 2 + 1 else "empty")
			var tex: Texture2D = art[state]
			# Keep the art's aspect, centred in the square cell.
			var fit := minf(size / tex.get_width(), size / tex.get_height())
			var drawn := tex.get_size() * fit
			ci.draw_texture_rect(tex, Rect2(rect.position + (rect.size - drawn) * 0.5, drawn), false)
		return
	var tex_size := HEART_TEXTURE.get_size()
	for i in heart_count:
		var rect := Rect2(origin + Vector2(i * (size + gap), 0), Vector2(size, size))
		if outlined:
			for offset: Vector2 in [Vector2(-1.5, 0), Vector2(1.5, 0), Vector2(0, -1.5), Vector2(0, 1.5)]:
				ci.draw_texture_rect(HEART_TEXTURE, Rect2(rect.position + offset, rect.size), false, Color(0, 0, 0, 0.85))
		ci.draw_texture_rect(HEART_TEXTURE, rect, false, empty)
		if current >= (i + 1) * 2:
			ci.draw_texture_rect(HEART_TEXTURE, rect, false, filled)
		elif current >= i * 2 + 1:
			var half_rect := Rect2(rect.position, Vector2(size * 0.5, size))
			ci.draw_texture_rect_region(HEART_TEXTURE, half_rect, Rect2(Vector2.ZERO, Vector2(tex_size.x * 0.5, tex_size.y)), filled)
