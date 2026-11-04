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
signal missions_changed
signal boss_encounter_changed(active: bool)
signal music_enabled_changed(value: bool)
signal effects_enabled_changed(value: bool)

const SAVE_PATH := "user://emberfall_save.json"
const MAX_ENERGY := 25
const ENERGY_COST := 5
const ENERGY_INTERVAL := 300.0
const STAGE_COUNT := 10
const DUNGEON_UNLOCK_STAGE := 10

## Six equipment slots; items, stats and rarities live in EquipmentCatalog.
const EQUIPMENT_TYPES := EquipmentCatalog.TYPES
const EQUIPMENT_TYPE_LABELS := EquipmentCatalog.TYPE_LABELS
const RARITY_WEIGHTS := {"common": 60, "rare": 30, "epic": 10, "legendary": 0}
const RARITY_LABELS := EquipmentCatalog.RARITY_LABELS

const DAY_SECONDS := 86400.0
const WEEK_SECONDS := 604800.0

## `type` selects which period counter tracks progress toward `target`.
## Progress and "claimed" state both reset when their period rolls over.
## "route" is where the MissionsScreen's IR button sends the player —
## PROMPT_MISIONES_EMBERFALL.md's "El botón IR navega al sistema relacionado
## con el objetivo".
const DAILY_MISSIONS := [
	{"id": "daily_kills", "period": "daily", "name": "CACERÍA DIARIA", "description": "Elimina 30 enemigos hoy", "type": "daily_kills", "target": 30, "gold": 30, "gems": 0, "route": "home"},
	{"id": "daily_gold", "period": "daily", "name": "BOTÍN DIARIO", "description": "Conseguí 150 de oro hoy", "type": "daily_gold", "target": 150, "gold": 0, "gems": 1, "route": "home"},
	{"id": "daily_runs", "period": "daily", "name": "AVENTURA DIARIA", "description": "Superá 1 pantalla o mazmorra hoy", "type": "daily_runs", "target": 1, "gold": 50, "gems": 0, "route": "home"},
]

const WEEKLY_MISSIONS := [
	{"id": "weekly_kills", "period": "weekly", "name": "EXTERMINIO SEMANAL", "description": "Eliminá 200 enemigos esta semana", "type": "weekly_kills", "target": 200, "gold": 150, "gems": 3, "route": "home"},
	{"id": "weekly_gold", "period": "weekly", "name": "FORTUNA SEMANAL", "description": "Conseguí 800 de oro esta semana", "type": "weekly_gold", "target": 800, "gold": 0, "gems": 6, "route": "home"},
	{"id": "weekly_runs", "period": "weekly", "name": "CAMPAÑA SEMANAL", "description": "Superá 7 pantallas o mazmorras esta semana", "type": "weekly_runs", "target": 7, "gold": 300, "gems": 8, "route": "dungeons"},
	{"id": "weekly_chests", "period": "weekly", "name": "BÓVEDA SEMANAL", "description": "Abrí 4 cofres esta semana", "type": "weekly_chests", "target": 4, "gold": 0, "gems": 5, "route": "shop"},
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
## Every other permanent upgrade (UpgradeCatalog), id -> level.
var permanent_upgrades: Dictionary = {}
## Lifetime stats that unlock abilities (AbilityCatalog.UNLOCKS).
var run_stats: Dictionary = {"lifetime_kills": 0, "bosses_defeated": 0, "best_level": 0, "chests_opened": 0, "evolutions_done": 0, "best_time": 0}
var unlocked_abilities: Array[String] = []
## Stats per hero, only from runs played with that hero (see
## AbilityCatalog.WEAPON_CHALLENGES), and the weapons already unlocked.
var hero_stats: Dictionary = {}
var unlocked_weapons: Array[String] = []
var music_enabled := true
var effects_enabled := true
var tutorial_completed := false
## Accessibility/comfort options (Configuración).
var vibration_enabled := true
## Turns off camera shake, hit stop and bright hit flashes.
var reduce_motion := false
## 0 small, 1 normal, 2 large — see JOYSTICK_SCALES.
var joystick_size := 1
const JOYSTICK_SCALES := [0.8, 1.0, 1.3]
var boss_encounter_active := false

var level := 1
var experience := 0
var experience_to_next := 100
var selected_character_id: StringName = &"variante_01"
var selected_character_texture := ""
var selected_character_sprite_folder := ""
var selected_map_id: StringName = &""
var notifications: Array = []

# Progression
var highest_stage_cleared := 0
var dungeons_cleared := 0
## "type_index" keys (e.g. "stage_3", "dungeon_1") already cleared at least
## once — drives the one-time first-clear bonus in finish_run().
var first_clears: Array = []
const FIRST_CLEAR_BONUS_GOLD := 40
const FIRST_CLEAR_BONUS_GEMS := 1
var owned_characters: Array = [&"variante_01"]
var equipment_inventory: Array = []
## Persistent counter for item uids (see _generate_item_uid) — never derived
## from a clock or from engine uptime, so it can't collide across sessions.
var _next_item_uid := 0
## Global loadout, independent of which hero is active: one item per
## equipment type (weapon/armor/helmet/amulet/ring/boots).
var equipped_by_type: Dictionary = {"weapon": "", "armor": "", "helmet": "", "amulet": "", "ring": "", "boots": ""}

# Daily/weekly mission counters. Each resets to 0 (and un-claims its
# missions) once its period elapses; see _check_period_resets().
var daily_reset_at := Time.get_unix_time_from_system()
var weekly_reset_at := Time.get_unix_time_from_system()
var daily_kills := 0
var daily_gold := 0
var daily_runs := 0
var daily_chests := 0
var weekly_kills := 0
var weekly_gold := 0
var weekly_runs := 0
var weekly_chests := 0
var claimed_daily_missions: Array = []
var claimed_weekly_missions: Array = []

# Context for the run currently starting/in progress, and the last one used
# (kept after the run ends so the result screen can offer "retry").
var current_stage_context: Dictionary = {}
var last_stage_context: Dictionary = {}
## Filled when a run ends (game_world.end_run + finish_run) for the result
## screen. Not saved: it only describes the run that just finished.
var last_run_summary: Dictionary = {}
var last_run_rewards: Dictionary = {}

# AUD-11: whether any persisted field changed since the last save() without
# being flushed yet — set by mid-run mutations like add_gold() so they don't
# get lost to a crash or force-close before the next natural save point.
var _save_dirty := false
var _last_dirty_save_at := 0.0
const DIRTY_SAVE_INTERVAL := 5.0

func _ready() -> void:
	load_save()
	refresh_energy()
	_check_period_resets()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_energy_tick)
	add_child(timer)

