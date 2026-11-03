class_name CharacterAnimations
extends RefCounted

## Builds a SpriteFrames from one of the emberfall_sprites_2d_simple folders:
## walk_right/walk_left (3 frames, looping) and attack (2 frames, one-shot).
## Idle just reuses the first walk frame of whichever way the player last
## faced, per the pack's own README.
const BASE_DIR := "res://assets/personajes/heroes"
const WALK_FPS := 7.0
const ATTACK_FPS := 9.0

static func build_sprite_frames(folder: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var base := "%s/%s" % [BASE_DIR, folder]

	for dir in ["right", "left"]:
		var anim := "walk_%s" % dir
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, WALK_FPS)
		for i in 3:
			frames.add_frame(anim, load("%s/walk_%s_%02d.png" % [base, dir, i]))

	frames.add_animation("attack")
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", ATTACK_FPS)
	for i in 2:
		frames.add_frame("attack", load("%s/attack_%02d.png" % [base, i]))

	for dir in ["right", "left"]:
		var idle := "idle_%s" % dir
		frames.add_animation(idle)
		frames.set_animation_loop(idle, false)
		frames.add_frame(idle, frames.get_frame_texture("walk_%s" % dir, 0))
	return frames
