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

## Soft round halo: three stacked circles fading outward.
static func glow(canvas: CanvasItem, at: Vector2, radius: float, color: Color, alpha: float = 0.35) -> void:
	var a := alpha * glow_strength()
	canvas.draw_circle(at, radius, Color(color, a * 0.30))
	canvas.draw_circle(at, radius * 0.66, Color(color, a * 0.55))
	canvas.draw_circle(at, radius * 0.38, Color(color, a))

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
