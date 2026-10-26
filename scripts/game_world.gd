extends Node2D

const BOSS_TIME := 720.0
const POWER_IDS: Array[String] = ["directed", "orbital", "area", "chain", "fire", "blizzard", "poison_bomb"]
const BOOST_IDS: Array[String] = ["boost_damage", "boost_health", "boost_speed", "boost_regen", "magnetism", "piercing", "poison_chance", "burn_chance", "freeze_chance", "extra_projectile", "crit_chance", "crit_damage", "attack_speed", "cooldown_reduction", "ability_duration"]
const BOOST_HEALTH_AMOUNT := 2 # 1 full heart per pick
const MAX_ABILITY_LEVEL := 6
const ABILITY_SPRITE_FX := preload("res://scripts/components/ability_sprite_fx.gd")

## STAGE-01: each of the 10 campaign stages (keyed by HomeScreen's 1-based
## index, matching its STAGE_NAMES order) gets its own enemy mix instead of
## sharing one universal curve — so two stages read as different encounters,
## not just the same fight with more enemy HP. Mazmorras and any stage
## without an entry here fall back to _default_archetype_mix().
const STAGE_ENEMY_MIXES := {
	1: {"CHASER": 1.0}, # Criptas del Vacío — plain intro
	2: {"CHASER": 0.7, "FAST": 0.3}, # Ruinas Verdantes — first taste of speed
	3: {"CHASER": 0.4, "FAST": 0.3, "CHARGER": 0.3}, # Forja de Ember — aggressive rushes
	4: {"CHASER": 0.3, "TANK": 0.5, "FAST": 0.2}, # Bosque Cenizo — tanky bruisers
	5: {"CHASER": 0.3, "SHOOTER": 0.5, "FAST": 0.2}, # Cavernas Rotas — ranged ambush
	6: {"CHASER": 0.2, "FAST": 0.2, "TANK": 0.2, "SHOOTER": 0.2, "CHARGER": 0.2}, # Torre Olvidada — everything at once
	7: {"CHASER": 0.2, "FAST": 0.4, "CHARGER": 0.4}, # Pantano Negro — relentless swarm
	8: {"TANK": 0.4, "SHOOTER": 0.4, "CHASER": 0.2}, # Cumbre Helada — slow, heavy-hitting siege
	9: {"FAST": 0.4, "CHARGER": 0.4, "CHASER": 0.2}, # Fosa de Magma — pure aggression
	10: {"CHASER": 0.15, "FAST": 0.2, "TANK": 0.2, "SHOOTER": 0.2, "CHARGER": 0.25}, # Trono de Emberfall — finale, all 5
}

## Multiplies the base spawn interval per stage (< 1.0 = enemies arrive
## faster) — the pacing half of "no diferenciarse solo por vida enemiga".
const STAGE_SPAWN_INTERVAL_MULT := {
	3: 0.85,
	7: 0.8,
	9: 0.75,
	10: 0.7,
}

var player: EmberfallPlayer
var elapsed := 0.0
var xp := 0
var level := 1
var xp_needed := 50
var kills := 0
var spawn_clock := 0.0
var spawn_interval := 2.2
var enemies: Array[EmberfallEnemy] = []
var orbs: Array[EmberfallXPOrb] = []
var projectiles: Array[EmberfallProjectile] = []
var _attack_count := 0
var skills: Dictionary = {"directed": 1}
var boosts: Dictionary = {
	"boost_damage": 0, "boost_health": 0, "boost_speed": 0, "boost_regen": 0, "magnetism": 0, "piercing": 0,
	"poison_chance": 0, "burn_chance": 0, "freeze_chance": 0, "extra_projectile": 0, "crit_chance": 0, "crit_damage": 0,
	"attack_speed": 0, "cooldown_reduction": 0, "ability_duration": 0,
}
var pending_levels := 0
var rerolls := 2
var fusions: Array[String] = []
var skill_timers := {"orbital": 0.0, "area": 0.0, "chain": 0.0, "fire": 0.0, "blizzard": 0.0, "poison_bomb": 0.0}
var boss: EmberfallEnemy
var boss_spawned := false
## Alternates the level-up screen between offering powers or boosts, one at a
## time. Starts true so the first flip lands on false (actives come first).
var current_options_are_boosts := true
var current_level_up_options: Array[String] = []
var _orbital_wave: EmberfallOrbitalWave
var _fire_aura: EmberfallPersistentAura

## STAGE-01: no per-biome background art exists yet, so a flat tint stands in
## for "bioma" — chapter 1 (Criptas/Ruinas/Forja/Bosque) reads cold violet,
## chapter 2 (Cavernas/Torre/Pantano/Cumbre) reads icy teal, chapter 3 (Fosa
## de Magma/Trono, the finale) reads ember red. Swap this for real art later
## without touching anything else — it's just one ColorRect.
const BIOME_TINTS := {
	1: Color("17232a"),
	2: Color("18302d"),
	3: Color("34231d"),
}

