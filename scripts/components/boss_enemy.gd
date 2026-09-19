extends EmberfallEnemy
class_name EmberfallBoss

## First boss: cycles through 3 telegraphed attack patterns instead of just
## chasing and touching like a regular enemy. Each pattern gives a clear
## visual warning before it deals its damage, so losing to it reads as
## "I didn't move" rather than "I couldn't have known" (ROADMAP BOSS-01).
##
## - Embestida (charge): commits to the player's position when the telegraph
##   starts, then dashes there — dodging means moving off that spot in time.
## - Golpe de Área (slam): a growing danger ring around the boss; stand
##   outside it before it fills in.
## - Ráfaga (barrage): a spread of slow projectiles the player can walk
##   between.

enum Pattern { CHARGE, SLAM, BARRAGE }

## STAGE-01: 3 campaign chapters share this one boss "reused with explicit
## variants" (per the product contract) instead of 3 separately-coded bosses
## — different stats, favored pattern, and tint per variant.
enum Variant { STANDARD, HEAVY, AGGRESSIVE }
const VARIANT_TINTS := {
	Variant.STANDARD: Color(1.4, 0.7, 0.7),
	Variant.HEAVY: Color(0.75, 0.85, 1.5),
	Variant.AGGRESSIVE: Color(1.6, 0.55, 0.35),
}

const PATTERN_COOLDOWN := 4.5 # seconds spent chasing normally between attacks
const TELEGRAPH_TIME := 0.9
const RECOVER_TIME := 0.5
const CHARGE_SPEED := 420.0
const CHARGE_DURATION := 0.6
const CHARGE_DAMAGE_MULT := 2.0
const SLAM_RADIUS := 130.0
const SLAM_DAMAGE_MULT := 2.5
const BARRAGE_COUNT := 5
const BARRAGE_SPREAD_DEG := 80.0
const BARRAGE_SPEED := 220.0

var variant: int = Variant.STANDARD
var pattern_cooldown := PATTERN_COOLDOWN
var _pattern_weights := {Pattern.CHARGE: 1.0, Pattern.SLAM: 1.0, Pattern.BARRAGE: 1.0}

var _state := "chase" # chase, telegraph, charge, recover
var _pattern_clock := 0.0
var _current_pattern: int = Pattern.CHARGE
var _telegraph_elapsed := 0.0
var _telegraph_target := Vector2.ZERO
var _charge_direction := Vector2.RIGHT
var _charge_elapsed := 0.0
var _recover_elapsed := 0.0

## Called right after setup() (which only knows is_boss=true, not which of
## the 3 campaign chapters this fight belongs to).
func configure_variant(new_variant: int) -> void:
	variant = new_variant
	match variant:
		Variant.HEAVY: # chapters 5-8: tankier, slower, favors the ground slam
			hp = int(hp * 1.25)
			max_hp = hp
			move_speed *= 0.85
			contact_damage += 1
			pattern_cooldown = PATTERN_COOLDOWN * 1.15
			_pattern_weights = {Pattern.CHARGE: 0.7, Pattern.SLAM: 1.6, Pattern.BARRAGE: 0.7}
		Variant.AGGRESSIVE: # chapter 9-10 finale: faster, hits harder, favors charge/barrage
			hp = int(hp * 0.9)
			max_hp = hp
			move_speed *= 1.1
			contact_damage += 1
			pattern_cooldown = PATTERN_COOLDOWN * 0.8
			_pattern_weights = {Pattern.CHARGE: 1.4, Pattern.SLAM: 0.6, Pattern.BARRAGE: 1.4}
		_:
			pass

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target) or GameState.screen != "playing":
		return
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
	_check_contact_damage(delta, contact_damage)
	_pattern_clock += delta
	if _pattern_clock >= pattern_cooldown:
		_pattern_clock = 0.0
		_begin_pattern()

func _begin_pattern() -> void:
	_current_pattern = _pick_weighted_pattern()
	_state = "telegraph"
	_telegraph_elapsed = 0.0
	velocity = Vector2.ZERO
	_telegraph_target = target.global_position
	SfxPlayer.play("boss/boss_telegraph.wav", false)

