extends SceneTree
## Pruebas automáticas de las reglas que no se ven a simple vista: energía,
## tienda, misiones, mejoras e idioma.
##
##   godot --headless --path . --script tools/run_tests.gd
##
## Sale con código 0 si pasan todas. No altera el progreso: lo primero que hace
## es apagar la escritura a disco de GameState (persistence_enabled).

var _state: Node
var _passed := 0
var _failed: Array[String] = []
var _current := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_state = root.get_node("GameState")
	_state.persistence_enabled = false
	for test in ["energy", "store_catalogue", "store_purchases", "ad_offers", "missions", "upgrades", "translation", "language_setting"]:
		_current = test
		call("_test_" + test)
	print("")
	print("%d comprobaciones correctas, %d fallidas." % [_passed, _failed.size()])
	for line in _failed:
		print("  FALLA  " + line)
	quit(0 if _failed.is_empty() else 1)

func _expect(condition: bool, what: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed.append("%s: %s" % [_current, what])

# --- Energía -------------------------------------------------------------------

func _test_energy() -> void:
	_state.energy = _state.MAX_ENERGY
	_expect(_state.can_start(), "con energía llena se puede jugar")
	_expect(_state.start_run(), "start_run arranca la partida")
	_expect(_state.energy == _state.MAX_ENERGY - _state.ENERGY_COST, "una partida descuenta ENERGY_COST")
	_state.energy = _state.ENERGY_COST - 1
	_state.energy_timestamp = Time.get_unix_time_from_system()
	_expect(not _state.can_start(), "sin energía suficiente no se puede jugar")
	_expect(not _state.start_run(), "start_run falla sin energía")
	_expect(_state.energy == _state.ENERGY_COST - 1, "un intento fallido no descuenta energía")
	_state.energy = _state.MAX_ENERGY

# --- Tienda --------------------------------------------------------------------

func _price(offer: Dictionary) -> float:
	return float(str(offer.usd).replace(",", "."))

## Cada paquete más caro tiene que dar más cantidad y mejor valor por dólar.
func _test_store_catalogue() -> void:
	for offers in [_state.COIN_OFFERS, _state.ENERGY_OFFERS]:
		var paid: Array = offers.filter(func(offer): return offer.has("usd"))
		_expect(paid.size() >= 2, "hay paquetes de pago")
		for i in range(1, paid.size()):
			var previous: Dictionary = paid[i - 1]
			var current: Dictionary = paid[i]
			_expect(_price(current) > _price(previous), "%s cuesta más que %s" % [current.id, previous.id])
			_expect(int(current.amount) > int(previous.amount), "%s da más que %s" % [current.id, previous.id])
			_expect(float(current.amount) / _price(current) >= float(previous.amount) / _price(previous),
				"%s rinde igual o más por dólar que %s" % [current.id, previous.id])
	var ids: Array[String] = _state.store_offer_ids()
	var unique := {}
	for id in ids:
		unique[id] = true
	_expect(unique.size() == ids.size(), "los ids de producto no se repiten")

func _test_store_purchases() -> void:
	var offer: Dictionary = _state.COIN_OFFERS[2]
	var before: int = _state.gold
	_expect(_state.grant_store_offer(str(offer.id), "token-prueba-1"), "una compra válida se entrega")
	_expect(_state.gold == before + int(offer.amount), "entrega la cantidad del catálogo")
	_expect(_state.grant_store_offer(str(offer.id), "token-prueba-1"), "el mismo token se acepta")
	_expect(_state.gold == before + int(offer.amount), "pero no se entrega dos veces")
	_expect(not _state.grant_store_offer("producto_inexistente", "token-prueba-2"), "un producto desconocido se rechaza")
	_expect(not _state.buy_coin_offer(2), "un paquete de pago no se puede comprar con gemas")
	_state.gold = before
	_state.processed_purchases.erase("token-prueba-1")
	# La energía comprada puede pasar el máximo normal, hasta el tope de reserva.
	var energy_offer: Dictionary = _state.ENERGY_OFFERS[2]
	_state.energy = _state.MAX_ENERGY
	_state.grant_store_offer(str(energy_offer.id), "")
	_expect(_state.energy == _state.MAX_ENERGY + int(energy_offer.amount), "la energía comprada supera el máximo")
	_state.energy = _state.ENERGY_OVERFLOW_CAP - 1
	_state.grant_store_offer(str(energy_offer.id), "")
	_expect(_state.energy == _state.ENERGY_OVERFLOW_CAP, "y se detiene en el tope de reserva")
	_state.energy = _state.MAX_ENERGY

func _test_ad_offers() -> void:
	var id := str(_state.COIN_OFFERS[1].id)
	var key: String = _state.ad_offer_key("coin", 1)
	var had: bool = _state.claimed_free_offers.has(key)
	_state.claimed_free_offers.erase(key)
	var before: int = _state.gold
	_expect(_state.is_ad_offer_pending(id), "la oferta con anuncio empieza pendiente")
	_expect(_state.grant_ad_offer(id), "ver el anuncio la entrega")
	_expect(_state.gold == before + int(_state.COIN_OFFERS[1].amount), "entrega la cantidad del catálogo")
	_expect(not _state.grant_ad_offer(id), "el anuncio solo sirve una vez")
	_expect(_state.gold == before + int(_state.COIN_OFFERS[1].amount), "y no vuelve a entregar")
	_state.gold = before
	if not had:
		_state.claimed_free_offers.erase(key)

# --- Misiones ------------------------------------------------------------------

func _test_missions() -> void:
	var daily: Array = _state.daily_missions()
	var expected := 0
	for tier in _state.DAILY_SLOTS:
		expected += int(_state.DAILY_SLOTS[tier])
	_expect(daily.size() == expected, "el día trae %d misiones" % expected)
	var ids := {}
	var points := 0
	for mission in daily:
		ids[str(mission.id)] = true
		points += int(mission.points)
	_expect(ids.size() == daily.size(), "las misiones del día no se repiten")
	_expect(points == _state.ACTIVITY_MAX, "las misiones del día suman %d puntos de actividad" % _state.ACTIVITY_MAX)
	var weekly_points := 0
	for mission in _state.WEEKLY_MISSIONS:
		weekly_points += int(mission.points)
	_expect(weekly_points == _state.ACTIVITY_MAX, "las semanales suman %d puntos" % _state.ACTIVITY_MAX)
	for milestones in [_state.DAILY_MILESTONES, _state.WEEKLY_MILESTONES]:
		var last := 0
		for milestone in milestones:
			_expect(int(milestone.threshold) > last and int(milestone.threshold) <= _state.ACTIVITY_MAX, "cofre de actividad alcanzable (%d)" % int(milestone.threshold))
			last = int(milestone.threshold)
	_expect(not _state.claim_mission("mision_inexistente"), "una misión desconocida no se reclama")

# --- Mejoras permanentes ---------------------------------------------------------

func _test_upgrades() -> void:
	var catalogue = load("res://scripts/data/upgrade_catalog.gd")
	var id := str(catalogue.UPGRADES[0].id)
	var stored: Dictionary = _state.upgrade_levels.duplicate() if "upgrade_levels" in _state else {}
	var gold_before: int = _state.gold
	var level: int = _state.get_upgrade_level(id)
	if level >= catalogue.max_level(id):
		_expect(not _state.buy_upgrade(id), "una mejora al máximo no se compra")
		return
	var cost: int = catalogue.cost(id, level)
	_state.gold = cost - 1
	_expect(not _state.buy_upgrade(id), "sin oro suficiente no se compra")
	_expect(_state.get_upgrade_level(id) == level, "y el nivel no cambia")
	_state.gold = cost
	_expect(_state.buy_upgrade(id), "con el oro justo se compra")
	_expect(_state.gold == 0, "descuenta el costo exacto")
	_expect(_state.get_upgrade_level(id) == level + 1, "y sube un nivel")
	_expect(catalogue.cost(id, level + 1) > cost, "el siguiente nivel cuesta más")
	_expect(not _state.buy_upgrade("mejora_inexistente"), "una mejora desconocida se rechaza")
	_state.gold = gold_before
	if "upgrade_levels" in _state:
		_state.upgrade_levels = stored

# --- Idioma --------------------------------------------------------------------

func _test_translation() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	_expect(str(TranslationServer.translate("JUGAR")) == "JUGAR", "en español se muestra el texto original")
	TranslationServer.set_locale("en")
	var cases := {
		"JUGAR": "PLAY",
		"Misiones": "Missions",
		"NIVEL 7": "LEVEL 7",
		"Elimina 150 enemigos": "Defeat 150 enemies",
		"02:13  ·  41 BAJAS": "02:13  ·  41 KILLS",
		"CAMBIAR (2)": "REROLL (2)",
		"+12% Crítico": "+12% Crit",
		"MEJORAR\n120 oro · 8 Esencia": "UPGRADE\n120 gold · 8 Essence",
		"Hace 3 días": "3 days ago",
		"· Nv.1/5  ·  ✓ ÁREA": "· Lv.1/5  ·  ✓ AREA",
		"Tienes 1 de 3. Te faltan 2 más iguales.": "You have 1 of 3. You need 2 more.",
		"VAELOR": "VAELOR",
		"12 / 30": "12 / 30",
	}
	for source in cases:
		var got := str(TranslationServer.translate(source))
		_expect(got == cases[source], "\"%s\" -> \"%s\" (dio \"%s\")" % [str(source).c_escape(), str(cases[source]).c_escape(), got.c_escape()])
	# Ninguna traducción puede perder o inventar marcadores %d / %s.
	var table: Dictionary = load("res://scripts/data/translations_en.gd").TABLE
	var marker := RegEx.create_from_string("%[-+0]*\\d*(?:\\.\\d+)?[sdf]")
	for source in table:
		var target := str(table[source])
		if target.contains("{0}"):
			continue
		_expect(marker.search_all(str(source)).size() >= marker.search_all(target).size(),
			"\"%s\" no usa más marcadores que su original" % target.c_escape())
		_expect(not target.strip_edges().is_empty(), "\"%s\" tiene traducción" % str(source).c_escape())
	TranslationServer.set_locale(previous)

func _test_language_setting() -> void:
	var localization: Node = root.get_node("Localization")
	var previous: String = localization.language
	localization.set_language("en")
	_expect(localization.locale() == "en" and _state.language == "en", "elegir inglés cambia el idioma y la preferencia")
	localization.set_language("es")
	_expect(localization.locale() == "es", "elegir español vuelve al original")
	localization.set_language("idioma_inexistente")
	_expect(localization.language == "es", "un idioma desconocido se ignora")
	localization.set_language(previous)
	_state.language = previous
