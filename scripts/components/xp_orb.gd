extends Node2D
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

## Gem / coin art from assets/pickups (PLAN_FINALIZACION §6.4). The tier
## follows the orb's value, so élite drops and merged piles look richer.
const XP_SMALL := preload("res://assets/mundo/recolectables/xp_chica.png")
const XP_MEDIUM := preload("res://assets/mundo/recolectables/xp_mediana.png")
const XP_LARGE := preload("res://assets/mundo/recolectables/xp_grande.png")
const GOLD_COIN := preload("res://assets/mundo/recolectables/moneda.png")
const GOLD_STACK := preload("res://assets/mundo/recolectables/monedas.png")

func _draw() -> void:
	var texture: Texture2D
	var height: float
	if is_gold:
		texture = GOLD_STACK if value >= 15 else GOLD_COIN
		height = 20.0 if value >= 15 else 15.0
	elif value >= 60:
		texture = XP_LARGE; height = 26.0
	elif value >= 20:
		texture = XP_MEDIUM; height = 21.0
	else:
		texture = XP_SMALL; height = 16.0
	var tex_size := texture.get_size()
	var draw_size := Vector2(height * tex_size.x / tex_size.y, height)
	draw_texture_rect(texture, Rect2(-draw_size / 2.0, draw_size), false)