func _pick_weighted_pattern() -> int:
	var total := 0.0
	for w in _pattern_weights.values():
		total += float(w)
	var roll := randf() * total
	var acc := 0.0
	for pattern in _pattern_weights:
		acc += float(_pattern_weights[pattern])
		if roll < acc:
			return pattern
	return Pattern.CHARGE

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
			_charge_direction = global_position.direction_to(_telegraph_target)
			if _charge_direction == Vector2.ZERO:
				_charge_direction = Vector2.RIGHT
			_charge_elapsed = 0.0
			_state = "charge"
		Pattern.SLAM:
			_resolve_slam()
			_enter_recover()
		Pattern.BARRAGE:
			_fire_barrage()
			_enter_recover()

func _process_charge(delta: float) -> void:
	velocity = _charge_direction * CHARGE_SPEED
	move_and_slide()
	_check_contact_damage(delta, int(contact_damage * CHARGE_DAMAGE_MULT), true)
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

func _resolve_slam() -> void:
	if global_position.distance_to(target.global_position) < SLAM_RADIUS:
		target.damage(int(contact_damage * SLAM_DAMAGE_MULT))
	SfxPlayer.play("boss/boss_impact.wav", false)
	if is_instance_valid(game_ref) and game_ref.has_method("_spawn_ability_fx"):
		game_ref._spawn_ability_fx("explosion_area", global_position, SLAM_RADIUS)

func _fire_barrage() -> void:
	if not is_instance_valid(game_ref):
		return
	var base_dir := global_position.direction_to(target.global_position)
	for i in BARRAGE_COUNT:
		var spread_deg := -BARRAGE_SPREAD_DEG / 2.0 + i * (BARRAGE_SPREAD_DEG / (BARRAGE_COUNT - 1))
		var dir := base_dir.rotated(deg_to_rad(spread_deg))
		var proj := EmberfallBossProjectile.new()
		proj.global_position = global_position
		proj.direction = dir
		proj.speed = BARRAGE_SPEED
		proj.damage_amount = contact_damage * 3
		proj.target = target
		game_ref.add_child(proj)

func _boss_tint() -> Color:
	return VARIANT_TINTS.get(variant, Color(1.4, 0.7, 0.7))

func _draw() -> void:
	super._draw()
	if _state == "telegraph":
		_draw_telegraph()
	elif _state == "charge":
		draw_circle(Vector2.ZERO, 16, Color(1.0, 0.35, 0.2, 0.85))

func _draw_telegraph() -> void:
	var progress := clampf(_telegraph_elapsed / TELEGRAPH_TIME, 0.0, 1.0)
	var alpha := 0.3 + progress * 0.5
	match _current_pattern:
		Pattern.CHARGE:
			var dir := global_position.direction_to(_telegraph_target)
			draw_line(Vector2.ZERO, dir * 220.0, Color(1.0, 0.3, 0.2, alpha), 6.0)
			draw_circle(dir * 220.0, 10.0, Color(1.0, 0.3, 0.2, alpha))
		Pattern.SLAM:
			draw_circle(Vector2.ZERO, SLAM_RADIUS, Color(1.0, 0.5, 0.1, 0.12 + progress * 0.15))
			draw_arc(Vector2.ZERO, SLAM_RADIUS, 0.0, TAU, 48, Color(1.0, 0.5, 0.1, alpha), 4.0)
		Pattern.BARRAGE:
			if not is_instance_valid(target):
				return
			var base_dir := global_position.direction_to(target.global_position)
			for i in BARRAGE_COUNT:
				var spread_deg := -BARRAGE_SPREAD_DEG / 2.0 + i * (BARRAGE_SPREAD_DEG / (BARRAGE_COUNT - 1))
				var dir := base_dir.rotated(deg_to_rad(spread_deg))
				draw_line(Vector2.ZERO, dir * 170.0, Color(0.8, 0.3, 0.9, alpha), 3.0)
