extends Area2D
class_name EmberfallBossProjectile

## Minimal enemy-owned projectile for the boss's barrage pattern — checks its
## own distance to the player each frame and deals damage once, instead of
## going through game_world's player-attack collision loop (which is scoped
## to the player's own shots hitting enemies, not the reverse).

var direction := Vector2.RIGHT
var damage_amount := 8
var lifetime := 2.5
var speed := 260.0
var target: Node2D
## Runa: the Guardián Hueco's violet rune bolts instead of the red fireball.
var rune := false
var _age := 0.0

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if rune:
		queue_redraw()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 26.0:
		target.damage(damage_amount)
		SfxPlayer.play("boss/boss_impact.wav", false)
		queue_free()

func _draw() -> void:
	if rune:
		draw_line(Vector2.ZERO, -direction * 26.0, Color(0.55, 0.3, 1.0, 0.45), 8.0)
		var r := Vector2.RIGHT.rotated(_age * 6.0)
		draw_colored_polygon(PackedVector2Array([r * 11.0, r.orthogonal() * 8.0, -r * 11.0, -r.orthogonal() * 8.0]), Color(0.55, 0.3, 1.0))
		draw_circle(Vector2.ZERO, 4.0, Color("2de1d0"))
		return
	draw_circle(Vector2.ZERO, 10, Color(0.85, 0.22, 0.2))
	draw_circle(Vector2.ZERO, 4, Color(1.0, 0.7, 0.3))
