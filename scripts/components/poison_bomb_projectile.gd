extends Node2D
class_name EmberfallPoisonBombProjectile

## Visual-only lob for Bomba Venenosa. The root moves linearly from origin to
## target (so the eventual puddle position is exact, never touched by the
## arc), the flask is drawn higher up along a short visual arc, and a flat
## shadow tracks the ground position beneath it. On arrival this frees itself
## and emits `landed`, which game_world uses to hand off to the existing
## EmberfallPoisonPool for the splash + persistent puddle + damage ticks.

signal landed(pos: Vector2)

const TRAVEL_TIME := 0.35
const ARC_HEIGHT := 46.0

var origin := Vector2.ZERO
var destination := Vector2.ZERO
var _elapsed := 0.0
var _color := Color("8ee05a")

func _ready() -> void:
	_color = AbilityCatalog.color("poison_bomb")

func launch(from: Vector2, to: Vector2) -> void:
	origin = from
	destination = to
	global_position = from

func _process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	var progress := clampf(_elapsed / TRAVEL_TIME, 0.0, 1.0)
	global_position = origin.lerp(destination, progress)
	queue_redraw()
	if progress >= 1.0:
		landed.emit(global_position)
		queue_free()

func _draw() -> void:
	var progress := clampf(_elapsed / TRAVEL_TIME, 0.0, 1.0)
	var lift := sin(PI * progress)
	# Shadow on the ground track, smaller while the flask is at its peak.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0 * (1.0 - 0.3 * lift), Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, -ARC_HEIGHT * lift), progress * TAU * 1.5, Vector2.ONE)
	# Small round flask: glow, body, neck, highlight.
	EmberfallFx.glow(self, Vector2.ZERO, 11.0, _color, 0.35)
	draw_circle(Vector2(0, 1), 5.0, Color(_color, 0.9))
	draw_rect(Rect2(-1.6, -6.5, 3.2, 4.0), Color(0.85, 0.95, 0.85, 0.9))
	draw_circle(Vector2(-1.6, -0.6), 1.4, Color(1, 1, 1, 0.9))
