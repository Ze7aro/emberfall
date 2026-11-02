extends Node2D
class_name EmberfallMeteorStrike

## Lluvia de Meteoros: a ground marker fills in during `telegraph`, then the
## meteor lands, damages and burns everything in `radius`. The marker is the
## player's warning too, so it reads the same as a boss telegraph.

var game_ref: Node
var radius := 50.0
var damage := 30
var telegraph := 0.7
var burn_duration := 2.0
var _age := 0.0
var _landed := false

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if not _landed and _age >= telegraph:
		_land()
	queue_redraw()

func _land() -> void:
	_landed = true
	SfxPlayer.play("abilities/area_explosion.wav")
	if is_instance_valid(game_ref):
		for enemy in game_ref.enemies:
			if is_instance_valid(enemy) and not enemy.dead and global_position.distance_to(enemy.global_position) < radius:
				enemy.apply_burn(burn_duration, maxi(2, damage / 8))
				game_ref._apply_damage(enemy, damage, true, true, "meteor")
		var fire := Color("ff8a3d")
		game_ref.spawn_ring(global_position, fire, radius * 1.15, 0.4, 7.0, true)
		game_ref.spawn_ring(global_position, Color("ffd38a"), radius * 0.6, 0.25, 4.0)
		game_ref.spawn_sparks(global_position, fire, clampi(int(radius / 6.0), 8, 24), 260.0)
	queue_free()

## Same footprint as the damage (a circle of `radius`): a rune marker that
## fills toward the center, and the rock falling in with a fire trail.
func _draw() -> void:
	var progress := clampf(_age / telegraph, 0.0, 1.0)
	var fire := Color(1.0, 0.55, 0.2)
	draw_circle(Vector2.ZERO, radius, Color(fire, 0.08 + progress * 0.10))
	draw_circle(Vector2.ZERO, radius * progress, Color(fire, 0.16))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.65, 0.3, 0.45 + progress * 0.5), 2.0)
	# Eight rune ticks around the edge, turning slowly and closing in.
	for i in 8:
		var a := TAU * float(i) / 8.0 + _age * 1.5
		var dir := Vector2.from_angle(a)
		draw_line(dir * radius * 0.82, dir * radius * (0.82 - 0.12 * progress) , Color(1.0, 0.8, 0.45, 0.4 + 0.5 * progress), 2.0)
	# The rock: big trail of fire behind it, dark core with a hot rim.
	var start := Vector2(-60.0, -220.0)
	var rock := start * (1.0 - progress * progress)
	var size := 6.0 + radius * 0.09
	var back := start.normalized()
	for i in 6:
		var k := float(i) / 6.0
		draw_circle(rock + back * (8.0 + 9.0 * i) * (1.0 + size * 0.05), size * (1.0 - k * 0.8), Color(1.0, 0.45 + 0.3 * k, 0.15, 0.55 * (1.0 - k)))
	EmberfallFx.glow(self, rock, size * 2.6, fire, 0.6)
	draw_circle(rock, size, Color("ff7a3d"))
	draw_circle(rock + Vector2(1, 1), size * 0.7, Color("5a2a1c"))
	draw_circle(rock - Vector2(1.5, 1.5), size * 0.3, Color("ffd38a"))
