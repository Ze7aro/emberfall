extends Node2D
class_name EmberfallAbilitySpriteFx

## Pixel-art visual feedback for the active abilities, from
## assets/emberfall_habilidades_sprites — replaces the old plain drawn
## shapes (ring/cross/disc/line). Plays its 3 frames once and frees itself;
## used both standalone (orbital/area/fire/blizzard) and as the opening
## throw-and-land flourish other components embed for a longer-lived hazard
## (poison_pool holds on the last frame once this finishes).

const SPRITE_DIR := "res://assets/emberfall_habilidades_sprites"
const FPS := 10.0

var sprite: AnimatedSprite2D

## Built in _init so callers can call setup() right after `.new()`, before
## this node ever enters the tree.
func _init() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

## `visual_scale` sizes the effect uniformly. Pass `scale_override` instead
## for non-uniform stretching (e.g. chain lightning bridging two points).
## `autofree` off lets a longer-lived owner (poison_pool) keep this node
## around after the intro animation settles on its last frame.
func setup(folder: String, visual_scale: float = 1.0, scale_override: Vector2 = Vector2.ZERO, autofree: bool = true) -> void:
	sprite.scale = scale_override if scale_override != Vector2.ZERO else Vector2(visual_scale, visual_scale)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("play")
	frames.set_animation_loop("play", false)
	frames.set_animation_speed("play", FPS)
	var base := "%s/%s" % [SPRITE_DIR, folder]
	for i in 3:
		frames.add_frame("play", load("%s/frame_%02d.png" % [base, i]))
	sprite.sprite_frames = frames
	sprite.play("play")
	if autofree:
		sprite.animation_finished.connect(queue_free)