func _build_biome_background() -> void:
	var chapter := int(GameState.current_stage_context.get("chapter", 1))
	var bg := ColorRect.new()
	bg.color = BIOME_TINTS.get(chapter, Color("101a2b"))
	bg.size = Vector2(2000, 2000)
	bg.position = Vector2(-1000, -1000)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

func _ready() -> void:
	GameState.change_screen("playing")
	GameState.set_boss_encounter(false)
	_build_biome_background()
	player = EmberfallPlayer.new()
	player.position = Vector2.ZERO
	player.setup(self)
	player.died.connect(_on_player_died)
	add_child(player)
	for i in 4:
		spawn_enemy()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	elapsed += delta
	if not boss_spawned and elapsed >= _boss_time():
		spawn_boss()
	spawn_clock += delta
	if spawn_clock >= spawn_interval * _stage_spawn_interval_mult():
		spawn_clock = 0.0
		spawn_enemy()
		if elapsed > 60.0:
			spawn_enemy()
		spawn_interval = maxf(0.55, spawn_interval * 0.995)
	for orb in orbs.duplicate():
		if is_instance_valid(orb):
			orb.tick(player, pickup_radius(), delta)
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			projectiles.erase(projectile)
	update_powers(delta)
	queue_redraw()

func spawn_boss() -> void:
	boss_spawned = true
	GameState.set_boss_encounter(true)
	SfxPlayer.play("boss/boss_spawn.wav", false)
	boss = EmberfallBoss.new()
	var angle := randf_range(0.0, TAU)
	boss.position = player.position + Vector2(cos(angle), sin(angle)) * 460.0
	boss.setup(player, 1.0 + elapsed / 90.0, true)
	boss.configure_variant(_boss_variant_for_chapter())
	boss.game_ref = self
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	add_child(boss)
	enemies.append(boss)

func update_powers(delta: float) -> void:
	for key in skill_timers:
		skill_timers[key] = float(skill_timers[key]) + delta
	var cooldown := cooldown_multiplier()
	# Onda Orbital v2: the moons themselves (EmberfallOrbitalWave) do their own
	# continuous per-target damage every physics frame — this timer only
	# drives the Corona del Trueno fusion's bonus bolt to whatever's beyond
	# the moons' actual orbit, since that's an occasional proc, not a constant.
	if int(skills.get("orbital", 0)) > 0 and fusions.has("Corona del Trueno") and skill_timers["orbital"] >= 0.6 * cooldown:
		skill_timers["orbital"] = 0.0
		var outside_ring := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e.global_position.distance_to(player.global_position) >= EmberfallOrbitalWave.RADIUS_X)
		var crown_target: EmberfallEnemy = nearest_from(outside_ring, player.global_position)
		if crown_target:
			_apply_damage(crown_target, 10 + int(skills["orbital"]) * 5)
			_spawn_chain_fx(player.global_position, crown_target.global_position)
	if int(skills.get("area", 0)) > 0 and skill_timers["area"] >= 2.4 * cooldown:
		skill_timers["area"] = 0.0
		SfxPlayer.play("abilities/area_explosion.wav")
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < AREA_RADIUS:
				_apply_damage(enemy, 16 + int(skills["area"]) * 8)
				# Tormenta de Ceniza (Área + Fuego): the burst leaves everything
				# it hits burning instead of just a one-time hit.
				if fusions.has("Tormenta de Ceniza"):
					enemy.apply_burn(3.0 * duration_multiplier(), 6)
		_spawn_ability_fx("explosion_area", player.global_position, AREA_RADIUS)
	if int(skills.get("chain", 0)) > 0 and skill_timers["chain"] >= 2.0 * cooldown:
		skill_timers["chain"] = 0.0
		SfxPlayer.play("abilities/chain_lightning.wav")
		var remaining := enemies.duplicate()
		var origin := player.global_position
		for i in mini(2 + int(skills["chain"]), remaining.size()):
			# Capped per jump so the arc reads as lightning hopping between
			# nearby enemies, not teleporting to whatever's left on the map.
			var target: EmberfallEnemy = nearest_from(remaining, origin, CHAIN_JUMP_RANGE)
			if not target:
				break
			_apply_damage(target, 20 + int(skills["chain"]) * 8)
			# Tempestad Ígnea (Cadena + Fuego): every jump also ignites.
			if fusions.has("Tempestad Ígnea"):
				target.apply_burn(3.0 * duration_multiplier(), 6)
			_spawn_chain_fx(origin, target.global_position)
			origin = target.global_position
			remaining.erase(target)
	# Fuego Constante: unlike the other actives, this one isn't a burst on a
	# cooldown, it's meant to be *constant* — so its tick rate stays fixed
	# instead of scaling with the cooldown-reduction stat, and it ticks twice
	# as often as before (every 0.25s) so it reads as continuous instead of
	# an intermittent pulse. Per-tick damage is halved to keep the same DPS.
	if int(skills.get("fire", 0)) > 0 and skill_timers["fire"] >= FIRE_TICK_INTERVAL:
		skill_timers["fire"] = 0.0
		var fire_tick_damage := int(round((4.0 + int(skills["fire"]) * 3.0) * 0.5))
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < FIRE_AURA_RADIUS:
				_apply_damage(enemy, fire_tick_damage)
	if int(skills.get("blizzard", 0)) > 0 and skill_timers["blizzard"] >= 3.0 * cooldown:
		skill_timers["blizzard"] = 0.0
		_trigger_blizzard(int(skills["blizzard"]))
	if int(skills.get("poison_bomb", 0)) > 0 and skill_timers["poison_bomb"] >= 4.0 * cooldown:
		skill_timers["poison_bomb"] = 0.0
		_trigger_poison_bomb(int(skills["poison_bomb"]))

