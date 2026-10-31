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
		game_ref._spawn_ability_fx("explosion_area", global_position, radius)
	queue_free()

func _draw() -> void:
	var progress := clampf(_age / telegraph, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.45, 0.15, 0.10 + progress * 0.12))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.6, 0.25, 0.4 + progress * 0.5), 2.0)
	draw_circle(Vector2.ZERO, radius * progress, Color(1.0, 0.55, 0.2, 0.18))
	# The falling rock itself, dropping in from above as the marker fills.
	var drop := Vector2(-40.0, -180.0) * (1.0 - progress)
	draw_circle(drop, 7.0 + radius * 0.08, Color("ff7a3d"))
	draw_circle(drop, 3.5 + radius * 0.04, Color("ffd38a"))
