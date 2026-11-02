extends Node2D
class_name EmberfallPoisonPool

## Lingering hazard left by Bomba Venenosa: any enemy standing inside gets
## re-poisoned every tick, so the DoT keeps refreshing while they linger.
## Drawn in code (§8): a translucent green pool with a wobbling edge and a
## few bubbles that rise and pop, instead of the opaque puddle sprite.

const FADE_IN := 0.18
const FADE_OUT := 0.4
const EDGE_POINTS := 28

var radius := 55.0
var lifetime := 4.0
var tick_damage := 3
var game_ref: Node
## Plaga Abisal: the pool slowly drifts toward the nearest enemy.
var chase_speed := 0.0
var _elapsed := 0.0
var _tick_clock := 0.0
var _color := Color("8ee05a")
var _bubbles: Array[Vector3] = [] # x, y (unit disc), phase

## Callers set `radius` right after `.new()` but before `add_child()`, so by
## _ready() it already holds its final value — no need to build in _init().
func _ready() -> void:
	material = EmberfallFx.additive()
	_color = AbilityCatalog.color("poison_bomb")
	if chase_speed > 0.0:
		_color = EmberfallFx.evolved_color(_color)
	for i in clampi(int(radius / 9.0), 5, 14):
		var p := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 0.75
		_bubbles.append(Vector3(p.x, p.y, randf()))
	if is_instance_valid(game_ref):
		game_ref.spawn_ring(global_position, _color, radius * 1.1, 0.3, 4.0)
		game_ref.spawn_sparks(global_position, _color, 8, 160.0)
	# Shared loop, not one per puddle (see SfxPlayer.start_poison_loop).
	SfxPlayer.start_poison_loop()
	tree_exiting.connect(SfxPlayer.stop_poison_loop)

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	if chase_speed > 0.0 and is_instance_valid(game_ref):
		var prey: EmberfallEnemy = game_ref.nearest_from(game_ref.enemies, global_position, 400.0)
		if prey:
			global_position = global_position.move_toward(prey.global_position, chase_speed * delta)
	_tick_clock -= delta
	if _tick_clock <= 0.0:
		_tick_clock = 0.5
		_apply_tick()
	queue_redraw()

func _apply_tick() -> void:
	if not is_instance_valid(game_ref):
		return
	for enemy in game_ref.enemies:
		if is_instance_valid(enemy) and not enemy.dead and global_position.distance_to(enemy.global_position) < radius:
			enemy.apply_poison(1.0, tick_damage)

func _draw() -> void:
	var grow := minf(1.0, _elapsed / FADE_IN)
	var alpha := grow * clampf((lifetime - _elapsed) / FADE_OUT, 0.0, 1.0)
	var r := radius * (0.6 + 0.4 * grow)
	var edge := PackedVector2Array()
	for i in EDGE_POINTS:
		var a := TAU * float(i) / float(EDGE_POINTS)
		var wobble := 1.0 + 0.05 * sin(a * 3.0 + _elapsed * 2.0) + 0.03 * sin(a * 5.0 - _elapsed * 3.0)
		edge.append(Vector2.from_angle(a) * r * wobble)
	draw_colored_polygon(edge, Color(_color, 0.10 * alpha))
	draw_circle(Vector2.ZERO, r * 0.55, Color(_color, 0.05 * alpha))
	edge.append(edge[0])
	draw_polyline(edge, Color(_color, 0.4 * alpha), 1.5)
	# Bubbles: grow for most of their cycle, then pop as a thin ring.
	for bubble in _bubbles:
		var t := fposmod(_elapsed * 0.7 + bubble.z, 1.0)
		var at := Vector2(bubble.x, bubble.y) * r
		if t < 0.8:
			draw_circle(at, 1.0 + 2.5 * (t / 0.8), Color(_color, 0.45 * alpha))
		else:
			var pop := (t - 0.8) / 0.2
			draw_arc(at, 3.5 + 3.0 * pop, 0.0, TAU, 10, Color(1, 1, 1, 0.4 * (1.0 - pop) * alpha), 1.0)
