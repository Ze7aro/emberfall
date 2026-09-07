extends Node

signal screen_changed(screen: String)
signal energy_changed(value: int)
signal gold_changed(value: int)
signal gems_changed(value: int)
signal run_finished(victory: bool)
signal level_changed(value: int)
signal experience_changed(current: int, needed: int)
signal notifications_changed(unread: int)
signal selected_character_changed(character_id: StringName)

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

var level := 1
var experience := 0
var experience_to_next := 100
var selected_character_id: StringName = &""
var selected_character_texture := ""
var selected_map_id: StringName = &""
var notifications: Array = []

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
	energy_changed.emit(energy)
	_save_energy_timestamp()
	save()
	return true

func finish_run(victory: bool, kills: int) -> void:
	if screen != "playing":
		return
	high_score = maxi(high_score, kills)
	gold += maxi(20 if victory else 5, kills / 2 + (10 if victory else 0))
	gold_changed.emit(gold)
	add_experience(30 + kills if victory else 10 + kills / 2)
	change_screen("victory" if victory else "defeat")
	run_finished.emit(victory)
	save()

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	while experience >= experience_to_next:
		experience -= experience_to_next
		experience_to_next = int(experience_to_next * 1.25)
		level += 1
		level_changed.emit(level)
	experience_changed.emit(experience, experience_to_next)
	save()

func set_selected_character(character_id: StringName, texture_path: String = "") -> void:
	selected_character_id = character_id
	selected_character_texture = texture_path
	selected_character_changed.emit(character_id)
	save()

func select_map(map_id: StringName) -> void:
	selected_map_id = map_id
	save()

func unread_notification_count() -> int:
	var count := 0
	for entry in notifications:
		if not bool(entry.get("read", false)):
			count += 1
	return count

func add_notification(text: String) -> void:
	notifications.push_front({"text": text, "read": false, "timestamp": Time.get_unix_time_from_system()})
	notifications = notifications.slice(0, 30)
	notifications_changed.emit(unread_notification_count())
	save()

func mark_notifications_read() -> void:
	for entry in notifications:
		entry["read"] = true
	notifications_changed.emit(0)
	save()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	save()

func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	save()

func buy_energy_refill(amount: int, cost: int) -> bool:
	if gold < cost or energy >= MAX_ENERGY:
		return false
	gold -= cost
	energy = mini(MAX_ENERGY, energy + amount)
	gold_changed.emit(gold)
	energy_changed.emit(energy)
	save()
	return true

func buy_upgrade(kind: String) -> bool:
	var level_value := get_upgrade_level(kind)
	var cost := 40 + level_value * 35
	if level_value >= 10 or gold < cost:
		return false
	gold -= cost
	set_upgrade_level(kind, level_value + 1)
	gold_changed.emit(gold)
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
	var data := _read_save()
	var stamp: float = float(data.get("energy_timestamp", Time.get_unix_time_from_system()))
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
	data.merge({
		"energy": energy, "gold": gold, "high_score": high_score,
		"damage": permanent_damage, "health": permanent_health, "speed": permanent_speed, "gems": gems,
		"music": music_enabled, "effects": effects_enabled,
		"level": level, "experience": experience, "experience_to_next": experience_to_next,
		"selected_character_id": str(selected_character_id), "selected_character_texture": selected_character_texture,
		"selected_map_id": str(selected_map_id), "notifications": notifications,
	}, true)
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
	level = maxi(1, int(data.get("level", 1)))
	experience = maxi(0, int(data.get("experience", 0)))
	experience_to_next = maxi(1, int(data.get("experience_to_next", 100)))
	selected_character_id = StringName(str(data.get("selected_character_id", "")))
	selected_character_texture = str(data.get("selected_character_texture", ""))
	selected_map_id = StringName(str(data.get("selected_map_id", "")))
	var stored_notifications = data.get("notifications", [])
	notifications = stored_notifications if stored_notifications is Array else []

func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
