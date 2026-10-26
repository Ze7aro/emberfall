class_name HudFillBar
extends Control
## Track and fill stay separate: any value is drawn without baking in numbers.

var track_texture: Texture2D
var fill_texture: Texture2D
var ratio: float = 0.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)

func set_amount(current: float, maximum: float) -> void:
	ratio = current / maximum if maximum > 0.0 else 0.0

func _draw() -> void:
	if track_texture == null:
		return
	draw_texture_rect(track_texture, Rect2(Vector2.ZERO, size), false)
	if fill_texture == null or ratio <= 0.0:
		return
	var inset := Vector2(size.x * 0.045, size.y * 0.20)
	var available := size - inset * 2.0
	# Crop the full-width fill instead of squeezing it as its value changes.
	var destination := Rect2(inset, Vector2(available.x * ratio, available.y))
	var source := Rect2(Vector2.ZERO, Vector2(fill_texture.get_width() * ratio, fill_texture.get_height()))
	draw_texture_rect_region(fill_texture, destination, source)
