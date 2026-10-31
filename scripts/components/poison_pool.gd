extends Node2D
class_name EmberfallPoisonPool

## Lingering hazard left by Bomba Venenosa: any enemy standing inside gets
## re-poisoned every tick, so the DoT keeps refreshing while they linger.
## Visual is the bomba_venenosa throw-and-land animation, held on its last
## (puddle) frame for the rest of this pool's lifetime.
const NATIVE_RADIUS := 255.0 # how big the puddle art reads at scale 1.0

var radius := 55.0
var lifetime := 4.0
var tick_damage := 3
var game_ref: Node
## Plaga Abisal: the pool slowly drifts toward the nearest enemy.
var chase_speed := 0.0
var _elapsed := 0.0
var _tick_clock := 0.0

## Callers set `radius` right after `.new()` but before `add_child()`, so by
## _ready() it already holds its final value — no need to build in _init().
func _ready() -> void:
	var fx := preload("res://scripts/components/ability_sprite_fx.gd").new()
	add_child(fx)
	fx.setup("bomba_venenosa", radius / NATIVE_RADIUS, Vector2.ZERO, false)
	# Shared loop, not one per puddle (see SfxPlayer.start_poison_loop).
	SfxPlayer.start_poison_loop()
	tree_exiting.connect(SfxPlayer.stop_poison_loop)

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()
		return
	if chase_speed > 0.0 and is_instance_valid(game_ref):
		var prey: EmberfallEnemy = game_ref.nearest_from(game_ref.enemies, global_position, 400.0)
		if prey:
			global_position = global_position.move_toward(prey.global_position, chase_speed * delta)
	_tick_clock -= delta
	if _tick_clock <= 0.0:
		_tick_clock = 0.5
		_apply_tick()

func _apply_tick() -> void:
	if not is_instance_valid(game_ref):
		return
	for enemy in game_ref.enemies:
		if is_instance_valid(enemy) and not enemy.dead and global_position.distance_to(enemy.global_position) < radius:
			enemy.apply_poison(1.0, tick_damage)
