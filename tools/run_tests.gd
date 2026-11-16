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
	for test in ["energy", "store_catalogue", "store_purchases", "ad_offers", "missions", "upgrades", "translation", "language_setting",
			"run_snapshot_contract", "run_resume_world", "run_resume_level_up_and_boss", "run_end_settles_once", "run_forfeit"]:
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
	_test_claim_all_chests(daily)

## Tocar el último cofre listo abre todos los listos, una sola vez cada uno.
func _test_claim_all_chests(daily: Array) -> void:
	var saved_missions: Array = _state.claimed_daily_missions.duplicate()
	var saved_chests: Array = _state.claimed_daily_milestones.duplicate()
	var saved_gold: int = _state.gold
	var saved_gems: int = _state.gems
	var saved_essence: int = _state.essence
	# 60 puntos: los cofres de 20, 40 y 60 quedan listos.
	var ids: Array = []
	var points := 0
	for mission in daily:
		if points >= 60:
			break
		ids.append(str(mission.id))
		points += int(mission.points)
	_state.claimed_daily_missions = ids
	_state.claimed_daily_milestones = []
	var ready: Array = _state.claimable_milestones("daily")
	var expected_gold := 0
	var expected_gems := 0
	for milestone in _state.DAILY_MILESTONES:
		if ready.has(int(milestone.threshold)):
			expected_gold += int(milestone.gold)
			expected_gems += int(milestone.gems)
	_expect(ready.size() >= 2, "con %d puntos hay varios cofres listos" % _state.activity_points("daily"))
	var gold_before: int = _state.gold
	var gems_before: int = _state.gems
	_expect(_state.claim_all_milestones("daily") == ready.size(), "reclamar todos abre cada cofre listo")
	_expect(_state.gold == gold_before + expected_gold and _state.gems == gems_before + expected_gems, "entrega la suma de sus recompensas")
	_expect(_state.claimable_milestones("daily").is_empty(), "no queda ningún cofre listo")
	_expect(_state.claim_all_milestones("daily") == 0 and _state.gold == gold_before + expected_gold, "repetir no entrega de nuevo")
	_state.claimed_daily_missions = saved_missions
	_state.claimed_daily_milestones = saved_chests
	_state.gold = saved_gold
	_state.gems = saved_gems
	_state.essence = saved_essence

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
		# Partida guardada: tarjeta de Inicio, pausa y confirmaciones.
		"07:32  ·  NV. 8": "07:32  ·  LV. 8",
		"CRIPTAS DEL VACÍO · 07:32": "CRYPTS OF THE VOID · 07:32",
		"GUARDAR Y SALIR": "SAVE & QUIT",
		"ABANDONAR Y JUGAR": "ABANDON & PLAY",
		"Partida guardada.\nPuedes reanudarla desde Inicio.": "Run saved.\nYou can resume it from Home.",
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

# --- Reanudar partidas (RUN-RESUME) ----------------------------------------------

const STAGE_ONE := {"id": &"stage_01", "type": "stage", "index": 1, "name": "CRIPTAS DEL VACÍO", "chapter": 1, "level": 1, "gold_reward": 60, "gems_reward": 1}

## A world on stage 1, as MainLayout builds it (restoring when `snapshot` is set).
func _make_world(snapshot: Dictionary = {}) -> Node:
	var world: Node = load("res://scripts/game_world.gd").new()
	world.restore_snapshot = snapshot
	root.add_child(world)
	return world

func _drop_world(world: Node) -> void:
	if is_instance_valid(world):
		root.remove_child(world)
		world.free()

## Snapshot as it comes back from the save file (JSON round trip).
func _through_json(snapshot: Dictionary) -> Dictionary:
	var parsed = JSON.parse_string(JSON.stringify(snapshot))
	return parsed if parsed is Dictionary else {}

func _reset_run_state() -> void:
	_state.clear_run_snapshot_provider()
	_state.active_run = {}
	_state.current_stage_context = {}
	_state.screen = "menu"
	_state.set_boss_encounter(false)

## A world in the middle of a run: elapsed time, kills, a passive, an élite,
## orbs, a chest, a poison pool and pending loot.
func _busy_world() -> Node:
	_state.begin_stage(STAGE_ONE)
	var world := _make_world()
	world.elapsed = 130.0
	world.kills = 7
	world.xp = 12
	world._kills_by_type = {"chaser": 7}
	world._events_fired.append(0)
	world.passives["might"] = 2
	world.spawn_elite(1)
	world.spawn_xp(Vector2(200, 0), 10)
	world.spawn_gold(Vector2(-200, 0), 6)
	world.spawn_pickup(Vector2(0, 220), EmberfallPickup.Kind.CHEST)
	world._spawn_poison_pool(Vector2(150, 150), 2)
	world._loot.append({"id": str(EquipmentCatalog.RECIPES[0]["id"]), "rarity": "rare"})
	return world

