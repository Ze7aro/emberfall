extends Area2D
class_name EmberfallProjectile

var direction := Vector2.RIGHT
var damage_amount := 20
var lifetime := 3.0

func setup(target: Vector2, amount: int) -> void:
	direction = global_position.direction_to(target)
	damage_amount = amount
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	global_position += direction * 520.0 * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9, Color(0.2, 0.95, 0.85))
	draw_circle(Vector2.ZERO, 4, Color.WHITE)
