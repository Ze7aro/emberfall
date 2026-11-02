extends Node2D
class_name EmberfallSlashFx

## Tajo Sombrío's visual: two filled crescents sweeping out to both sides of
## the player, thick in the middle and tapering at the tips, with a white
## cutting edge. Visual only — game_world applies the damage over the same
## rectangle (`half_width` × `half_height`).

const LIFETIME := 0.26
const SEGMENTS := 14

var half_width := 70.0
var half_height := 23.0
var color := Color("b07cff")
var evolved := false
var _age := 0.0

func _ready() -> void:
	material = EmberfallFx.additive()
	if evolved:
		color = EmberfallFx.evolved_color(color)

func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := _age / LIFETIME
	# Fast sweep out, then hold and fade.
	var reach := 1.0 - pow(1.0 - minf(1.0, t * 2.2), 3.0)
	var alpha := 1.0 - maxf(0.0, t - 0.35) / 0.65
	var thickness := (14.0 if evolved else 10.0) * (1.0 - t * 0.5)
	for side: float in [-1.0, 1.0]:
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for i in SEGMENTS + 1:
			var k := float(i) / float(SEGMENTS)
			var y := lerpf(-half_height, half_height, k) * 1.3
			var bulge := sin(k * PI)
			var x := side * half_width * (0.3 + 0.7 * bulge) * (0.55 + 0.45 * reach)
			outer.append(Vector2(x, y))
			# Tips are shared with the outer edge; repeating them would leave
			# duplicate points and break the polygon fill.
			if i > 0 and i < SEGMENTS:
				inner.append(Vector2(x - side * thickness * bulge, y))
		var shape := outer.duplicate()
		inner.reverse()
		shape.append_array(inner)
		draw_colored_polygon(shape, Color(color, 0.55 * alpha))
		draw_polyline(outer, Color(1, 1, 1, 0.9 * alpha), 2.0)
		EmberfallFx.glow(self, outer[SEGMENTS >> 1], 20.0, color, 0.5 * alpha)
