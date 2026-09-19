extends Area2D
class_name EmberfallXPOrb

var value := 10
var collected := false
var is_gold := false

func setup(amount: int, gold: bool = false) -> void:
	value = amount
	is_gold = gold
	queue_redraw()

func tick(player: Node2D, pickup_radius: float, delta: float) -> void:
	if collected:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < pickup_radius and distance > 1.0:
		global_position = global_position.move_toward(player.global_position, 320.0 * delta)
	if distance < 30.0:
		collected = true
		SfxPlayer.play("economy/pickup_gold.wav" if is_gold else "economy/pickup_xp.wav")
		queue_free()

func _draw() -> void:
	if is_gold:
		draw_circle(Vector2.ZERO, 9, Color(0.85, 0.65, 0.15))
		draw_circle(Vector2.ZERO, 4, Color(1.0, 0.9, 0.4))
	else:
		draw_circle(Vector2.ZERO, 9, Color(0.55, 0.25, 0.95))
		draw_circle(Vector2.ZERO, 4, Color(0.85, 0.65, 1.0))