## Roughly how big each ability's visible art reads at scale 1.0 (eyeballed
## from the source PNGs), so `_spawn_ability_fx`'s target_radius lines up
## with each ability's actual hit radius instead of needing a magic scale
## per call site.
const FX_NATIVE_RADIUS := {
	"explosion_area": 300.0,
	"fuego_constante": 165.0,
}

## Fuego Constante's frame_01/02 are a near-solid disc (unlike frame_00's
## sparse ring) — at the old 70px radius its *bounding box* was similar to
## Onda Orbital's moon orbit (78x44), but being solid instead of sparse, it
## visually swallowed the moons and the character whenever they passed near
## or under it. Shrunk so its footprint (40) sits entirely inside the
## moons' orbit (min half-axis 44, see EmberfallOrbitalWave.RADIUS_Y) —
## a small flame core with the moons circling cleanly around the outside of
## it, instead of the two fighting for the same screen space.
const FIRE_AURA_RADIUS := 40.0
const FIRE_TICK_INTERVAL := 0.25
## Explosión de Área used to read as covering a disproportionate chunk of the
## arena at its old size (120); shrunk to a personal-space burst instead of a
## screen-filling one. (Onda Orbital's own reach now lives on
## EmberfallOrbitalWave, since it's driven by that scene, not a flat radius.)
const AREA_RADIUS := 90.0
## Cadena Eléctrica had no cap at all — each jump picked the nearest
## *remaining* enemy anywhere on the map, so a sparse field could send it
## arcing clear across the screen. Bounded to a believable lightning hop.
const CHAIN_JUMP_RANGE := 220.0

## Onda Orbital and Fuego Constante are auras, not bursts — they read wrong
## as a flash recreated on every damage tick, so instead this creates one
## persistent visual the first time the power is picked, parented directly
## to the player so it follows for free. Called again on every subsequent
## level-up of the same power too, so Onda Orbital can grow its moon count.
func _ensure_aura(power_id: String) -> void:
	match power_id:
		"orbital":
			if not is_instance_valid(_orbital_wave):
				_orbital_wave = preload("res://scripts/components/orbital_wave.gd").new()
				_orbital_wave.game_ref = self
				_orbital_wave.player_node = player
				player.add_child(_orbital_wave)
				SfxPlayer.play("abilities/orbital.wav", false)
			# Re-synced on every level-up, not just the first pick: 2 moons at
			# level 1, growing to the design's max of 6 by level 5.
			_orbital_wave.moon_count = int(skills["orbital"]) + 1
			_orbital_wave.damage = 6 + int(skills["orbital"]) * 3
		"fire":
			if not is_instance_valid(_fire_aura):
				_fire_aura = preload("res://scripts/components/persistent_aura.gd").new()
				_fire_aura.setup("fuego_constante", FIRE_AURA_RADIUS / FX_NATIVE_RADIUS["fuego_constante"])
				player.add_child(_fire_aura)
				player.move_child(_fire_aura, 0)
				SfxPlayer.play("abilities/constant_fire_start.wav", false)

func _spawn_ability_fx(folder: String, pos: Vector2, target_radius: float) -> void:
	var fx := ABILITY_SPRITE_FX.new()
	fx.position = pos
	fx.setup(folder, target_radius / float(FX_NATIVE_RADIUS.get(folder, target_radius)))
	add_child(fx)

## Basic-attack impact: the shot packs only ship "fly" frames, so this is a
## tiny procedural burst instead — separate from damage (already applied by
## the caller) and separate from the projectile itself (which may keep going
## if it pierces).
func _spawn_impact_flash(pos: Vector2, color: Color) -> void:
	var flash := EmberfallImpactFlash.new()
	flash.position = pos
	flash.color = color
	add_child(flash)

