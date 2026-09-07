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

func setup(owner: Node) -> void:
	game = owner
	max_hp += GameState.permanent_health * 15
	hp = max_hp
	speed *= 1.0 + GameState.permanent_speed * 0.05
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not game or GameState.screen != "playing":
		return
	var input := touch_direction if touch_direction.length_squared() > 0.01 else Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input * speed
	move_and_slide()
	position.x = clampf(position.x, -760.0, 760.0)
	position.y = clampf(position.y, -760.0, 760.0)
	invulnerable = maxf(0.0, invulnerable - delta)
	attack_clock += delta
	if attack_clock >= 1.2:
		attack_clock = 0.0
		game.spawn_projectile(self)
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
	var tex := load(texture_path) as Texture2D
	if tex:
		draw_texture_rect(tex, Rect2(-34, -34, 68, 68), false)
	draw_circle(Vector2.ZERO, 38, Color(0.2, 0.95, 0.85, 0.12))
	draw_rect(Rect2(-30, -45, 60, 5), Color(0.05, 0.05, 0.1, 0.8))
	draw_rect(Rect2(-30, -45, 60.0 * float(hp) / max_hp, 5), Color(0.95, 0.25, 0.35))