func _test_run_snapshot_contract() -> void:
	_reset_run_state()
	_expect(not _state.is_valid_run_snapshot({}), "una instantánea vacía no es válida")
	_expect(not _state.is_valid_run_snapshot("texto"), "un tipo incorrecto no es válido")
	_state.begin_stage(STAGE_ONE)
	var world := _make_world()
	var good: Dictionary = _through_json(world.capture_snapshot())
	_drop_world(world)
	_reset_run_state()
	_expect(_state.is_valid_run_snapshot(good), "la instantánea de una partida real es válida tras pasar por JSON")
	_expect(JSON.stringify(good).find("Object") == -1, "la instantánea no guarda nodos")
	var cases := {
		"versión desconocida": ["version", 99],
		"fase desconocida": ["phase", "jefe"],
		"escenario bloqueado": ["context", {"type": "stage", "index": 9}],
		"héroe que no se tiene": ["hero", {"id": "heroe_inexistente"}],
		"mundo dañado": ["world", "x"],
		"enemigos dañados": ["enemies", {"a": 1}],
	}
	for what in cases:
		var bad: Dictionary = good.duplicate(true)
		bad[cases[what][0]] = cases[what][1]
		_expect(not _state.is_valid_run_snapshot(bad), "se rechaza: %s" % what)
	var dead: Dictionary = good.duplicate(true)
	dead["player"]["hp"] = 0
	_expect(not _state.is_valid_run_snapshot(dead), "se rechaza un héroe sin vida")
	# Cargar un guardado con la partida dañada no bloquea ni pierde el perfil.
	var payload: Dictionary = _through_json(_state.save_payload())
	var gold_before: int = _state.gold
	for broken in ["texto", 5, {"version": 0}, null]:
		payload["active_run"] = broken
		_state.load_data(payload)
		_expect(not _state.has_resumable_run() and _state.gold == gold_before, "un active_run dañado (%s) se descarta y el perfil carga" % type_string(typeof(broken)))
	payload["active_run"] = good
	_state.load_data(_through_json(payload))
	_expect(_state.has_resumable_run(), "una partida guardada se conserva al cargar")
	var energy_before: int = _state.energy
	var gold_now: int = _state.gold
	_expect(_state.save_run_snapshot(good), "guardar una instantánea válida")
	_expect(_state.energy == energy_before and _state.gold == gold_now, "guardar la instantánea no toca energía ni oro")
	_expect(not _state.save_run_snapshot({"version": 1}), "no se guarda una instantánea inválida")
	_reset_run_state()

func _test_run_resume_world() -> void:
	_reset_run_state()
	var world := _busy_world()
	var enemies_before: int = world.enemies.size()
	var orbs_value := 0
	for orb in world.orbs:
		orbs_value += orb.value
	world.player.hp = world.player.max_hp - 1
	world.player.position = Vector2(64, -32)
	var gold_before: int = _state.gold
	_expect(world.suspend(), "guardar y salir conserva la partida")
	var saved: Dictionary = _through_json(_state.active_run)
	_drop_world(world)
	_expect(_state.gold == gold_before, "salir no cobra los orbes del suelo")
	_state.screen = "menu"
	var energy_before: int = _state.energy
	var stats_before: Dictionary = _state.run_stats.duplicate()
	_state.active_run = saved
	var snapshot: Dictionary = _state.prepare_resume()
	_expect(not snapshot.is_empty(), "prepare_resume entrega la partida")
	_expect(int(_state.current_stage_context.get("index", 0)) == 1, "reanudar restaura el escenario")
	var resumed := _make_world(snapshot)
	_expect(_state.energy == energy_before, "reanudar no cobra energía")
	_expect(_state.run_stats == stats_before, "reanudar no registra estadísticas de partida")
	_expect(_state.screen == "paused", "la partida reanudada empieza en pausa")
	_expect(is_equal_approx(resumed.elapsed, 130.0) and resumed.kills == 7 and resumed.xp == 12, "tiempo, bajas y experiencia se conservan")
	_expect(resumed.enemies.size() == enemies_before, "mismos enemigos (%d), sin los 4 iniciales extra" % enemies_before)
	_expect(resumed.enemies.filter(func(e): return e.elite_tier == 1).size() == 1, "el élite vuelve una sola vez")
	var restored_value := 0
	for orb in resumed.orbs:
		restored_value += orb.value
	_expect(restored_value == orbs_value, "los orbes del suelo vuelven con su valor")
	_expect(resumed.pickups.size() == 1 and resumed.pickups[0].kind == EmberfallPickup.Kind.CHEST, "el cofre sigue en el suelo")
	_expect(resumed.get_children().filter(func(c): return c.get_script() != null and str(c.get_script().resource_path).ends_with("poison_pool.gd")).size() == 1, "el charco venenoso vuelve")
	_expect(resumed.skills.size() == 1 and resumed.skill_level(resumed.own_weapon_id()) == 1, "el arma inicial no se concede de nuevo")
	_expect(resumed.passive_level("might") == 2, "las pasivas se conservan")
	_expect(resumed.player.hp == resumed.player.max_hp - 1 and resumed.player.position.is_equal_approx(Vector2(64, -32)), "vida y posición del héroe")
	_expect(Array(resumed._events_fired) == [0], "los eventos ya disparados no se repiten")
	_expect(resumed._loot.size() == 1, "el botín pendiente se conserva")
	_expect(resumed.gold_this_run() == 0, "el oro de la partida se cuenta una vez")
	_drop_world(resumed)
	_reset_run_state()