## Chain lightning's art is a fixed 4-node strip, not a tileable beam — it
## gets rotated to face the hop and stretched horizontally to roughly bridge
## the two points, same spirit as the old drawn LINE it replaces.
func _spawn_chain_fx(from: Vector2, to: Vector2) -> void:
	var diff := to - from
	var fx := ABILITY_SPRITE_FX.new()
	fx.position = (from + to) / 2.0
	fx.rotation = diff.angle()
	var scale_x := clampf(diff.length() / 360.0, 0.35, 2.2)
	fx.setup("cadena_electrica", 1.0, Vector2(scale_x, 0.5))
	add_child(fx)

## Ventisca: a lasting frost zone drops at a random spot near the player (not
## centered on them, unlike Área) and keeps chilling/damaging anything that
## stays inside it for its whole 7s lifetime, instead of a single instant hit.
func _trigger_blizzard(level: int) -> void:
	var angle := randf_range(0.0, TAU)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(40.0, 150.0)
	SfxPlayer.play("abilities/blizzard_start.wav")
	var zone := preload("res://scripts/components/frost_zone.gd").new()
	zone.position = pos
	zone.radius = 70.0 + level * 6.0
	zone.tick_damage = 6 + level * 2
	zone.freeze_duration = 0.6
	zone.lifetime = 7.0 * duration_multiplier()
	zone.game_ref = self
	add_child(zone)

## Bomba Venenosa: a bomb visibly arcs from the player to a nearby point (see
## EmberfallPoisonBombProjectile), then on landing leaves a pool that keeps
## poisoning whatever stands in it until it dissipates.
func _trigger_poison_bomb(level: int) -> void:
	var angle := randf_range(0.0, TAU)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(60.0, 180.0)
	var thrown := preload("res://scripts/components/poison_bomb_projectile.gd").new()
	thrown.launch(player.global_position, pos)
	thrown.landed.connect(_spawn_poison_pool.bind(level))
	add_child(thrown)
	SfxPlayer.play("abilities/poison_bomb_throw.wav")

func _spawn_poison_pool(pos: Vector2, level: int) -> void:
	SfxPlayer.play("abilities/poison_bomb_impact.wav")
	var pool := preload("res://scripts/components/poison_pool.gd").new()
	pool.position = pos
	pool.radius = 55.0 + level * 4.0
	pool.tick_damage = 3 + level * 2
	pool.lifetime = 4.0 + level * 0.5
	pool.game_ref = self
	add_child(pool)

## Applies damage to an enemy (rolling crit + status effects) and, if it
## dies, grants kills/loot consistently across every damage source
## (projectiles and ability ticks alike).
func _apply_damage(enemy: EmberfallEnemy, amount: int, apply_multiplier: bool = true) -> void:
	if not is_instance_valid(enemy):
		return
	var final_amount := amount
	if apply_multiplier:
		final_amount = int(round(final_amount * damage_multiplier()))
	var is_crit := randf() < crit_chance()
	if is_crit:
		final_amount = int(round(final_amount * crit_multiplier()))
	spawn_damage_number(enemy.global_position, final_amount, is_crit)
	SfxPlayer.play_enemy_hit()
	if is_crit:
		SfxPlayer.play("combat/critical_hit.wav")
	if enemy.damage(final_amount):
		_on_enemy_killed(enemy)
		return
	_maybe_apply_status(enemy)

## Public so enemy.gd can show numbers for its own poison/burn ticks too,
## keeping every damage source visually consistent.
func spawn_damage_number(pos: Vector2, amount: int, is_crit: bool) -> void:
	var number := preload("res://scripts/components/damage_number.gd").new()
	number.position = pos + Vector2(randf_range(-10.0, 10.0), -10.0)
	number.amount = amount
	number.is_crit = is_crit
	add_child(number)

func _maybe_apply_status(enemy: EmberfallEnemy) -> void:
	var duration := duration_multiplier()
	if randf() < poison_chance():
		enemy.apply_poison(3.0 * duration, 4 + int(boosts.get("poison_chance", 0)))
	if randf() < burn_chance():
		enemy.apply_burn(3.0 * duration, 4 + int(boosts.get("burn_chance", 0)))
	if randf() < freeze_chance():
		enemy.apply_freeze(1.5 * duration)

func nearest_from(pool: Array, origin: Vector2, max_distance: float = INF) -> EmberfallEnemy:
	var result: EmberfallEnemy
	var best := INF
	var max_distance_squared := max_distance * max_distance
	for enemy in pool:
		if is_instance_valid(enemy) and not enemy.dead:
			var distance := origin.distance_squared_to(enemy.global_position)
			if distance < best and distance <= max_distance_squared:
				best = distance
				result = enemy
	return result

