extends Node2D
class_name EmberfallXPOrb

var value := 10
var collected := false
var is_gold := false
## Set by the Imán pickup: flies to the player from anywhere on the map.
var magnetized := false
## Orbs that absorbed others (see game_world.ORB_CAP) draw bigger.
var _base_value := 10

func setup(amount: int, gold: bool = false) -> void:
	value = amount
	_base_value = maxi(1, amount)
	is_gold = gold
	queue_redraw()

func absorb(amount: int) -> void:
	value += amount
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
	var grow := clampf(sqrt(float(value) / float(_base_value)), 1.0, 2.0)
	var outer := 7.0 * grow
	var inner := 3.0 * grow
	if is_gold:
		draw_circle(Vector2.ZERO, outer, Color(0.90, 0.68, 0.20))
		draw_circle(Vector2.ZERO, inner, Color(1.0, 0.91, 0.52))
	elif grow > 1.2:
		# Merged XP turns violet so a big pile reads as "worth more".
		draw_circle(Vector2.ZERO, outer, Color(0.66, 0.42, 0.95))
		draw_circle(Vector2.ZERO, inner, Color(0.90, 0.80, 1.0))
	else:
		draw_circle(Vector2.ZERO, outer, Color(0.39, 0.72, 0.92))
		draw_circle(Vector2.ZERO, inner, Color(0.74, 0.90, 1.0))
