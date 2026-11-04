class_name EquipmentCatalog
extends RefCounted

## Equipment rules (docs/PLAN_EQUIPAMIENTO_Y_ARMAS.md, part B): every item
## has a fixed main stat for its slot, random secondary stats by rarity and
## a level from 1 to 10 that scales all of them. Items are plain
## dictionaries so they save as JSON:
##   {uid, id, name, equipment_type, rarity, level,
##    main: {stat, base}, subs: [{stat, base}], unique: ""}
## `base` is the value at level 1; value_at() applies the level.

const TYPES := ["weapon", "armor", "helmet", "amulet", "ring", "boots"]
const TYPE_LABELS := {
	"weapon": "ARMA", "armor": "ARMADURA", "helmet": "CASCO",
	"amulet": "AMULETO", "ring": "ANILLO", "boots": "BOTAS",
}

const RARITIES := ["common", "rare", "epic", "legendary"]
const RARITY_LABELS := {"common": "COMÚN", "rare": "RARO", "epic": "ÉPICO", "legendary": "LEGENDARIO"}
const RARITY_COLORS := {
	"common": Color("9b8eaa"), "rare": Color("6be0ff"),
	"epic": Color("c58bff"), "legendary": Color("ffb84d"),
}
const SUB_COUNT := {"common": 0, "rare": 1, "epic": 2, "legendary": 2}

const MAX_LEVEL := 10
## Each level adds this share of the level-1 value (level 10 = x2.35).
const LEVEL_GROWTH := 0.15

const MAIN_STAT := {
	"weapon": "damage", "armor": "health", "helmet": "block",
	"amulet": "cooldown", "ring": "crit", "boots": "speed",
}
const SUB_STATS := ["area", "magnet", "gold", "xp", "regen", "proj_speed"]

## Level-1 value per rarity (common, rare, epic, legendary). `pct` stats are
## percentages; damage is flat attack, health is half-hearts, regen is
## half-hearts per minute.
const STATS := {
	"damage": {"label": "Daño", "values": [3, 6, 10, 15], "pct": false},
	"health": {"label": "Vida", "values": [1, 2, 3, 4], "pct": false},
	"block": {"label": "Bloqueo", "values": [2, 3, 5, 7], "pct": true},
	"cooldown": {"label": "Enfriamiento", "values": [3, 5, 8, 10], "pct": true},
	"crit": {"label": "Crítico", "values": [3, 5, 8, 10], "pct": true},
	"speed": {"label": "Velocidad", "values": [4, 7, 10, 14], "pct": true},
	"area": {"label": "Área", "values": [4, 6, 8, 10], "pct": true},
	"magnet": {"label": "Imán", "values": [8, 12, 16, 20], "pct": true},
	"gold": {"label": "Oro", "values": [5, 8, 12, 15], "pct": true},
	"xp": {"label": "Experiencia", "values": [4, 6, 8, 10], "pct": true},
	"regen": {"label": "Regeneración", "values": [1, 1.5, 2, 3], "pct": false},
	"proj_speed": {"label": "Vel. de proyectil", "values": [5, 8, 12, 15], "pct": true},
}

