extends Node

## Drag-to-scroll with inertia for a vertical ScrollContainer full of
## buttons (e.g. the Progreso grids).
##
## The buttons inside must use MOUSE_FILTER_PASS so their presses and drags
## bubble up to the ScrollContainer, where this helper picks them up. It works
## with the mouse too (desktop/editor) and replaces the built-in touch drag,
## which only reacts on empty space between buttons.
##
## A drag (or a tap that just stops a moving list) must not count as a tap on
## the button under the finger: check `blocks_tap()` in the button's handler.
## Buttons emit `pressed` before the event bubbles up here, so the flag is
## still up when they ask.

## Pixels the finger must travel before a press becomes a drag.
const DEADZONE := 10.0
## How fast the fling slows down (per second, exponential).
const FRICTION := 5.0
## Below this speed (px/s) the fling stops.
const MIN_SPEED := 40.0
## A pause this long (ms) before lifting the finger means "no fling".
const STILL_MS := 90

var scroll: ScrollContainer

var _pressed := false
var _dragging := false
var _swallow_tap := false
var _anchor_y := 0.0
var _anchor_scroll := 0.0
var _last_y := 0.0
var _last_ms := 0
var _velocity := 0.0
var _fling_pos := 0.0
var _flinging := false

func _init(target: ScrollContainer = null) -> void:
	scroll = target

func _ready() -> void:
	scroll.gui_input.connect(_on_scroll_input)

## True while a press is being used to scroll (or to stop a fling); the
## button under the finger should ignore its `pressed` then.
func blocks_tap() -> bool:
	return _dragging or _swallow_tap

func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swallow_tap = _flinging
			_flinging = false
			_pressed = true
			_dragging = false
			_anchor_y = event.global_position.y
			_anchor_scroll = scroll.scroll_vertical
			_velocity = 0.0
			_last_y = _anchor_y
			_last_ms = Time.get_ticks_msec()
		else:
			if _dragging and Time.get_ticks_msec() - _last_ms <= STILL_MS and absf(_velocity) > MIN_SPEED:
				_fling_pos = scroll.scroll_vertical
				_flinging = true
			_pressed = false
			_dragging = false
			_swallow_tap = false
		# Taken here so the built-in touch drag doesn't scroll a second time.
		scroll.accept_event()
	elif event is InputEventMouseMotion and _pressed:
		var y: float = event.global_position.y
		if not _dragging and absf(y - _anchor_y) > DEADZONE:
			_dragging = true
			# Start from where the finger is now, so the list doesn't jump
			# by the dead zone.
			_anchor_y = y
			_anchor_scroll = scroll.scroll_vertical
		if _dragging:
			scroll.scroll_vertical = int(round(_anchor_scroll - (y - _anchor_y)))
			var now := Time.get_ticks_msec()
			var dt := maxf(0.001, float(now - _last_ms) / 1000.0)
			_velocity = lerpf(_velocity, -(y - _last_y) / dt, 0.4)
			_last_y = y
			_last_ms = now
		scroll.accept_event()

func _process(delta: float) -> void:
	if not _flinging:
		return
	if not scroll.is_visible_in_tree():
		_flinging = false
		return
	_fling_pos += _velocity * delta
	_velocity *= exp(-FRICTION * delta)
	var before := scroll.scroll_vertical
	scroll.scroll_vertical = int(round(_fling_pos))
	# Stop at either end of the list, or once it has slowed down enough.
	if absf(_velocity) < MIN_SPEED or (scroll.scroll_vertical == before and absf(_velocity * delta) >= 1.0):
		_flinging = false
