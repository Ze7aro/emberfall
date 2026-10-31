extends Node2D
class_name EmberfallSlashFx

## Tajo Sombrío's visual: two crescents sweeping out to both sides of the
## player, fading in 0.25s. Visual only — game_world applies the damage
## over the same rectangle (`half_width` × `half_height`).

const LIFETIME := 0.25

var half_width := 70.0
var half_height := 23.0
var color := Color("b07cff")
var _age := 0.0

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := _age / LIFETIME
	var alpha := 1.0 - t
	for side: float in [-1.0, 1.0]:
		var points := PackedVector2Array()
		for i in 9:
			var k := float(i) / 8.0
			var y := lerpf(-half_height, half_height, k)
			var x := side * half_width * (0.35 + 0.65 * sin(k * PI)) * (0.6 + 0.4 * t)
			points.append(Vector2(x, y))
		draw_polyline(points, Color(color, alpha), 6.0 * (1.0 - t * 0.5))
		draw_polyline(points, Color(1, 1, 1, alpha * 0.8), 2.0)