func _on_energy_tick() -> void:
	refresh_energy()
	energy_countdown_changed.emit(seconds_until_next_energy())
	_check_period_resets()
	# AUD-11: gold picked up mid-run only lives in memory until something else
	# triggers a save (finish_run, buying, etc.) — a force-close or crash
	# mid-run would silently lose it. Flush it to disk on a short throttle
	# instead of on every pickup, so a mid-run save spike doesn't hammer disk I/O.
	if _save_dirty:
		var now := Time.get_unix_time_from_system()
		if now - _last_dirty_save_at >= DIRTY_SAVE_INTERVAL:
			save()
			_last_dirty_save_at = now

## Resets daily/weekly mission counters (and un-claims their missions) once
## their period has fully elapsed since the last reset. If the system clock
## has moved backward since the reset point was stored (DST, timezone,
## manual change, a bad clock getting corrected), `now - reset_at` goes
## negative and would otherwise never reach the threshold — re-baseline to
## `now` instead of leaving the period stuck waiting for a "now" that might
## not arrive for a very long time.
func _check_period_resets() -> void:
	var now := Time.get_unix_time_from_system()
	if now < daily_reset_at:
		daily_reset_at = now
	elif now - daily_reset_at >= DAY_SECONDS:
		daily_reset_at = now
		daily_kills = 0; daily_gold = 0; daily_runs = 0; daily_chests = 0
		claimed_daily_missions = []
		claimed_daily_milestones = []
		missions_changed.emit()
		save()
	if now < weekly_reset_at:
		weekly_reset_at = now
	elif now - weekly_reset_at >= WEEK_SECONDS:
		weekly_reset_at = now
		weekly_kills = 0; weekly_gold = 0; weekly_runs = 0; weekly_chests = 0
		claimed_weekly_missions = []
		claimed_weekly_milestones = []
		missions_changed.emit()
		save()

func seconds_until_daily_reset() -> int:
	return maxi(0, int(DAY_SECONDS - (Time.get_unix_time_from_system() - daily_reset_at)))

func seconds_until_weekly_reset() -> int:
	return maxi(0, int(WEEK_SECONDS - (Time.get_unix_time_from_system() - weekly_reset_at)))

func seconds_until_next_energy() -> int:
	if energy >= MAX_ENERGY:
		return 0
	# fmod() keeps the sign of its input, so a negative `elapsed` (clock moved
	# backward past energy_timestamp) would otherwise produce a countdown
	# longer than a full interval instead of a sane one.
	var elapsed := maxf(0.0, Time.get_unix_time_from_system() - energy_timestamp)
	var remaining := ENERGY_INTERVAL - fmod(elapsed, ENERGY_INTERVAL)
	return int(ceil(remaining))

func change_screen(value: String) -> void:
	# AUD-11: leaving "playing" (pause, victory, defeat) is exactly when the OS
	# is likeliest to suspend or kill the app (focus loss, phone call) — flush
	# any gold collected this run before that can happen instead of waiting
	# for the next throttled tick.
	var leaving_playing := screen == "playing" and value != "playing"
	screen = value
	screen_changed.emit(value)
	if leaving_playing and _save_dirty:
		save()
		_last_dirty_save_at = Time.get_unix_time_from_system()

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

## Domain-side gate on top of whatever the screen's own buttons already
## disable — a stage/dungeon must actually be unlocked to be startable, not
## just "not clickable in this particular UI".
func is_scenario_unlocked(context: Dictionary) -> bool:
	var index_value = context.get("index", 0)
	var index := int(index_value) if index_value is int or index_value is float else 0
	match str(context.get("type", "")):
		"stage": return is_stage_unlocked(index)
		"dungeon": return is_dungeon_unlocked(index)
	return false

func begin_stage(context: Dictionary) -> bool:
	if not is_scenario_unlocked(context):
		return false
	current_stage_context = context
	last_stage_context = context
	select_map(StringName(str(context.get("id", ""))))
	return true

## Rewards granted immediately as loot is collected mid-run (gold/xp orbs).
func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	daily_gold += amount
	weekly_gold += amount
	_save_dirty = true
	gold_changed.emit(gold)
	missions_changed.emit()

func finish_run(victory: bool, kills: int) -> void:
	if screen != "playing":
		return
	high_score = maxi(high_score, kills)
	daily_kills += kills
	weekly_kills += kills
	var context := current_stage_context
	last_run_rewards = {"gold": 0, "gems": 0, "xp": 0, "first_clear": false}
	if victory:
		var bonus_gold := int(context.get("gold_reward", 20 + kills / 2))
		var bonus_gems := int(context.get("gems_reward", 0))
		# ECON-02: the very first clear of a given stage/dungeon pays extra —
		# repeating it for farming still pays the normal reward, just not
		# this one-time bonus, so replaying stays worthwhile without making
		# grinding a specific stage the best strategy.
		var clear_key := "%s_%s" % [str(context.get("type", "stage")), str(context.get("index", 0))]
		if not first_clears.has(clear_key):
			first_clears.append(clear_key)
			bonus_gold += FIRST_CLEAR_BONUS_GOLD
			bonus_gems += FIRST_CLEAR_BONUS_GEMS
			last_run_rewards["first_clear"] = true
		last_run_rewards["gold"] = bonus_gold
		last_run_rewards["gems"] = bonus_gems
		gold += bonus_gold
		daily_gold += bonus_gold
		weekly_gold += bonus_gold
		gems += bonus_gems
		daily_runs += 1
		weekly_runs += 1
		gold_changed.emit(gold)
		gems_changed.emit(gems)
		_apply_stage_clear(context)
	var xp_gain: int = (30 + kills) if victory else (10 + kills / 2)
	last_run_rewards["xp"] = xp_gain
	add_experience(xp_gain)
	SfxPlayer.play("progression/victory.wav" if victory else "progression/player_defeat.wav", false)
	change_screen("victory" if victory else "defeat")
	run_finished.emit(victory)
	missions_changed.emit()
	current_stage_context = {}
	save()

func _apply_stage_clear(context: Dictionary) -> void:
	var type := str(context.get("type", "stage"))
	var index := int(context.get("index", 0))
	if type == "stage":
		if index > highest_stage_cleared:
			highest_stage_cleared = index
			progress_changed.emit()
			missions_changed.emit()
	elif type == "dungeon":
		if index > dungeons_cleared:
			dungeons_cleared = index
			progress_changed.emit()
			missions_changed.emit()

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

