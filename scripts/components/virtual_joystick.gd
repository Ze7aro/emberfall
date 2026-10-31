extends Control
class_name EmberfallVirtualJoystick

## Covers the whole play area (invisible until touched) so the joystick can
## appear wherever the player puts their thumb, instead of a fixed corner.

signal direction_changed(value: Vector2)
var finger := -1
var direction := Vector2.ZERO
var radius := 64.0
var active := false
var touch_origin := Vector2.ZERO

var knob_radius := 23.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var joystick_scale: float = GameState.joystick_scale()
	radius *= joystick_scale
	knob_radius *= joystick_scale

## If the OS suspends the app mid-drag (a call, the home button, a
## notification), it never delivers the matching "finger lifted" touch event
## — without this, the joystick would stay latched to its last direction and
## the player would keep walking on their own once the app resumes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		finger = -1
		active = false
		_set_direction(Vector2.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			active = true
			touch_origin = event.position.clamp(Vector2(radius, radius), size - Vector2(radius, radius))
			_update_direction(event.position)
		elif not event.pressed and event.index == finger:
			finger = -1
			active = false
			_set_direction(Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == finger:
		_update_direction(event.position)

func _update_direction(local_position: Vector2) -> void:
	var offset := local_position - touch_origin
	_set_direction(offset.limit_length(radius) / radius)

func _set_direction(value: Vector2) -> void:
	direction = value
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	# Two translucent discs are enough feedback for a thumb without obscuring
	# enemies or projectiles underneath it.
	draw_circle(touch_origin, radius, Color(0.03, 0.08, 0.10, 0.38))
	draw_arc(touch_origin, radius, 0, TAU, 32, Color(0.72, 0.86, 0.66, 0.38), 1.5)
	draw_circle(touch_origin + direction * radius, knob_radius,Color(0.47, 0.78, 0.31, 0.78))
