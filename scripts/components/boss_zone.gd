extends Node2D
class_name EmberfallBossZone

## Matriarca de Ceniza, "zonas rúnicas": a rune circle fixed on the map that
## fills up for `delay` seconds and then explodes. Lives apart from the boss
## so it stays where it was placed while she keeps moving.

var target: Node2D
var radius := 70.0
var delay := 1.3
var damage_amount := 2
var color := Color("2de1d0")

var _age := 0.0
var _exploded := false
const BLAST_TIME := 0.3

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if not _exploded and _age >= delay:
		_exploded = true
		SfxPlayer.play("boss/boss_impact.wav", false)
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < radius:
			target.damage(damage_amount)
	if _age >= delay + BLAST_TIME:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _exploded:
		var progress := clampf(_age / delay, 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius, Color(color, 0.08))
		draw_circle(Vector2.ZERO, radius * progress, Color(color, 0.22))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.85), 2.5)
		draw_arc(Vector2.ZERO, radius * 0.62, _age * 2.0, _age * 2.0 + TAU * 0.75, 24, Color(color, 0.6), 2.0)
		return
	var t := clampf((_age - delay) / BLAST_TIME, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * (0.8 + 0.3 * t), Color(1.0, 0.95, 0.85, 0.6 * (1.0 - t)))
	draw_arc(Vector2.ZERO, radius * (0.9 + 0.4 * t), 0.0, TAU, 40, Color(color, 1.0 - t), 4.0)