## Always a plain chase for the first minute regardless of stage, so the
## opening moments of any encounter stay simple and readable — then the
## stage's own mix (or the generic fallback curve) takes over.
func _pick_archetype() -> int:
	if elapsed < 60.0:
		return EmberfallEnemy.Archetype.CHASER
	var stage_index := int(GameState.current_stage_context.get("index", 0))
	var stage_type := str(GameState.current_stage_context.get("type", ""))
	var mix: Dictionary = STAGE_ENEMY_MIXES.get(stage_index, {}) if stage_type == "stage" else {}
	if mix.is_empty():
		mix = _default_archetype_mix()
	return _weighted_archetype_pick(mix)

## Used for mazmorras and any stage not (yet) listed in STAGE_ENEMY_MIXES.
func _default_archetype_mix() -> Dictionary:
	if elapsed < 180.0:
		return {"CHASER": 0.6, "FAST": 0.25, "CHARGER": 0.15}
	elif elapsed < 360.0:
		return {"CHASER": 0.4, "FAST": 0.2, "TANK": 0.2, "CHARGER": 0.2}
	return {"CHASER": 0.25, "FAST": 0.2, "TANK": 0.2, "SHOOTER": 0.2, "CHARGER": 0.15}

func _weighted_archetype_pick(mix: Dictionary) -> int:
	var roll := randf()
	var acc := 0.0
	for key in mix:
		acc += float(mix[key])
		if roll < acc:
			return EmberfallEnemy.Archetype[key]
	return EmberfallEnemy.Archetype.CHASER

func _dungeon_modifier() -> String:
	if str(GameState.current_stage_context.get("type", "")) != "dungeon":
		return ""
	return str(GameState.current_stage_context.get("modifier", ""))

func _stage_spawn_interval_mult() -> float:
	if _dungeon_modifier() == "swarm":
		return 0.7
	if str(GameState.current_stage_context.get("type", "")) != "stage":
		return 1.0
	var stage_index := int(GameState.current_stage_context.get("index", 0))
	return float(STAGE_SPAWN_INTERVAL_MULT.get(stage_index, 1.0))

func _difficulty_multiplier() -> float:
	return 1.3 if _dungeon_modifier() == "hardened" else 1.0

func _boss_time() -> float:
	return 480.0 if _dungeon_modifier() == "reckoning" else BOSS_TIME

## Stages and dungeons alike already carry a real "chapter" (1-3, see
## HomeScreen/DungeonSelectionScreen) — reused here to pick which of the 3
## boss variants shows up, so the finale chapters feel like an escalation.
func _boss_variant_for_chapter() -> int:
	match int(GameState.current_stage_context.get("chapter", 1)):
		2: return EmberfallBoss.Variant.HEAVY
		3: return EmberfallBoss.Variant.AGGRESSIVE
		_: return EmberfallBoss.Variant.STANDARD

func spawn_enemy() -> void:
	var enemy := EmberfallEnemy.new()
	var angle := randf_range(0.0, TAU)
	enemy.position = player.position + Vector2(cos(angle), sin(angle)) * 540.0
	enemy.setup(player, (1.0 + elapsed / 90.0) * _difficulty_multiplier(), false, _pick_archetype())
	enemy.game_ref = self
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	add_child(enemy)
	enemies.append(enemy)

const PROJECTILE_SPEED := 520.0
## Tuned so the default (ranged) reach lands past melee/mid-range without
## covering the whole arena — enemies spawn 540px out, so a shot needs to let
## some of them close in first instead of sniping everything on spawn.
const PROJECTILE_BASE_LIFETIME := 1.0

## Effective reach of the current hero's basic attack — same speed/lifetime
## math spawn_projectile uses, exposed for the temporary debug range overlay.
func player_attack_range() -> float:
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	var range_scale := hero_data.attack_range_scale if hero_data != null else 1.0
	return PROJECTILE_SPEED * PROJECTILE_BASE_LIFETIME * range_scale

