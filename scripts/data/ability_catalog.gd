class_name AbilityCatalog
extends RefCounted

## Single source of truth for every in-run ability: names, descriptions,
## icons and evolution recipes, shared by game_world (rules) and ui.gd
## (cards, build bar, pause). See docs/PLAN_FINALIZACION.md §2 for the design.
##
## Rules in short: 6 active slots + 6 passive slots, max level 5 each. An
## active at max level whose paired passive is owned (any level) offers its
## evolution as a golden card on the next level-up.

const MAX_LEVEL := 5
const ACTIVE_SLOTS := 6
const PASSIVE_SLOTS := 6
const EVOLUTION_PREFIX := "evo:"

## Generated icons go here as `<id>.png` (and `evo_<id>.png` for
## evolutions); until they exist the UI falls back to `fallback_icon`, then
## to a drawn placeholder.
## Locked actives and what unlocks them (lifetime stats in GameState). The
## other 6 are available from the start.
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
		"fallback_icon": "",
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
		"fallback_icon": "",
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
	"armor": {"name": "ARMADURA", "desc": "+8% de probabilidad de bloquear un golpe", "fallback_icon": "mejora_armadura.png"},
	"haste": {"name": "CELERIDAD", "desc": "+8% de velocidad de ataque", "fallback_icon": "velocidad_de_ataque.png"},
	"cooldown": {"name": "ENFRIAMIENTO", "desc": "-8% de tiempo de reutilización", "fallback_icon": "cooldown.png"},
	"area": {"name": "ÁREA", "desc": "+10% de tamaño de las habilidades", "fallback_icon": "area.png"},
	"duration": {"name": "DURACIÓN", "desc": "+15% de duración de efectos y zonas", "fallback_icon": "duracion.png"},
	"amount": {"name": "AMPLITUD", "desc": "+1 proyectil en ataques y habilidades", "fallback_icon": "proyectiles.png"},
	"proj_speed": {"name": "VELOCIDAD DE PROYECTIL", "desc": "+15% de velocidad de proyectiles", "fallback_icon": "velocidad_de_proyectil.png"},
	"crit": {"name": "CRÍTICO", "desc": "+8% de probabilidad y +20% de daño crítico", "fallback_icon": "probabilidad_de_critico.png"},
	"magnet": {"name": "MAGNETISMO", "desc": "Recogés orbes desde más lejos", "fallback_icon": "area_recoleccion_experiencia.png"},
}

## Hero weapons: each hero's basic attack is an active with id
## "arma:<hero id>", levels 1-5, sharing the active slots. Name, colour and
## art come from the hero's CharacterData. Like the actives, a level-5
## weapon plus its paired passive evolves (WEAPON_EVOLUTIONS).
const WEAPON_PREFIX := "arma:"
const PROJECTILE_DIR := "res://assets/habilidades/proyectiles"
## What each weapon level adds on top of the previous one.
const WEAPON_LEVEL_TEXT := {
	1: "Ataque básico del héroe",
	2: "+30% de daño",
	3: "+1 proyectil",
	4: "Atraviesa 1 enemigo más y +20% de alcance",
	5: "+30% de daño y ataca 20% más rápido",
}

## Each hero's weapon unlocks for every hero once its challenge is met
## playing that hero. `stat` is a per-hero stat in GameState.hero_stats:
## the ones starting with "best_" keep the best run, the rest add up.
const WEAPON_CHALLENGES := {
	"variante_01": {"stat": "best_time", "target": 300, "text": "Sobreviví 5 minutos"},
	"variante_02": {"stat": "frozen", "target": 300, "text": "Congelá 300 enemigos"},
	"variante_03": {"stat": "poison_kills", "target": 300, "text": "Eliminá 300 enemigos envenenados"},
	"variante_04": {"stat": "best_level", "target": 15, "text": "Llegá al nivel 15"},
	"variante_05": {"stat": "kills", "target": 500, "text": "Eliminá 500 enemigos"},
	"variante_06": {"stat": "best_time", "target": 480, "text": "Sobreviví 8 minutos"},
	"variante_07": {"stat": "elites", "target": 3, "text": "Eliminá 3 élites"},
	"variante_08": {"stat": "bosses", "target": 1, "text": "Derrotá a un jefe"},
	"variante_09": {"stat": "kills", "target": 800, "text": "Eliminá 800 enemigos"},
	"variante_10": {"stat": "best_clean_time", "target": 600, "text": "Sobreviví 10 minutos sin perder más de 3 corazones"},
	"variante_11": {"stat": "best_level", "target": 20, "text": "Llegá al nivel 20"},
	"variante_12": {"stat": "evolutions", "target": 1, "text": "Evolucioná una habilidad"},
	"variante_13": {"stat": "kills", "target": 1000, "text": "Eliminá 1000 enemigos"},
	"variante_14": {"stat": "bosses", "target": 2, "text": "Derrotá a 2 jefes"},
}