func set_selected_character(character_id: StringName, texture_path: String = "", sprite_folder: String = "") -> void:
	if not owns_character(character_id):
		return
	selected_character_id = character_id
	selected_character_texture = texture_path
	selected_character_sprite_folder = sprite_folder
	selected_character_changed.emit(character_id)
	save()

func owns_character(character_id: StringName) -> bool:
	return owned_characters.has(character_id)

var _character_data_cache: Dictionary = {}

## Loads (and caches) the CharacterData resource for a hero id, so gameplay
## code can read per-hero fields (attack_name, attack_color, ...) without
## duplicating the roster that CharacterEquipmentScreen already maintains.
func get_character_data(character_id: StringName) -> CharacterData:
	if _character_data_cache.has(character_id):
		return _character_data_cache[character_id]
	if _character_data_cache.is_empty():
		for data in CharacterCatalog.load_all():
			_character_data_cache[StringName(str(data.id))] = data
	return _character_data_cache.get(character_id)

## Cost, currency and unlock requirement all come from the hero's own
## CharacterData — never from the caller — so a purchase can't be forged by
## passing a different cost than the one actually listed, and the unlock
## requirement is enforced here too, not just by a disabled button in the UI.
func character_requirement_met(requirement: String) -> bool:
	if requirement == "":
		return true
	if requirement.begins_with("stage_"):
		return highest_stage_cleared >= int(requirement.trim_prefix("stage_"))
	if requirement.begins_with("dungeon_"):
		return dungeons_cleared >= int(requirement.trim_prefix("dungeon_"))
	return true

func buy_character(character_id: StringName) -> bool:
	if owns_character(character_id):
		return false
	var data := get_character_data(character_id)
	if data == null or not character_requirement_met(data.requirement):
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return false
	if data.currency == "gems":
		if gems < data.cost:
			SfxPlayer.play("economy/purchase_failed.wav", false)
			return false
		gems -= data.cost
		gems_changed.emit(gems)
	else:
		if gold < data.cost:
			SfxPlayer.play("economy/purchase_failed.wav", false)
			return false
		gold -= data.cost
		gold_changed.emit(gold)
	owned_characters.append(character_id)
	save()
	SfxPlayer.play("economy/purchase_success.wav", false)
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
	SfxPlayer.play_ui("ui/notification.wav")
	save()

func mark_notifications_read() -> void:
	for entry in notifications:
		entry["read"] = true
	notifications_changed.emit(0)
	save()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	music_enabled_changed.emit(value)
	save()

## Not persisted — a boss is only ever "active" mid-run, and every run starts
## with it false (see game_world.gd). Just lets MusicDirector (and anything
## else) know when to switch to boss music without reaching into game_world.
func set_boss_encounter(active: bool) -> void:
	if boss_encounter_active == active:
		return
	boss_encounter_active = active
	boss_encounter_changed.emit(active)

func set_effects_enabled(value: bool) -> void:
	effects_enabled = value
	effects_enabled_changed.emit(value)
	save()

func set_vibration_enabled(value: bool) -> void:
	vibration_enabled = value
	save()

func set_reduce_motion(value: bool) -> void:
	reduce_motion = value
	save()

func set_joystick_size(value: int) -> void:
	joystick_size = clampi(value, 0, JOYSTICK_SCALES.size() - 1)
	save()

func joystick_scale() -> float:
	return float(JOYSTICK_SCALES[clampi(joystick_size, 0, JOYSTICK_SCALES.size() - 1)])

## Short buzz on phones, respecting the Vibración option.
func vibrate(ms: int) -> void:
	if vibration_enabled:
		Input.vibrate_handheld(ms)

func mark_tutorial_completed() -> void:
	if tutorial_completed:
		return
	tutorial_completed = true
	save()

## AUD-08: the shop's product/energy/chest catalogues used to live only in
## ShopScreen.gd, which meant GameState just trusted whatever amount/cost a
## caller passed it — a UI bug (or a hand-edited call) could buy any amount
## for any price. These are now the single source of truth; ShopScreen reads
## them for display and buys by index, never by raw amount/cost.
## "usd" marks a real-money offer: there is no payment SDK yet, so those
## offers cannot be bought with gems (cost -1) and buy_*_offer() refuses them.
## "ad_first" additionally offers the first purchase through a rewarded ad.
## Both are display-only until a store/ads integration is connected.
const COIN_OFFERS := [
	{"id": "recarga_oro_gratis", "amount": 100, "cost": 0, "art": "COINS"},
	{"id": "recarga_oro_baja", "amount": 500, "cost": -1, "usd": "0,99", "ad_first": true, "art": "STACK"},
	{"id": "recarga_oro_media", "amount": 1200, "cost": -1, "usd": "1,99", "art": "PILE"},
	{"id": "bolsa_oro_media", "amount": 2500, "cost": -1, "usd": "3,99", "art": "BAG"},
	{"id": "cofre_oro_medio", "amount": 6500, "cost": -1, "usd": "3,99", "art": "CHEST"},
	{"id": "cofre_oro_grande", "amount": 14000, "cost": -1, "usd": "74,99", "art": "CHEST"},
]
const ENERGY_OFFERS := [
	{"id": "recarga_energia_gratuita", "amount": 20, "cost": 0, "art": "ENERGY"},
	{"id": "recarga_energia_media", "amount": 60, "cost": -1, "usd": "0,99", "ad_first": true, "art": "BOTTLE"},
	{"id": "recarga_energia_grande", "amount": 120, "cost": -1, "usd": "1,99", "art": "BOTTLES"},
]
const CHEST_TIERS := [
	{"id": "baul_comun", "title": "BAÚL COMÚN", "cost": 150, "rarities": ["COMÚN", "RARO"], "art": "COMMON"},
	{"id": "baul_epico", "title": "BAÚL ÉPICO", "cost": 400, "rarities": ["RARO", "ÉPICO"], "art": "EPIC"},
]
## One-time "GRATIS" (cost 0) offers — without this they had no claimed-once
## guard, so the free-coins/free-energy buttons could be tapped indefinitely
## for unlimited currency. Keys are "coin_<index>"/"energy_<index>".
var claimed_free_offers: Array = []

func _is_free_offer_available(key: String) -> bool:
	return not claimed_free_offers.has(key)

func _mark_free_offer_claimed(key: String) -> void:
	if not claimed_free_offers.has(key):
		claimed_free_offers.append(key)

