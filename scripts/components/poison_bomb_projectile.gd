extends Node2D
class_name EmberfallPoisonBombProjectile

## Visual-only lob for Bomba Venenosa. The root moves linearly from origin to
## target (so the eventual puddle position is exact, never touched by the
## arc), a child sprite bobs up in a short visual arc, and a flat shadow
## tracks the ground position beneath it. On arrival this frees itself and
## emits `landed`, which game_world uses to hand off to the existing
## EmberfallPoisonPool for the splash + persistent puddle + damage ticks —
## no separate pool/damage logic duplicated here.

signal landed(pos: Vector2)

const SPRITE_DIR := "res://assets/emberfall_habilidades_sprites/bomba_venenosa"
const TRAVEL_TIME := 0.35
const ARC_HEIGHT := 46.0
const BOMB_SCALE := 0.16

var origin := Vector2.ZERO
var destination := Vector2.ZERO
var _elapsed := 0.0
var _bomb_sprite: Sprite2D

func _init() -> void:
	_bomb_sprite = Sprite2D.new()
	_bomb_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bomb_sprite.texture = load("%s/frame_00.png" % SPRITE_DIR)
	_bomb_sprite.scale = Vector2(BOMB_SCALE, BOMB_SCALE)
	add_child(_bomb_sprite)

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
	# Root stays on the ground track (and is what the shadow draws at) —
	# only the bomb sprite itself rises and falls.
	_bomb_sprite.position.y = -ARC_HEIGHT * sin(PI * progress)
	queue_redraw()
	if progress >= 1.0:
		landed.emit(global_position)
		queue_free()

func _draw() -> void:
	var progress := clampf(_elapsed / TRAVEL_TIME, 0.0, 1.0)
	var shrink := 1.0 - 0.3 * sin(PI * progress) # smaller while the bomb is at its peak
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 10.0 * shrink, Color(0.0, 0.0, 0.0, 0.35))
