extends CharacterBody2D
class_name EmberfallEnemy

var hp := 30
var move_speed := 80.0
var contact_damage := 10
var target: Node2D
var xp_value := 10
var hit_clock := 0.0
var dead := false

func setup(player: Node2D, difficulty: float) -> void:
	target = player
	hp = int(30.0 * difficulty)
	move_speed = 80.0 + difficulty * 12.0
	contact_damage = int(10.0 * difficulty)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target) or GameState.screen != "playing":
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed
	move_and_slide()
	hit_clock = maxf(0.0, hit_clock - delta)
	if global_position.distance_to(target.global_position) < 48.0 and hit_clock <= 0.0:
		hit_clock = 1.2
		target.damage(contact_damage)
	queue_redraw()

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

func _draw() -> void:
	var tex := load("res://assets/characters/enemy.png") as Texture2D
	if tex:
		draw_texture_rect(tex, Rect2(-30, -30, 60, 60), false)
	draw_rect(Rect2(-25, -39, 50, 4), Color(0.05, 0.05, 0.1, 0.8))
	draw_rect(Rect2(-25, -39, 50.0 * clampf(float(hp) / 30.0, 0.0, 1.0), 4), Color(0.95, 0.25, 0.35))
