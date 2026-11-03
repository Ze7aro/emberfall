extends Node

## Background music. Three pools — vistas/menú, combate, jefe — picked from
## GameState.screen (run lifecycle) plus GameState.boss_encounter_active.
## Each switch fades out/in and picks a random track different from the last
## one played in that pool, so repeat visits don't always hear the same cue;
## a track ending mid-pool picks another for variety within the same mood.
## Respects GameState.music_enabled at all times.

const MUSIC_DIR := "res://assets/audio/musica"
const INTRO_TRACKS := ["Intro_01.mp3", "Intro_02.mp3", "Intro_03.mp3"]
const COMBAT_TRACKS := ["Combat_01.mp3", "Combat_02.mp3"]
const BOSS_TRACKS := ["Boss_01.mp3", "Boss_02.mp3"]
const FADE_TIME := 0.5

var _player: AudioStreamPlayer
var _category := ""
var _last_track := ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.finished.connect(_on_track_finished)
	add_child(_player)
	GameState.screen_changed.connect(func(_v): _refresh())
	GameState.boss_encounter_changed.connect(func(_v): _refresh())
	GameState.music_enabled_changed.connect(_on_music_enabled_changed)
	_refresh()

func _category_for_screen(screen: String) -> String:
	if screen in ["playing", "paused", "level_up"]:
		return "boss" if GameState.boss_encounter_active else "combat"
	return "intro"

func _tracks_for(category: String) -> Array:
	match category:
		"combat": return COMBAT_TRACKS
		"boss": return BOSS_TRACKS
	return INTRO_TRACKS

func _refresh() -> void:
	var category := _category_for_screen(GameState.screen)
	if category == _category and (_player.playing or not GameState.music_enabled):
		return
	_category = category
	if not GameState.music_enabled:
		return
	if _player.playing:
		var tween := create_tween()
		tween.tween_property(_player, "volume_db", -40.0, FADE_TIME)
		tween.tween_callback(_start_track)
	else:
		_start_track()

func _start_track() -> void:
	var pool := _tracks_for(_category)
	if pool.is_empty():
		return
	var choice: String = pool[randi() % pool.size()]
	if pool.size() > 1:
		while choice == _last_track:
			choice = pool[randi() % pool.size()]
	_last_track = choice
	_player.stream = load("%s/%s" % [MUSIC_DIR, choice])
	_player.volume_db = 0.0
	_player.play()

## Natural end of a track (not a category switch) — keep the same mood going
## with another pick from the same pool instead of looping just one file.
func _on_track_finished() -> void:
	if GameState.music_enabled:
		_start_track()

func _on_music_enabled_changed(enabled: bool) -> void:
	if enabled:
		_start_track()
	else:
		_player.stop()
