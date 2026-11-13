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
	EmberfallFx.glow(self, Vector2.ZERO, radius * 0.8, _color, 0.20 * flicker)
	# The edge wavers like fire instead of being a clean circle.
	var ring := PackedVector2Array()
	var core := PackedVector2Array()
	for i in 49:
		var a := TAU * float(i) / 48.0
		var wobble := 1.0 + 0.05 * sin(a * 7.0 + _time * 6.0) + 0.035 * sin(a * 13.0 - _time * 9.0)
		ring.append(Vector2.from_angle(a) * radius * wobble)
		core.append(Vector2.from_angle(a) * radius * wobble * 0.94)
	draw_polyline(ring, Color(_color, 0.55 * flicker), 3.5)
	draw_polyline(core, Color(1.0, 0.9, 0.6, 0.35 * flicker), 1.5)
	# Flame tongues licking up from the edge.
	for i in 14:
		var a := TAU * float(i) / 14.0 + _time * 0.35
		var base := Vector2.from_angle(a) * radius
		var height := 9.0 + 7.0 * (0.5 + 0.5 * sin(_time * 7.0 + i * 1.7))
		var half := 3.5
		draw_colored_polygon(PackedVector2Array([base + Vector2(-half, 0), base + Vector2(sin(_time * 5.0 + i) * 2.0, -height), base + Vector2(half, 0)]), Color(_color.lerp(Color(1.0, 0.9, 0.55), 0.35), 0.5 * flicker))
	if evolved:
		# Corona Solar: short sun rays turning slowly around the edge.
		for i in 12:
			var dir := Vector2.from_angle(_time * 0.5 + TAU * float(i) / 12.0)
			var reach := 1.1 + 0.05 * sin(_time * 4.0 + i)
			draw_line(dir * radius * 0.94, dir * radius * (reach + 0.06), Color(EmberfallFx.GOLD, 0.6 * flicker), 3.0)
	# Embers: rise a little, drift and fade, then start again lower down.
	for ember in _embers:
		var t := fposmod(_time * 0.8 + ember.z, 1.0)
		var at := Vector2(ember.x + sin(_time * 3.0 + ember.z * TAU) * 0.05, ember.y) * radius
		at.y -= t * 30.0
		var k := sin(PI * t)
		var hot := _color.lerp(Color(1.0, 0.92, 0.6), 1.0 - t)
		draw_circle(at, 2.6 * (1.0 - t * 0.5), Color(hot, 0.85 * k))
