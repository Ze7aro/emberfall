extends Node2D
class_name EmberfallPickup

## Special drops on the map: chests (from élites / mini-jefe), potion, magnet
## and bomb. game_world ticks them like the XP orbs and applies the effect
## when one is collected.
##
## Art: the recolectable sheet cut into assets/pickups/ (PLAN_FINALIZACION
## §6.4). The epic chest has no art of its own yet: it reuses the chest
## tinted violet. If a file goes missing, magnet/bomb fall back to a drawing.

enum Kind { CHEST, EPIC_CHEST, POTION, MAGNET, BOMB }

const ART_DIR := "res://assets/mundo/recolectables/"
const ART_NAMES := {
	Kind.CHEST: "cofre", Kind.EPIC_CHEST: "cofre_epico", Kind.POTION: "pocion",
	Kind.MAGNET: "iman", Kind.BOMB: "bomba",
}
const EPIC_TINT := Color(0.86, 0.66, 1.0)
const GLOW := {
	Kind.CHEST: Color("e8b84a"), Kind.EPIC_CHEST: Color("b07cff"),
	Kind.POTION: Color("5a8cff"), Kind.MAGNET: Color("e86958"), Kind.BOMB: Color("ff9a3c"),
}
const PICKUP_DISTANCE := 34.0
## Chests stay until opened; the small drops fade so the map doesn't fill up.
const SMALL_DROP_LIFETIME := 40.0

var kind: int = Kind.POTION
var collected := false
var _texture: Texture2D
var _age := 0.0

func setup(new_kind: int) -> void:
	kind = new_kind
	var custom := ART_DIR + str(ART_NAMES.get(kind, "")) + ".png"
	if ResourceLoader.exists(custom):
		_texture = load(custom) as Texture2D

func is_chest() -> bool:
	return kind == Kind.CHEST or kind == Kind.EPIC_CHEST

## Returns true the frame it gets collected.
func tick(player: Node2D, delta: float) -> bool:
	if collected:
		return false
	_age += delta
	if not is_chest() and _age > SMALL_DROP_LIFETIME:
		queue_free()
		return false
	var distance := global_position.distance_to(player.global_position)
	if distance < 70.0 and not is_chest():
		global_position = global_position.move_toward(player.global_position, 260.0 * delta)
	queue_redraw()
	if distance < PICKUP_DISTANCE + (8.0 if is_chest() else 0.0):
		collected = true
		return true
	return false

func _draw() -> void:
	var bob := sin(_age * 4.0) * 3.0
	var glow: Color = GLOW.get(kind, Color.WHITE)
	var size := 44.0 if is_chest() else 30.0
	var pulse := 0.5 + 0.5 * sin(_age * 5.0)
	draw_circle(Vector2(0, size * 0.42), size * 0.45, Color(0, 0, 0, 0.25))
	draw_circle(Vector2(0, bob), size * 0.62, Color(glow, 0.12 + 0.10 * pulse))
	# Small drops blink in their last 5 s so the player knows they're leaving.
	if not is_chest() and _age > SMALL_DROP_LIFETIME - 5.0 and int(_age * 8.0) % 2 == 0:
		return
	if _texture:
		# Keep the art's aspect ratio inside a size×size box.
		var tex_size := _texture.get_size()
		var fit := size / maxf(tex_size.x, tex_size.y)
		var draw_size := tex_size * fit
		var tint := EPIC_TINT if kind == Kind.EPIC_CHEST else Color.WHITE
		draw_texture_rect(_texture, Rect2(Vector2(-draw_size.x / 2.0, -draw_size.y / 2.0 + bob), draw_size), false, tint)
		return
	match kind:
		Kind.MAGNET:
			var c := Vector2(0, bob)
			draw_arc(c + Vector2(0, -2), 9.0, 0.0, PI, 12, Color("e86958"), 6.0)
			draw_rect(Rect2(c + Vector2(-12, -9), Vector2(6, 8)), Color("e86958"))
			draw_rect(Rect2(c + Vector2(6, -9), Vector2(6, 8)), Color("e86958"))
			draw_rect(Rect2(c + Vector2(-12, -13), Vector2(6, 4)), Color("e9e4f0"))
			draw_rect(Rect2(c + Vector2(6, -13), Vector2(6, 4)), Color("e9e4f0"))
		Kind.BOMB:
			var c := Vector2(0, bob + 2)
			draw_circle(c, 10.0, Color("2a2238"))
			draw_circle(c + Vector2(-3, -3), 3.0, Color("5a4f6e"))
			draw_line(c + Vector2(5, -8), c + Vector2(9, -14), Color("c8a46a"), 2.0)
			draw_circle(c + Vector2(9, -15), 2.5 + pulse * 1.5, Color("ffd36a"))
