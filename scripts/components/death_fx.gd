extends Node2D
class_name EmberfallDeathFx

## Enemy death: the sprite flashes, shrinks into the ground and breaks into
## ash/ember specks that drift up, instead of vanishing on the spot.

const LIFETIME := 0.5

var texture: Texture2D
var size := 60.0
var tint := Color.WHITE
var ember := Color("ff9f4a")

var _age := 0.0
var _specks: Array[Dictionary] = []

func _ready() -> void:
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
		var s := Vector2(size, size) * squash
		draw_texture_rect(texture, Rect2(Vector2(-s.x / 2.0, size / 2.0 - s.y), s), false, c)
	for speck in _specks:
		var color: Color = ember if speck["ember"] else Color(0.55, 0.5, 0.62)
		var px: float = speck["size"]
		draw_rect(Rect2(speck["pos"], Vector2(px, px)), Color(color, 1.0 - t))
