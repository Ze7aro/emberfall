extends Node

signal screen_changed(screen: String)
signal energy_changed(value: int)
signal gold_changed(value: int)
signal gems_changed(value: int)
signal run_finished(victory: bool)

const SAVE_PATH := "user://emberfall_save.json"
const MAX_ENERGY := 50
const ENERGY_COST := 5
const ENERGY_INTERVAL := 300.0
var screen := "menu"
var energy := MAX_ENERGY
var gold := 0
var gems := 0
var high_score := 0
var permanent_damage := 0
var permanent_health := 0
var permanent_speed := 0
var music_enabled := true
var effects_enabled := true

func _ready() -> void:
	load_save()
	refresh_energy()

func change_screen(value: String) -> void:
	screen = value
	screen_changed.emit(value)

func can_start() -> bool:
	refresh_energy()
	return energy >= ENERGY_COST

func start_run() -> bool:
	refresh_energy()
	if energy < ENERGY_COST:
		return false
	energy -= ENERGY_COST
	_save_energy_timestamp()
	save()
	return true

func finish_run(victory: bool, kills: int) -> void:
	if screen != "playing":
		return
	high_score = maxi(high_score, kills)
	gold += maxi(20 if victory else 5, kills / 2 + (10 if victory else 0))
	gold_changed.emit(gold)
	change_screen("victory" if victory else "defeat")
	run_finished.emit(victory)
	save()

func buy_upgrade(kind: String) -> bool:
	var level := get_upgrade_level(kind)
	var cost := 40 + level * 35
	if level >= 10 or gold < cost:
		return false
	gold -= cost
	set_upgrade_level(kind, level + 1)
	save()
	return true

func get_upgrade_level(kind: String) -> int:
	match kind:
		"damage": return permanent_damage
		"health": return permanent_health
		"speed": return permanent_speed
	return 0

func set_upgrade_level(kind: String, value: int) -> void:
	match kind:
		"damage": permanent_damage = clampi(value, 0, 10)
		"health": permanent_health = clampi(value, 0, 10)
		"speed": permanent_speed = clampi(value, 0, 10)

func refresh_energy() -> void:
	if energy >= MAX_ENERGY:
		return
	var stamp: float = float(ProjectSettings.get_setting("application/config/version", 0.0))
	var data := _read_save()
	stamp = float(data.get("energy_timestamp", Time.get_unix_time_from_system()))
	var recovered := int((Time.get_unix_time_from_system() - stamp) / ENERGY_INTERVAL)
	if recovered > 0:
		energy = mini(MAX_ENERGY, energy + recovered)
		_save_energy_timestamp()
		energy_changed.emit(energy)
		save()

func _save_energy_timestamp() -> void:
	var data := _read_save()
	data["energy_timestamp"] = Time.get_unix_time_from_system()
	_write_save(data)

func save() -> void:
	var data := _read_save()
	data.merge({"energy": energy, "gold": gold, "high_score": high_score,
		"damage": permanent_damage, "health": permanent_health, "speed": permanent_speed, "gems": gems,
		"music": music_enabled, "effects": effects_enabled}, true)
	_write_save(data)

func load_save() -> void:
	var data := _read_save()
	energy = clampi(int(data.get("energy", MAX_ENERGY)), 0, MAX_ENERGY)
	gold = maxi(0, int(data.get("gold", 0)))
	gems = maxi(0, int(data.get("gems", 0)))
	high_score = maxi(0, int(data.get("high_score", 0)))
	permanent_damage = clampi(int(data.get("damage", 0)), 0, 10)
	permanent_health = clampi(int(data.get("health", 0)), 0, 10)
	permanent_speed = clampi(int(data.get("speed", 0)), 0, 10)
	music_enabled = bool(data.get("music", true))
	effects_enabled = bool(data.get("effects", true))

func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