## Golden weapons: +WEAPON_EVO_DAMAGE damage and a trait applied by
## game_world.gd (_weapon_evo_hit / _fire_weapon):
##   blast   - the hit explodes around the enemy (with the hero's status)
##   pool    - the hit leaves a poison pool
##   split   - the shot splits into 2 shards on hit
##   volley  - +2 shots per attack
##   chain   - the hit jumps to 2 more enemies
##   leech   - hits may heal half a heart
##   quake   - every 3rd attack hits everything around the hero
##   pierce  - shots go through every enemy
##   execute - hits finish off enemies under 25% life (not bosses)
##   meteor  - every 3rd attack drops a meteor on the target
const WEAPON_EVO_DAMAGE := 1.3
const WEAPON_EVOLUTIONS := {
	"variante_01": {"passive": "area", "name": "FÉNIX", "trait": "blast", "desc": "Los disparos estallan y queman alrededor"},
	"variante_02": {"passive": "duration", "name": "CERO ABSOLUTO", "trait": "blast", "desc": "Los disparos estallan y congelan alrededor"},
	"variante_03": {"passive": "cooldown", "name": "PESTE NEGRA", "trait": "pool", "desc": "Cada disparo deja un charco de veneno"},
	"variante_04": {"passive": "amount", "name": "LUNA ROTA", "trait": "split", "desc": "Cada disparo se parte en dos esquirlas"},
	"variante_05": {"passive": "haste", "name": "LLUVIA DE FLECHAS", "trait": "volley", "desc": "Dispara 2 flechas más por ataque"},
	"variante_06": {"passive": "magnet", "name": "SELLO RÚNICO", "trait": "blast", "desc": "Los disparos estallan en runas"},
	"variante_07": {"passive": "vitality", "name": "SEGADOR CARMESÍ", "trait": "leech", "desc": "Los golpes pueden curarte medio corazón"},
	"variante_08": {"passive": "armor", "name": "FALLA SÍSMICA", "trait": "quake", "desc": "Cada 3 ataques, golpea todo alrededor"},
	"variante_09": {"passive": "proj_speed", "name": "HACHA TORMENTA", "trait": "pierce", "desc": "El hacha atraviesa a todos los enemigos"},
	"variante_10": {"passive": "crit", "name": "ESTOCADA LETAL", "trait": "execute", "desc": "Remata enemigos con menos de 25% de vida"},
	"variante_11": {"passive": "might", "name": "OBÚS ÍGNEO", "trait": "meteor", "desc": "Cada 3 ataques cae un meteoro"},
	"variante_12": {"passive": "regen", "name": "TORRENTE ARCANO", "trait": "chain", "desc": "Los disparos saltan a 2 enemigos más"},
	"variante_13": {"passive": "haste", "name": "PUÑO DEL TRUENO", "trait": "chain", "desc": "Los golpes lanzan rayos a 2 enemigos"},
	"variante_14": {"passive": "area", "name": "VENDAVAL DE ACERO", "trait": "quake", "desc": "Cada 3 ataques, cortes en cruz alrededor"},
}

## Weapon art in ICON_DIR (docs/PROMPTS_ARMAS.md): [normal, golden]. While
## a file is missing the hero's projectile sprite stands in.
const WEAPON_ICONS := {
	"variante_01": ["arma_disparo_de_fuego", "evo_fenix"],
	"variante_02": ["arma_disparo_de_hielo", "evo_cero_absoluto"],
	"variante_03": ["arma_disparo_de_veneno", "evo_peste_negra"],
	"variante_04": ["arma_disparo_lunar", "evo_luna_rota"],
	"variante_05": ["arma_flecha", "evo_lluvia_de_flechas"],
	"variante_06": ["arma_disparo_runico", "evo_sello_runico"],
	"variante_07": ["arma_tajo_en_u", "evo_segador_carmesi"],
	"variante_08": ["arma_grieta_de_impacto", "evo_falla_sismica"],
	"variante_09": ["arma_hacha_arrojadiza", "evo_hacha_tormenta"],
	"variante_10": ["arma_estocada", "evo_estocada_letal"],
	"variante_11": ["arma_bala_compacta", "evo_obus_igneo"],
	"variante_12": ["arma_disparo_magico", "evo_torrente_arcano"],
	"variante_13": ["arma_onda_de_puno", "evo_puno_del_trueno"],
	"variante_14": ["arma_corte_en_x", "evo_vendaval_de_acero"],
}