func _test_run_resume_level_up_and_boss() -> void:
	_reset_run_state()
	var world := _busy_world()
	world.spawn_boss()
	world.add_xp(world.xp_needed)
	var options: Array = Array(world.current_level_up_options)
	_expect(_state.screen == "level_up" and not options.is_empty(), "subir de nivel abre la elección")
	var rerolls: int = world.rerolls
	var snapshot: Dictionary = _through_json(world.capture_snapshot())
	_expect(str(snapshot.get("phase", "")) == "level_up", "la fase de subida de nivel se guarda")
	world.suspend()
	_drop_world(world)
	_state.screen = "menu"
	_state.active_run = snapshot
	var resumed := _make_world(_state.prepare_resume())
	_expect(_state.screen == "level_up", "se reabre la misma elección")
	_expect(Array(resumed.current_level_up_options) == options, "con las mismas cartas")
	_expect(resumed.rerolls == rerolls and resumed.pending_levels == 1, "sin gastar cambios ni niveles")
	_expect(resumed.boss_spawned and is_instance_valid(resumed.boss), "el jefe sigue en pie")
	_expect(resumed.enemies.filter(func(e): return e.is_boss).size() == 1, "hay un solo jefe")
	_expect(_state.boss_encounter_active, "la música de jefe vuelve")
	resumed.choose_power(options[0])
	_expect(_state.screen == "playing" and resumed.pending_levels == 0, "elegir una carta tras reanudar cierra la subida")
	_drop_world(resumed)
	_reset_run_state()

func _test_run_end_settles_once() -> void:
	_reset_run_state()
	var world := _busy_world()
	var kills_before := int(_state.run_stats.get("lifetime_kills", 0))
	var inventory_before: int = _state.equipment_inventory.size()
	var xp_before: int = _state.experience + _state.level * 100000
	_expect(_state.has_resumable_run(), "una partida nueva queda guardada desde el inicio")
	world.end_run(false)
	_expect(not _state.has_resumable_run(), "la derrota borra la partida guardada")
	_expect(_state.screen == "defeat", "y termina en derrota")
	_expect(int(_state.run_stats.get("lifetime_kills", 0)) == kills_before + 7, "las bajas se registran una vez")
	_expect(_state.equipment_inventory.size() == inventory_before + 1, "el botín se entrega una vez")
	_expect(_state._save_batch_depth == 0, "el guardado por lotes queda cerrado")
	_expect(world.capture_snapshot().is_empty(), "una partida terminada no genera instantánea")
	var xp_after: int = _state.experience + _state.level * 100000
	_expect(xp_after > xp_before, "la derrota da experiencia")
	_state.screen = "playing"
	world.end_run(false)
	_expect(int(_state.run_stats.get("lifetime_kills", 0)) == kills_before + 7, "repetir end_run no suma bajas otra vez")
	_expect(_state.equipment_inventory.size() == inventory_before + 1, "ni botín")
	_expect(not _state.has_resumable_run(), "ni revive la partida guardada")
	_drop_world(world)
	_reset_run_state()

func _test_run_forfeit() -> void:
	_reset_run_state()
	var world := _busy_world()
	world.suspend()
	var snapshot: Dictionary = _through_json(_state.active_run)
	_drop_world(world)
	_reset_run_state()
	_state.active_run = snapshot
	var kills_before := int(_state.run_stats.get("lifetime_kills", 0))
	var inventory_before: int = _state.equipment_inventory.size()
	var energy_before: int = _state.energy
	var rewards: Dictionary = _state.forfeit_pending_run()
	_expect(not _state.has_resumable_run(), "abandonar desde el menú borra la partida")
	_expect(int(rewards.get("xp", 0)) > 0, "abandonar entrega la experiencia de derrota")
	_expect(int(_state.run_stats.get("lifetime_kills", 0)) == kills_before + 7, "abandonar registra las bajas una vez")
	_expect(_state.equipment_inventory.size() == inventory_before + 1, "abandonar entrega el botín pendiente")
	_expect(_state.forfeit_pending_run().is_empty(), "abandonar dos veces no entrega nada")
	_expect(int(_state.run_stats.get("lifetime_kills", 0)) == kills_before + 7 and _state.energy == energy_before, "ni cambia bajas ni energía")
	_reset_run_state()
