extends Node2D
class_name EmberfallSparks

## One node draws every hit spark in the run (cheaper than a node per spark).
## game_world.spawn_sparks() feeds it; sparks fly out, slow down and fade.

const CAP := 180
const LIFETIME := 0.32

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _colors := PackedColorArray()

func _init() -> void:
	material = EmberfallFx.additive()
	z_index = 5

func burst(at: Vector2, color: Color, count: int, speed: float = 150.0) -> void:
	for i in count:
		if _pos.size() >= CAP:
			# Recycle the oldest spark instead of growing past the cap.
			_pos.remove_at(0); _vel.remove_at(0); _age.remove_at(0); _colors.remove_at(0)
		_pos.append(at)
		_vel.append(Vector2.from_angle(randf() * TAU) * speed * randf_range(0.5, 1.0) + Vector2(0, -40))
		_age.append(randf() * 0.06)
		_colors.append(color)

func _process(delta: float) -> void:
	if _pos.is_empty():
		return
	if GameState.screen == "playing":
		var i := _pos.size() - 1
		while i >= 0:
			_age[i] += delta
			if _age[i] >= LIFETIME:
				_pos.remove_at(i); _vel.remove_at(i); _age.remove_at(i); _colors.remove_at(i)
			else:
				_pos[i] += _vel[i] * delta
				_vel[i] *= 0.88
			i -= 1
	queue_redraw()

func _draw() -> void:
	for i in _pos.size():
		var k := 1.0 - _age[i] / LIFETIME
		var tail := _vel[i] * 0.035
		draw_line(_pos[i] - tail, _pos[i], Color(_colors[i], k), 2.5)
		draw_circle(_pos[i], 1.4, Color(1, 1, 1, k))
