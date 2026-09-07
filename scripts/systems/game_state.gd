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
signal progress_changed
signal inventory_changed
signal energy_countdown_changed(seconds_left: int)

const SAVE_PATH := "user://emberfall_save.json"
const MAX_ENERGY := 50
const ENERGY_COST := 5
const ENERGY_INTERVAL := 300.0
const STAGE_COUNT := 10
const DUNGEON_UNLOCK_STAGE := 10

const EQUIPMENT_POOL := [
	{"id": "blade_focus", "name": "FILO ENFOCADO", "stat": "damage", "value": 4},
	{"id": "iron_will", "name": "VOLUNTAD DE HIERRO", "stat": "health", "value": 5},
	{"id": "swift_boots", "name": "BOTAS VELOCES", "stat": "speed", "value": 3},
]

var screen := "menu"
var energy := MAX_ENERGY
var energy_timestamp := Time.get_unix_time_from_system()
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

# Progression
var highest_stage_cleared := 0
var dungeons_cleared := 0
var owned_characters: Array = [&"variante_01"]
var equipment_inventory: Array = []
var equipped_equipment_id := ""

# Context for the run currently starting/in progress, and the last one used
# (kept after the run ends so the result screen can offer "retry").
var current_stage_context: Dictionary = {}
var last_stage_context: Dictionary = {}

func _ready() -> void:
	load_save()
	refresh_energy()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_energy_tick)
	add_child(timer)

func _on_energy_tick() -> void:
	refresh_energy()
	energy_countdown_changed.emit(seconds_until_next_energy())

func seconds_until_next_energy() -> int:
	if energy >= MAX_ENERGY:
		return 0
	var elapsed := Time.get_unix_time_from_system() - energy_timestamp
	var remaining := ENERGY_INTERVAL - fmod(elapsed, ENERGY_INTERVAL)
	return int(ceil(remaining))

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
	var was_full := energy >= MAX_ENERGY
	energy -= ENERGY_COST
	energy_changed.emit(energy)
	# Spending doesn't reset the regen countdown unless it wasn't running yet
	# (i.e. energy was full, so there was nothing counting down until now).
	if was_full:
		energy_timestamp = Time.get_unix_time_from_system()
	save()
	return true

func select_map(map_id: StringName) -> void:
	selected_map_id = map_id
	save()

func begin_stage(context: Dictionary) -> void:
	current_stage_context = context
	last_stage_context = context
	select_map(StringName(str(context.get("id", ""))))

## Rewards granted immediately as loot is collected mid-run (gold/xp orbs).
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)

func finish_run(victory: bool, kills: int) -> void:
	if screen != "playing":
		return
	high_score = maxi(high_score, kills)
	var context := current_stage_context
	if victory:
		var bonus_gold := int(context.get("gold_reward", 20 + kills / 2))
		var bonus_gems := int(context.get("gems_reward", 0))
		gold += bonus_gold
		gems += bonus_gems
		gold_changed.emit(gold)
		gems_changed.emit(gems)
		_apply_stage_clear(context)
	add_experience((30 + kills) if victory else (10 + kills / 2))
	change_screen("victory" if victory else "defeat")
	run_finished.emit(victory)
	current_stage_context = {}
	save()

func _apply_stage_clear(context: Dictionary) -> void:
	var type := str(context.get("type", "stage"))
	var index := int(context.get("index", 0))
	if type == "stage":
		if index > highest_stage_cleared:
			highest_stage_cleared = index
			progress_changed.emit()
	elif type == "dungeon":
		if index > dungeons_cleared:
			dungeons_cleared = index
			progress_changed.emit()

func is_stage_unlocked(index: int) -> bool:
	return index <= 1 or highest_stage_cleared >= index - 1

func are_dungeons_unlocked() -> bool:
	return highest_stage_cleared >= DUNGEON_UNLOCK_STAGE

func is_dungeon_unlocked(index: int) -> bool:
	return are_dungeons_unlocked() and (index <= 1 or dungeons_cleared >= index - 1)

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
	if not owns_character(character_id):
		return
	selected_character_id = character_id
	selected_character_texture = texture_path
	selected_character_changed.emit(character_id)
	save()

func owns_character(character_id: StringName) -> bool:
	return owned_characters.has(character_id)