## Store-facing gem/gold purchases, resolved entirely from the catalogues
## above by index — never from caller-supplied amount/cost.
func buy_coin_offer(index: int) -> bool:
	if index < 0 or index >= COIN_OFFERS.size():
		return false
	var offer: Dictionary = COIN_OFFERS[index]
	if offer.has("usd"):
		return false
	var cost := int(offer.cost)
	var key := "coin_%d" % index
	if cost == 0:
		if not _is_free_offer_available(key):
			SfxPlayer.play("economy/purchase_failed.wav", false)
			return false
		_mark_free_offer_claimed(key)
	elif gems < cost:
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return false
	else:
		gems -= cost
		gems_changed.emit(gems)
	gold += int(offer.amount)
	gold_changed.emit(gold)
	SfxPlayer.play("economy/purchase_success.wav", false)
	save()
	return true

func buy_energy_offer(index: int) -> bool:
	if index < 0 or index >= ENERGY_OFFERS.size():
		return false
	if energy >= MAX_ENERGY:
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return false
	var offer: Dictionary = ENERGY_OFFERS[index]
	if offer.has("usd"):
		return false
	var cost := int(offer.cost)
	var key := "energy_%d" % index
	if cost == 0:
		if not _is_free_offer_available(key):
			SfxPlayer.play("economy/purchase_failed.wav", false)
			return false
		_mark_free_offer_claimed(key)
	elif gems < cost:
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return false
	else:
		gems -= cost
		gems_changed.emit(gems)
	energy = mini(MAX_ENERGY, energy + int(offer.amount))
	energy_changed.emit(energy)
	energy_countdown_changed.emit(seconds_until_next_energy())
	SfxPlayer.play("economy/purchase_success.wav", false)
	save()
	return true

func open_chest_with_gems(tier_index: int) -> Dictionary:
	if tier_index < 0 or tier_index >= CHEST_TIERS.size():
		return {}
	var tier: Dictionary = CHEST_TIERS[tier_index]
	var cost := int(tier.cost)
	if gems < cost:
		return {}
	var allowed: Array = []
	for key in RARITY_LABELS:
		if tier.rarities.has(RARITY_LABELS[key]):
			allowed.append(key)
	var recipe_id := _roll_equipment_drop(allowed)
	gems -= cost; gems_changed.emit(gems)
	var item := EquipmentCatalog.make_item(recipe_id, _generate_item_uid(recipe_id))
	equipment_inventory.append(item); inventory_changed.emit(); daily_chests += 1; weekly_chests += 1; missions_changed.emit(); save()
	return item

func buy_upgrade(kind: String) -> bool:
	if not UpgradeCatalog.has(kind):
		return false
	var level_value := get_upgrade_level(kind)
	var cost := UpgradeCatalog.cost(kind, level_value)
	if level_value >= UpgradeCatalog.max_level(kind) or gold < cost:
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return false
	gold -= cost
	set_upgrade_level(kind, level_value + 1)
	gold_changed.emit(gold)
	SfxPlayer.play("economy/purchase_success.wav", false)
	save()
	return true

func get_upgrade_level(kind: String) -> int:
	match kind:
		"damage": return permanent_damage
		"health": return permanent_health
		"speed": return permanent_speed
	return int(permanent_upgrades.get(kind, 0))

func set_upgrade_level(kind: String, value: int) -> void:
	match kind:
		"damage": permanent_damage = clampi(value, 0, 10)
		"health": permanent_health = clampi(value, 0, 10)
		"speed": permanent_speed = clampi(value, 0, 10)
		_:
			if UpgradeCatalog.has(kind):
				permanent_upgrades[kind] = clampi(value, 0, UpgradeCatalog.max_level(kind))

## -- Ability unlocks --

func is_ability_unlocked(id: String) -> bool:
	return not AbilityCatalog.UNLOCKS.has(id) or id in unlocked_abilities

## Progress toward an unlock as [current, target].
func unlock_progress(id: String) -> Array:
	var requirement: Dictionary = AbilityCatalog.UNLOCKS.get(id, {})
	if requirement.is_empty():
		return [1, 1]
	return [int(run_stats.get(str(requirement["stat"]), 0)), int(requirement["target"])]

## -- Hero weapons --

func is_weapon_unlocked(id: String) -> bool:
	return id in unlocked_weapons

## Progress of a hero's weapon challenge as [current, target].
func weapon_challenge_progress(hero_id: String) -> Array:
	var challenge := AbilityCatalog.weapon_challenge(hero_id)
	if challenge.is_empty():
		return [0, 1]
	var stats: Dictionary = hero_stats.get(hero_id, {})
	return [int(stats.get(str(challenge["stat"]), 0)), int(challenge["target"])]

## Adds a run to its hero's stats and unlocks that hero's weapon when the
## challenge is met. Returns the newly unlocked weapon ids.
func _record_hero_run(stats: Dictionary) -> Array[String]:
	var unlocked: Array[String] = []
	var hero_id := str(stats.get("hero", ""))
	if hero_id == "":
		return unlocked
	var mine: Dictionary = hero_stats.get(hero_id, {})
	var run := {
		"kills": int(stats.get("kills", 0)),
		"bosses": 1 if stats.get("victory", false) else 0,
		"elites": int(stats.get("elites", 0)),
		"frozen": int(stats.get("frozen", 0)),
		"poison_kills": int(stats.get("poison_kills", 0)),
		"evolutions": int(stats.get("evolutions", 0)),
		"best_time": int(stats.get("time", 0)),
		"best_level": int(stats.get("level", 0)),
		"best_clean_time": int(stats.get("clean_time", 0)),
	}
	for key: String in run:
		if key.begins_with("best_"):
			mine[key] = maxi(int(mine.get(key, 0)), int(run[key]))
		else:
			mine[key] = int(mine.get(key, 0)) + int(run[key])
	hero_stats[hero_id] = mine
	var weapon := AbilityCatalog.weapon_id(StringName(hero_id))
	var progress := weapon_challenge_progress(hero_id)
	if weapon not in unlocked_weapons and not AbilityCatalog.weapon_challenge(hero_id).is_empty() and int(progress[0]) >= int(progress[1]):
		unlocked_weapons.append(weapon)
		unlocked.append(weapon)
		var hero := AbilityCatalog.weapon_hero(weapon)
		add_notification("Arma desbloqueada: %s" % (hero.attack_name if hero != null else weapon))
	return unlocked

## -- Códex --
## Abilities/passives ever taken, evolutions ever made, and lifetime kills
## per bestiary key (see BestiaryCatalog). Updated once per run in record_run.
var discovered_abilities: Array[String] = []
var discovered_evolutions: Array[String] = []
var bestiary: Dictionary = {}

