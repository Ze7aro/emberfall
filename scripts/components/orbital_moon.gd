extends Node2D
class_name EmberfallOrbitalMoon

## One orbiting sphere of Lunas Orbitales. Pure visual: OrbitalWave owns its
## position (the elliptical orbit) and its damage/cooldown. Drawn in code as
## a plain white sphere with a soft halo and a gentle pulse.

const RADIUS := 8.5
const HALO_RADIUS := 20.0
const PULSE_SPEED := 5.0
const TRAIL_POINTS := 9

var evolved := false
var _time := randf() * TAU # random phase so the spheres don't pulse in sync
## Recent positions (parent space), oldest first: the fading tail.
var _trail: Array[Vector2] = []

func _process(delta: float) -> void:
	_time += delta
	if GameState.screen == "playing":
		_trail.append(position)
		if _trail.size() > TRAIL_POINTS:
			_trail.pop_front()
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
	var tint := Color(0.45, 0.95, 1.0) if evolved else Color(0.72, 0.86, 1.0)
	# Tail: shrinking, fading copies along the orbit already travelled.
	for i in _trail.size():
		var k := float(i + 1) / float(_trail.size() + 1)
		draw_circle(_trail[i] - position, RADIUS * 0.8 * k, Color(tint, 0.20 * k))
	EmberfallFx.glow(self, Vector2.ZERO, HALO_RADIUS + pulse * 3.0, tint, 0.42 if evolved else 0.34)
	draw_circle(Vector2.ZERO, RADIUS + 1.5, Color(tint, 0.6))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.96, 0.98, 1.0))
	# Shaded side and a highlight: reads as a small moon, not a dot.
	draw_circle(Vector2(2.6, 2.2), RADIUS * 0.7, Color(0.60, 0.70, 0.92, 0.55))
	draw_circle(Vector2(-2.6, -2.6), 2.0, Color(1, 1, 1, 0.95))
