extends Node

## One-shot sound effects, from assets/Emberfall_SFX (see its own README for
## the mixing notes this follows: pitch variation on common impacts,
## alternating enemy_hit_01/02, a single shared poison-puddle loop instead of
## one per hazard, and a pool instead of a single player so overlapping hits
## don't cut each other off).

const SFX_DIR := "res://assets/Emberfall_SFX"
const POOL_SIZE := 12
const IMPACT_PITCH_RANGE := Vector2(0.94, 1.06)

var _pool: Array[AudioStreamPlayer] = []
var _next_pool_index := 0
var _stream_cache: Dictionary = {}
var _enemy_hit_toggle := 0

var _poison_loop_player: AudioStreamPlayer
var _poison_loop_refcount := 0

func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	_poison_loop_player = AudioStreamPlayer.new()
	_poison_loop_player.bus = "SFX"
	add_child(_poison_loop_player)
	var loop_stream := _load("abilities/poison_puddle_loop.ogg")
	if loop_stream is AudioStreamOggVorbis:
		loop_stream.loop = true
	_poison_loop_player.stream = loop_stream
	GameState.effects_enabled_changed.connect(_on_effects_enabled_changed)

func _load(rel_path: String) -> AudioStream:
	if not _stream_cache.has(rel_path):
		_stream_cache[rel_path] = load("%s/%s" % [SFX_DIR, rel_path])
	return _stream_cache[rel_path]

## `pitch_variation` follows the pack's own guidance: vary common impacts,
## but not one-off cues like fanfares or UI taps (pass false for those).
func play(rel_path: String, pitch_variation: bool = true, bus: String = "SFX") -> void:
	if not GameState.effects_enabled:
		return
	var player := _pool[_next_pool_index]
	_next_pool_index = (_next_pool_index + 1) % _pool.size()
	player.bus = bus
	player.stream = _load(rel_path)
	player.pitch_scale = randf_range(IMPACT_PITCH_RANGE.x, IMPACT_PITCH_RANGE.y) if pitch_variation else 1.0
	player.play()

func play_ui(rel_path: String) -> void:
	play(rel_path, false, "UI")

## Alternates enemy_hit_01/02 instead of picking either at random, per the
## pack's README.
func play_enemy_hit() -> void:
	_enemy_hit_toggle = 1 - _enemy_hit_toggle
	play("combat/enemy_hit_%02d.wav" % (_enemy_hit_toggle + 1))

## One shared loop for however many poison puddles are alive at once, not one
## per puddle — callers must pair every start with a stop (poison_pool.gd
## calls this in _ready()/tree_exiting so it's always balanced).
func start_poison_loop() -> void:
	_poison_loop_refcount += 1
	if _poison_loop_refcount == 1 and GameState.effects_enabled:
		_poison_loop_player.play()

func stop_poison_loop() -> void:
	_poison_loop_refcount = maxi(0, _poison_loop_refcount - 1)
	if _poison_loop_refcount == 0:
		_poison_loop_player.stop()

func _on_effects_enabled_changed(enabled: bool) -> void:
	if not enabled:
		for player in _pool:
			player.stop()
		_poison_loop_player.stop()
	elif _poison_loop_refcount > 0:
		_poison_loop_player.play()