func _load_ability_ids(stored: Variant, target: Array[String]) -> void:
	target.clear()
	if not stored is Array:
		return
	for id in stored:
		if id is String and (AbilityCatalog.ACTIVES.has(id) or AbilityCatalog.PASSIVES.has(id)) and id not in target:
			target.append(id)

func _record_discoveries(stats: Dictionary) -> void:
	for id in stats.get("abilities", []):
		if str(id) not in discovered_abilities:
			discovered_abilities.append(str(id))
	for id in stats.get("evolved", []):
		if str(id) not in discovered_evolutions:
			discovered_evolutions.append(str(id))
	var kills_by_type: Dictionary = stats.get("kills_by_type", {})
	for key in kills_by_type:
		bestiary[str(key)] = int(bestiary.get(str(key), 0)) + int(kills_by_type[key])

## The still-locked ability closest to unlocking, as {id, text, current,
## target}; empty once everything is unlocked.
func next_unlock_goal() -> Dictionary:
	var best := {}
	var best_ratio := -1.0
	for id in AbilityCatalog.UNLOCKS:
		if is_ability_unlocked(id):
			continue
		var progress := unlock_progress(id)
		var ratio := float(progress[0]) / maxf(1.0, float(progress[1]))
		if ratio > best_ratio:
			best_ratio = ratio
			best = {"id": id, "text": str(AbilityCatalog.UNLOCKS[id]["text"]), "current": int(progress[0]), "target": int(progress[1])}
	return best

## Called by game_world when a run ends (any way). Adds the run to the
## lifetime stats and unlocks any ability whose goal was reached; returns
## the newly unlocked ids.
func record_run(stats: Dictionary) -> Array[String]:
	run_stats["lifetime_kills"] = int(run_stats.get("lifetime_kills", 0)) + int(stats.get("kills", 0))
	run_stats["bosses_defeated"] = int(run_stats.get("bosses_defeated", 0)) + (1 if stats.get("victory", false) else 0)
	run_stats["chests_opened"] = int(run_stats.get("chests_opened", 0)) + int(stats.get("chests", 0))
	run_stats["evolutions_done"] = int(run_stats.get("evolutions_done", 0)) + int(stats.get("evolutions", 0))
	run_stats["best_level"] = maxi(int(run_stats.get("best_level", 0)), int(stats.get("level", 0)))
	run_stats["best_time"] = maxi(int(run_stats.get("best_time", 0)), int(stats.get("time", 0)))
	_record_discoveries(stats)
	var unlocked: Array[String] = []
	for id in AbilityCatalog.UNLOCKS:
		if id in unlocked_abilities:
			continue
		var progress := unlock_progress(id)
		if int(progress[0]) >= int(progress[1]):
			unlocked_abilities.append(id)
			unlocked.append(id)
			add_notification("Habilidad desbloqueada: %s" % AbilityCatalog.display_name(id))
	unlocked.append_array(_record_hero_run(stats))
	save()
	return unlocked

## -- Equipment / chests --

const CHEST_COST := 150

## A recipe id: rarity by RARITY_WEIGHTS (only among `allowed`, all when
## empty), then any slot of that rarity.
func _roll_equipment_drop(allowed: Array = []) -> String:
	var rarities: Array = allowed if not allowed.is_empty() else RARITY_WEIGHTS.keys()
	var total := 0
	for r in rarities:
		total += int(RARITY_WEIGHTS.get(r, 0))
	var picked: String = str(rarities[0])
	if total > 0:
		var roll := randi() % total
		for r in rarities:
			roll -= int(RARITY_WEIGHTS.get(r, 0))
			if roll < 0:
				picked = str(r)
				break
	return EquipmentCatalog.random_recipe([picked])

## Time.get_ticks_msec() resets to 0 every launch, so two chests opened at
## roughly the same point in two different sessions could mint the exact
## same uid — an incrementing counter that's part of the save can't repeat.
func _generate_item_uid(base_id: String) -> String:
	_next_item_uid += 1
	return "%s_%d" % [base_id, _next_item_uid]

## ECON-02: a duplicate recipe would otherwise just sit in the backpack as
## dead weight (only one item per equipment_type can ever be equipped at
## once). Converting it to gold instead means every chest is worth opening,
## never a wasted pull.
const DUPLICATE_REFUND_GOLD := {"common": 15, "rare": 35, "epic": 70, "legendary": 150}

func _owns_equipment_recipe(recipe_id: String) -> bool:
	for existing in equipment_inventory:
		if str(existing.get("id", "")) == recipe_id:
			return true
	return false

func open_chest() -> Dictionary:
	if gold < CHEST_COST:
		SfxPlayer.play("economy/purchase_failed.wav", false)
		return {}
	gold -= CHEST_COST
	gold_changed.emit(gold)
	var recipe_id := _roll_equipment_drop()
	var item: Dictionary = EquipmentCatalog.recipe(recipe_id).duplicate()
	if _owns_equipment_recipe(recipe_id):
		var refund := int(DUPLICATE_REFUND_GOLD.get(str(item.get("rarity", "common")), 15))
		gold += refund
		gold_changed.emit(gold)
		item["duplicate_refund"] = refund
	else:
		item = EquipmentCatalog.make_item(recipe_id, _generate_item_uid(recipe_id))
		equipment_inventory.append(item)
		inventory_changed.emit()
	daily_chests += 1
	weekly_chests += 1
	missions_changed.emit()
	SfxPlayer.play("economy/chest_open.wav", false)
	save()
	return item

## Each equipment type (weapon/armor/helmet/amulet/ring/boots) has its own
## slot; equipping an item replaces whatever was in that type's slot before.
## This loadout is global — it doesn't belong to any one hero.
func equip_item(uid: String) -> void:
	for item in equipment_inventory:
		if str(item.get("uid", "")) == uid:
			var equipment_type := str(item.get("equipment_type", ""))
			if equipment_type != "":
				equipped_by_type[equipment_type] = uid
			inventory_changed.emit()
			SfxPlayer.play_ui("economy/item_equip.wav")
			save()
			return

func unequip_type(equipment_type: String) -> void:
	if not equipped_by_type.has(equipment_type):
		return
	equipped_by_type[equipment_type] = ""
	inventory_changed.emit()
	SfxPlayer.play_ui("economy/item_equip.wav")
	save()

