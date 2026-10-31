extends Node2D
class_name EmberfallSpectralFamiliar

## Familiar Espectral: floats around the player at its own slot on a slow
## circle and shoots a bolt at the nearest enemy in range on its own clock.
## game_world owns the stats and re-syncs them on every level/evolution.

const RANGE := 300.0
const ORBIT_RADIUS := 46.0

var game_ref: Node
var player_node: Node2D
var slot := 0
var slot_count := 1
var damage := 10
var fire_interval := 1.2
var _clock := 0.0
var _time := 0.0

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing" or not is_instance_valid(player_node):
		return
	_time += delta
	var angle := _time * 1.2 + TAU * float(slot) / float(maxi(1, slot_count))
	var goal := player_node.global_position + Vector2(cos(angle), sin(angle) * 0.6) * ORBIT_RADIUS + Vector2(0, -18)
	global_position = global_position.lerp(goal, minf(1.0, delta * 8.0))
	_clock += delta
	if _clock >= fire_interval:
		var target: EmberfallEnemy = game_ref.nearest_from(game_ref.enemies, global_position, RANGE)
		if target:
			_clock = 0.0
			_fire(target)
	queue_redraw()

func _fire(target: EmberfallEnemy) -> void:
	var bolt := EmberfallSkillProjectile.new()
	bolt.game_ref = game_ref
	bolt.style = EmberfallSkillProjectile.Style.BOLT
	bolt.color = Color("8ff0d0")
	bolt.global_position = global_position
	bolt.direction = global_position.direction_to(target.global_position)
	bolt.speed = 420.0 * game_ref.proj_speed_multiplier()
	bolt.damage = damage
	bolt.lifetime = 0.9
	bolt.source_id = "familiar"
	game_ref.add_child(bolt)

func _draw() -> void:
	var bob := sin(_time * 5.0) * 2.0
	draw_circle(Vector2(0, bob), 9.0, Color(0.56, 0.94, 0.82, 0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(-6, bob + 6), Vector2(0, bob - 9), Vector2(6, bob + 6)]), Color("cfeee6"))
	draw_circle(Vector2(-2, bob - 1), 1.3, Color("2de1d0"))
	draw_circle(Vector2(2, bob - 1), 1.3, Color("2de1d0"))
