extends CharacterBody2D
class_name EmberfallPlayer

signal died
const BASE_MAX_HP := 6 # 3 hearts, 2 half-heart units each
const DEFAULT_SPRITE_FOLDER := "variante_01_baculo (Vaelor)"
const SPRITE_SCALE := 0.2 # 256px source frames down to ~50px on screen

var hp := BASE_MAX_HP
var max_hp := BASE_MAX_HP
var speed := 220.0
var invulnerable := 0.0
var attack_clock := 0.0
var game: Node
var touch_direction := Vector2.ZERO
var _regen_accum := 0.0
var _sprite: AnimatedSprite2D
var _facing_right := true
var _attack_anim_time := 0.0

## Continuous aim direction, not just the 2-way body-sprite facing: updated
## whenever the player actually moves, and read as a fallback by anything
## that wants "the direction the player is oriented" when there's no live
## target to aim at (the basic attack itself always has one, since it only
## fires when an enemy exists — see game_world.spawn_projectile).
var facing_direction := Vector2.RIGHT

## Where shots/effects originate — a fixed offset toward the front of the
## character, not the body center/feet. Kept as a real child node (not just
## a computed offset) so it's easy to see/adjust in the editor later.
var projectile_origin: Marker2D

func setup(owner: Node) -> void:
	game = owner
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	max_hp += GameState.permanent_health + GameState.get_equipped_bonus("health")
	if hero_data != null:
		max_hp = maxi(2, max_hp + hero_data.hp_modifier)
	hp = max_hp
	speed *= 1.0 + (GameState.permanent_speed + GameState.get_equipped_bonus("speed")) * 0.05
	if hero_data != null:
		speed *= hero_data.move_speed_modifier
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.0, 1.0)
	camera.position_smoothing_enabled = true
	camera.enabled = true
	add_child(camera)

	var folder := GameState.selected_character_sprite_folder if GameState.selected_character_sprite_folder != "" else DEFAULT_SPRITE_FOLDER
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = CharacterAnimations.build_sprite_frames(folder)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(_sprite)
	_sprite.play("idle_right")

	projectile_origin = Marker2D.new()
	projectile_origin.name = "ProjectileOrigin"
	projectile_origin.position = Vector2(10, -8) # slightly forward/up from center, not the feet
	add_child(projectile_origin)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not game or GameState.screen != "playing":
		return
	var input := touch_direction if touch_direction.length_squared() > 0.01 else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input.length_squared() > 0.01:
		facing_direction = input.normalized()
	velocity = input * speed * game.speed_multiplier()
	move_and_slide()
	position.x = clampf(position.x, -760.0, 760.0)
	position.y = clampf(position.y, -760.0, 760.0)
	invulnerable = maxf(0.0, invulnerable - delta)
	_tick_regen(delta)
	_update_animation(input, delta)
	attack_clock += delta
	var directed_level: int = game.skills.get("directed", 1)
	var base_interval := 1.2 - float(directed_level - 1) * 0.1
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	var hero_attack_speed_mod := hero_data.attack_speed_modifier if hero_data != null else 1.0
	var attack_interval := maxf(0.25, base_interval * game.attack_speed_multiplier() * hero_attack_speed_mod)
	if attack_clock >= attack_interval:
		attack_clock = 0.0
		game.spawn_projectile(self)
		_play_attack()
	queue_redraw()

## Walk while moving, idle on the last frame faced otherwise; an attack in
## progress takes priority over both until its short duration elapses.
func _update_animation(input: Vector2, delta: float) -> void:
	if _attack_anim_time > 0.0:
		_attack_anim_time = maxf(0.0, _attack_anim_time - delta)
		return
	if absf(input.x) > 0.05:
		_facing_right = input.x > 0.0
		projectile_origin.position.x = absf(projectile_origin.position.x) * (1.0 if _facing_right else -1.0)
	var moving := input.length_squared() > 0.01
	var target := ("walk_right" if _facing_right else "walk_left") if moving else ("idle_right" if _facing_right else "idle_left")
	if _sprite.animation != target:
		_sprite.play(target)

func _play_attack() -> void:
	_attack_anim_time = 2.0 / CharacterAnimations.ATTACK_FPS
	_sprite.play("attack")

func _tick_regen(delta: float) -> void:
	var rate: float = game.regen_per_second()
	if rate <= 0.0 or hp >= max_hp:
		return
	_regen_accum += rate * delta
	var whole := int(_regen_accum)
	if whole > 0:
		_regen_accum -= whole
		hp = mini(max_hp, hp + whole)
		queue_redraw()

func damage(amount: int) -> void:
	if invulnerable > 0.0 or GameState.screen != "playing":
		return
	invulnerable = 1.2
	hp = maxi(0, hp - amount)
	SfxPlayer.play("combat/player_hit.wav")
	if hp == 0:
		died.emit()
	queue_redraw()

func _draw() -> void:
	var heart_count := int(ceil(max_hp / 2.0))
	var row_width := heart_count * 13.0 - 3.0
	HeartsRow.draw_row(self, Vector2(-row_width / 2.0, -46), 10.0, 3.0, hp, max_hp, Color("e65a5a"), Color("4a3f5c"))