func spawn_projectile(_from: EmberfallPlayer) -> void:
	# The debug overlay in player.gd has always drawn this radius as "the"
	# attack range, but nothing actually enforced it — any living enemy could
	# be targeted regardless of distance, which read as infinite range. Gate
	# candidates by it for real instead of just picking the globally nearest.
	var attack_range := player_attack_range()
	var living_enemies := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e.global_position.distance_to(player.global_position) <= attack_range)
	if living_enemies.is_empty():
		return
	living_enemies.sort_custom(func(a, b):
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position)
	)
	var directed_level := int(skills.get("directed", 1))
	var bonus_damage := GameState.permanent_damage + GameState.get_equipped_bonus("damage")
	var base_damage := 20 + bonus_damage * 2 + (directed_level - 1) * 6
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	var hero_damage_mod := hero_data.damage_modifier if hero_data != null else 1.0
	var final_damage := int(round(base_damage * damage_multiplier() * hero_damage_mod))
	_attack_count += 1

	# Some melee heroes (e.g. Theron) land an area hit instead of a
	# single-target one every Nth swing — that replaces this attack entirely.
	if hero_data != null and hero_data.attack_aoe_every > 0 and _attack_count % hero_data.attack_aoe_every == 0:
		_trigger_melee_aoe(hero_data, final_damage)
		return

	var shot_range_scale := hero_data.attack_range_scale if hero_data != null else 1.0
	SfxPlayer.play("combat/basic_melee.wav" if shot_range_scale < 1.0 else "combat/basic_projectile.wav")
	var shot_count := 1 + int(boosts.get("extra_projectile", 0))
	var shot_color := hero_data.attack_color if hero_data != null else Color(0.2, 0.95, 0.85)
	var shot_sprite_folder := hero_data.attack_sprite_folder if hero_data != null else ""
	var shot_frame_names := _shot_frame_names(hero_data)
	var origin_pos := player.projectile_origin.global_position if is_instance_valid(player.projectile_origin) else player.position
	for i in mini(shot_count, living_enemies.size()):
		var target: EmberfallEnemy = living_enemies[i]
		var projectile := EmberfallProjectile.new()
		projectile.position = origin_pos
		projectile.setup(target.position, final_damage, shot_color, shot_sprite_folder, shot_range_scale, shot_frame_names)
		projectile.set_meta("hit_enemies", [])
		projectile.set_meta("max_pierces", int(boosts.get("piercing", 0)))
		projectile.tree_exiting.connect(_on_projectile_removed.bind(projectile))
		add_child(projectile)
		projectiles.append(projectile)

## Heroes with explicit frames (melee packs like Darven/Kaelgor) just use
## them. Heroes with alternating variants (Mordrak's two swing directions)
## get a single frame that flips each attack instead of looping both.
func _shot_frame_names(hero_data: CharacterData) -> PackedStringArray:
	if hero_data == null:
		return PackedStringArray()
	var alt_names := hero_data.attack_alt_frame_names
	if alt_names.size() >= 2:
		return PackedStringArray([alt_names[_attack_count % alt_names.size()]])
	return hero_data.attack_frame_names

## Theron-style every-Nth-attack burst: hits every enemy in range at once
## instead of the usual single target, with its own (bigger) visual cue.
func _trigger_melee_aoe(hero_data: CharacterData, hit_damage: int) -> void:
	SfxPlayer.play("combat/basic_melee.wav")
	var radius := hero_data.attack_aoe_radius
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(player.global_position) < radius:
			_apply_damage(enemy, hit_damage, false)
			_apply_hero_guaranteed_status(enemy)
	var fx := EmberfallProjectile.new()
	fx.position = player.position
	fx.setup(player.position, 0, hero_data.attack_color, hero_data.attack_sprite_folder, 0.4, hero_data.attack_aoe_frame_names, 0.5)
	add_child(fx)

func _process(_delta: float) -> void:
	if GameState.screen != "playing":
		return
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			continue
		var hit_enemies: Array = projectile.get_meta("hit_enemies", [])
		var max_pierces: int = projectile.get_meta("max_pierces", 0)
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and not enemy.dead and not hit_enemies.has(enemy) and projectile.global_position.distance_to(enemy.global_position) < 34.0:
				hit_enemies.append(enemy)
				projectile.set_meta("hit_enemies", hit_enemies)
				_apply_damage(enemy, projectile.damage_amount, false)
				_apply_basic_attack_fusions(enemy, projectile.damage_amount)
				_apply_hero_guaranteed_status(enemy)
				_spawn_impact_flash(enemy.global_position, projectile.color)
				if hit_enemies.size() > max_pierces:
					projectile.queue_free()
				break

## Lanza del Eclipse and Horizonte Magnético both enhance every basic-attack
## hit once unlocked (ranged shots and melee swings alike, since they all
## land through this same collision check), rather than being tied to one
## specific hero's power.
func _apply_basic_attack_fusions(hit_enemy: EmberfallEnemy, base_damage: int) -> void:
	# Lanza del Eclipse (Dirigido + Cadena): the shot arcs to one more nearby
	# enemy after its primary hit, at reduced damage.
	if fusions.has("Lanza del Eclipse"):
		var others := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e != hit_enemy)
		var arc_target: EmberfallEnemy = nearest_from(others, hit_enemy.global_position)
		if arc_target:
			_apply_damage(arc_target, int(base_damage * 0.6), false)
			_spawn_chain_fx(hit_enemy.global_position, arc_target.global_position)
	# Horizonte Magnético (Área + Dirigido): the shot also splashes a portion
	# of its damage to anything else standing right next to the hit enemy.
	if fusions.has("Horizonte Magnético"):
		var splash_radius := 55.0
		var splashed := false
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and not enemy.dead and enemy != hit_enemy and enemy.global_position.distance_to(hit_enemy.global_position) < splash_radius:
				_apply_damage(enemy, int(base_damage * 0.4), false)
				splashed = true
		if splashed:
			_spawn_ability_fx("explosion_area", hit_enemy.global_position, splash_radius)

