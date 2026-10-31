extends EmberfallEnemy
class_name EmberfallBoss

## One boss per campaign chapter, each with its own sprite and its own two
## telegraphed patterns (art and pattern spec:
## assets/Emberfall_Jefes_Simplificados/README.md). Every pattern shows a
## clear warning first, so losing reads as "I didn't move" rather than
## "I couldn't have known".
##
## - Coloso Rúnico (chapter 1): Embestida (line dash at the spot locked when
##   the warning starts) and Golpe al Suelo (ring around itself).
## - Guardián Hueco (chapter 2): Barrido (wide frontal arc) and Abanico Rúnico
##   (3 rune bolts).
## - Matriarca de Ceniza (chapter 3): Cono de Fuego (short frontal cone) and
##   Zonas Rúnicas (3 circles on the map that explode after a delay).

enum Pattern { CHARGE, SLAM, SWEEP, RUNE_FAN, FIRE_CONE, ZONES }

## Kept under these names because game_world picks it per chapter.
## STANDARD = Coloso, HEAVY = Guardián, AGGRESSIVE = Matriarca.
enum Variant { STANDARD, HEAVY, AGGRESSIVE }

const ART_DIR := "res://assets/Emberfall_Jefes_Simplificados/"
const VARIANT_INFO := {
	Variant.STANDARD: {
		"name": "Coloso Rúnico", "folder": "01_coloso_runico",
		"patterns": [Pattern.CHARGE, Pattern.SLAM],
		# Which way each attack pose faces in the art: -1 left, 0 symmetric, 1 right.
		"facing": [-1, 0],
	},
	Variant.HEAVY: {
		"name": "Guardián Hueco", "folder": "02_guardian_hueco",
		"patterns": [Pattern.SWEEP, Pattern.RUNE_FAN],
		"facing": [-1, 1],
	},
	Variant.AGGRESSIVE: {
		"name": "Matriarca de Ceniza", "folder": "03_matriarca_ceniza",
		"patterns": [Pattern.FIRE_CONE, Pattern.ZONES],
		"facing": [1, 0],
	},
}

const SPRITE_SIZE := 150.0
const PATTERN_COOLDOWN := 4.0 # seconds spent chasing between attacks
const TELEGRAPH_TIME := 0.9
const RECOVER_TIME := 0.55
const WARN_COLOR := Color(0.95, 0.40, 0.27)

const CHARGE_SPEED := 430.0
const CHARGE_DURATION := 0.6
const CHARGE_DAMAGE := 3
const SLAM_RADIUS := 130.0
const SLAM_DAMAGE := 3
const SWEEP_RADIUS := 175.0
const SWEEP_HALF_ANGLE := 1.134 # 65°
const SWEEP_DAMAGE := 3
const RUNE_COUNT := 3
const RUNE_SPREAD := 0.524 # 30°
const RUNE_SPEED := 240.0
const RUNE_DAMAGE := 2
const CONE_RADIUS := 200.0
const CONE_HALF_ANGLE := 0.489 # 28°
const CONE_DAMAGE := 3
const ZONE_COUNT := 3
const ZONE_RADIUS := 70.0
const ZONE_DAMAGE := 2

var variant: int = Variant.STANDARD
var display_name := "Coloso Rúnico"
var pattern_cooldown := PATTERN_COOLDOWN

var _patterns: Array = [Pattern.CHARGE, Pattern.SLAM]
var _facing: Array = [-1, 0]
var _poses: Array[Texture2D] = []
var _state := "chase" # chase, telegraph, charge, recover
var _pattern_clock := 0.0
var _pattern_index := 0 # 0 or 1 inside _patterns
var _current_pattern: int = Pattern.CHARGE
var _telegraph_elapsed := 0.0
var _locked_direction := Vector2.RIGHT
var _locked_target := Vector2.ZERO
var _charge_elapsed := 0.0
var _recover_elapsed := 0.0
var _look_right := true

