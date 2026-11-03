class_name AbilityCatalog
extends RefCounted

## Single source of truth for every in-run ability: names, descriptions,
## icons and evolution recipes, shared by game_world (rules) and ui.gd
## (cards, build bar, pause). See docs/PLAN_FINALIZACION.md §2 for the design.
##
## Rules in short: 4 active slots + 4 passive slots, max level 5 each. An
## active at max level whose paired passive is owned (any level) offers its
## evolution as a golden card on the next level-up.

const MAX_LEVEL := 5
const ACTIVE_SLOTS := 4
const PASSIVE_SLOTS := 4
const EVOLUTION_PREFIX := "evo:"

## Generated icons go here as `<id>.png` (and `evo_<id>.png` for
## evolutions); until they exist the UI falls back to `fallback_icon`, then
## to a drawn placeholder.
## Locked actives and what unlocks them (lifetime stats in GameState). The
## other 6 are available from the start, and a hero's own starting active is
## always available in their runs even while still locked.
const UNLOCKS := {
	"boomerang": {"stat": "lifetime_kills", "target": 1000, "text": "Eliminá 1000 enemigos en total"},
	"slash": {"stat": "bosses_defeated", "target": 1, "text": "Derrotá a un jefe"},
	"meteor": {"stat": "best_level", "target": 20, "text": "Llegá al nivel 20 en una partida"},
	"shard": {"stat": "chests_opened", "target": 5, "text": "Abrí 5 cofres de élite"},
	"familiar": {"stat": "evolutions_done", "target": 1, "text": "Evolucioná una habilidad"},
	"aegis": {"stat": "best_time", "target": 600, "text": "Sobreviví 10 minutos en una partida"},
}

const ICON_DIR := "res://assets/habilidades/iconos"
const LEGACY_ICON_DIR := "res://assets/mejoras"
## Evolution art is named after the evolution, not the active. Missing ones
## (blizzard, familiar) fall back to the active's own icon.
const EVOLUTION_ICONS := {
	"daggers": "evo_tormenta_de_filos.png",
	"orbital": "evo_eclipse_eterno.png",
	"fire": "evo_corona_solar.png",
	"chain": "evo_tormenta_viva.png",
	"poison_bomb": "evo_plaga_abisal.png",
	"boomerang": "evo_torbellino_de_acero.png",
	"slash": "evo_guadana_del_vacio.png",
	"meteor": "evo_cataclismo.png",
	"shard": "evo_prisma_infinito.png",
	"aegis": "evo_bastion.png",
	"blizzard": "evo_invierno_perpetuo.png",
	"familiar": "evo_legion_espectral.png",
}

const ACTIVES := {
	"daggers": {
		"name": "DAGAS RÚNICAS",
		"desc": "Ráfaga de dagas hacia donde mirás",
		"fallback_icon": "proyectiles.png",
		"color": Color("2de1d0"),
		"evolution": {"passive": "haste", "name": "TORMENTA DE FILOS", "desc": "Dagas sin pausa que atraviesan a todos"},
	},
	"orbital": {
		"name": "LUNAS ORBITALES",
		"desc": "Lunas que giran a tu alrededor y dañan al contacto",
		"fallback_icon": "",
		"color": Color("9fe8ff"),
		"evolution": {"passive": "duration", "name": "ECLIPSE ETERNO", "desc": "Seis lunas más fuertes que empujan a los enemigos"},
	},
	"fire": {
		"name": "AURA ÍGNEA",
		"desc": "Quema constantemente a los enemigos cercanos",
		"fallback_icon": "dano_de_fuego.png",
		"color": Color("ff9f4a"),
		"evolution": {"passive": "vitality", "name": "CORONA SOLAR", "desc": "Aura más grande que te cura mientras quema"},
	},
	"chain": {
		"name": "CADENA ELÉCTRICA",
		"desc": "Rayo que salta entre enemigos y los electrocuta",
		"fallback_icon": "rebote_de_proyectiles.png",
		"color": Color("7ff5ea"),
		"evolution": {"passive": "amount", "name": "TORMENTA VIVA", "desc": "Rayos más seguidos que saltan sin límite"},
	},
	"poison_bomb": {
		"name": "FRASCO TÓXICO",
		"desc": "Lanza un frasco que deja un charco venenoso",
		"fallback_icon": "dano_de_veneno.png",
		"color": Color("7ddc4a"),
		"evolution": {"passive": "area", "name": "PLAGA ABISAL", "desc": "Dos frascos; los charcos persiguen a los enemigos"},
	},
	"blizzard": {
		"name": "VENTISCA",
		"desc": "Zona helada cerca tuyo que daña y ralentiza",
		"fallback_icon": "",
		"color": Color("bfe9ff"),
		"evolution": {"passive": "armor", "name": "INVIERNO PERPETUO", "desc": "La ventisca te sigue y congela por completo"},
	},
	"boomerang": {
		"name": "HACHA BUMERÁN",
		"desc": "Hacha que va y vuelve atravesando enemigos",
		"fallback_icon": "",
		"color": Color("c9d3e0"),
		"evolution": {"passive": "might", "name": "TORBELLINO DE ACERO", "desc": "Hachas en espiral que no dejan de girar"},
	},
	"slash": {
		"name": "TAJO SOMBRÍO",
		"desc": "Corte amplio a ambos lados",
		"fallback_icon": "",
		"color": Color("b07cff"),
		"evolution": {"passive": "crit", "name": "GUADAÑA DEL VACÍO", "desc": "Los golpes críticos que matan hacen explotar al enemigo"},
	},
	"meteor": {
		"name": "LLUVIA DE METEOROS",
		"desc": "Meteoros marcados en el suelo que queman al caer",
		"fallback_icon": "",
		"color": Color("ff7a3d"),
		"evolution": {"passive": "cooldown", "name": "CATACLISMO", "desc": "Además, un meteoro gigante cada 10 segundos"},
	},
	"shard": {
		"name": "ESQUIRLA ERRANTE",
		"desc": "Cristal que rebota en los bordes de la pantalla",
		"fallback_icon": "",
		"color": Color("e07cff"),
		"evolution": {"passive": "proj_speed", "name": "PRISMA INFINITO", "desc": "Al rebotar se divide en esquirlas menores"},
	},
	"familiar": {
		"name": "FAMILIAR ESPECTRAL",
		"desc": "Espíritu que te acompaña y dispara a los enemigos",
		"fallback_icon": "",
		"color": Color("8ff0d0"),
		"evolution": {"passive": "magnet", "name": "LEGIÓN ESPECTRAL", "desc": "Más familiares, disparan el doble y atraen orbes"},
	},
	"aegis": {
		"name": "ÉGIDA RÚNICA",
		"desc": "Escudo que bloquea un golpe y se recarga",
		"fallback_icon": "invencible_tras_dano.png",
		"color": Color("4fd6ff"),
		"evolution": {"passive": "regen", "name": "BASTIÓN", "desc": "Dos cargas; al romperse lanza una nova que empuja"},
	},
}

