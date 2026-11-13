extends Node2D
class_name EmberfallImpactFlash

## Brief impact cue for the basic attack — the pack only ships fly frames,
## no dedicated impact art, so this is a small procedural burst (2-3 visual
## steps: bright core, ring, fade) tinted to the shot's own color. Purely
## cosmetic and self-freeing; never touches damage, which is already applied
## by the caller before this is even spawned.

var color := Color(0.2, 0.95, 0.85)
var lifetime := 0.20
var _elapsed := 0.0

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := _elapsed / lifetime
	var alpha := 1.0 - progress
	EmberfallFx.glow(self, Vector2.ZERO, 22.0 + progress * 10.0, color, 0.5 * alpha)
	draw_circle(Vector2.ZERO, 7.0 + progress * 7.0, Color(color.r, color.g, color.b, alpha * 0.85))
	draw_circle(Vector2.ZERO, 4.0 * alpha, Color(1, 1, 1, alpha))
	draw_arc(Vector2.ZERO, 11.0 + progress * 13.0, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, alpha * 0.75), 2.5)
	EmberfallFx.burst(self, Vector2.ZERO, 20.0, color.lightened(0.5), progress, 6, 0.4)