func get_equipped_item_for_type(equipment_type: String) -> Dictionary:
	var uid := str(equipped_by_type.get(equipment_type, ""))
	if uid == "":
		return {}
	for item in equipment_inventory:
		if str(item.get("uid", "")) == uid:
			return item
	return {}

## Every stat from the equipped items added up, as {stat: value} (see
## EquipmentCatalog.STATS for units).
func equipment_totals() -> Dictionary:
	var totals := {}
	for equipment_type in equipped_by_type:
		var item := get_equipped_item_for_type(equipment_type)
		if item.is_empty():
			continue
		var stats := EquipmentCatalog.item_stats(item)
		for stat in stats:
			totals[stat] = float(totals.get(stat, 0.0)) + float(stats[stat])
	return totals

func equipment_stat(stat: String) -> float:
	return float(equipment_totals().get(stat, 0.0))

## Flat stats (damage, health) rounded, for code that works in whole units.
func get_equipped_bonus(stat: String) -> int:
	return int(round(equipment_stat(stat)))

## -- Missions --

func mission_progress(mission: Dictionary) -> int:
	match str(mission.get("type", "")):
		"daily_kills": return daily_kills
		"daily_gold": return daily_gold
		"daily_runs": return daily_runs
		"daily_chests": return daily_chests
		"weekly_kills": return weekly_kills
		"weekly_gold": return weekly_gold
		"weekly_runs": return weekly_runs
		"weekly_chests": return weekly_chests
	return 0

func _claimed_list(mission: Dictionary) -> Array:
	return claimed_weekly_missions if str(mission.get("period", "")) == "weekly" else claimed_daily_missions

func is_mission_claimed(mission: Dictionary) -> bool:
	return _claimed_list(mission).has(str(mission.get("id", "")))

func can_claim_mission(mission: Dictionary) -> bool:
	if is_mission_claimed(mission):
		return false
	return mission_progress(mission) >= int(mission.get("target", 0))

func find_mission(id: String) -> Dictionary:
	for entry in DAILY_MISSIONS:
		if str(entry.get("id", "")) == id:
			return entry
	for entry in WEEKLY_MISSIONS:
		if str(entry.get("id", "")) == id:
			return entry
	return {}

func claim_mission(id: String) -> bool:
	var mission := find_mission(id)
	if mission.is_empty() or not can_claim_mission(mission):
		return false
	_claimed_list(mission).append(id)
	var reward_gold := int(mission.get("gold", 0))
	var reward_gems := int(mission.get("gems", 0))
	if reward_gold > 0:
		gold += reward_gold
		gold_changed.emit(gold)
	if reward_gems > 0:
		gems += reward_gems
		gems_changed.emit(gems)
	missions_changed.emit()
	save()
	return true

func has_claimable_missions() -> bool:
	for mission in DAILY_MISSIONS:
		if can_claim_mission(mission):
			return true
	for mission in WEEKLY_MISSIONS:
		if can_claim_mission(mission):
			return true
	return false

## PROMPT_MISIONES_EMBERFALL.md's cumulative "PROGRESO DIARIO/SEMANAL" strip:
## a milestone chest every N missions claimed *this period*, on top of each
## mission's own reward. Thresholds are scaled to how many missions actually
## exist per period (3 daily, 4 weekly) rather than the spec's illustrative
## 1/3/5/7/10 (which assumes a bigger catalogue than DAILY_MISSIONS has) —
## same shape, real numbers.
const DAILY_MILESTONES := [
	{"threshold": 1, "gold": 30, "gems": 0},
	{"threshold": 2, "gold": 60, "gems": 1},
	{"threshold": 3, "gold": 120, "gems": 2},
]
const WEEKLY_MILESTONES := [
	{"threshold": 1, "gold": 80, "gems": 0},
	{"threshold": 2, "gold": 160, "gems": 2},
	{"threshold": 3, "gold": 280, "gems": 4},
	{"threshold": 4, "gold": 450, "gems": 8},
]
var claimed_daily_milestones: Array = []
var claimed_weekly_milestones: Array = []

func daily_missions_claimed_count() -> int:
	return claimed_daily_missions.size()

func weekly_missions_claimed_count() -> int:
	return claimed_weekly_missions.size()

func can_claim_daily_milestone(threshold: int) -> bool:
	return not claimed_daily_milestones.has(threshold) and daily_missions_claimed_count() >= threshold

func can_claim_weekly_milestone(threshold: int) -> bool:
	return not claimed_weekly_milestones.has(threshold) and weekly_missions_claimed_count() >= threshold

func claim_daily_milestone(threshold: int) -> bool:
	if not can_claim_daily_milestone(threshold):
		return false
	var entry: Dictionary = DAILY_MILESTONES.filter(func(m): return int(m.threshold) == threshold)[0]
	claimed_daily_milestones.append(threshold)
	_grant_milestone_reward(entry)
	return true

func claim_weekly_milestone(threshold: int) -> bool:
	if not can_claim_weekly_milestone(threshold):
		return false
	var entry: Dictionary = WEEKLY_MILESTONES.filter(func(m): return int(m.threshold) == threshold)[0]
	claimed_weekly_milestones.append(threshold)
	_grant_milestone_reward(entry)
	return true

func _grant_milestone_reward(entry: Dictionary) -> void:
	var reward_gold := int(entry.get("gold", 0))
	var reward_gems := int(entry.get("gems", 0))
	if reward_gold > 0:
		gold += reward_gold
		gold_changed.emit(gold)
	if reward_gems > 0:
		gems += reward_gems
		gems_changed.emit(gems)
	SfxPlayer.play("economy/chest_open.wav", false)
	missions_changed.emit()
	save()

