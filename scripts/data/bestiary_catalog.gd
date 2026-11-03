class_name BestiaryCatalog
extends RefCounted

## Bestiary entries for the Códex, keyed like game_world records kills:
## regular enemies by archetype, élites and mini-bosses apart, and each boss
## by variant. An entry is "discovered" once it has at least one kill.

const ENEMY_TEXTURE := "res://assets/characters/enemy.png"
const BOSS_DIR := "res://assets/Emberfall_Jefes_Simplificados/"

const ENTRIES := [
	{"key": "chaser", "name": "ACECHADOR", "desc": "Te persigue sin descanso. El enemigo más común.", "archetype": 0},
	{"key": "fast", "name": "CORREDOR", "desc": "Rápido y frágil: cuesta escaparle.", "archetype": 1},
	{"key": "tank", "name": "BRUTO", "desc": "Lento y resistente; casi no retrocede al golpearlo.", "archetype": 2},
	{"key": "shooter", "name": "LANZADOR", "desc": "Mantiene la distancia y dispara proyectiles.", "archetype": 3},
	{"key": "charger", "name": "EMBESTIDOR", "desc": "Se detiene, apunta y embiste en línea recta.", "archetype": 4},
	{"key": "elite", "name": "ÉLITE", "desc": "Aura dorada y mucha vida. Suelta un cofre.", "archetype": 0, "art": "elite"},
	{"key": "miniboss", "name": "MINI-JEFE", "desc": "Aura violeta, aparece a los 6 minutos. Suelta un cofre épico.", "archetype": 2, "art": "elite", "tint": Color(0.8, 0.6, 1.0)},
	{"key": "boss_0", "name": "COLOSO RÚNICO", "desc": "Embiste y golpea el suelo con ondas de choque.", "boss_folder": "01_coloso_runico"},
	{"key": "boss_1", "name": "GUARDIÁN HUECO", "desc": "Barre a su alrededor y lanza abanicos de runas.", "boss_folder": "02_guardian_hueco"},
	{"key": "boss_2", "name": "MATRIARCA DE CENIZA", "desc": "Conos de fuego y zonas rúnicas que estallan.", "boss_folder": "03_matriarca_ceniza"},
]

const ARCHETYPE_KEYS := ["chaser", "fast", "tank", "shooter", "charger"]

static func has(key: String) -> bool:
	for entry in ENTRIES:
		if entry["key"] == key:
			return true
	return false

## Key for a killed enemy, matching ENTRIES.
static func key_for(enemy: EmberfallEnemy) -> String:
	if enemy is EmberfallBoss:
		return "boss_%d" % (enemy as EmberfallBoss).variant
	if enemy.elite_tier >= 2:
		return "miniboss"
	if enemy.elite_tier == 1:
		return "elite"
	return ARCHETYPE_KEYS[clampi(enemy.archetype, 0, ARCHETYPE_KEYS.size() - 1)]

static func texture(entry: Dictionary) -> Texture2D:
	if entry.has("boss_folder"):
		var path := "%s%s/idle.png" % [BOSS_DIR, entry["boss_folder"]]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	# Regular enemies: their own walk art (chapter 1 pose).
	var folder := str(entry.get("art", entry["key"]))
	var frames := EmberfallEnemy.walk_frames(folder, 1)
	if not frames.is_empty():
		return frames[0]
	return load(ENEMY_TEXTURE) as Texture2D

## True when the entry shows its own art (no archetype tint needed).
static func has_own_art(entry: Dictionary) -> bool:
	return not entry.has("boss_folder") and not EmberfallEnemy.walk_frames(str(entry.get("art", entry["key"])), 1).is_empty()

static func tint(entry: Dictionary) -> Color:
	if entry.has("tint"):
		return entry["tint"]
	if has_own_art(entry):
		return Color.WHITE
	if entry.has("archetype"):
		return EmberfallEnemy.ARCHETYPE_TINTS.get(int(entry["archetype"]), Color.WHITE)
	return Color.WHITE
