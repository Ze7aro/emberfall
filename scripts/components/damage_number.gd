extends Node2D
class_name EmberfallDamageNumber

## Floating combat text: rises and fades out. Crits render bigger and red;
## everything else (including poison/burn ticks) uses a neutral tone so the
## player can still tell a hit landed without it reading as a crit.
var amount := 0
var is_crit := false
var lifetime := 0.6
var _elapsed := 0.0

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	position.y -= 26.0 * delta
	if _elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - _elapsed / lifetime
	var font := ThemeDB.fallback_font
	var font_size := 18 if is_crit else 13
	var color := Color(1.0, 0.72, 0.26, alpha) if is_crit else Color(0.94, 0.97, 0.93, alpha)
	var text := str(amount) + ("!" if is_crit else "")
	draw_string(font, Vector2(-14, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 28, font_size, color)