func refresh_energy() -> void:
	if energy >= MAX_ENERGY:
		return
	var now := Time.get_unix_time_from_system()
	if energy_timestamp > now:
		# Stored timestamp is ahead of the system clock (it was set forward
		# and then corrected back) — without this, regen would stay stuck
		# until real time caught up to that bogus future point, possibly for
		# a very long time. Re-baseline instead of granting or losing energy.
		energy_timestamp = now
		return
	var recovered := int((now - energy_timestamp) / ENERGY_INTERVAL)
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
		"save_version": SAVE_FORMAT_VERSION,
		"energy": energy, "energy_timestamp": energy_timestamp, "gold": gold, "high_score": high_score,
		"damage": permanent_damage, "health": permanent_health, "speed": permanent_speed, "gems": gems,
		"permanent_upgrades": permanent_upgrades, "run_stats": run_stats, "unlocked_abilities": unlocked_abilities,
		"hero_stats": hero_stats, "unlocked_weapons": unlocked_weapons,
		"discovered_abilities": discovered_abilities, "discovered_evolutions": discovered_evolutions, "bestiary": bestiary,
		"music": music_enabled, "effects": effects_enabled, "tutorial_completed": tutorial_completed,
		"vibration": vibration_enabled, "reduce_motion": reduce_motion, "joystick_size": joystick_size,
		"level": level, "experience": experience, "experience_to_next": experience_to_next,
		"selected_character_id": str(selected_character_id), "selected_character_texture": selected_character_texture,
		"selected_character_sprite_folder": selected_character_sprite_folder,
		"selected_map_id": str(selected_map_id), "notifications": notifications,
		"highest_stage_cleared": highest_stage_cleared, "dungeons_cleared": dungeons_cleared, "first_clears": first_clears,
		"claimed_free_offers": claimed_free_offers,
		"owned_characters": owned_characters.map(func(id): return str(id)),
		"equipment_inventory": equipment_inventory, "equipped_by_type": equipped_by_type,
		"next_item_uid": _next_item_uid,
		"daily_reset_at": daily_reset_at, "weekly_reset_at": weekly_reset_at,
		"daily_kills": daily_kills, "daily_gold": daily_gold, "daily_runs": daily_runs, "daily_chests": daily_chests,
		"weekly_kills": weekly_kills, "weekly_gold": weekly_gold, "weekly_runs": weekly_runs, "weekly_chests": weekly_chests,
		"claimed_daily_missions": claimed_daily_missions, "claimed_weekly_missions": claimed_weekly_missions,
		"claimed_daily_milestones": claimed_daily_milestones, "claimed_weekly_milestones": claimed_weekly_milestones,
	}, true)
	_write_save(data)
	_save_dirty = false

const SAVE_FORMAT_VERSION := 1

## GDScript's int()/float()/str() throw a script error and abort the calling
## function when given an incompatible Variant type (e.g. int() on a
## Dictionary) instead of failing gracefully — confirmed by hand. A hand-edited
## or corrupted save can easily put the wrong JSON type under a known key, so
## every read in load_save() goes through one of these instead of a bare
## conversion, falling back to `default` rather than aborting mid-load.
func _safe_int(value: Variant, default: int) -> int:
	return int(value) if value is int or value is float else default

func _safe_float(value: Variant, default: float) -> float:
	return float(value) if value is int or value is float else default

func _safe_bool(value: Variant, default: bool) -> bool:
	return value if value is bool else default

func _safe_string(value: Variant, default: String) -> String:
	return str(value) if value is String or value is StringName else default