func buy_character(character_id: StringName, cost: int, currency: String) -> bool:
	if owns_character(character_id):
		return false
	if currency == "gems":
		if gems < cost:
			return false
		gems -= cost
		gems_changed.emit(gems)
	else:
		if gold < cost:
			return false
		gold -= cost
		gold_changed.emit(gold)
	owned_characters.append(character_id)
	save()
	return true

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
	if energy < MAX_ENERGY:
		energy_timestamp = Time.get_unix_time_from_system()
	gold_changed.emit(gold)
	energy_changed.emit(energy)
	energy_countdown_changed.emit(seconds_until_next_energy())
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

## -- Equipment / chests --

const CHEST_COST := 150

func open_chest() -> Dictionary:
	if gold < CHEST_COST:
		return {}
	gold -= CHEST_COST
	gold_changed.emit(gold)
	var item: Dictionary = EQUIPMENT_POOL[randi() % EQUIPMENT_POOL.size()].duplicate()
	item["uid"] = "%s_%d" % [item["id"], Time.get_ticks_msec()]
	equipment_inventory.append(item)
	inventory_changed.emit()
	save()
	return item

func equip_item(uid: String) -> void:
	for item in equipment_inventory:
		if str(item.get("uid", "")) == uid:
			equipped_equipment_id = uid
			inventory_changed.emit()
			save()
			return

func unequip_item() -> void:
	equipped_equipment_id = ""
	inventory_changed.emit()
	save()

func get_equipped_item() -> Dictionary:
	for item in equipment_inventory:
		if str(item.get("uid", "")) == equipped_equipment_id:
			return item
	return {}

func get_equipped_bonus(stat: String) -> int:
	var item := get_equipped_item()
	if item.is_empty():
		return 0
	return int(item.get("value", 0)) if str(item.get("stat", "")) == stat else 0

func refresh_energy() -> void:
	if energy >= MAX_ENERGY:
		return
	var recovered := int((Time.get_unix_time_from_system() - energy_timestamp) / ENERGY_INTERVAL)
	if recovered > 0:
		energy = mini(MAX_ENERGY, energy + recovered)
		# Advance by exact interval multiples (not "now") so the countdown to
		# the following point keeps its correct phase instead of resetting.
		energy_timestamp += recovered * ENERGY_INTERVAL
		energy_changed.emit(energy)
		save()

func save() -> void:
	var data := _read_save()
	data.merge({
		"energy": energy, "energy_timestamp": energy_timestamp, "gold": gold, "high_score": high_score,
		"damage": permanent_damage, "health": permanent_health, "speed": permanent_speed, "gems": gems,
		"music": music_enabled, "effects": effects_enabled,
		"level": level, "experience": experience, "experience_to_next": experience_to_next,
		"selected_character_id": str(selected_character_id), "selected_character_texture": selected_character_texture,
		"selected_map_id": str(selected_map_id), "notifications": notifications,
		"highest_stage_cleared": highest_stage_cleared, "dungeons_cleared": dungeons_cleared,
		"owned_characters": owned_characters.map(func(id): return str(id)),
		"equipment_inventory": equipment_inventory, "equipped_equipment_id": equipped_equipment_id,
	}, true)
	_write_save(data)

func load_save() -> void:
	var data := _read_save()
	energy = clampi(int(data.get("energy", MAX_ENERGY)), 0, MAX_ENERGY)
	energy_timestamp = float(data.get("energy_timestamp", Time.get_unix_time_from_system()))
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
	highest_stage_cleared = clampi(int(data.get("highest_stage_cleared", 0)), 0, STAGE_COUNT)
	dungeons_cleared = maxi(0, int(data.get("dungeons_cleared", 0)))
	var stored_owned = data.get("owned_characters", [])
	owned_characters = (stored_owned as Array).map(func(id): return StringName(str(id))) if stored_owned is Array and not stored_owned.is_empty() else [&"variante_01"]
	if not owned_characters.has(&"variante_01"):
		owned_characters.append(&"variante_01")
	var stored_equipment = data.get("equipment_inventory", [])
	equipment_inventory = stored_equipment if stored_equipment is Array else []
	equipped_equipment_id = str(data.get("equipped_equipment_id", ""))

func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
