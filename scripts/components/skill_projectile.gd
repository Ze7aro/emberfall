extends Node2D
class_name EmberfallSkillProjectile

## Shared projectile for the active abilities (Dagas, Hacha Bumerán,
## Esquirla, Familiar). Hit-tests by distance against game_ref.enemies like
## every other ability, instead of going through game_world's basic-attack
## loop, so it never picks up hero-only effects (guaranteed status, etc.).
## Drawn in code with the shared look (EmberfallFx, PLAN_FINALIZACION §8):
## white core, ability color, additive halo and a short fading trail.

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
## Evolved abilities draw bigger and shifted toward gold.
var evolved := false

const TRAIL_LENGTH := {Style.DAGGER: 6, Style.AXE: 0, Style.SHARD: 5, Style.BOLT: 6}
var _trail: Array[Vector2] = [] # global positions, oldest first

var _age := 0.0
var _travelled := 0.0
var _returning := false
var _hits := 0
var _last_hit := {} # instance_id -> _age

func _ready() -> void:
	material = EmberfallFx.additive()
	if evolved:
		color = EmberfallFx.evolved_color(color)
		visual_scale *= 1.25

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_trail.append(global_position)
	if _trail.size() > int(TRAIL_LENGTH.get(style, 0)):
		_trail.pop_front()
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
	if is_instance_valid(game_ref):
		game_ref.spawn_sparks(global_position, color, 4, 120.0)
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
	var local_trail := PackedVector2Array()
	for point in _trail:
		local_trail.append(to_local(point))
	match style:
		Style.DAGGER:
			EmberfallFx.trail(self, local_trail, color, 5.0 * visual_scale)
			draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE * visual_scale)
			EmberfallFx.glow(self, Vector2(2, 0), 13.0, color, 0.35)
			# Long thin blade, a hilt, and a white edge down the middle.
			draw_colored_polygon(PackedVector2Array([Vector2(16, 0), Vector2(-2, 3.2), Vector2(-7, 0), Vector2(-2, -3.2)]), color)
			draw_line(Vector2(-6, 0), Vector2(13, 0), Color(1, 1, 1, 0.95), 1.4)
			draw_line(Vector2(-7, -4.5), Vector2(-7, 4.5), color.lightened(0.3), 2.0)
		Style.AXE:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * visual_scale)
			var spin := _age * 15.0
			EmberfallFx.glow(self, Vector2.ZERO, 22.0, color, 0.25)
			# Motion blur: two faint arcs trailing each blade.
			for i in 2:
				var a := spin + PI * i
				draw_arc(Vector2.ZERO, 15.0, a - 1.6, a, 10, Color(color, 0.35), 7.0)
				draw_arc(Vector2.ZERO, 17.0, a - 0.8, a, 6, Color(1, 1, 1, 0.35), 2.0)
			for i in 2:
				var dir := Vector2.RIGHT.rotated(spin + PI * i)
				var side := dir.orthogonal()
				var blade := PackedVector2Array([dir * 5.0, dir * 15.0 + side * 10.0, dir * 20.0, dir * 15.0 - side * 7.0])
				draw_colored_polygon(blade, color)
				draw_line(dir * 15.0 + side * 10.0, dir * 20.0, Color.WHITE, 2.0)
				draw_line(dir * 20.0, dir * 15.0 - side * 7.0, Color.WHITE, 2.0)
			draw_line(Vector2.RIGHT.rotated(spin) * 6.0, Vector2.RIGHT.rotated(spin + PI) * 6.0, Color("cfc6dc"), 3.0)
			draw_circle(Vector2.ZERO, 3.5, Color("3b2457"))
		Style.SHARD:
			# Afterimages along the path instead of a line trail.
			for i in local_trail.size():
				var k := float(i + 1) / float(local_trail.size() + 1)
				_draw_shard(local_trail[i], Color(color, 0.35 * k), 0.75 + 0.25 * k, false)
			EmberfallFx.glow(self, Vector2.ZERO, 16.0 * visual_scale, color, 0.4)
			_draw_shard(Vector2.ZERO, color, 1.0, true)
		Style.BOLT:
			EmberfallFx.trail(self, local_trail, color, 6.0 * visual_scale)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * visual_scale)
			EmberfallFx.glow(self, Vector2.ZERO, 12.0, color, 0.5)
			draw_circle(Vector2.ZERO, 4.5, color)
			draw_circle(Vector2.ZERO, 2.4, Color.WHITE)

## Spinning crystal: colored rhombus with a white inner facet.
func _draw_shard(at: Vector2, tint: Color, scale_factor: float, with_core: bool) -> void:
	var s := scale_factor * visual_scale
	var r := Vector2.RIGHT.rotated(_age * 9.0)
	var o := r.orthogonal()
	draw_colored_polygon(PackedVector2Array([at + r * 12.0 * s, at + o * 6.0 * s, at - r * 12.0 * s, at - o * 6.0 * s]), tint)
	if with_core:
		draw_colored_polygon(PackedVector2Array([at + r * 6.0 * s, at + o * 2.5 * s, at - r * 2.0 * s, at - o * 2.5 * s]), Color(1, 1, 1, 0.95))
