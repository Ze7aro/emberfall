extends Node2D
class_name EmberfallOrbitalMoon

## Onda Orbital v2 — one glowing moon. Pure visual, same "just a companion"
## role persistent_aura.gd plays for the other auras: OrbitalWave owns its
## position (the elliptical orbit) and its damage/cooldown; this only plays
## the 3-frame glow-pulse loop from onda_orbital_v2's asset pack.

const SPRITE_DIR := "res://assets/emberfall_habilidades_sprites/onda_orbital_v2"
const FPS := 8.0
const VISUAL_SCALE := 0.12 # ~250px content on a 724px canvas down to ~30px

var sprite: AnimatedSprite2D

func _init() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(VISUAL_SCALE, VISUAL_SCALE)
	add_child(sprite)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("glow")
	frames.set_animation_loop("glow", true)
	frames.set_animation_speed("glow", FPS)
	for i in 3:
		frames.add_frame("glow", load("%s/moon_frame_%02d.png" % [SPRITE_DIR, i]))
	sprite.sprite_frames = frames
	# Frames aren't perfectly time-aligned (each moon would otherwise pulse in
	# lockstep, which reads as one blinking ring instead of independent
	# moons) — starting mid-loop at a random offset per instance fixes that.
	sprite.play("glow")
	sprite.frame = randi() % 3
