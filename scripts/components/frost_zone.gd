extends Node2D
class_name EmberfallFrostZone

## Lingering hazard left by Ventisca: chills and damages anything caught
## inside on a steady tick for its whole lifetime. Drawn in code (§8): a
## faint icy disc with a soft edge and snow drifting through it, so it reads
## as an area without covering the enemies standing in it.

const TICK_INTERVAL := 0.5
const FADE_IN := 0.25
const FADE_OUT := 0.5

var radius := 70.0
var lifetime := 7.0
var tick_damage := 6
var freeze_duration := 0.6
var game_ref: Node
var _elapsed := 0.0
var _tick_clock := 0.0
var _color := Color("8fd8ff")
var _flakes: Array[Vector3] = [] # x, y (unit disc), phase

## Callers set `radius`/`tick_damage`/`lifetime` right after `.new()` but
## before `add_child()`, so by _ready() they already hold their final value.
func _ready() -> void:
	material = EmberfallFx.additive()
	_color = AbilityCatalog.color("blizzard")
	for i in clampi(int(radius / 5.0), 10, 40):
		_flakes.append(Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf()))
	_apply_tick() # hits immediately on landing instead of waiting a full tick

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	_tick_clock -= delta
	if _tick_clock <= 0.0:
		_tick_clock = TICK_INTERVAL
		_apply_tick()
	queue_redraw()

func _apply_tick() -> void:
	if not is_instance_valid(game_ref):
		return
	for enemy in game_ref.enemies:
		if is_instance_valid(enemy) and not enemy.dead and global_position.distance_to(enemy.global_position) < radius:
			game_ref._apply_damage(enemy, tick_damage, true, true, "blizzard")
			enemy.apply_freeze(freeze_duration)

func _draw() -> void:
	var alpha := minf(1.0, _elapsed / FADE_IN)
	if lifetime < INF:
		alpha *= clampf((lifetime - _elapsed) / FADE_OUT, 0.0, 1.0)
	var r := radius * (0.85 + 0.15 * minf(1.0, _elapsed / FADE_IN))
	draw_circle(Vector2.ZERO, r, Color(_color, 0.07 * alpha))
	draw_circle(Vector2.ZERO, r * 0.6, Color(_color, 0.04 * alpha))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(_color, 0.35 * alpha), 1.5)
	# Slow rotating dashes just inside the edge: the "wind" of the blizzard.
	var spin := _elapsed * 0.6
	for i in 6:
		var a := spin + TAU * float(i) / 6.0
		draw_arc(Vector2.ZERO, r * 0.82, a, a + 0.45, 8, Color(1, 1, 1, 0.18 * alpha), 1.2)
	# Snow falling diagonally, wrapped inside the disc.
	for flake in _flakes:
		var y := fposmod(flake.y + _elapsed * 0.35 + flake.z, 2.0) - 1.0
		var x := flake.x + sin(_elapsed * 1.5 + flake.z * TAU) * 0.08 - y * 0.15
		var p := Vector2(x, y)
		var edge := 1.0 - p.length()
		if edge <= 0.0:
			continue
		var k := minf(1.0, edge * 4.0) * alpha
		draw_circle(p * r, 1.3, Color(1, 1, 1, 0.7 * k))
