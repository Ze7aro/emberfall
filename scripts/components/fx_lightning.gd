extends Node2D
class_name EmberfallLightning

## Cadena Eléctrica's bolt between two world points: a jagged line that
## re-rolls its shape a few times while it fades, with a white core, the
## ability's color and a wide soft glow. Lives in world space (position 0).

const LIFETIME := 0.24
const RESHAPE_EVERY := 0.06

var from := Vector2.ZERO
var to := Vector2.ZERO
var color := Color("6ad8ff")
var thick := 1.0
var _age := 0.0
var _reshape := 0.0
var _points := PackedVector2Array()

func _init() -> void:
	material = EmberfallFx.additive()

func _ready() -> void:
	_build()

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	_reshape += delta
	if _reshape >= RESHAPE_EVERY:
		_reshape = 0.0
		_build()
	queue_redraw()

func _build() -> void:
	_points = PackedVector2Array()
	var diff := to - from
	var normal := diff.orthogonal().normalized()
	var steps := clampi(int(diff.length() / 18.0), 3, 14)
	var jitter := clampf(diff.length() * 0.08, 6.0, 16.0)
	_points.append(from)
	for i in range(1, steps):
		var k := float(i) / float(steps)
		_points.append(from + diff * k + normal * randf_range(-jitter, jitter))
	_points.append(to)

func _draw() -> void:
	var alpha := 1.0 - _age / LIFETIME
	var g := EmberfallFx.glow_strength()
	draw_polyline(_points, Color(color, 0.25 * alpha * g), 9.0 * thick)
	draw_polyline(_points, Color(color, 0.85 * alpha), 3.5 * thick)
	draw_polyline(_points, Color(1, 1, 1, alpha), 1.4 * thick)
	EmberfallFx.glow(self, to, 14.0 * thick, color, 0.6 * alpha)
