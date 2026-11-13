class_name EmberfallFx
extends RefCounted

## Shared look for ability visuals (PLAN_FINALIZACION §8.2): white core,
## the ability's color, and an additive halo. Static helpers only; the
## nodes that use them draw in their own _draw().

const GOLD := Color("ffd27a")

static var _additive: CanvasItemMaterial

## Additive blending: overlapping effects add up and glow on the dark floor.
static func additive() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive

## Halo strength, lowered by "Reducir temblor y destellos".
static func glow_strength() -> float:
	return 0.45 if GameState.reduce_motion else 1.0

static var _soft: GradientTexture2D

## Radial falloff (opaque centre to nothing at the edge), generated once and
## shared by every halo. 256 px so it stays smooth under nearest filtering.
static func soft_texture() -> Texture2D:
	if _soft == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.65, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.14), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = gradient
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
		_soft.width = 256
		_soft.height = 256
	return _soft

## Soft round halo that fades smoothly to nothing. `radius` is where the
## light is still clearly visible; the falloff reaches a bit further.
static func glow(canvas: CanvasItem, at: Vector2, radius: float, color: Color, alpha: float = 0.35) -> void:
	var a := minf(1.0, alpha * 1.7) * glow_strength()
	var reach := radius * 1.6
	canvas.draw_texture_rect(soft_texture(), Rect2(at - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, Color(color, a))

## Short streaks flying out from a point (impacts, bursts). `t` is 0..1.
static func burst(canvas: CanvasItem, at: Vector2, radius: float, color: Color, t: float, count: int = 6, spin: float = 0.0) -> void:
	var fade := 1.0 - t
	for i in count:
		var dir := Vector2.from_angle(spin + TAU * float(i) / float(count))
		canvas.draw_line(at + dir * radius * (0.35 + 0.65 * t), at + dir * radius * (0.75 + 0.65 * t), Color(color, fade), 2.5 * fade + 0.5)

## Evolutions shift toward gold/white so they read as "more".
static func evolved_color(color: Color) -> Color:
	return color.lerp(GOLD, 0.45).lightened(0.15)

## Polygon of an ellipse (for 3/4-view rings and pools).
static func ellipse(center: Vector2, rx: float, ry: float, segments: int = 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points

## Fading trail through `points` (oldest first, local space): each segment
## gets wider and more opaque toward the head.
static func trail(canvas: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var count := points.size()
	if count < 2:
		return
	for i in count - 1:
		var k := float(i + 1) / float(count - 1)
		canvas.draw_line(points[i], points[i + 1], Color(color, 0.55 * k * k), maxf(1.0, width * k))
