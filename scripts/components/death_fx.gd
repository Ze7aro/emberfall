extends Node2D
class_name EmberfallDeathFx

## Enemy death: the enemy's own sprite flashes and sinks, then the dissolve
## frames (assets/vfx/muerte) play over it while ash/ember specks drift up.

const LIFETIME := 0.5

var texture: Texture2D
var size := 60.0
var tint := Color.WHITE
var ember := Color("ff9f4a")
## Mirrors the dissolve so it matches the way the enemy faced.
var flip := false

const DISSOLVE_START := 0.1
const DISSOLVE_FPS := 14.0

var _age := 0.0
var _specks: Array[Dictionary] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var count := clampi(int(size / 6.0), 8, 26)
	for i in count:
		_specks.append({
			"pos": Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.3)) * size,
			"vel": Vector2(randf_range(-40.0, 40.0), randf_range(-90.0, -20.0)),
			"size": randf_range(2.0, 4.0),
			"ember": randf() < 0.35,
		})

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	for speck in _specks:
		speck["pos"] += speck["vel"] * delta
		speck["vel"] *= 0.94
	queue_redraw()

func _draw() -> void:
	var t := _age / LIFETIME
	if texture and t < 0.5:
		var k := t / 0.5
		var squash := Vector2(1.0 + 0.2 * k, 1.0 - 0.8 * k)
		var flash := 2.5 * (1.0 - k)
		var c := Color(tint.r + flash, tint.g + flash, tint.b + flash, 1.0 - k)
		# Same footprint as the walking enemy: aspect kept, feet on the shadow.
		var fit := size * 1.15 / float(maxi(texture.get_width(), texture.get_height()))
		var s := texture.get_size() * fit * squash
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(texture, Rect2(Vector2(-s.x / 2.0, size * 0.45 - s.y), s), false, c)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var dissolve := EmberfallVfxArt.frames("muerte")
	var frame := int((_age - DISSOLVE_START) * DISSOLVE_FPS)
	if not dissolve.is_empty() and _age >= DISSOLVE_START and frame < dissolve.size():
		var tex: Texture2D = dissolve[frame]
		var k := size * 1.2 / float(maxi(tex.get_width(), tex.get_height()))
		var drawn := tex.get_size() * k
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(tex, Rect2(-drawn.x / 2.0, size * 0.45 - drawn.y, drawn.x, drawn.y), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for speck in _specks:
		var color: Color = ember if speck["ember"] else Color(0.55, 0.5, 0.62)
		var px: float = speck["size"]
		draw_rect(Rect2(speck["pos"], Vector2(px, px)), Color(color, 1.0 - t))
