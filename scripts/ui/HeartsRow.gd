extends Control
class_name HeartsRow

## Renders a row of heart icons from an HP value expressed in half-heart
## units (2 units = 1 heart), used both by the in-run HUD and by the small
## world-space indicator over the player.

var current_units := 6
var max_units := 6
var heart_size := 18.0
var spacing := 4.0
var filled_color := Color("e65a5a")
var empty_color := Color("4a3f5c")

func set_hearts(current: int, max_val: int) -> void:
	current_units = current
	max_units = max_val
	var heart_count := int(ceil(max_units / 2.0))
	custom_minimum_size = Vector2(heart_count * (heart_size + spacing), heart_size)
	queue_redraw()

func _draw() -> void:
	draw_row(self, Vector2.ZERO, heart_size, spacing, current_units, max_units, filled_color, empty_color)

## Static so world-space nodes (Node2D, not just Control) can draw the same
## hearts directly in their own _draw() without instancing this scene.
static func draw_row(ci: CanvasItem, origin: Vector2, size: float, gap: float, current: int, max_val: int, filled: Color, empty: Color) -> void:
	var heart_count := int(ceil(max_val / 2.0))
	for i in heart_count:
		var state := "empty"
		if current >= (i + 1) * 2:
			state = "full"
		elif current >= i * 2 + 1:
			state = "half"
		var center := origin + Vector2(i * (size + gap) + size / 2.0, size / 2.0)
		_draw_heart(ci, center, size, state, filled, empty)

static func _draw_heart(ci: CanvasItem, center: Vector2, s: float, state: String, filled: Color, empty: Color) -> void:
	var pts := _heart_points(center, s * 0.55)
	if state == "empty":
		ci.draw_polyline(Array(pts) + [pts[0]], empty, 2.0)
		return
	if state == "half":
		# Clip to the left half by collapsing every point past the midline
		# onto it, instead of painting over with a guessed background color.
		var half_pts := PackedVector2Array()
		for p in pts:
			half_pts.append(Vector2(minf(p.x, center.x), p.y))
		ci.draw_colored_polygon(half_pts, filled)
		ci.draw_polyline(Array(pts) + [pts[0]], filled, 1.5)
		return
	ci.draw_colored_polygon(pts, filled)

static func _heart_points(center: Vector2, scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := 24
	for i in steps:
		var t := TAU * i / steps
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(center + Vector2(x, -y) * (scale / 16.0))
	return pts