## HERO-01: ties each mage's element to their own identity instead of the
## random passive chances (AUD-05) — Vaelor's fire always burns, Azyren's
## ice always briefly freezes, Orven's poison always poisons.
func _apply_hero_guaranteed_status(enemy: EmberfallEnemy) -> void:
	if not is_instance_valid(enemy) or enemy.dead:
		return
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	if hero_data == null:
		return
	match hero_data.guaranteed_status:
		"burn": enemy.apply_burn(3.0 * duration_multiplier(), 5)
		"freeze": enemy.apply_freeze(0.5 * duration_multiplier())
		"poison": enemy.apply_poison(3.0 * duration_multiplier(), 4)

## Grants the kill, drops gold OR xp (never both), and ends the run in
## victory once the stage boss falls.
func _on_enemy_killed(enemy: EmberfallEnemy) -> void:
	kills += 1
	if randf() < 0.15:
		spawn_gold(enemy.global_position, enemy.gold_value)
	else:
		spawn_xp(enemy.global_position, enemy.xp_value)
	if enemy == boss:
		SfxPlayer.play("boss/boss_defeated.wav", false)
		GameState.finish_run(true, kills)
	else:
		SfxPlayer.play("combat/enemy_death.wav")

func spawn_xp(at: Vector2, amount: int) -> void:
	var orb := EmberfallXPOrb.new()
	orb.position = at
	orb.setup(amount, false)
	orb.tree_exiting.connect(_on_orb_removed.bind(orb))
	add_child(orb)
	orbs.append(orb)

func spawn_gold(at: Vector2, amount: int) -> void:
	var orb := EmberfallXPOrb.new()
	orb.position = at
	orb.setup(amount, true)
	orb.tree_exiting.connect(_on_orb_removed.bind(orb))
	add_child(orb)
	orbs.append(orb)

func pickup_radius() -> float:
	return 80.0 + float(boosts.get("magnetism", 0)) * 35.0

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		xp_needed = int(xp_needed * 1.35)
		level += 1
		pending_levels += 1
	if pending_levels > 0 and GameState.screen != "level_up":
		_present_level_up()

## AUD-07: if every active power and passive boost is already at
## MAX_ABILITY_LEVEL, both pools in _roll_level_up_options() come back empty
## — showing that screen would leave the player stuck looking at zero
## choices forever. Auto-resolve each such pending level with a small gold
## bonus instead, and only actually open the screen once there's a real
## choice to offer.
func _present_level_up() -> void:
	current_level_up_options = _roll_level_up_options()
	if current_level_up_options.is_empty():
		GameState.gold += 20
		GameState.gold_changed.emit(GameState.gold)
		pending_levels = maxi(0, pending_levels - 1)
		if pending_levels > 0:
			_present_level_up()
		elif GameState.screen == "level_up":
			GameState.change_screen("playing")
		return
	if GameState.screen != "level_up":
		GameState.change_screen("level_up")
		SfxPlayer.play("progression/level_up.wav", false)

func ability_level(id: String) -> int:
	return int(boosts.get(id, 0)) if id in BOOST_IDS else int(skills.get(id, 0))

