extends Node2D
class_name EmberfallImpactFlash

## Brief impact cue for the basic attack — the pack only ships fly frames,
## no dedicated impact art, so this is a small procedural burst (2-3 visual
## steps: bright core, ring, fade) tinted to the shot's own color. Purely
## cosmetic and self-freeing; never touches damage, which is already applied
## by the caller before this is even spawned.

var color := Color(0.2, 0.95, 0.85)
var lifetime := 0.16
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
	draw_circle(Vector2.ZERO, 5.0 + progress * 6.0, Color(color.r, color.g, color.b, alpha * 0.8))
	draw_arc(Vector2.ZERO, 8.0 + progress * 8.0, 0.0, TAU, 16, Color(1.0, 1.0, 1.0, alpha * 0.7), 2.0)