## Called right after setup(), which only knows is_boss=true.
func configure_variant(new_variant: int) -> void:
	variant = new_variant
	var info: Dictionary = VARIANT_INFO.get(variant, VARIANT_INFO[Variant.STANDARD])
	display_name = str(info["name"])
	_patterns = info["patterns"]
	_facing = info["facing"]
	var folder := ART_DIR + str(info["folder"]) + "/"
	_poses.clear()
	for file in ["idle.png", "attack_01.png", "attack_02.png"]:
		_poses.append(load(folder + file) as Texture2D)
	match variant:
		Variant.HEAVY: # tankier and slower, but hits a wide area
			hp = int(hp * 1.25)
			max_hp = hp
			move_speed *= 0.85
			pattern_cooldown = PATTERN_COOLDOWN * 1.1
		Variant.AGGRESSIVE: # finale: faster and attacks more often
			hp = int(hp * 1.1)
			max_hp = hp
			move_speed *= 1.1
			pattern_cooldown = PATTERN_COOLDOWN * 0.8
		_:
			pass

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target) or GameState.screen != "playing":
		return
	hit_flash = maxf(0.0, hit_flash - delta * 7.0)
	_tick_status(delta)
	if dead:
		return
	match _state:
		"chase": _process_chase(delta)
		"telegraph": _process_telegraph(delta)
		"charge": _process_charge(delta)
		"recover": _process_recover(delta)
	queue_redraw()

