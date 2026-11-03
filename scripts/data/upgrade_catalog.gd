extends RefCounted
class_name UpgradeCatalog

## Permanent upgrades bought with gold between runs (Vampire Survivors'
## "PowerUps"). The order here is the order of the grid. "damage", "health"
## and "speed" keep their old ids and save keys so existing progress carries
## over. Effects are read in game_world.gd / player.gd via
## GameState.get_upgrade_level(id).
##
## Icons live in assets/cuadros_habilidades_emberfall/; a missing one falls
## back to a tile with the initial.

const ICON_DIR := "res://assets/mejoras/"

const UPGRADES := [
	{"id": "damage", "name": "Poder", "desc": "+2 de daño al ataque básico y +3% de daño total por nivel.", "icon": "dano.png", "max": 10, "base": 40, "step": 35},
	{"id": "health", "name": "Vitalidad", "desc": "+½ corazón de vida máxima por nivel.", "icon": "corazon_extra.png", "max": 10, "base": 40, "step": 35},
	{"id": "speed", "name": "Movilidad", "desc": "+5% de velocidad de movimiento por nivel.", "icon": "velocidad_de_movimiento.png", "max": 10, "base": 40, "step": 35},
	{"id": "armor", "name": "Armadura", "desc": "+3% de probabilidad de bloquear un golpe por nivel.", "icon": "mejora_armadura.png", "max": 3, "base": 120, "step": 120},
	{"id": "regen", "name": "Regeneración", "desc": "Recuperás vida poco a poco (+½ corazón cada 30 s por nivel).", "icon": "corazon_extra_II.png", "max": 3, "base": 150, "step": 150},
	{"id": "haste", "name": "Celeridad", "desc": "-4% de tiempo entre ataques básicos por nivel.", "icon": "velocidad_de_ataque.png", "max": 3, "base": 100, "step": 100},
	{"id": "area", "name": "Amplitud", "desc": "+5% de área de las habilidades por nivel.", "icon": "area.png", "max": 3, "base": 100, "step": 100},
	{"id": "cooldown", "name": "Enfriamiento", "desc": "-3% de enfriamiento de las habilidades por nivel.", "icon": "cooldown.png", "max": 3, "base": 150, "step": 150},
	{"id": "duration", "name": "Duración", "desc": "+8% de duración de efectos y estados por nivel.", "icon": "duracion.png", "max": 3, "base": 100, "step": 100},
	{"id": "amount", "name": "Cantidad", "desc": "+1 proyectil o efecto en las habilidades que disparan varios.", "icon": "proyectiles.png", "max": 1, "base": 600, "step": 0},
	{"id": "proj_speed", "name": "Velocidad de proyectil", "desc": "+8% de velocidad de proyectiles por nivel.", "icon": "velocidad_de_proyectil.png", "max": 3, "base": 80, "step": 80},
	{"id": "crit", "name": "Crítico", "desc": "+3% de probabilidad de crítico por nivel.", "icon": "probabilidad_de_critico.png", "max": 3, "base": 120, "step": 120},
	{"id": "magnet", "name": "Imán", "desc": "+20 de radio para recoger experiencia y oro por nivel.", "icon": "area_recoleccion_experiencia.png", "max": 3, "base": 60, "step": 60},
	{"id": "growth", "name": "Crecimiento", "desc": "+4% de experiencia ganada por nivel.", "icon": "experiencia_ganada.png", "max": 5, "base": 100, "step": 80},
	{"id": "greed", "name": "Codicia", "desc": "+10% de oro recogido por nivel.", "icon": "probabilidad_oro.png", "max": 5, "base": 80, "step": 60},
	{"id": "luck", "name": "Suerte", "desc": "+25% de probabilidad de pociones, imanes y bombas por nivel.", "icon": "mejora_suerte.png", "max": 3, "base": 120, "step": 120},
	{"id": "boss_damage", "name": "Cazajefes", "desc": "+10% de daño a jefes y élites por nivel.", "icon": "dano_a_jefes.png", "max": 3, "base": 150, "step": 150},
	{"id": "invuln", "name": "Resguardo", "desc": "+0,15 s de invencibilidad después de recibir daño por nivel.", "icon": "invencible_tras_dano.png", "max": 3, "base": 120, "step": 120},
	{"id": "reroll", "name": "Cambiar", "desc": "+1 uso de Cambiar por partida por nivel.", "icon": "rerolls.png", "max": 3, "base": 150, "step": 150},
	{"id": "banish", "name": "Descartar", "desc": "+1 uso de Descartar por partida por nivel.", "icon": "mejora_bloqueada.png", "max": 3, "base": 150, "step": 150},
	{"id": "revival", "name": "Revivir", "desc": "Una vez por partida, al caer revivís con media vida.", "icon": "revivir.png", "max": 1, "base": 1000, "step": 0},
]

## The 3 upgrades that existed before the grid; GameState keeps them in
## their own variables and save keys.
const LEGACY_IDS := ["damage", "health", "speed"]

static func entry(id: String) -> Dictionary:
	for upgrade in UPGRADES:
		if upgrade["id"] == id:
			return upgrade
	return {}

static func has(id: String) -> bool:
	return not entry(id).is_empty()

static func max_level(id: String) -> int:
	return int(entry(id).get("max", 0))

static func cost(id: String, current_level: int) -> int:
	var upgrade := entry(id)
	return int(upgrade.get("base", 0)) + int(upgrade.get("step", 0)) * current_level

static func icon(id: String) -> Texture2D:
	var path := ICON_DIR + str(entry(id).get("icon", ""))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
