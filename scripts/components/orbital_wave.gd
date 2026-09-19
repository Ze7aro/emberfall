extends Node2D
class_name EmberfallOrbitalWave

## Onda Orbital v2: 2-6 glowing moons continuously orbiting the player in an
## ellipse (radius_x > radius_y, matching the game's 3/4 perspective), each
## one damaging whatever it touches on its own per-target cooldown — replacing
## the old model of a single flat-radius pulse hitting everything at once.
## See assets/emberfall_habilidades_sprites/onda_orbital_v2/README.md and
## PROMPT_IMPLEMENTACION_GODOT.md for the source design brief. One deliberate
## departure from that brief: moons are plain Node2D visuals hit-tested by
## simple distance checks here, not Area2D/CollisionShape2D pairs — every
## other ability in this project (orbital's old model, area, chain, fire,
## blizzard) already damages this same way, so this reuses that instead of
## introducing a second, physics-collision-based hit path alongside it.

const MOON_SCRIPT := preload("res://scripts/components/orbital_moon.gd")
const MIN_MOONS := 2
const MAX_MOONS := 6
const RADIUS_X := 78.0
const RADIUS_Y := 44.0
const ANGULAR_SPEED := 1.8 # radians/sec
const HIT_DISTANCE := 38.0 # moon radius + a typical enemy's half-size
const HIT_COOLDOWN := 0.6 # seconds of simulated time, see _check_hits

var game_ref: Node
## Moons are parented here (not to this node) so their draw order can be
## reordered directly against the player's own sprite every frame — see the
## z-order note in _physics_process for why that's needed instead of z_index.
var player_node: Node2D
var damage := 10
var moon_count := MIN_MOONS:
	set(value):
		var clamped := clampi(value, MIN_MOONS, MAX_MOONS)
		if clamped == moon_count and _moons.size() == clamped:
			return
		moon_count = clamped
		_rebuild_moons()

var _orbit_time := 0.0
var _moons: Array[EmberfallOrbitalMoon] = []

func _rebuild_moons() -> void:
	for m in _moons:
		if is_instance_valid(m):
			m.queue_free()
	_moons.clear()
	if not is_instance_valid(player_node):
		return
	for i in moon_count:
		var moon := MOON_SCRIPT.new()
		player_node.add_child(moon)
		_moons.append(moon)

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_orbit_time += delta
	for i in _moons.size():
		var moon := _moons[i]
		if not is_instance_valid(moon):
			continue
		var angle := _orbit_time * ANGULAR_SPEED + TAU * float(i) / float(moon_count)
		moon.position = Vector2(cos(angle) * RADIUS_X, sin(angle) * RADIUS_Y)
		# Passes in front of the player for the lower half of the orbit,
		# behind for the upper half — a cheap pseudo-depth cue for the 3/4
		# view. Done by reordering as a sibling of the player's own sprite
		# rather than with z_index: a negative z_index here read as invisible
		# instead of merely "behind" (same issue the fire/orbital auras hit
		# earlier), so this sidesteps it by reusing the trick that actually
		# worked there — moving in front of / behind the sprite in the tree.
		if is_instance_valid(player_node):
			player_node.move_child(moon, player_node.get_child_count() - 1 if moon.position.y >= 0.0 else 0)
		_check_hits(moon, i)

## Cooldown state lives as metadata on the enemy itself (same trick
## spawn_projectile already uses for pierce tracking), keyed per moon, so it
## is freed automatically with the enemy instead of accumulating forever in
## a dictionary here across an entire run's worth of spawned-and-killed
## enemies. Timed off `_orbit_time` (accumulated from the same `delta` this
## node's own movement uses) rather than wall-clock time, so it behaves
## identically in real play and in a manually-stepped headless test.
func _check_hits(moon: EmberfallOrbitalMoon, moon_index: int) -> void:
	if not is_instance_valid(game_ref):
		return
	var meta_key := "orbital_moon_hit_%d" % moon_index
	for enemy in game_ref.enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if moon.global_position.distance_to(enemy.global_position) > HIT_DISTANCE:
			continue
		var last: float = enemy.get_meta(meta_key, -HIT_COOLDOWN)
		if _orbit_time - last < HIT_COOLDOWN:
			continue
		enemy.set_meta(meta_key, _orbit_time)
		game_ref._apply_damage(enemy, damage)