func _process_chase(delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	var speed_scale := 0.35 if freeze_timer > 0.0 else 1.0
	velocity = direction * move_speed * speed_scale
	move_and_slide()
	_look_right = target.global_position.x >= global_position.x
	_check_contact_damage(delta, contact_damage)
	_pattern_clock += delta
	if _pattern_clock >= pattern_cooldown:
		_pattern_clock = 0.0
		_begin_pattern()

## Alternates the two patterns, with a 30% chance to repeat one so the
## rhythm isn't fully predictable.
func _begin_pattern() -> void:
	if randf() > 0.3:
		_pattern_index = 1 - _pattern_index
	_current_pattern = int(_patterns[_pattern_index])
	_state = "telegraph"
	_telegraph_elapsed = 0.0
	velocity = Vector2.ZERO
	_locked_target = target.global_position
	_locked_direction = global_position.direction_to(_locked_target)
	if _locked_direction == Vector2.ZERO:
		_locked_direction = Vector2.RIGHT
	_look_right = _locked_direction.x >= 0.0
	SfxPlayer.play("boss/boss_telegraph.wav", false)
	if _current_pattern == Pattern.ZONES:
		_spawn_zones() # the zones carry their own warning

func _process_telegraph(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_check_contact_damage(delta, contact_damage)
	_telegraph_elapsed += delta
	if _telegraph_elapsed >= TELEGRAPH_TIME:
		_execute_pattern()

func _execute_pattern() -> void:
	match _current_pattern:
		Pattern.CHARGE:
			_charge_elapsed = 0.0
			_state = "charge"
			return
		Pattern.SLAM:
			if global_position.distance_to(target.global_position) < SLAM_RADIUS:
				target.damage(SLAM_DAMAGE)
			_spawn_fx("explosion_area", global_position, SLAM_RADIUS)
		Pattern.SWEEP:
			if _in_sector(SWEEP_RADIUS, SWEEP_HALF_ANGLE):
				target.damage(SWEEP_DAMAGE)
		Pattern.RUNE_FAN:
			_fire_runes()
		Pattern.FIRE_CONE:
			if _in_sector(CONE_RADIUS, CONE_HALF_ANGLE):
				target.damage(CONE_DAMAGE)
		Pattern.ZONES:
			pass
	SfxPlayer.play("boss/boss_impact.wav", false)
	_enter_recover()

func _process_charge(delta: float) -> void:
	velocity = _locked_direction * CHARGE_SPEED
	move_and_slide()
	_check_contact_damage(delta, CHARGE_DAMAGE, true)
	_charge_elapsed += delta
	if _charge_elapsed >= CHARGE_DURATION:
		_enter_recover()

func _enter_recover() -> void:
	_state = "recover"
	_recover_elapsed = 0.0

func _process_recover(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_check_contact_damage(delta, contact_damage)
	_recover_elapsed += delta
	if _recover_elapsed >= RECOVER_TIME:
		_state = "chase"

func _check_contact_damage(delta: float, amount: int, is_attack_pattern: bool = false) -> void:
	hit_clock = maxf(0.0, hit_clock - delta)
	if global_position.distance_to(target.global_position) < CONTACT_RANGE and hit_clock <= 0.0:
		hit_clock = 1.2
		target.damage(amount)
		if is_attack_pattern:
			SfxPlayer.play("boss/boss_impact.wav", false)

## True when the player stands inside the cone locked at telegraph start.
func _in_sector(radius: float, half_angle: float) -> bool:
	var to_player := target.global_position - global_position
	if to_player.length() > radius:
		return false
	return absf(_locked_direction.angle_to(to_player)) <= half_angle

func _fire_runes() -> void:
	if not is_instance_valid(game_ref):
		return
	var aim := global_position.direction_to(target.global_position)
	for i in RUNE_COUNT:
		var proj := EmberfallBossProjectile.new()
		proj.global_position = global_position
		proj.direction = aim.rotated(RUNE_SPREAD * (i - (RUNE_COUNT - 1) / 2.0))
		proj.speed = RUNE_SPEED
		proj.damage_amount = RUNE_DAMAGE
		proj.target = target
		proj.rune = true
		game_ref.add_child(proj)

## One zone on the player and two around them, so standing still is never safe.
func _spawn_zones() -> void:
	if not is_instance_valid(game_ref):
		return
	var start_angle := randf() * TAU
	for i in ZONE_COUNT:
		var zone := EmberfallBossZone.new()
		var offset := Vector2.ZERO
		if i > 0:
			offset = Vector2.from_angle(start_angle + PI * (i - 1)) * randf_range(90.0, 130.0)
		zone.global_position = _locked_target + offset
		zone.radius = ZONE_RADIUS
		zone.delay = TELEGRAPH_TIME + 0.4
		zone.damage_amount = ZONE_DAMAGE
		zone.target = target
		game_ref.add_child(zone)

func _spawn_fx(kind: String, at: Vector2, radius: float) -> void:
	if is_instance_valid(game_ref) and game_ref.has_method("_spawn_ability_fx"):
		game_ref._spawn_ability_fx(kind, at, radius)

func _pose_index() -> int:
	if _state == "chase":
		return 0
	return 1 + _pattern_index

func _draw() -> void:
	if _state == "telegraph":
		_draw_telegraph()
	elif _state == "recover":
		_draw_aftermath()
	var pose := _pose_index()
	var texture: Texture2D = _poses[pose] if pose < _poses.size() else null
	draw_set_transform(Vector2(0, SPRITE_SIZE * 0.36), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, SPRITE_SIZE * 0.32, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if texture:
		var facing := 0 if pose == 0 else int(_facing[pose - 1])
		var flip := (facing < 0 and _look_right) or (facing > 0 and not _look_right) or (facing == 0 and not _look_right and pose == 0)
		var glow := 1.0 + hit_flash * (0.6 if GameState.reduce_motion else 2.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
		draw_texture_rect(texture, Rect2(-SPRITE_SIZE / 2.0, -SPRITE_SIZE * 0.6, SPRITE_SIZE, SPRITE_SIZE), false, Color(glow, glow, glow))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Name + health bar over the head (the HUD keeps the top of the screen
	# for the hero's own XP and hearts).
	var bar_width := 130.0
	var bar_height := 9.0
	var bar_y := -SPRITE_SIZE * 0.6 - 10.0
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(-bar_width / 2.0 - 2.0, bar_y - 2.0, bar_width + 4.0, bar_height + 4.0), Color(0.02, 0.02, 0.05, 0.9))
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width * ratio, bar_height), Color("d96168"))
	draw_rect(Rect2(-bar_width / 2.0, bar_y, bar_width * ratio, 3.0), Color(1.0, 0.62, 0.62, 0.8))
	var font := ThemeDB.fallback_font
	var label := display_name.to_upper()
	var font_size := 12
	var text_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_pos := Vector2(-text_width / 2.0, bar_y - 6.0)
	draw_string_outline(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.9))
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("ffd166"))
	draw_status_icons(Vector2(0, bar_y - 26.0))

func _draw_telegraph() -> void:
	var progress := clampf(_telegraph_elapsed / TELEGRAPH_TIME, 0.0, 1.0)
	var alpha := 0.25 + progress * 0.45
	match _current_pattern:
		Pattern.CHARGE:
			var end := _locked_direction * CHARGE_SPEED * CHARGE_DURATION
			draw_line(Vector2.ZERO, end, Color(WARN_COLOR, alpha * 0.5), 40.0)
			draw_line(Vector2.ZERO, end * progress, Color(WARN_COLOR, alpha), 40.0)
		Pattern.SLAM:
			draw_circle(Vector2.ZERO, SLAM_RADIUS, Color(1.0, 0.5, 0.1, 0.10))
			draw_circle(Vector2.ZERO, SLAM_RADIUS * progress, Color(1.0, 0.5, 0.1, 0.18))
			draw_arc(Vector2.ZERO, SLAM_RADIUS, 0.0, TAU, 40, Color(0.95, 0.63, 0.22, alpha), 3.0)
		Pattern.SWEEP:
			_draw_sector(SWEEP_RADIUS, SWEEP_HALF_ANGLE, Color(0.55, 0.3, 1.0, 0.10), Color(0.55, 0.3, 1.0, alpha))
			_draw_sector(SWEEP_RADIUS * progress, SWEEP_HALF_ANGLE, Color(0.55, 0.3, 1.0, 0.16), Color(0, 0, 0, 0))
		Pattern.RUNE_FAN:
			var aim := global_position.direction_to(target.global_position)
			for i in RUNE_COUNT:
				var dir := aim.rotated(RUNE_SPREAD * (i - (RUNE_COUNT - 1) / 2.0))
				draw_line(Vector2.ZERO, dir * 190.0, Color(0.55, 0.3, 1.0, alpha), 3.0)
		Pattern.FIRE_CONE:
			_draw_sector(CONE_RADIUS, CONE_HALF_ANGLE, Color(1.0, 0.5, 0.1, 0.10), Color(1.0, 0.55, 0.2, alpha))
			_draw_sector(CONE_RADIUS * progress, CONE_HALF_ANGLE, Color(1.0, 0.5, 0.1, 0.18), Color(0, 0, 0, 0))
		Pattern.ZONES:
			pass

## Short flash of the area that was just hit, so the player sees what landed.
func _draw_aftermath() -> void:
	var fade := 1.0 - clampf(_recover_elapsed / 0.3, 0.0, 1.0)
	if fade <= 0.0:
		return
	match _current_pattern:
		Pattern.SWEEP:
			_draw_sector(SWEEP_RADIUS, SWEEP_HALF_ANGLE, Color(0.62, 0.45, 1.0, 0.45 * fade), Color(0.85, 0.75, 1.0, fade))
		Pattern.FIRE_CONE:
			_draw_sector(CONE_RADIUS, CONE_HALF_ANGLE, Color(1.0, 0.55, 0.15, 0.55 * fade), Color(1.0, 0.85, 0.4, fade))

func _draw_sector(radius: float, half_angle: float, fill: Color, outline: Color) -> void:
	if radius <= 1.0:
		return
	var base := _locked_direction.angle()
	var points := PackedVector2Array([Vector2.ZERO])
	var steps := 16
	for i in steps + 1:
		var a := base - half_angle + 2.0 * half_angle * float(i) / float(steps)
		points.append(Vector2.from_angle(a) * radius)
	draw_colored_polygon(points, fill)
	if outline.a > 0.0:
		points.append(Vector2.ZERO)
		draw_polyline(points, outline, 2.5)
