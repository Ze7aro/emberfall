extends CharacterBody2D
class_name EmberfallEnemy

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

var poison_timer := 0.0
var poison_tick_clock := 0.0
var poison_damage := 0
var burn_timer := 0.0
var burn_tick_clock := 0.0
var burn_damage := 0
var freeze_timer := 0.0

func setup(player: Node2D, difficulty: float, boss: bool = false) -> void:
	target = player
	is_boss = boss
	if is_boss:
		hp = int(600.0 * difficulty)
		move_speed = 62.0
		contact_damage = int(28.0 * difficulty)
		xp_value = 150
		gold_value = 120
	else:
		hp = int(30.0 * difficulty)
		move_speed = 80.0 + difficulty * 12.0
		contact_damage = int(10.0 * difficulty)
		xp_value = 10
		gold_value = 6
	max_hp = hp

func apply_poison(duration: float, damage_per_tick: int) -> void:
	poison_timer = maxf(poison_timer, duration)
	poison_damage = maxi(poison_damage, damage_per_tick)

func apply_burn(duration: float, damage_per_tick: int) -> void:
	burn_timer = maxf(burn_timer, duration)
	burn_damage = maxi(burn_damage, damage_per_tick)

func apply_freeze(duration: float) -> void:
	freeze_timer = maxf(freeze_timer, duration)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target) or GameState.screen != "playing":
		return
	_tick_status(delta)
	if dead:
		return
	var direction := global_position.direction_to(target.global_position)
	var speed_scale := 0.35 if freeze_timer > 0.0 else 1.0
	velocity = direction * move_speed * speed_scale
	move_and_slide()
	hit_clock = maxf(0.0, hit_clock - delta)
	if global_position.distance_to(target.global_position) < 48.0 and hit_clock <= 0.0:
		hit_clock = 1.2
		target.damage(contact_damage)
	queue_redraw()

func _tick_status(delta: float) -> void:
	freeze_timer = maxf(0.0, freeze_timer - delta)
	if poison_timer > 0.0:
		poison_timer -= delta
		poison_tick_clock -= delta
		if poison_tick_clock <= 0.0:
			poison_tick_clock = 1.0
			_status_damage(poison_damage)
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_clock -= delta
		if burn_tick_clock <= 0.0:
			burn_tick_clock = 1.0
			_status_damage(burn_damage)

## Damage from poison/burn ticks bypasses combat multipliers (crit, boost_damage)
## since it's a flat damage-over-time effect, but still grants kill rewards.
func _status_damage(amount: int) -> void:
	if damage(amount) and is_instance_valid(game_ref) and game_ref.has_method("_on_enemy_killed"):
		game_ref._on_enemy_killed(self)

func damage(amount: int) -> bool:
	if dead:
		return false
	hp -= amount
	if hp <= 0:
		dead = true
		queue_free()
		return true
	queue_redraw()
	return false

static var _shared_texture: Texture2D

func _draw() -> void:
	var size := 60.0 if not is_boss else 100.0
	if _shared_texture == null:
		_shared_texture = load("res://assets/characters/enemy.png") as Texture2D
	if _shared_texture:
		draw_texture_rect(_shared_texture, Rect2(-size / 2, -size / 2, size, size), false, Color(1.4, 0.7, 0.7) if is_boss else Color.WHITE)
	var bar_width := 50.0 if not is_boss else 90.0
	draw_rect(Rect2(-bar_width / 2, -size / 2 - 9, bar_width, 5), Color(0.05, 0.05, 0.1, 0.8))
	draw_rect(Rect2(-bar_width / 2, -size / 2 - 9, bar_width * clampf(float(hp) / float(max_hp), 0.0, 1.0), 5), Color(0.95, 0.25, 0.35) if not is_boss else Color(1.0, 0.65, 0.1))
	if poison_timer > 0.0:
		draw_circle(Vector2.ZERO, size / 2 + 5, Color(0.3, 0.9, 0.3, 0.3))
	if burn_timer > 0.0:
		draw_circle(Vector2.ZERO, size / 2 + 5, Color(1.0, 0.5, 0.1, 0.3))
	if freeze_timer > 0.0:
		draw_circle(Vector2.ZERO, size / 2 + 5, Color(0.4, 0.8, 1.0, 0.3))
