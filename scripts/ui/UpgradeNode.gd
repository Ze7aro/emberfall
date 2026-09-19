extends Control
class_name UpgradeNode

## A single node in the permanent-upgrades tree: a custom-drawn shape whose
## color/outline reflect whether it's purchased, available to buy, or still
## locked behind the node above it in its branch.

signal pressed

enum Shape { CIRCLE, DIAMOND, HEX }

const STATE_LOCKED := "locked"
const STATE_AVAILABLE := "available"
const STATE_PURCHASED := "purchased"

var shape: int = Shape.CIRCLE
var state: String = STATE_LOCKED
var is_milestone: bool = false
var accent_color: Color = Color("20e6bd")

func _ready() -> void:
	custom_minimum_size = Vector2(88, 88) if is_milestone else Vector2(60, 60)

func set_state(value: String) -> void:
	state = value
	mouse_filter = Control.MOUSE_FILTER_IGNORE if state == STATE_LOCKED else Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if state == STATE_LOCKED:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()

func _fill_color() -> Color:
	match state:
		STATE_PURCHASED: return accent_color
		STATE_AVAILABLE: return accent_color.darkened(0.35)
		_: return Color("241c30")

func _outline_color() -> Color:
	return accent_color if state != STATE_LOCKED else Color("4a3f5c")

func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 4.0
	var fill := _fill_color()
	var outline := _outline_color()
	var width := 3.0 if not is_milestone else 4.0
	match shape:
		Shape.CIRCLE:
			draw_circle(center, radius, fill)
			draw_arc(center, radius, 0.0, TAU, 40, outline, width)
		Shape.DIAMOND:
			var pts := PackedVector2Array([
				center + Vector2(0, -radius), center + Vector2(radius, 0),
				center + Vector2(0, radius), center + Vector2(-radius, 0),
			])
			draw_colored_polygon(pts, fill)
			draw_polyline(Array(pts) + [pts[0]], outline, width)
		Shape.HEX:
			var hex_pts := PackedVector2Array()
			for i in 6:
				var angle := TAU / 6.0 * i - PI / 2.0
				hex_pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
			draw_colored_polygon(hex_pts, fill)
			draw_polyline(Array(hex_pts) + [hex_pts[0]], outline, width)
	if state == STATE_LOCKED:
		var lock_size := radius * 0.7
		draw_rect(Rect2(center.x - lock_size / 2, center.y - lock_size * 0.1, lock_size, lock_size * 0.6), Color("6a5f7a"), false, 2.0)
		draw_arc(center + Vector2(0, -lock_size * 0.15), lock_size * 0.32, PI, TAU, 16, Color("6a5f7a"), 2.0)
