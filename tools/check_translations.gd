extends SceneTree
## Recorre las pantallas del juego en inglés y lista los textos visibles que
## quedaron sin traducir (faltan en scripts/data/translations_en.gd).
##
##   godot --headless --path . --script tools/check_translations.gd
##
## Sale con código 1 si falta alguno. No inicia partidas ni altera el progreso:
## el idioma se fuerza solo para este proceso.

const ROUTES := [&"home", &"character", &"inventory", &"missions", &"dungeons", &"upgrades", &"shop", &"codex"]
const MODALS := [&"profile", &"settings", &"credits", &"notifications"]
## Textos que son iguales en los dos idiomas.
const SAME := ["EMBERFALL", "Emberfall", "Joystick", "Normal", "Auto", "Español", "English", "DROPS", "MINI", "???", "GRATIS"]

const SAME_PATTERNS := ["^USD ", "^\\+\\d+ act\\.$", "^Audio$", "SIL Open Font License 1\\.1$"]

var _missing: Dictionary = {}
var _seen := 0
var _hero_names: Array[String] = []
var _abilities: Variant
var _equipment: Variant
var _upgrades: Variant
var _bestiary: Variant
var _characters: Variant
var _state: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TranslationServer.set_locale("en")
	# Se cargan en tiempo de ejecución: este script se compila antes de que
	# existan los autoloads de los que dependen los catálogos.
	_abilities = load("res://scripts/data/ability_catalog.gd")
	_equipment = load("res://scripts/data/equipment_catalog.gd")
	_upgrades = load("res://scripts/data/upgrade_catalog.gd")
	_bestiary = load("res://scripts/data/bestiary_catalog.gd")
	_characters = load("res://scripts/data/character_catalog.gd")
	_state = root.get_node("GameState")
	_state.persistence_enabled = false
	for hero in _characters.load_all():
		_hero_names.append(str(hero.display_name).to_upper())
	var main: Node = load("res://scenes/MainLayout.tscn").instantiate()
	root.add_child(main)
	await _frames(4)
	for route in ROUTES:
		main.navigate_to(route)
		await _frames(4)
		_collect(main, str(route))
	for modal in MODALS:
		main.open_modal(modal)
		await _frames(4)
		_collect(main, "modal " + str(modal))
		main.close_active_modal()
		await _frames(2)
	_check_catalogues()
	print("Textos revisados: %d" % _seen)
	if _missing.is_empty():
		print("OK: no hay textos sin traducir.")
		quit(0)
		return
	print("SIN TRADUCIR (%d):" % _missing.size())
	for text in _missing:
		print("  [%s] %s" % [_missing[text], str(text).c_escape()])
	quit(1)

func _frames(count: int) -> void:
	for i in count:
		await process_frame

func _collect(node: Node, where: String) -> void:
	if node is Label or node is Button or node is RichTextLabel:
		if node.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED and (node as CanvasItem).is_visible_in_tree():
			_check(str(node.get("text")), where)
	if node is Control and str((node as Control).tooltip_text) != "":
		_check((node as Control).tooltip_text, where + " (tooltip)")
	for child in node.get_children():
		_collect(child, where)

## Los textos de datos que solo aparecen durante una partida.
const TEXT_KEYS := ["name", "desc", "description", "text", "label", "effect_text", "title"]

func _check_catalogues() -> void:
	_walk(_abilities.ACTIVES, "habilidades")
	_walk(_abilities.PASSIVES, "pasivas")
	_walk(_abilities.UNLOCKS, "desbloqueos")
	_walk(_abilities.WEAPON_CHALLENGES, "desafíos de arma")
	_walk(_abilities.WEAPON_EVOLUTIONS, "evoluciones de arma")
	for level in _abilities.WEAPON_LEVEL_TEXT:
		_check(str(_abilities.WEAPON_LEVEL_TEXT[level]), "niveles de arma")
	_walk(_equipment.RECIPES, "equipo")
	_walk(_equipment.UNIQUES, "efectos únicos")
	_walk(_equipment.SETS, "sets")
	_walk(_equipment.STATS, "stats")
	_walk(_upgrades.UPGRADES, "mejoras")
	_walk(_bestiary.ENTRIES, "bestiario")
	_walk(_state.DAILY_POOL, "misiones diarias")
	_walk(_state.WEEKLY_MISSIONS, "misiones semanales")
	_walk(_state.CHEST_TIERS, "baúles")
	for hero in _characters.load_all():
		_check(str(hero.attack_name), "ataque de héroe")

func _walk(value: Variant, where: String) -> void:
	if value is Dictionary:
		for key in value:
			if value[key] is String and TEXT_KEYS.has(str(key)):
				_check(value[key], where)
			else:
				_walk(value[key], where)
	elif value is Array:
		for item in value:
			_walk(item, where)

func _check(text: String, where: String) -> void:
	text = text.strip_edges()
	if text.length() < 2 or SAME.has(text) or _missing.has(text):
		return
	# Solo cuentan los textos con palabras: números, tiempos y símbolos no.
	var letters := RegEx.create_from_string("[A-Za-zÁÉÍÓÚÑáéíóúñ]{3}")
	if letters.search(text) == null:
		return
	_seen += 1
	if str(TranslationServer.translate(text)) != text:
		return
	for pattern in SAME_PATTERNS:
		if RegEx.create_from_string(pattern).search(text) != null:
			return
	if _hero_names.has(text.to_upper()):
		return  # los nombres propios no se traducen
	_missing[text] = where
