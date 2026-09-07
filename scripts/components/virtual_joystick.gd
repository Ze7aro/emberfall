extends Control
class_name EmberfallVirtualJoystick

signal direction_changed(value: Vector2)
var finger := -1
var direction := Vector2.ZERO
var radius := 64.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(170, 170)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			_update_direction(event.position)
		elif not event.pressed and event.index == finger:
			finger = -1
			_set_direction(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == finger:
		_update_direction(event.position)

func _update_direction(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	_set_direction(offset.limit_length(radius) / radius)

func _set_direction(value: Vector2) -> void:
	direction = value
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.02, 0.03, 0.10, 0.55))
	draw_arc(center, radius, 0, TAU, 48, Color(0.2, 0.95, 0.85, 0.55), 2)
	draw_circle(center + direction * radius, 28, Color(1.0, 0.47, 0.12, 0.8))