const PASSIVES := {
	"might": {"name": "FUERZA", "desc": "+10% de daño de todo", "fallback_icon": "dano.png"},
	"vitality": {"name": "VITALIDAD", "desc": "+1 corazón y te cura", "fallback_icon": "corazon_extra.png"},
	"regen": {"name": "REGENERACIÓN", "desc": "Recuperás vida con el tiempo", "fallback_icon": "corazon_extra_II.png"},
	"armor": {"name": "ARMADURA", "desc": "+8% de probabilidad de bloquear un golpe", "fallback_icon": ""},
	"haste": {"name": "CELERIDAD", "desc": "+8% de velocidad de ataque", "fallback_icon": "velocidad_de_ataque.png"},
	"cooldown": {"name": "ENFRIAMIENTO", "desc": "-8% de tiempo de reutilización", "fallback_icon": "cooldown.png"},
	"area": {"name": "ÁREA", "desc": "+10% de tamaño de las habilidades", "fallback_icon": "area.png"},
	"duration": {"name": "DURACIÓN", "desc": "+15% de duración de efectos y zonas", "fallback_icon": "duracion.png"},
	"amount": {"name": "AMPLITUD", "desc": "+1 proyectil en ataques y habilidades", "fallback_icon": "proyectiles.png"},
	"proj_speed": {"name": "VELOCIDAD DE PROYECTIL", "desc": "+15% de velocidad de proyectiles", "fallback_icon": "velocidad_de_proyectil.png"},
	"crit": {"name": "CRÍTICO", "desc": "+8% de probabilidad y +20% de daño crítico", "fallback_icon": "probabilidad_de_critico.png"},
	"magnet": {"name": "MAGNETISMO", "desc": "Recogés orbes desde más lejos", "fallback_icon": "area_recoleccion_experiencia.png"},
}

static func is_active(id: String) -> bool:
	return ACTIVES.has(id)

static func is_passive(id: String) -> bool:
	return PASSIVES.has(id)

static func is_evolution(option_id: String) -> bool:
	return option_id.begins_with(EVOLUTION_PREFIX)

static func evolution_option(active_id: String) -> String:
	return EVOLUTION_PREFIX + active_id

static func evolution_source(option_id: String) -> String:
	return option_id.trim_prefix(EVOLUTION_PREFIX)

static func _entry(id: String) -> Dictionary:
	if is_evolution(id):
		return ACTIVES.get(evolution_source(id), {}).get("evolution", {})
	if ACTIVES.has(id):
		return ACTIVES[id]
	return PASSIVES.get(id, {})

static func display_name(id: String, evolved: bool = false) -> String:
	if evolved and ACTIVES.has(id):
		return str(ACTIVES[id]["evolution"]["name"])
	return str(_entry(id).get("name", id))

static func description(id: String) -> String:
	return str(_entry(id).get("desc", ""))

static func color(id: String) -> Color:
	var base := evolution_source(id) if is_evolution(id) else id
	return ACTIVES.get(base, {}).get("color", Color("8a7d9c"))

## Icon for a card/build slot, or null when nothing exists yet (the caller
## then draws a placeholder). Evolutions try their own art first, then
## their source active's.
static func icon(id: String, evolved: bool = false) -> Texture2D:
	var base := evolution_source(id) if is_evolution(id) else id
	var candidates: Array[String] = []
	if is_evolution(id) or evolved:
		if EVOLUTION_ICONS.has(base):
			candidates.append("%s/%s" % [ICON_DIR, EVOLUTION_ICONS[base]])
		candidates.append("%s/evo_%s.png" % [ICON_DIR, base])
	candidates.append("%s/%s.png" % [ICON_DIR, base])
	var fallback := str(_fallback_entry(base).get("fallback_icon", ""))
	if fallback != "":
		candidates.append("%s/%s" % [LEGACY_ICON_DIR, fallback])
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

static func _fallback_entry(id: String) -> Dictionary:
	return ACTIVES[id] if ACTIVES.has(id) else PASSIVES.get(id, {})
