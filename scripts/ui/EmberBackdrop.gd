extends Control
class_name EmberBackdrop

## Shared menu backdrop, drawn in code: a deep violet gradient, a soft glow
## behind the content, a vignette and a few embers drifting up. Replaces the
## flat 192×320 background so every menu screen shares the same mood.

const TOP := Color("1d1233")
const BOTTOM := Color("07080f")
const GLOW := Color(0.36, 0.2, 0.62, 0.22)
const EMBER := Color("ff9a4a")
const EMBER_COUNT := 26

var _embers: Array[Dictionary] = []
var _gradient: GradientTexture2D
var _vignette: GradientTexture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	_gradient = _make_linear()
	_vignette = _make_radial()
	for i in EMBER_COUNT:
		_embers.append(_new_ember(true))

func _new_ember(anywhere: bool) -> Dictionary:
	var area := size if size != Vector2.ZERO else Vector2(390, 844)
	return {
		"pos": Vector2(randf() * area.x, randf() * area.y if anywhere else area.y + 8.0),
		"speed": randf_range(10.0, 26.0),
		"sway": randf_range(6.0, 16.0),
		"phase": randf() * TAU,
		"size": randf_range(1.0, 2.4),
		"alpha": randf_range(0.25, 0.7),
	}

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	for i in _embers.size():
		var e := _embers[i]
		e["pos"].y -= e["speed"] * delta
		e["phase"] += delta * 1.4
		if e["pos"].y < -10.0:
			_embers[i] = _new_ember(false)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_texture_rect(_gradient, rect, false)
	# Soft glow behind the middle of the screen, where the content sits.
	var c := size * Vector2(0.5, 0.38)
	for k in 6:
		var r := size.x * (0.75 - k * 0.1)
		draw_circle(c, r, Color(GLOW, GLOW.a / 6.0))
	for e in _embers:
		var flicker := 0.75 + 0.25 * sin(e["phase"] * 3.0)
		var p: Vector2 = e["pos"] + Vector2(sin(e["phase"]) * e["sway"], 0.0)
		var a: float = e["alpha"] * flicker
		draw_circle(p, e["size"] * 2.6, Color(EMBER, a * 0.12))
		draw_circle(p, e["size"], Color(EMBER.lightened(0.3), a))
	draw_texture_rect(_vignette, rect, false)

func _make_linear() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, TOP)
	g.set_color(1, BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 128
	return tex

func _make_radial() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.65))
	g.add_point(0.55, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.05, 1.0)
	tex.width = 64
	tex.height = 128
	return tex