## One recipe per slot and rarity (ids kept from the old pool so saves map
## straight across).
const RECIPES := [
	{"id": "blade_focus", "name": "FILO ENFOCADO", "equipment_type": "weapon", "rarity": "common"},
	{"id": "sharp_claw", "name": "GARRA AFILADA", "equipment_type": "weapon", "rarity": "rare"},
	{"id": "chaos_fang", "name": "COLMILLO DEL CAOS", "equipment_type": "weapon", "rarity": "epic"},
	{"id": "ember_fury", "name": "FURIA DE EMBERFALL", "equipment_type": "weapon", "rarity": "legendary"},
	{"id": "iron_will", "name": "VOLUNTAD DE HIERRO", "equipment_type": "armor", "rarity": "common"},
	{"id": "oak_heart", "name": "CORAZÓN DE ROBLE", "equipment_type": "armor", "rarity": "rare"},
	{"id": "unbreakable_soul", "name": "ALMA INQUEBRANTABLE", "equipment_type": "armor", "rarity": "epic"},
	{"id": "abyss_aegis", "name": "ÉGIDA DEL ABISMO", "equipment_type": "armor", "rarity": "legendary"},
	{"id": "iron_helm", "name": "YELMO DE HIERRO", "equipment_type": "helmet", "rarity": "common"},
	{"id": "warded_helm", "name": "YELMO PROTEGIDO", "equipment_type": "helmet", "rarity": "rare"},
	{"id": "dragonbone_helm", "name": "YELMO DE DRAGÓN", "equipment_type": "helmet", "rarity": "epic"},
	{"id": "eclipse_crown", "name": "CORONA DEL ECLIPSE", "equipment_type": "helmet", "rarity": "legendary"},
	{"id": "ember_amulet", "name": "AMULETO DE BRASA", "equipment_type": "amulet", "rarity": "common"},
	{"id": "void_amulet", "name": "AMULETO DEL VACÍO", "equipment_type": "amulet", "rarity": "rare"},
	{"id": "soul_amulet", "name": "AMULETO DE ALMAS", "equipment_type": "amulet", "rarity": "epic"},
	{"id": "forge_heart", "name": "CORAZÓN DE LA FORJA", "equipment_type": "amulet", "rarity": "legendary"},
	{"id": "swift_ring", "name": "ANILLO VELOZ", "equipment_type": "ring", "rarity": "common"},
	{"id": "storm_ring", "name": "ANILLO TORMENTA", "equipment_type": "ring", "rarity": "rare"},
	{"id": "gale_ring", "name": "ANILLO DEL VENDAVAL", "equipment_type": "ring", "rarity": "epic"},
	{"id": "void_seal", "name": "SELLO DEL VACÍO", "equipment_type": "ring", "rarity": "legendary"},
	{"id": "swift_boots", "name": "BOTAS VELOCES", "equipment_type": "boots", "rarity": "common"},
	{"id": "wind_wings", "name": "ALAS DE VIENTO", "equipment_type": "boots", "rarity": "rare"},
	{"id": "ghost_step", "name": "PASO FANTASMA", "equipment_type": "boots", "rarity": "epic"},
	{"id": "comet_stride", "name": "PASOS DEL COMETA", "equipment_type": "boots", "rarity": "legendary"},
]

## Upgrade price from level L to L+1: gold and Esencia grow with the level
## and the rarity. Salvaging gives a base amount by rarity plus half of the
## Esencia spent upgrading the item.
const RARITY_COST_MULT := [1.0, 1.5, 2.5, 4.0]
const UPGRADE_GOLD := 40
const UPGRADE_ESSENCE := 4
const SALVAGE_ESSENCE := [10, 25, 60, 150]

## Legendary effects. They are rolled and shown now; the effects
## themselves arrive with the sets (phase 8 of the plan).
const UNIQUES := {
	"heart_drop": "Al matar, 3% de chance de soltar un corazón",
	"empowered": "Cada 10 s, la próxima habilidad hace el doble de daño",
	"repel_nova": "Al recibir daño, una nova empuja a los enemigos",
}

static func recipe(recipe_id: String) -> Dictionary:
	for entry in RECIPES:
		if entry["id"] == recipe_id:
			return entry
	return {}

static func recipe_for(equipment_type: String, rarity: String) -> Dictionary:
	for entry in RECIPES:
		if entry["equipment_type"] == equipment_type and entry["rarity"] == rarity:
			return entry
	return {}

static func rarity_index(rarity: String) -> int:
	return maxi(0, RARITIES.find(rarity))

static func base_value(stat: String, rarity: String) -> float:
	var values: Array = STATS.get(stat, {}).get("values", [0, 0, 0, 0])
	return float(values[rarity_index(rarity)])

static func value_at(base: float, level: int) -> float:
	return base * (1.0 + LEVEL_GROWTH * float(clampi(level, 1, MAX_LEVEL) - 1))

## A fresh level-1 item from a recipe, with its secondary stats rolled.
static func make_item(recipe_id: String, uid: String) -> Dictionary:
	var entry := recipe(recipe_id)
	if entry.is_empty():
		return {}
	var rarity := str(entry["rarity"])
	var equipment_type := str(entry["equipment_type"])
	var main_stat := str(MAIN_STAT[equipment_type])
	var pool: Array = SUB_STATS.duplicate()
	pool.shuffle()
	var subs: Array = []
	for i in int(SUB_COUNT.get(rarity, 0)):
		subs.append({"stat": pool[i], "base": base_value(str(pool[i]), rarity)})
	var unique := ""
	if rarity == "legendary":
		unique = str(UNIQUES.keys().pick_random())
	return {
		"uid": uid, "id": recipe_id, "name": entry["name"],
		"equipment_type": equipment_type, "rarity": rarity, "level": 1,
		"main": {"stat": main_stat, "base": base_value(main_stat, rarity)},
		"subs": subs, "unique": unique,
	}

