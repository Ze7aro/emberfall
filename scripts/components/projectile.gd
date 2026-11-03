extends Area2D
class_name EmberfallProjectile

const SPRITE_DIR := "res://assets/habilidades/proyectiles"
const SPRITE_FPS := 10.0
const SPRITE_SCALE := 0.16 # 256px source frames down to ~41px on screen
const DEFAULT_FRAME_NAMES: PackedStringArray = ["projectile_00.png", "projectile_01.png"]

var direction := Vector2.RIGHT
var damage_amount := 20
var lifetime := 3.0
var speed := 520.0
var color := Color(0.2, 0.95, 0.85)

var _sprite: AnimatedSprite2D
var _use_sprite := false

## Built in _init (not _ready) so setup() can configure the sprite right
## after `.new()`, before this node ever enters the tree.
func _init() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.visible = false
	add_child(_sprite)

## `sprite_folder` is a real emberfall_poderes folder (e.g. "disparo_fuego") or
## "" — heroes without an assigned power keep the colored-circle fallback.
## `range_scale` shortens/lengthens reach for short-range powers (e.g. Raiken's
## fist wave, or any melee swing) by scaling how long the shot travels before
## it expires. `frame_names` overrides the default projectile_00/01 pair —
## melee effects use their own filenames (slash_x_00.png, ...), and passing a
## single name freezes the sprite on that one frame (Mordrak's alternating
## swings). `visual_scale` overrides the default on-screen size, for effects
## that should read larger than a regular shot (e.g. an AoE burst).
func setup(target: Vector2, amount: int, shot_color: Color = Color(0.2, 0.95, 0.85), sprite_folder: String = "", range_scale: float = 1.0, frame_names: PackedStringArray = PackedStringArray(), visual_scale: float = -1.0) -> void:
	direction = global_position.direction_to(target)
	damage_amount = amount
	color = shot_color
	lifetime *= range_scale
	if visual_scale > 0.0:
		_sprite.scale = Vector2(visual_scale, visual_scale)
	# Art is a single right-facing sprite; rotating the child (not the root,
	# which stays unrotated so `direction` keeps driving movement cleanly)
	# points it at the real aim angle instead of only flipping left/right.
	_sprite.rotation = direction.angle()
	if sprite_folder != "":
		_use_sprite = true
		_sprite.sprite_frames = _build_frames(sprite_folder, frame_names)
		_sprite.play("fly")
		_sprite.visible = true

func _build_frames(folder: String, frame_names: PackedStringArray) -> SpriteFrames:
	var names := frame_names if frame_names.size() > 0 else DEFAULT_FRAME_NAMES
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("fly")
	frames.set_animation_loop("fly", true)
	frames.set_animation_speed("fly", SPRITE_FPS)
	var base := "%s/%s" % [SPRITE_DIR, folder]
	for frame_name in names:
		frames.add_frame("fly", load("%s/%s" % [base, frame_name]))
	return frames

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	if _use_sprite:
		return
	draw_circle(Vector2.ZERO, 7, color)
	draw_circle(Vector2.ZERO, 2.5, Color.WHITE)