func _available(pool: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for id in pool:
		if ability_level(id) < MAX_ABILITY_LEVEL:
			result.append(id)
	return result

## Picks up to 3 choices, all of the same kind (power or boost), alternating
## kind each time a fresh level-up round starts (not on reroll, which keeps
## the kind). Abilities already at MAX_ABILITY_LEVEL are left out entirely.
func _roll_level_up_options(flip_kind: bool = true) -> Array[String]:
	if flip_kind:
		current_options_are_boosts = not current_options_are_boosts
	var boost_pool := _available(BOOST_IDS)
	var power_pool := _available(POWER_IDS)
	if current_options_are_boosts and boost_pool.is_empty():
		current_options_are_boosts = false
	elif not current_options_are_boosts and power_pool.is_empty():
		current_options_are_boosts = true
	var pool := (boost_pool if current_options_are_boosts else power_pool).duplicate()
	pool.shuffle()
	return pool.slice(0, 3)

func damage_multiplier() -> float:
	return 1.0 + float(boosts.get("boost_damage", 0)) * 0.08

func speed_multiplier() -> float:
	return 1.0 + float(boosts.get("boost_speed", 0)) * 0.08

func regen_per_second() -> float:
	return float(boosts.get("boost_regen", 0)) * 0.25

func poison_chance() -> float:
	return float(boosts.get("poison_chance", 0)) * 0.15

func burn_chance() -> float:
	return float(boosts.get("burn_chance", 0)) * 0.15

func freeze_chance() -> float:
	return float(boosts.get("freeze_chance", 0)) * 0.12

func crit_chance() -> float:
	return float(boosts.get("crit_chance", 0)) * 0.08

func crit_multiplier() -> float:
	return 1.5 + float(boosts.get("crit_damage", 0)) * 0.3

func attack_speed_multiplier() -> float:
	return maxf(0.5, 1.0 - float(boosts.get("attack_speed", 0)) * 0.07)

func cooldown_multiplier() -> float:
	return maxf(0.4, 1.0 - float(boosts.get("cooldown_reduction", 0)) * 0.08)

func duration_multiplier() -> float:
	return 1.0 + float(boosts.get("ability_duration", 0)) * 0.15

## The level-up panel's queue_free() is deferred (still alive/clickable for
## the rest of the frame it was freed on), so a fast double-tap on the same
## button can fire this twice before the panel is actually gone. `_choice_locked`
## closes that window; the deferred unlock only re-opens it once this frame
## has fully finished, well before the rebuilt panel could be tapped again.
var _choice_locked := false

func choose_power(power_id: String) -> void:
	if _choice_locked or GameState.screen != "level_up":
		return
	if ability_level(power_id) >= MAX_ABILITY_LEVEL:
		return
	_choice_locked = true
	call_deferred("_unlock_choice")
	SfxPlayer.play("progression/power_selected.wav", false)
	if power_id in BOOST_IDS:
		boosts[power_id] = int(boosts.get(power_id, 0)) + 1
		if power_id == "boost_health":
			player.max_hp += BOOST_HEALTH_AMOUNT
			player.hp += BOOST_HEALTH_AMOUNT
	else:
		skills[power_id] = int(skills.get(power_id, 0)) + 1
		check_fusions()
		_ensure_aura(power_id)
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels == 0:
		GameState.change_screen("playing")
	else:
		_present_level_up()

func _unlock_choice() -> void:
	_choice_locked = false

func reroll_power_choices() -> bool:
	if rerolls <= 0 or GameState.screen != "level_up":
		return false
	rerolls -= 1
	# Reroll within the same kind currently on offer, not a fresh flip.
	current_level_up_options = _roll_level_up_options(false)
	return true

## Each fusion's real combat effect lives inline in update_powers()/_process()
## next to the two abilities it combines (search the fusion's name to find
## it) — this dictionary is only the unlock recipe, shared with the UI so the
## pause screen can show real requirements instead of a hidden formula.
const FUSION_RECIPES := {
	"Tormenta de Ceniza": ["area", "fire"],
	"Corona del Trueno": ["orbital", "chain"],
	"Lanza del Eclipse": ["directed", "chain"],
	"Horizonte Magnético": ["area", "directed"],
	"Tempestad Ígnea": ["chain", "fire"],
}
const FUSION_LEVEL_REQUIRED := 5

func check_fusions() -> void:
	for name in FUSION_RECIPES:
		var pair: Array = FUSION_RECIPES[name]
		if int(skills.get(pair[0], 0)) >= FUSION_LEVEL_REQUIRED and int(skills.get(pair[1], 0)) >= FUSION_LEVEL_REQUIRED and not fusions.has(name):
			fusions.append(name)
			GameState.add_notification("¡Fusión desbloqueada: %s!" % name)
			_spawn_ability_fx("explosion_area", player.global_position, 170.0)
			SfxPlayer.play("progression/fusion_unlocked.wav", false)

func _on_player_died() -> void:
	GameState.finish_run(false, kills)

func _on_enemy_removed(enemy: EmberfallEnemy) -> void:
	enemies.erase(enemy)

func _on_orb_removed(orb: EmberfallXPOrb) -> void:
	if orb.collected:
		if orb.is_gold:
			GameState.add_gold(orb.value)
		else:
			add_xp(orb.value)
	orbs.erase(orb)

func _on_projectile_removed(projectile: EmberfallProjectile) -> void:
	projectiles.erase(projectile)

func _draw() -> void:
	# A quiet arena makes projectiles and enemy silhouettes readable on a phone.
	var chapter := int(GameState.current_stage_context.get("chapter", 1))
	var ground: Color = BIOME_TINTS.get(chapter, BIOME_TINTS[1])
	draw_rect(Rect2(-900, -900, 1800, 1800), ground)
	# Barely-visible patches prevent the arena from feeling like a flat editor
	# canvas while keeping the gameplay silhouette-first.
	var shadow := ground.darkened(0.38)
	shadow.a = 0.16
	draw_set_transform(Vector2(-320, -190), 0.0, Vector2(1.8, 0.7))
	draw_circle(Vector2.ZERO, 180.0, shadow)
	draw_set_transform(Vector2(310, 240), 0.0, Vector2(1.4, 0.55))
	draw_circle(Vector2.ZERO, 210.0, shadow)
	draw_set_transform(Vector2.ZERO)
