extends Area2D
class_name EmberfallXPOrb

var value := 10
var collected := false

func setup(amount: int) -> void:
	value = amount
	queue_redraw()

func tick(player: Node2D, pickup_radius: float, delta: float) -> void:
	if collected:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < pickup_radius and distance > 1.0:
		global_position = global_position.move_toward(player.global_position, 320.0 * delta)
	if distance < 30.0:
		collected = true
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9, Color(0.55, 0.25, 0.95))
	draw_circle(Vector2.ZERO, 4, Color(0.85, 0.65, 1.0))
