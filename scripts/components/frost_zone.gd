extends Node2D
class_name EmberfallFrostZone

## Lingering hazard left by Ventisca: chills and damages anything caught
## inside on a steady tick for its whole lifetime, instead of the old single
## instant hit. Loops its full 3-frame animation the whole time (same
## looping approach as persistent_aura.gd) rather than playing once and
## freezing on a frame, so it visibly reads as an active blizzard throughout.

const SPRITE_DIR := "res://assets/emberfall_habilidades_sprites/ventisca"
const NATIVE_RADIUS := 195.0 # how big the ventisca art reads at scale 1.0
const FPS := 8.0
const TICK_INTERVAL := 0.5

var radius := 70.0
var lifetime := 7.0
var tick_damage := 6
var freeze_duration := 0.6
var game_ref: Node
var _elapsed := 0.0
var _tick_clock := 0.0

## Callers set `radius`/`tick_damage`/`lifetime` right after `.new()` but
## before `add_child()`, so by _ready() they already hold their final value.
func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE * (radius / NATIVE_RADIUS)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("loop")
	frames.set_animation_loop("loop", true)
	frames.set_animation_speed("loop", FPS)
	for i in 3:
		frames.add_frame("loop", load("%s/frame_%02d.png" % [SPRITE_DIR, i]))
	sprite.sprite_frames = frames
	sprite.play("loop")
	add_child(sprite)
	_apply_tick() # hits immediately on landing instead of waiting a full tick

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	_tick_clock -= delta
	if _tick_clock <= 0.0:
		_tick_clock = TICK_INTERVAL
		_apply_tick()

func _apply_tick() -> void:
	if not is_instance_valid(game_ref):
		return
	for enemy in game_ref.enemies:
		if is_instance_valid(enemy) and not enemy.dead and global_position.distance_to(enemy.global_position) < radius:
			game_ref._apply_damage(enemy, tick_damage, true, true, "blizzard")
			enemy.apply_freeze(freeze_duration)
