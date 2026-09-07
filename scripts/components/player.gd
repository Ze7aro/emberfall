extends CharacterBody2D
class_name EmberfallPlayer

signal died
var hp := 100
var max_hp := 100
var speed := 220.0
var invulnerable := 0.0
var attack_clock := 0.0
var game: Node
var touch_direction := Vector2.ZERO
var _cached_texture: Texture2D
var _cached_texture_path := ""
var _regen_accum := 0.0

func setup(owner: Node) -> void:
	game = owner
	max_hp += (GameState.permanent_health + GameState.get_equipped_bonus("health")) * 15
	hp = max_hp
	speed *= 1.0 + (GameState.permanent_speed + GameState.get_equipped_bonus("speed")) * 0.05
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.4, 1.4)
	camera.position_smoothing_enabled = true
	camera.enabled = true
	add_child(camera)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not game or GameState.screen != "playing":
		return
	var input := touch_direction if touch_direction.length_squared() > 0.01 else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input * speed * game.speed_multiplier()
	move_and_slide()
	position.x = clampf(position.x, -760.0, 760.0)
	position.y = clampf(position.y, -760.0, 760.0)
	invulnerable = maxf(0.0, invulnerable - delta)
	_tick_regen(delta)
	attack_clock += delta
	var directed_level: int = game.skills.get("directed", 1)
	var base_interval := 1.2 - float(directed_level - 1) * 0.1
	var attack_interval := maxf(0.25, base_interval * game.attack_speed_multiplier())
	if attack_clock >= attack_interval:
		attack_clock = 0.0
		game.spawn_projectile(self)
	queue_redraw()

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
	if hp == 0:
		died.emit()
	queue_redraw()

func _draw() -> void:
	var texture_path := GameState.selected_character_texture if GameState.selected_character_texture != "" else "res://assets/characters/player.png"
	if texture_path != _cached_texture_path:
		_cached_texture_path = texture_path
		_cached_texture = load(texture_path) as Texture2D
	if _cached_texture:
		draw_texture_rect(_cached_texture, Rect2(-34, -34, 68, 68), false)
	draw_circle(Vector2.ZERO, 38, Color(0.2, 0.95, 0.85, 0.12))
	draw_rect(Rect2(-30, -45, 60, 5), Color(0.05, 0.05, 0.1, 0.8))
	draw_rect(Rect2(-30, -45, 60.0 * float(hp) / max_hp, 5), Color(0.95, 0.25, 0.35))
