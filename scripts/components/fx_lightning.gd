extends Node2D
class_name EmberfallLightning

## Cadena Eléctrica's bolt between two world points: a jagged line that
## re-rolls its shape a few times while it fades, with a white core, the
## ability's color and a wide soft glow. Lives in world space (position 0).

const LIFETIME := 0.30
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
	draw_polyline(_points, Color(color, 0.22 * alpha * g), 18.0 * thick)
	draw_polyline(_points, Color(color, 0.9 * alpha), 6.0 * thick)
	draw_polyline(_points, Color(1, 1, 1, alpha), 2.4 * thick)
	# A short fork off the middle of the bolt.
	if _points.size() >= 4:
		var mid := _points[_points.size() >> 1]
		var along := (to - from).normalized()
		var fork := mid + along.rotated(0.9 if (_points.size() & 1) == 0 else -0.9) * 22.0 * thick
		draw_line(mid, fork, Color(color, 0.8 * alpha), 3.0 * thick)
		draw_line(mid, fork, Color(1, 1, 1, 0.8 * alpha), 1.2 * thick)
	EmberfallFx.glow(self, from, 12.0 * thick, color, 0.4 * alpha)
	EmberfallFx.glow(self, to, 20.0 * thick, color, 0.6 * alpha)
	EmberfallFx.burst(self, to, 16.0 * thick, Color(1, 1, 1), _age / LIFETIME, 5, _points.size() * 0.7)
