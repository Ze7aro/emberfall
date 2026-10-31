extends Area2D
class_name EmberfallXPOrb

var value := 10
var collected := false
var is_gold := false
## Set by the Imán pickup: flies to the player from anywhere on the map.
var magnetized := false

func setup(amount: int, gold: bool = false) -> void:
	value = amount
	is_gold = gold
	queue_redraw()

func tick(player: Node2D, pickup_radius: float, delta: float) -> void:
	if collected:
		return
	var distance := global_position.distance_to(player.global_position)
	if magnetized and distance > 1.0:
		global_position = global_position.move_toward(player.global_position, 750.0 * delta)
	elif distance < pickup_radius and distance > 1.0:
		global_position = global_position.move_toward(player.global_position, 320.0 * delta)
	if distance < 30.0:
		collected = true
		SfxPlayer.play("economy/pickup_gold.wav" if is_gold else "economy/pickup_xp.wav")
		queue_free()

func _draw() -> void:
	if is_gold:
		draw_circle(Vector2.ZERO, 7, Color(0.90, 0.68, 0.20))
		draw_circle(Vector2.ZERO, 3, Color(1.0, 0.91, 0.52))
	else:
		draw_circle(Vector2.ZERO, 7, Color(0.39, 0.72, 0.92))
		draw_circle(Vector2.ZERO, 3, Color(0.74, 0.90, 1.0))
