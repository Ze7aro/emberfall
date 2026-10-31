extends Node2D
class_name EmberfallSkillProjectile

## Shared projectile for the active abilities (Dagas, Hacha Bumerán,
## Esquirla, Familiar). Hit-tests by distance against game_ref.enemies like
## every other ability, instead of going through game_world's basic-attack
## loop, so it never picks up hero-only effects (guaranteed status, etc.).
## Drawn procedurally until the generated VFX strips from
## docs/PLAN_FINALIZACION.md §6.5 exist.

enum Mode { STRAIGHT, BOOMERANG, SPIRAL, BOUNCE }
enum Style { DAGGER, AXE, SHARD, BOLT }

signal bounced(at: Vector2, new_direction: Vector2)

var game_ref: Node
var mode: int = Mode.STRAIGHT
var style: int = Style.DAGGER
var color := Color("2de1d0")
var direction := Vector2.RIGHT
var speed := 600.0
var damage := 10
var lifetime := 1.0
## Enemies this can hit before disappearing; -1 = unlimited.
var pierce := 0
## Seconds before the same enemy can be hit again; 0 = only once ever.
var rehit_interval := 0.0
var hit_radius := 22.0
var bounces := 0
## BOOMERANG: distance travelled before turning back toward `return_target`.
var out_distance := 220.0
var return_target: Node2D
var visual_scale := 1.0
## Ability id credited in the result screen's damage ranking.
var source_id := ""

var _age := 0.0
var _travelled := 0.0
var _returning := false
var _hits := 0
var _last_hit := {} # instance_id -> _age

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	match mode:
		Mode.BOOMERANG:
			_move_boomerang(delta)
		Mode.SPIRAL:
			direction = direction.rotated(4.0 / (1.0 + _age * 1.5) * delta)
			global_position += direction * speed * delta
		Mode.BOUNCE:
			global_position += direction * speed * delta
			_bounce_off_screen()
		_:
			global_position += direction * speed * delta
	_check_hits()
	queue_redraw()

func _move_boomerang(delta: float) -> void:
	if not _returning:
		global_position += direction * speed * delta
		_travelled += speed * delta
		if _travelled >= out_distance:
			_returning = true
			_last_hit.clear() # the way back can hit the same enemies again
		return
	if not is_instance_valid(return_target):
		queue_free()
		return
	var to_target := return_target.global_position - global_position
	if to_target.length() < 24.0:
		queue_free()
		return
	direction = to_target.normalized()
	global_position += direction * speed * 1.15 * delta

## Bounds are the visible screen around the player (camera has no zoom).
func _bounce_off_screen() -> void:
	if not is_instance_valid(game_ref) or not is_instance_valid(game_ref.player):
		return
	var half := get_viewport_rect().size * 0.5
	var center: Vector2 = game_ref.player.global_position
	var bounced_now := false
	if absf(global_position.x - center.x) > half.x:
		direction.x = -signf(global_position.x - center.x) * absf(direction.x)
		bounced_now = true
	if absf(global_position.y - center.y) > half.y:
		direction.y = -signf(global_position.y - center.y) * absf(direction.y)
		bounced_now = true
	if not bounced_now:
		return
	if bounces <= 0:
		queue_free()
		return
	bounces -= 1
	bounced.emit(global_position, direction)

func _check_hits() -> void:
	if not is_instance_valid(game_ref):
		return
	for enemy in game_ref.enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if global_position.distance_to(enemy.global_position) > hit_radius + 18.0:
			continue
		var key: int = enemy.get_instance_id()
		if _last_hit.has(key) and (rehit_interval <= 0.0 or _age - float(_last_hit[key]) < rehit_interval):
			continue
		_last_hit[key] = _age
		game_ref._apply_damage(enemy, damage, true, true, source_id)
		_hits += 1
		if pierce >= 0 and _hits > pierce:
			queue_free()
			return

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * visual_scale)
	match style:
		Style.DAGGER:
			var tip := direction * 14.0
			var side := direction.orthogonal() * 3.0
			draw_colored_polygon(PackedVector2Array([tip, -direction * 6.0 + side, -direction * 10.0, -direction * 6.0 - side]), color)
			draw_line(-direction * 10.0, -direction * 22.0, Color(color, 0.35), 3.0)
		Style.AXE:
			var spin := _age * 14.0
			for i in 2:
				var a := Vector2.RIGHT.rotated(spin + PI * i)
				draw_colored_polygon(PackedVector2Array([a * 4.0, a * 16.0 + a.orthogonal() * 9.0, a * 18.0 - a.orthogonal() * 7.0]), color)
			draw_circle(Vector2.ZERO, 4.0, Color("3b2457"))
		Style.SHARD:
			var r := Vector2.RIGHT.rotated(_age * 9.0)
			draw_colored_polygon(PackedVector2Array([r * 11.0, r.orthogonal() * 6.0, -r * 11.0, -r.orthogonal() * 6.0]), color)
			draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
		Style.BOLT:
			draw_circle(Vector2.ZERO, 6.0, Color(color, 0.45))
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
