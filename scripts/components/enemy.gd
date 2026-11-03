extends CharacterBody2D
class_name EmberfallEnemy

## STAGE-01: five archetypes so encounters can differ by more than enemy HP.
## CHASER is the original, unchanged behavior (also what bosses build on top
## of via their own state machine, which never reads `archetype`).
enum Archetype { CHASER, FAST, TANK, SHOOTER, CHARGER }

var hp := 30
var max_hp := 30
var move_speed := 80.0
var contact_damage := 10
var target: Node2D
var xp_value := 10
var gold_value := 6
var hit_clock := 0.0
var dead := false
var is_boss := false
var game_ref: Node
var archetype: int = Archetype.CHASER
## 0 = regular, 1 = élite (drops a chest), 2 = mini-jefe (drops an epic chest).
var elite_tier := 0

const CONTACT_RANGE := 48.0 # matches the distance check in _check_contact

var poison_timer := 0.0
var poison_tick_clock := 0.0
var poison_damage := 0
var burn_timer := 0.0
var burn_tick_clock := 0.0
var burn_damage := 0
var freeze_timer := 0.0
## Electrocutado (Cadena Eléctrica): the next hit taken deals +25%.
var shock_timer := 0.0
var hit_flash := 0.0
## Push from abilities (Eclipse Eterno, Bastión), decays on its own. Bosses
## ignore it — their state machine owns their movement.
var _knockback := Vector2.ZERO

# Shooter (tirador): holds a preferred distance and fires at the player
# instead of closing in for contact damage.
const SHOOTER_PREFERRED_RANGE := 260.0
const SHOOTER_FIRE_INTERVAL := 1.8
const SHOOTER_PROJECTILE_SPEED := 220.0
var _shoot_clock := 0.0

# Charger (cargador): chases normally, then periodically commits to a fast
# dash — a simpler, cheaper cousin of the boss's own charge pattern.
const CHARGER_INTERVAL := 3.0
const CHARGER_SPEED_MULT := 2.6
const CHARGER_DURATION := 0.5
var _charge_clock := 0.0
var _charging := false
var _charger_elapsed := 0.0
var _charger_direction := Vector2.RIGHT

func setup(player: Node2D, difficulty: float, boss: bool = false, new_archetype: int = Archetype.CHASER) -> void:
	target = player
	is_boss = boss
	archetype = new_archetype
	if is_boss:
		hp = int(600.0 * difficulty)
		move_speed = 52.0
		contact_damage = 2 # 1 full heart per hit, regardless of difficulty
		xp_value = 150
		gold_value = 120
	else:
		match archetype:
			Archetype.FAST:
				hp = int(18.0 * difficulty)
				move_speed = 68.0 + difficulty * 10.0 + 70.0
				contact_damage = 1
			Archetype.TANK:
				hp = int(75.0 * difficulty)
				move_speed = maxf(40.0, 68.0 + difficulty * 10.0 - 35.0)
				contact_damage = 2
			Archetype.SHOOTER:
				hp = int(20.0 * difficulty)
				move_speed = 68.0 + difficulty * 10.0 - 8.0
				contact_damage = 1
			Archetype.CHARGER:
				hp = int(26.0 * difficulty)
				move_speed = 68.0 + difficulty * 10.0
				contact_damage = 1
			_:
				hp = int(30.0 * difficulty)
				move_speed = 68.0 + difficulty * 10.0
				contact_damage = 1
		xp_value = 10
		gold_value = 6
	max_hp = hp

## Élite / mini-jefe: same archetype behavior, much tougher, bigger and with
## a golden aura so it reads as "worth chasing" from across the screen.
func make_elite(tier: int) -> void:
	elite_tier = tier
	var hp_mult := 22.0 if tier >= 2 else 8.0
	hp = int(hp * hp_mult)
	max_hp = hp
	contact_damage += 1
	move_speed *= 0.9 if tier >= 2 else 0.95
	xp_value *= 8 if tier >= 2 else 5
	gold_value *= 5 if tier >= 2 else 3

func apply_poison(duration: float, damage_per_tick: int) -> void:
	poison_timer = maxf(poison_timer, duration)
	poison_damage = maxi(poison_damage, damage_per_tick)

func apply_burn(duration: float, damage_per_tick: int) -> void:
	burn_timer = maxf(burn_timer, duration)
	burn_damage = maxi(burn_damage, damage_per_tick)

func apply_freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)
	SfxPlayer.play("status/freeze_apply.wav")

func apply_shock(duration: float) -> void:
	shock_timer = maxf(shock_timer, duration)

## Returns the multiplier for an incoming hit and consumes the shock.
func consume_shock() -> float:
	if shock_timer <= 0.0:
		return 1.0
	shock_timer = 0.0
	return 1.25

