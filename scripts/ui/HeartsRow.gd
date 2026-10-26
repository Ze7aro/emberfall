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
var empty_color := Color("4a3f5c")

func set_hearts(current: int, max_val: int) -> void:
	current_units = current
	max_units = max_val
	var heart_count := int(ceil(max_units / 2.0))
	custom_minimum_size = Vector2(heart_count * (heart_size + spacing), heart_size)
	queue_redraw()

## Static so world-space nodes (Node2D, not just Control) can draw the same
## hearts directly in their own _draw() without instancing this scene.
static func draw_row(ci: CanvasItem, origin: Vector2, size: float, gap: float, current: int, max_val: int, filled: Color, empty: Color) -> void:
	var heart_count := int(ceil(max_val / 2.0))
	for i in heart_count:
		var rect := Rect2(origin + Vector2(i * (size + gap), 0), Vector2(size, size))
		var state := 0
		if current >= (i + 1) * 2:
			state = 2
		elif current >= i * 2 + 1:
			state = 1
		if state == 0:
			ci.draw_texture_rect(HEART_TEXTURE, rect, false, Color(0.55, 0.52, 0.66, 0.62))
		elif state == 2:
			ci.draw_texture_rect(HEART_TEXTURE, rect, false, filled)
		else:
			ci.draw_texture_rect(HEART_TEXTURE, rect, false, Color(0.55, 0.52, 0.66, 0.62))
			var half_rect := Rect2(rect.position, Vector2(size * 0.5, size))
			ci.draw_texture_rect_region(HEART_TEXTURE, half_rect, Rect2(0, 0, 12, 24), filled)
