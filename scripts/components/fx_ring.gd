extends Node2D
class_name EmberfallFxRing

## Expanding ring that fades out: meteor impacts, Égida breaking, shard
## bounces. `flatten` < 1 squashes it into a ground ellipse (3/4 view).

var color := Color.WHITE
var radius := 60.0
var lifetime := 0.35
var width := 5.0
var flatten := 0.6
var fill := false
var _age := 0.0

func _init() -> void:
	material = EmberfallFx.additive()

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := _age / lifetime
	var r := radius * (0.25 + 0.75 * (1.0 - pow(1.0 - t, 3.0)))
	var alpha := 1.0 - t
	var points := EmberfallFx.ellipse(Vector2.ZERO, r, r * flatten, 32)
	if fill:
		draw_colored_polygon(points, Color(color, 0.18 * alpha))
	points.append(points[0])
	draw_polyline(points, Color(color, 0.8 * alpha), width * (1.0 - t * 0.6))
	draw_polyline(points, Color(1, 1, 1, 0.6 * alpha), maxf(1.0, width * 0.3))