func knockback(impulse: Vector2) -> void:
	if not is_boss:
		_knockback = impulse

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target) or GameState.screen != "playing":
		return
	hit_flash = maxf(0.0, hit_flash - delta * 7.0)
	_tick_status(delta)
	if dead:
		return
	match archetype:
		Archetype.SHOOTER:
			_process_shooter(delta)
		Archetype.CHARGER:
			_process_charger(delta)
		_:
			_process_chase(delta)
	if _knockback.length_squared() > 1.0:
		position += _knockback * delta
		_knockback = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	queue_redraw()

func _process_chase(delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	var speed_scale := 0.35 if freeze_timer > 0.0 else 1.0
	velocity = direction * move_speed * speed_scale
	move_and_slide()
	_check_contact(delta)

func _check_contact(delta: float) -> void:
	hit_clock = maxf(0.0, hit_clock - delta)
	if global_position.distance_to(target.global_position) < CONTACT_RANGE and hit_clock <= 0.0:
		hit_clock = 1.2
		target.damage(contact_damage)

## Tirador: keeps its distance (backs off if the player gets close, closes in
## if too far) and fires at the player instead of relying only on contact.
func _process_shooter(delta: float) -> void:
	var distance := global_position.distance_to(target.global_position)
	var direction := global_position.direction_to(target.global_position)
	var speed_scale := 0.35 if freeze_timer > 0.0 else 1.0
	if distance > SHOOTER_PREFERRED_RANGE:
		velocity = direction * move_speed * speed_scale
	elif distance < SHOOTER_PREFERRED_RANGE * 0.7:
		velocity = -direction * move_speed * speed_scale * 0.6
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_check_contact(delta)
	_shoot_clock += delta
	if _shoot_clock >= SHOOTER_FIRE_INTERVAL and distance < SHOOTER_PREFERRED_RANGE * 1.3:
		_shoot_clock = 0.0
		_fire_at_player()

func _fire_at_player() -> void:
	if not is_instance_valid(game_ref):
		return
	var proj := EmberfallBossProjectile.new()
	proj.global_position = global_position
	proj.direction = global_position.direction_to(target.global_position)
	proj.speed = SHOOTER_PROJECTILE_SPEED
	proj.damage_amount = contact_damage * 2
	proj.target = target
	game_ref.add_child(proj)

## Cargador: chases normally, then periodically commits to a short, fast
## dash — telegraphed only by its own approach speed picking up, not a full
## boss-style warning (it's a rank-and-file enemy, not a boss encounter).
func _process_charger(delta: float) -> void:
	if _charging:
		velocity = _charger_direction * move_speed * CHARGER_SPEED_MULT
		move_and_slide()
		_check_contact(delta)
		_charger_elapsed += delta
		if _charger_elapsed >= CHARGER_DURATION:
			_charging = false
			_charge_clock = 0.0
		return
	var direction := global_position.direction_to(target.global_position)
	var speed_scale := 0.35 if freeze_timer > 0.0 else 1.0
	velocity = direction * move_speed * speed_scale
	move_and_slide()
	_check_contact(delta)
	_charge_clock += delta
	if _charge_clock >= CHARGER_INTERVAL:
		_charging = true
		_charger_elapsed = 0.0
		_charger_direction = global_position.direction_to(target.global_position)

func _tick_status(delta: float) -> void:
	freeze_timer = maxf(0.0, freeze_timer - delta)
	shock_timer = maxf(0.0, shock_timer - delta)
	if poison_timer > 0.0:
		poison_timer -= delta
		poison_tick_clock -= delta
		if poison_tick_clock <= 0.0:
			poison_tick_clock = 1.0
			_status_damage(poison_damage, "status/poison_tick.wav", "poison")
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_clock -= delta
		if burn_tick_clock <= 0.0:
			burn_tick_clock = 1.0
			_status_damage(burn_damage, "status/burn_tick.wav", "burn")

## Damage from poison/burn ticks bypasses combat multipliers (crit, boost_damage)
## since it's a flat damage-over-time effect, but still grants kill rewards.
func _status_damage(amount: int, sfx: String, source: String) -> void:
	SfxPlayer.play(sfx)
	if is_instance_valid(game_ref) and game_ref.has_method("spawn_damage_number"):
		game_ref.spawn_damage_number(global_position, amount, false)
	if is_instance_valid(game_ref) and game_ref.has_method("record_damage"):
		game_ref.record_damage(source, mini(amount, hp))
	if damage(amount) and is_instance_valid(game_ref) and game_ref.has_method("_on_enemy_killed"):
		game_ref._on_enemy_killed(self)

func damage(amount: int) -> bool:
	if dead:
		return false
	hp -= amount
	hit_flash = 0.7
	if hp <= 0:
		dead = true
		queue_free()
		return true
	queue_redraw()
	return false

static var _shared_texture: Texture2D

func _init() -> void:
	# The walk art is big and drawn small: smooth it so it doesn't shimmer.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

## Walk frames per archetype and chapter: assets/enemigos/<type>/cap<N>/
## walk_00..02.png (cropped to the character, so they align by the feet).
## A chapter missing its art borrows another chapter's; no art at all falls
## back to the shared tinted sprite.
const ENEMY_ART_DIR := "res://assets/enemigos/"
const ARCHETYPE_FOLDERS := {
	Archetype.CHASER: "chaser", Archetype.FAST: "fast", Archetype.TANK: "tank",
	Archetype.SHOOTER: "shooter", Archetype.CHARGER: "charger",
}
## Which way each art faces (-1 left, 1 right, 0 front): it is flipped when
## the enemy walks the other way.
const ART_FACING := {"fast": -1, "charger": 1}
const WALK_FPS := 7.0
const WALK_CYCLE := [0, 1, 2, 1]
static var _walk_cache := {}
var _walk_phase := randf() * 10.0
var _face_left := false

static func walk_frames(folder: String, chapter: int) -> Array:
	var key := "%s/%d" % [folder, chapter]
	if _walk_cache.has(key):
		return _walk_cache[key]
	var frames: Array = []
	for cap in [chapter, 1, 2, 3]:
		var base := "%s%s/cap%d/" % [ENEMY_ART_DIR, folder, cap]
		if ResourceLoader.exists(base + "walk_00.png"):
			for i in 3:
				var path := base + "walk_%02d.png" % i
				if ResourceLoader.exists(path):
					frames.append(load(path))
			break
	_walk_cache[key] = frames
	return frames

## What the enemy looks like right now (for the death effect).
func death_texture() -> Texture2D:
	var frames: Array = [] if is_boss else walk_frames(_art_folder(), int(GameState.current_stage_context.get("chapter", 1)))
	if not frames.is_empty():
		return frames[0]
	if _shared_texture == null:
		_shared_texture = load("res://assets/characters/enemy.png") as Texture2D
	return _shared_texture

func uses_own_art() -> bool:
	return not is_boss and not walk_frames(_art_folder(), int(GameState.current_stage_context.get("chapter", 1))).is_empty()

func faces_left() -> bool:
	var facing: int = ART_FACING.get(_art_folder(), 0)
	return facing != 0 and ((_face_left and facing > 0) or (not _face_left and facing < 0))

func _art_folder() -> String:
	return "elite" if elite_tier > 0 else str(ARCHETYPE_FOLDERS.get(archetype, "chaser"))

## Archetypes share the one enemy sprite (no new art) — a distinct tint and
## size per type is enough to read as a different threat at a glance.
const ARCHETYPE_TINTS := {
	Archetype.CHASER: Color(1.0, 1.0, 1.0),
	Archetype.FAST: Color(0.72, 0.92, 0.58),
	Archetype.TANK: Color(0.86, 0.79, 0.54),
	Archetype.SHOOTER: Color(0.62, 0.78, 0.92),
	Archetype.CHARGER: Color(1.25, 0.48, 0.34),
}
const ARCHETYPE_SIZES := {
	Archetype.CHASER: 60.0,
	Archetype.FAST: 52.0,
	Archetype.TANK: 74.0,
	Archetype.SHOOTER: 56.0,
	Archetype.CHARGER: 62.0,
}

## Overridden by EmberfallBoss so its 3 campaign variants read as visually
## distinct even though they share this one sprite/draw path.
func _boss_tint() -> Color:
	return Color(1.4, 0.7, 0.7)


## On-screen size, also used by the death effect.
func visual_size() -> float:
	var size := 100.0 if is_boss else float(ARCHETYPE_SIZES.get(archetype, 60.0))
	if elite_tier > 0:
		size *= 1.8 if elite_tier >= 2 else 1.4
	return size

func visual_tint() -> Color:
	if is_boss:
		return _boss_tint()
	return ARCHETYPE_TINTS.get(archetype, Color.WHITE)

func _draw() -> void:
	var size := visual_size()
	if elite_tier > 0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
		var aura := Color("e8b84a") if elite_tier == 1 else Color("b07cff")
		draw_circle(Vector2.ZERO, size * 0.55, Color(aura, 0.10 + 0.08 * pulse))
		draw_arc(Vector2.ZERO, size * 0.55, 0.0, TAU, 32, Color(aura, 0.55 + 0.3 * pulse), 2.5)
	draw_set_transform(Vector2(0, size * 0.42), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, size * 0.36, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var frames: Array = [] if is_boss else walk_frames(_art_folder(), int(GameState.current_stage_context.get("chapter", 1)))
	var top := -size / 2.0
	if not frames.is_empty():
		top = _draw_walk(frames, size)
	elif _shared_texture == null:
		_shared_texture = load("res://assets/characters/enemy.png") as Texture2D
	if frames.is_empty() and _shared_texture:
		var tint := visual_tint()
		if freeze_timer > 0.0:
			tint = tint * Color(0.7, 0.9, 1.3)
		elif burn_timer > 0.0:
			tint = tint * Color(1.2, 0.85, 0.7)
		# Values above 1 brighten the sprite: a real white flash on hit.
		var flash := hit_flash * (0.6 if GameState.reduce_motion else 2.5)
		tint = Color(tint.r + flash, tint.g + flash, tint.b + flash, tint.a)
		draw_texture_rect(_shared_texture, Rect2(-size / 2, -size / 2, size, size), false, tint)
	var bar_width := 90.0 if is_boss else (70.0 if elite_tier > 0 else 50.0)
	draw_rect(Rect2(-bar_width / 2, top - 9, bar_width, 4), Color(0.04, 0.08, 0.10, 0.85))
	draw_rect(Rect2(-bar_width / 2, top - 9, bar_width * clampf(float(hp) / float(max_hp), 0.0, 1.0), 4), Color(0.95, 0.68, 0.25) if is_boss or elite_tier > 0 else Color(0.91, 0.30, 0.29))
	draw_status_icons(Vector2(0, top - 19))

## Own art: one scale for all frames (from the biggest), bottom-aligned at
## the shadow so the walk cycle doesn't bob in size or slide.
func _draw_walk(frames: Array, size: float) -> float:
	var biggest := 1.0
	for f: Texture2D in frames:
		biggest = maxf(biggest, maxf(f.get_width(), f.get_height()))
	var k := size * 1.15 / biggest
	var t := Time.get_ticks_msec() / 1000.0 + _walk_phase
	var moving := velocity.length() > 5.0
	var index: int = WALK_CYCLE[int(t * WALK_FPS) % WALK_CYCLE.size()] if moving else 0
	var tex: Texture2D = frames[mini(index, frames.size() - 1)]
	if absf(velocity.x) > 5.0:
		_face_left = velocity.x < 0.0
	var facing: int = ART_FACING.get(_art_folder(), 0)
	var flip := facing != 0 and ((_face_left and facing > 0) or (not _face_left and facing < 0))
	var drawn := tex.get_size() * k
	var tint := Color.WHITE
	if freeze_timer > 0.0:
		tint = Color(0.7, 0.9, 1.3)
	elif burn_timer > 0.0:
		tint = Color(1.2, 0.85, 0.7)
	var flash := hit_flash * (0.6 if GameState.reduce_motion else 2.5)
	tint = Color(tint.r + flash, tint.g + flash, tint.b + flash)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect(tex, Rect2(-drawn.x / 2.0, size * 0.45 - drawn.y, drawn.x, drawn.y), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return size * 0.45 - biggest * k

## Small glyphs above the health bar, one per active status, so the player
## can read at a glance what their build is doing to each enemy.
func draw_status_icons(center: Vector2) -> void:
	var active: Array[String] = []
	if burn_timer > 0.0: active.append("burn")
	if poison_timer > 0.0: active.append("poison")
	if freeze_timer > 0.0: active.append("freeze")
	if shock_timer > 0.0: active.append("shock")
	if active.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	var spacing := 15.0
	var x := -spacing * (active.size() - 1) / 2.0
	for status in active:
		var c := center + Vector2(x, sin(t * 6.0 + x) * 1.5)
		# Badge art for burn/poison/freeze (assets/vfx/estados); shock and any
		# missing badge keep the small drawn glyph.
		var badge := EmberfallVfxArt.image("estados/%s.png" % status)
		if badge:
			draw_texture_rect(badge, Rect2(c - Vector2(7, 7), Vector2(14, 14)), false)
			x += spacing
			continue
		draw_circle(c, 6.5, Color(0.05, 0.03, 0.10, 0.75))
		match status:
			"burn":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(4, 3), c + Vector2(-4, 3)]), Color("ff9a3c"))
				draw_circle(c + Vector2(0, 2), 2.0, Color("ffd36a"))
			"poison":
				draw_circle(c + Vector2(0, 1.5), 3.5, Color("5ad65a"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5.5), c + Vector2(3, 0), c + Vector2(-3, 0)]), Color("5ad65a"))
			"freeze":
				for i in 3:
					var d := Vector2.from_angle(PI / 3.0 * i) * 5.0
					draw_line(c - d, c + d, Color("aee6ff"), 1.5)
			"shock":
				draw_polyline(PackedVector2Array([c + Vector2(-2, -5), c + Vector2(2, -1), c + Vector2(-2, 1), c + Vector2(2, 5)]), Color("7ff5ea"), 1.8)
		x += spacing