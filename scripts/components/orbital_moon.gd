extends Node2D
class_name EmberfallOrbitalMoon

## One orbiting sphere of Lunas Orbitales. Pure visual: OrbitalWave owns its
## position (the elliptical orbit) and its damage/cooldown. Drawn in code as
## a plain white sphere with a soft halo and a gentle pulse.

const RADIUS := 4.5
const HALO_RADIUS := 8.5
const PULSE_SPEED := 5.0

var _time := randf() * TAU # random phase so the spheres don't pulse in sync

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
	draw_circle(Vector2.ZERO, HALO_RADIUS + pulse * 1.5, Color(1, 1, 1, 0.07 + 0.05 * pulse))
	draw_circle(Vector2.ZERO, RADIUS + 1.5, Color(1, 1, 1, 0.2))
	draw_circle(Vector2.ZERO, RADIUS, Color(0.94, 0.96, 1.0, 0.95))
