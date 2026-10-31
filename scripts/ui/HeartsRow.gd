extends Control
class_name HeartsRow

const HEART_TEXTURE := preload("res://assets/ui/pixel_simple_v1/icons/heart.png")

## Renders a row of heart icons from an HP value expressed in half-heart
## units (2 units = 1 heart), used both by the in-run HUD and by the small
## world-space indicator over the player.

var current_units := 6
var max_units := 6
var heart_size := 18.0
var spacing := 4.0
var filled_color := Color.WHITE
var empty_color := Color(0.30, 0.26, 0.40, 0.85)

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
static func draw_row(ci: CanvasItem, origin: Vector2, size: float, gap: float, current: int, max_val: int, filled: Color, empty: Color, outlined: bool = false) -> void:
	var heart_count := int(ceil(max_val / 2.0))
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