## Evolution data of an active or weapon ({passive, name, desc, ...}), or {}.
static func evolution_info(id: String) -> Dictionary:
	if is_weapon(id):
		return WEAPON_EVOLUTIONS.get(weapon_hero_id(id), {})
	return ACTIVES.get(id, {}).get("evolution", {})

## The passive that evolves `id` together with it ("" when none).
static func evolution_partner(id: String) -> String:
	return str(evolution_info(id).get("passive", ""))

static func weapon_trait(id: String) -> String:
	return str(evolution_info(id).get("trait", ""))

static func weapon_challenge(hero_id: String) -> Dictionary:
	return WEAPON_CHALLENGES.get(hero_id, {})

static func weapon_hero_id(id: String) -> String:
	return id.trim_prefix(WEAPON_PREFIX)

static func is_weapon(id: String) -> bool:
	return id.begins_with(WEAPON_PREFIX)

static func weapon_id(hero_id: StringName) -> String:
	return WEAPON_PREFIX + str(hero_id)

## Not through GameState: GameState itself depends on this catalog.
static func weapon_hero(id: String) -> CharacterData:
	var path := "res://resources/characters/%s.tres" % id.trim_prefix(WEAPON_PREFIX)
	return load(path) as CharacterData if ResourceLoader.exists(path) else null

## Totals for a weapon at `level`: damage and range multipliers, extra
## shots, extra enemies pierced and the attack-interval multiplier.
static func weapon_stats(level: int) -> Dictionary:
	var damage := 1.0
	if level >= 2:
		damage += 0.3
	if level >= 5:
		damage += 0.3
	return {
		"damage": damage,
		"shots": 1 if level >= 3 else 0,
		"pierce": 1 if level >= 4 else 0,
		"range": 1.2 if level >= 4 else 1.0,
		"interval": 0.8 if level >= 5 else 1.0,
	}

static func weapon_level_text(level: int) -> String:
	return str(WEAPON_LEVEL_TEXT.get(level, ""))

## Actives and weapons both take an active slot.
static func takes_active_slot(id: String) -> bool:
	return ACTIVES.has(id) or is_weapon(id)

static func has_evolution(id: String) -> bool:
	return not evolution_info(id).is_empty()

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
		return evolution_info(evolution_source(id))
	if ACTIVES.has(id):
		return ACTIVES[id]
	return PASSIVES.get(id, {})

static func display_name(id: String, evolved: bool = false) -> String:
	if is_weapon(id):
		if evolved and has_evolution(id):
			return str(evolution_info(id)["name"])
		var hero := weapon_hero(id)
		return hero.attack_name.to_upper() if hero != null else "ARMA"
	if is_evolution(id):
		return display_name(evolution_source(id), true)
	if evolved and ACTIVES.has(id):
		return str(ACTIVES[id]["evolution"]["name"])
	return str(_entry(id).get("name", id))

static func description(id: String) -> String:
	if is_weapon(id):
		var hero := weapon_hero(id)
		return "Ataque básico de %s" % hero.display_name.capitalize() if hero != null else ""
	return str(_entry(id).get("desc", ""))

static func color(id: String) -> Color:
	if is_evolution(id) and is_weapon(evolution_source(id)):
		return color(evolution_source(id))
	if is_weapon(id):
		var hero := weapon_hero(id)
		return hero.attack_color if hero != null else Color("8a7d9c")
	var base := evolution_source(id) if is_evolution(id) else id
	return ACTIVES.get(base, {}).get("color", Color("8a7d9c"))

