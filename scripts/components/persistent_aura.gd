extends Node2D
class_name EmberfallPersistentAura

## Visual-only companion for aura-style active abilities (Onda Orbital, Fuego
## Constante): added as a child of the player once, then just sits there
## looping and following automatically via normal Node2D parenting — no
## per-frame position syncing needed. Damage/intervals stay entirely owned
## by game_world.update_powers(); this never touches damage, only replaces
## what used to be a one-shot flash recreated on every damage tick.

const SPRITE_DIR := "res://assets/emberfall_habilidades_sprites"
const FPS := 6.0

var sprite: AnimatedSprite2D
var _base_scale := Vector2.ONE
var _flicker_time := 0.0
var _flicker_enabled := false

func _init() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

## `frame_indices` lets a caller skip frames that don't actually belong in a
## loop — fuego_constante's frame_01/02 are a much denser, near-solid disc
## than frame_00's sparse ring (same authored canvas size, wildly different
## content), so cycling all three reads as the aura suddenly ballooning into
## a screen-covering blob every half second instead of a steady flame.
func setup(folder: String, visual_scale: float, frame_indices: Array = [0, 1, 2]) -> void:
	_base_scale = Vector2(visual_scale, visual_scale)
	sprite.scale = _base_scale
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("loop")
	frames.set_animation_loop("loop", true)
	frames.set_animation_speed("loop", FPS)
	var base := "%s/%s" % [SPRITE_DIR, folder]
	for i in frame_indices:
		frames.add_frame("loop", load("%s/frame_%02d.png" % [base, i]))
	sprite.sprite_frames = frames
	sprite.play("loop")
	# A single static frame (fuego_constante's case, see above) has no frame
	# animation to give it life, so fake a gentle flame-flicker procedurally
	# instead: a slow breathing scale, a light wobble, and a soft alpha pulse.
	# Multi-frame auras (Onda Orbital) already get their motion from the loop.
	_flicker_enabled = frame_indices.size() <= 1

func _process(delta: float) -> void:
	if not _flicker_enabled:
		return
	_flicker_time += delta
	sprite.scale = _base_scale * (1.0 + sin(_flicker_time * 6.0) * 0.06)
	sprite.rotation = sin(_flicker_time * 3.7) * 0.05
	sprite.modulate.a = 0.9 + 0.1 * sin(_flicker_time * 9.0)