## Random recipe of one of `rarities` (any slot).
static func random_recipe(rarities: Array) -> String:
	var options := RECIPES.filter(func(e): return e["rarity"] in rarities)
	if options.is_empty():
		return str(RECIPES[0]["id"])
	return str(options.pick_random()["id"])

## True for items saved before this system (single "stat"/"value").
static func is_legacy(item: Dictionary) -> bool:
	return not item.has("main")

## Old item -> new item: same uid, recipe and rarity, level 1, the slot's
## new main stat and freshly rolled secondary stats.
static func convert_legacy(item: Dictionary) -> Dictionary:
	var recipe_id := str(item.get("id", ""))
	if recipe(recipe_id).is_empty():
		var rarity := str(item.get("rarity", "common"))
		recipe_id = str(recipe_for(str(item.get("equipment_type", "weapon")), rarity if rarity in RARITIES else "common").get("id", "blade_focus"))
	return make_item(recipe_id, str(item.get("uid", recipe_id)))

## Every stat on an item at its current level, as {stat: value}.
static func item_stats(item: Dictionary) -> Dictionary:
	var level := int(item.get("level", 1))
	var result := {}
	var main: Dictionary = item.get("main", {})
	if not main.is_empty():
		result[str(main["stat"])] = value_at(float(main["base"]), level)
	for sub in item.get("subs", []):
		var stat := str(sub["stat"])
		result[stat] = float(result.get(stat, 0.0)) + value_at(float(sub["base"]), level)
	return result

## "+12% Crítico", "+3 Vida".
static func stat_text(stat: String, value: float) -> String:
	var label := stat_label(stat)
	if stat == "regen":
		return "%s %s/min" % [value_text(stat, value), label]
	return "%s %s" % [value_text(stat, value), label]

static func stat_label(stat: String) -> String:
	return str(STATS.get(stat, {}).get("label", stat))

## Just the number: "+12%", "+3", "+1.5" (regen keeps one decimal).
static func value_text(stat: String, value: float) -> String:
	var shown := snappedf(value, 0.1) if stat == "regen" else roundf(value)
	var number := str(int(shown)) if is_equal_approx(shown, roundf(shown)) else "%.1f" % shown
	if bool(STATS.get(stat, {}).get("pct", false)):
		return "+%s%%" % number
	return "+" + number

## Short value for a slot tile: the main stat at its level.
static func main_short(item: Dictionary) -> String:
	var main: Dictionary = item.get("main", {})
	if main.is_empty():
		return ""
	var value := value_at(float(main["base"]), int(item.get("level", 1)))
	var shown := int(round(value))
	return ("+%d%%" if bool(STATS.get(str(main["stat"]), {}).get("pct", false)) else "+%d") % shown

## {gold, essence} to raise `item` one level; empty at MAX_LEVEL.
static func upgrade_cost(item: Dictionary) -> Dictionary:
	var level := int(item.get("level", 1))
	if level >= MAX_LEVEL:
		return {}
	var mult: float = RARITY_COST_MULT[rarity_index(str(item.get("rarity", "common")))]
	return {
		"gold": int(round(UPGRADE_GOLD * level * mult)),
		"essence": int(round(UPGRADE_ESSENCE * level * mult)),
	}

## Esencia returned when salvaging `item`.
static func salvage_value(item: Dictionary) -> int:
	var rarity := str(item.get("rarity", "common"))
	var mult: float = RARITY_COST_MULT[rarity_index(rarity)]
	var spent := 0
	for l in range(1, int(item.get("level", 1))):
		spent += int(round(UPGRADE_ESSENCE * l * mult))
	return int(SALVAGE_ESSENCE[rarity_index(rarity)]) + spent / 2

## Value of the item's main stat at its level (to compare items).
static func main_value(item: Dictionary) -> float:
	var main: Dictionary = item.get("main", {})
	if main.is_empty():
		return 0.0
	return value_at(float(main["base"]), int(item.get("level", 1)))

## Signed difference for the compare view: "+3", "-2%", "+0.5/min".
static func delta_text(stat: String, delta: float) -> String:
	var info: Dictionary = STATS.get(stat, {})
	var shown := snappedf(delta, 0.1) if stat == "regen" else roundf(delta)
	var number := str(int(absf(shown))) if is_equal_approx(shown, roundf(shown)) else "%.1f" % absf(shown)
	var sign := "+" if shown >= 0.0 else "-"
	if bool(info.get("pct", false)):
		return "%s%s%%" % [sign, number]
	return sign + number
