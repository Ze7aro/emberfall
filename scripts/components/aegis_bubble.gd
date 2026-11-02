extends Node2D
class_name EmberfallAegisBubble

## Égida Rúnica: a shimmering hexagon around the player while a charge is
## stored (a second, outer one for Bastión's second charge). game_world
## owns the charges; breaking it spawns a ring and sparks there.

const RADIUS := 30.0

var game_ref: Node
var evolved := false
var _time := 0.0
var _shown := 0.0 # eases in when a charge comes back

func _init() -> void:
	material = EmberfallFx.additive()
	position = Vector2(0, -6)

func _process(delta: float) -> void:
	_time += delta
	var charges: int = game_ref.aegis_charges if is_instance_valid(game_ref) else 0
	_shown = move_toward(_shown, 1.0 if charges > 0 else 0.0, delta * 4.0)
	queue_redraw()

func _draw() -> void:
	if _shown <= 0.0 or not is_instance_valid(game_ref):
		return
	var color := AbilityCatalog.color("aegis")
	if evolved:
		color = EmberfallFx.evolved_color(color)
	var charges: int = game_ref.aegis_charges
	for layer in maxi(charges, 1):
		var r := (RADIUS + layer * 7.0) * (0.85 + 0.15 * _shown)
		var points := _hexagon(r, _time * 0.4 * (1.0 if layer == 0 else -1.0))
		draw_colored_polygon(points, Color(color, 0.07 * _shown))
		points.append(points[0])
		draw_polyline(points, Color(color, 0.55 * _shown), 2.0)
		# A highlight that runs around the edge so the shield feels alive.
		var k := fposmod(_time * 0.8 + layer * 0.5, 1.0) * 6.0
		var i := int(k)
		var spot := points[i].lerp(points[i + 1], k - i)
		draw_circle(spot, 2.5, Color(1, 1, 1, 0.9 * _shown))
		EmberfallFx.glow(self, spot, 8.0, color, 0.5 * _shown)

func _hexagon(r: float, spin: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		var a := spin + TAU * float(i) / 6.0
		points.append(Vector2(cos(a) * r, sin(a) * r * 0.9))
	return points
