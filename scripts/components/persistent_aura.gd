extends Node2D
class_name EmberfallPersistentAura

## Visual-only companion for Aura Ígnea: a child of the player that just
## follows them. Damage and intervals stay owned by game_world. Drawn in
## code (§8): a faint warm disc with a flickering edge and embers rising
## from inside it, instead of the opaque fuego_constante sprite.

var radius := 44.0
var evolved := false
var _time := 0.0
var _color := Color("ff8a3d")
var _embers: Array[Vector3] = [] # x, y (unit disc), phase

func _init() -> void:
	material = EmberfallFx.additive()
	for i in 16:
		var p := Vector2.from_angle(randf() * TAU) * sqrt(randf()) * 0.9
		_embers.append(Vector3(p.x, p.y, randf()))

## Re-run on every pick so Área / level / Corona Solar resize the visual.
func setup(aura_radius: float, is_evolved: bool) -> void:
	radius = aura_radius
	evolved = is_evolved
	_color = AbilityCatalog.color("fire")
	if evolved:
		_color = EmberfallFx.evolved_color(_color)

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 9.0) * sin(_time * 5.3)
	draw_circle(Vector2.ZERO, radius, Color(_color, 0.06 * flicker))
	draw_circle(Vector2.ZERO, radius * 0.5, Color(_color, 0.05 * flicker))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(_color, 0.28 * flicker), 1.5)
	if evolved:
		# Corona Solar: short sun rays turning slowly around the edge.
		for i in 12:
			var dir := Vector2.from_angle(_time * 0.5 + TAU * float(i) / 12.0)
			var reach := 1.1 + 0.05 * sin(_time * 4.0 + i)
			draw_line(dir * radius * 0.94, dir * radius * reach, Color(EmberfallFx.GOLD, 0.35 * flicker), 2.0)
	# Embers: rise a little, drift and fade, then start again lower down.
	for ember in _embers:
		var t := fposmod(_time * 0.8 + ember.z, 1.0)
		var at := Vector2(ember.x + sin(_time * 3.0 + ember.z * TAU) * 0.05, ember.y) * radius
		at.y -= t * 22.0
		var k := sin(PI * t)
		var hot := _color.lerp(Color(1.0, 0.92, 0.6), 1.0 - t)
		draw_circle(at, 1.6 * (1.0 - t * 0.5), Color(hot, 0.75 * k))