## Icon for a card/build slot, or null when nothing exists yet (the caller
## then draws a placeholder). Evolutions try their own art first, then
## their source active's.
static func icon(id: String, evolved: bool = false) -> Texture2D:
	if is_evolution(id) and is_weapon(evolution_source(id)):
		return _weapon_icon(evolution_source(id), true)
	if is_weapon(id):
		return _weapon_icon(id, evolved)
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
			var texture := load(path) as Texture2D
			if ACTIVES.has(base):
				return _badge(texture, path, color(base), is_evolution(id) or evolved)
			return texture
	return null

## Actives and evolutions are shown on a round badge: dark disc, rim in the
## ability's colour (gold for evolutions). The art itself has no frame.
## Built once per icon and cached.
const BADGE_SIZE := 256
const GOLD_RIM := Color("f2c25a")
static var _badge_cache := {}

static func _badge(texture: Texture2D, key: String, tint: Color, evolved: bool, trim: bool = false) -> Texture2D:
	var cache_key := "%s|%s" % [key, evolved]
	if _badge_cache.has(cache_key):
		return _badge_cache[cache_key]
	var art := texture.get_image()
	if art == null:
		return texture
	if art.is_compressed():
		art.decompress()
	art.convert(Image.FORMAT_RGBA8)
	var n := BADGE_SIZE
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	var r := n / 2.0 - 2.0
	var rim_w := 12.0 if evolved else 8.0
	var rim := GOLD_RIM if evolved else tint
	var disc_center := Color("1d1530")
	var disc_edge := Color("0c0916")
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var cover := clampf(r - d + 0.5, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var col := disc_center.lerp(disc_edge, clampf(d / r, 0.0, 1.0))
			# Soft inner glow in the ability colour just inside the rim.
			var glow := clampf(1.0 - (r - rim_w - d) / 26.0, 0.0, 1.0)
			col = col.lerp(tint.darkened(0.35), glow * 0.45)
			if d > r - rim_w:
				col = rim
				if evolved and d < r - rim_w + 3.0:
					col = tint
			elif d > r - rim_w - 2.0:
				col = Color("07060d")
			img.set_pixel(x, y, Color(col, cover))
	var inner := (r - rim_w) * 2.0 * 0.82
	# Keep the art's proportions (projectile frames are often wide).
	var used := art.get_used_rect()
	if trim and used.size.x > 0 and used.size.y > 0 and used.size != art.get_size():
		art = art.get_region(used)
	var fit := inner / float(maxi(art.get_width(), art.get_height()))
	var art_size := Vector2i(maxi(1, int(art.get_width() * fit)), maxi(1, int(art.get_height() * fit)))
	art.resize(art_size.x, art_size.y, Image.INTERPOLATE_LANCZOS)
	var offset := (Vector2i(n, n) - art_size) / 2
	img.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), offset)
	img.generate_mipmaps()
	var out := ImageTexture.create_from_image(img)
	_badge_cache[cache_key] = out
	return out

## Until weapons get their own art: the hero's first projectile frame on a
## badge in the hero's attack colour.
static func _weapon_icon(id: String, evolved: bool = false) -> Texture2D:
	var names: Array = WEAPON_ICONS.get(weapon_hero_id(id), [])
	var own_art: Array = []
	if evolved and names.size() > 1:
		own_art.append(names[1])
	if not names.is_empty():
		own_art.append(names[0])
	for art_name in own_art:
		var art_path := "%s/%s.png" % [ICON_DIR, art_name]
		if ResourceLoader.exists(art_path):
			var hero_color := weapon_hero(id).attack_color if weapon_hero(id) != null else Color("8a7d9c")
			return _badge(load(art_path) as Texture2D, art_path, hero_color, evolved)
	var hero := weapon_hero(id)
	if hero == null or hero.attack_sprite_folder == "":
		return null
	var frame := "projectile_00.png"
	if hero.attack_alt_frame_names.size() > 0:
		frame = hero.attack_alt_frame_names[0]
	elif hero.attack_frame_names.size() > 0:
		frame = hero.attack_frame_names[0]
	var path := "%s/%s/%s" % [PROJECTILE_DIR, hero.attack_sprite_folder, frame]
	if not ResourceLoader.exists(path):
		return null
	return _badge(load(path) as Texture2D, path, hero.attack_color, evolved, true)

static func _fallback_entry(id: String) -> Dictionary:
	return ACTIVES[id] if ACTIVES.has(id) else PASSIVES.get(id, {})