## Upgrades a save's data to SAVE_FORMAT_VERSION before load_save() reads it.
## A save with no "save_version" predates this field and is treated as 0.
## No migrations exist yet (this is still version 1) — add a branch here
## each time SAVE_FORMAT_VERSION increases, so old saves keep loading.
func _migrate_save(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return data
	var version := _safe_int(data.get("save_version"), 0)
	if version < 1:
		pass # nothing to transform yet, version 0 and 1 share the same shape
	data["save_version"] = SAVE_FORMAT_VERSION
	return data

func load_save() -> void:
	var data := _migrate_save(_read_save())
	energy = clampi(_safe_int(data.get("energy"), MAX_ENERGY), 0, MAX_ENERGY)
	energy_timestamp = _safe_float(data.get("energy_timestamp"), Time.get_unix_time_from_system())
	gold = maxi(0, _safe_int(data.get("gold"), 0))
	gems = maxi(0, _safe_int(data.get("gems"), 0))
	high_score = maxi(0, _safe_int(data.get("high_score"), 0))
	permanent_damage = clampi(_safe_int(data.get("damage"), 0), 0, 10)
	permanent_health = clampi(_safe_int(data.get("health"), 0), 0, 10)
	permanent_speed = clampi(_safe_int(data.get("speed"), 0), 0, 10)
	permanent_upgrades = {}
	var stored_upgrades = data.get("permanent_upgrades", {})
	if stored_upgrades is Dictionary:
		for key in stored_upgrades:
			if UpgradeCatalog.has(str(key)) and str(key) not in UpgradeCatalog.LEGACY_IDS:
				permanent_upgrades[str(key)] = clampi(_safe_int(stored_upgrades[key], 0), 0, UpgradeCatalog.max_level(str(key)))
	var stored_stats = data.get("run_stats", {})
	if stored_stats is Dictionary:
		for key in run_stats.keys():
			run_stats[key] = maxi(0, _safe_int(stored_stats.get(key), 0))
	unlocked_abilities.clear()
	var stored_unlocked = data.get("unlocked_abilities", [])
	if stored_unlocked is Array:
		for id in stored_unlocked:
			if id is String and AbilityCatalog.UNLOCKS.has(id) and id not in unlocked_abilities:
				unlocked_abilities.append(id)
	hero_stats = {}
	var stored_hero_stats = data.get("hero_stats", {})
	if stored_hero_stats is Dictionary:
		for hero_id in stored_hero_stats:
			var entry = stored_hero_stats[hero_id]
			if AbilityCatalog.WEAPON_CHALLENGES.has(str(hero_id)) and entry is Dictionary:
				var clean := {}
				for key in entry:
					clean[str(key)] = maxi(0, _safe_int(entry[key], 0))
				hero_stats[str(hero_id)] = clean
	unlocked_weapons.clear()
	var stored_weapons = data.get("unlocked_weapons", [])
	if stored_weapons is Array:
		for id in stored_weapons:
			if id is String and AbilityCatalog.is_weapon(id) and AbilityCatalog.WEAPON_CHALLENGES.has(AbilityCatalog.weapon_hero_id(id)) and id not in unlocked_weapons:
				unlocked_weapons.append(id)
	_load_ability_ids(data.get("discovered_abilities", []), discovered_abilities)
	_load_ability_ids(data.get("discovered_evolutions", []), discovered_evolutions)
	bestiary = {}
	var stored_bestiary = data.get("bestiary", {})
	if stored_bestiary is Dictionary:
		for key in stored_bestiary:
			if BestiaryCatalog.has(str(key)):
				bestiary[str(key)] = maxi(0, _safe_int(stored_bestiary[key], 0))
	music_enabled = _safe_bool(data.get("music"), true)
	effects_enabled = _safe_bool(data.get("effects"), true)
	tutorial_completed = _safe_bool(data.get("tutorial_completed"), false)
	vibration_enabled = _safe_bool(data.get("vibration"), true)
	reduce_motion = _safe_bool(data.get("reduce_motion"), false)
	joystick_size = clampi(_safe_int(data.get("joystick_size"), 1), 0, JOYSTICK_SCALES.size() - 1)
	level = maxi(1, _safe_int(data.get("level"), 1))
	experience = maxi(0, _safe_int(data.get("experience"), 0))
	experience_to_next = maxi(1, _safe_int(data.get("experience_to_next"), 100))
	var stored_selected_id := _safe_string(data.get("selected_character_id"), "")
	selected_character_id = StringName(stored_selected_id) if stored_selected_id != "" else &"variante_01"
	selected_character_texture = _safe_string(data.get("selected_character_texture"), "")
	selected_character_sprite_folder = _safe_string(data.get("selected_character_sprite_folder"), "")
	selected_map_id = StringName(_safe_string(data.get("selected_map_id"), ""))
	var stored_notifications = data.get("notifications", [])
	notifications = stored_notifications if stored_notifications is Array else []
	highest_stage_cleared = clampi(_safe_int(data.get("highest_stage_cleared"), 0), 0, STAGE_COUNT)
	dungeons_cleared = maxi(0, _safe_int(data.get("dungeons_cleared"), 0))
	var stored_first_clears = data.get("first_clears", [])
	first_clears = (stored_first_clears as Array).filter(func(v): return v is String) if stored_first_clears is Array else []
	var stored_claimed_free_offers = data.get("claimed_free_offers", [])
	claimed_free_offers = (stored_claimed_free_offers as Array).filter(func(v): return v is String) if stored_claimed_free_offers is Array else []
	var stored_owned = data.get("owned_characters", [])
	owned_characters = (stored_owned as Array).filter(func(id): return id is String or id is StringName).map(func(id): return StringName(str(id))) if stored_owned is Array else []
	if owned_characters.is_empty():
		owned_characters = [&"variante_01"]
	if not owned_characters.has(&"variante_01"):
		owned_characters.append(&"variante_01")
	var stored_equipment = data.get("equipment_inventory", [])
	equipment_inventory = (stored_equipment as Array).filter(func(item): return item is Dictionary) if stored_equipment is Array else []
	# Items from before EquipmentCatalog become level-1 items of the same
	# recipe and rarity (same uid, so equipped slots still point at them).
	for i in equipment_inventory.size():
		if EquipmentCatalog.is_legacy(equipment_inventory[i]):
			equipment_inventory[i] = EquipmentCatalog.convert_legacy(equipment_inventory[i])
	# Never trust the stored counter alone — also scan existing items in case
	# this save predates it (their uids came from the old, collision-prone
	# Time.get_ticks_msec() scheme) or it was hand-edited to something stale.
	_next_item_uid = maxi(0, _safe_int(data.get("next_item_uid"), 0))
	for item in equipment_inventory:
		var uid := str(item.get("uid", ""))
		var last_underscore := uid.rfind("_")
		if last_underscore == -1:
			continue
		var suffix := uid.substr(last_underscore + 1)
		if suffix.is_valid_int():
			_next_item_uid = maxi(_next_item_uid, int(suffix))
	var stored_equipped = data.get("equipped_by_type", {})
	equipped_by_type = stored_equipped if stored_equipped is Dictionary else {}
	for equipment_type in EQUIPMENT_TYPES:
		var current_value = equipped_by_type.get(equipment_type)
		if not (current_value is String or current_value is StringName):
			equipped_by_type[equipment_type] = ""
	daily_reset_at = _safe_float(data.get("daily_reset_at"), Time.get_unix_time_from_system())
	weekly_reset_at = _safe_float(data.get("weekly_reset_at"), Time.get_unix_time_from_system())
	daily_kills = maxi(0, _safe_int(data.get("daily_kills"), 0))
	daily_gold = maxi(0, _safe_int(data.get("daily_gold"), 0))
	daily_runs = maxi(0, _safe_int(data.get("daily_runs"), 0))
	daily_chests = maxi(0, _safe_int(data.get("daily_chests"), 0))
	weekly_kills = maxi(0, _safe_int(data.get("weekly_kills"), 0))
	weekly_gold = maxi(0, _safe_int(data.get("weekly_gold"), 0))
	weekly_runs = maxi(0, _safe_int(data.get("weekly_runs"), 0))
	weekly_chests = maxi(0, _safe_int(data.get("weekly_chests"), 0))
	var stored_daily_claimed = data.get("claimed_daily_missions", [])
	claimed_daily_missions = stored_daily_claimed if stored_daily_claimed is Array else []
	var stored_weekly_claimed = data.get("claimed_weekly_missions", [])
	claimed_weekly_missions = stored_weekly_claimed if stored_weekly_claimed is Array else []
	var stored_daily_milestones = data.get("claimed_daily_milestones", [])
	claimed_daily_milestones = (stored_daily_milestones as Array).filter(func(v): return v is int or v is float) if stored_daily_milestones is Array else []
	var stored_weekly_milestones = data.get("claimed_weekly_milestones", [])
	claimed_weekly_milestones = (stored_weekly_milestones as Array).filter(func(v): return v is int or v is float) if stored_weekly_milestones is Array else []

const BACKUP_PATH := "user://emberfall_save.bak.json"
const TEMP_PATH := "user://emberfall_save.tmp.json"

## Falls back to the backup whenever the main save comes back empty —
## whether that's because it's missing, unreadable, or corrupt JSON. A
## genuinely fresh install (no backup either) just returns the empty dict.
func _read_save() -> Dictionary:
	var data := _read_save_file(SAVE_PATH)
	if not data.is_empty():
		return data
	if not FileAccess.file_exists(BACKUP_PATH):
		return data
	push_warning("Emberfall: save principal ilegible o ausente, usando backup")
	return _read_save_file(BACKUP_PATH)

func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Emberfall: no se pudo abrir %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

## Write-temp-verify-replace: never touches the main save or its backup
## until the new data is confirmed to round-trip through the JSON parser,
## and never promotes a corrupt main save into the backup slot.
func _write_save(data: Dictionary) -> void:
	var temp_file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if temp_file == null:
		push_error("Emberfall: no se pudo escribir el guardado temporal (error %d)" % FileAccess.get_open_error())
		return
	temp_file.store_string(JSON.stringify(data))
	temp_file.close()
	if _read_save_file(TEMP_PATH).is_empty():
		push_error("Emberfall: el guardado temporal no se pudo verificar, se descarta")
		DirAccess.remove_absolute(TEMP_PATH)
		return
	if not _read_save_file(SAVE_PATH).is_empty():
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(BACKUP_PATH)
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
