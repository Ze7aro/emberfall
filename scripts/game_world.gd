extends Node2D

## Short in-run banner (hordes, élites, chests, evolutions); ui.gd shows it.
signal announced(text: String, color: Color)

const BOSS_TIME := 720.0
const GOLD := Color("e8b84a")
const DANGER := Color("e86958")
const VIOLET := Color("b07cff")

## Élites (drop a chest) every 90-120 s until the boss shows up.
const ELITE_INTERVAL_MIN := 90.0
const ELITE_INTERVAL_MAX := 120.0
## Scripted wave events on top of the regular spawn curve: "ring" closes a
## circle around the player, "swarm" sends a fast column from one side, and
## "miniboss" brings a tier-2 élite that drops an epic chest.
const WAVE_EVENTS := [
	{"time": 150.0, "type": "ring"},
	{"time": 240.0, "type": "swarm"},
	{"time": 330.0, "type": "ring"},
	{"time": 360.0, "type": "miniboss"},
	{"time": 420.0, "type": "swarm"},
	{"time": 510.0, "type": "ring"},
	{"time": 600.0, "type": "swarm"},
	{"time": 660.0, "type": "ring"},
]
## Chance per regular kill for each small drop (rolled once, in this order).
const DROP_POTION := 0.008
const DROP_MAGNET := 0.004
const DROP_BOMB := 0.003
const POTION_HEAL := 2 # 1 full heart
const MAX_ABILITY_LEVEL := AbilityCatalog.MAX_LEVEL
## Used when a hero has no starting_power set in its CharacterData.
const DEFAULT_STARTING_POWER := "daggers"

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
var pickups: Array[EmberfallPickup] = []
var _next_elite_time := ELITE_INTERVAL_MIN
## Run stats reported to GameState.record_run() (ability unlocks).
var _chests_opened := 0
var _evolutions_done := 0
## Kills per bestiary key this run (BestiaryCatalog), saved in end_run.
var _kills_by_type := {}
var _run_reported := false
var _revives_left := 0
var _events_fired: Array[int] = []
var _attack_count := 0
## Owned actives and passives, id -> level (see AbilityCatalog). Insertion
## order is pick order, which the build bar shows as-is.
var skills: Dictionary = {}
var passives: Dictionary = {}
## Actives that already evolved (their id stays in `skills`).
var evolved: Array[String] = []
## Options removed from this run with "Descartar".
var banished: Array[String] = []
var pending_levels := 0
var rerolls := 2
var banishes := 2
var skill_timers := {}
var boss: EmberfallEnemy
var boss_spawned := false
var current_level_up_options: Array[String] = []
var _orbital_wave: EmberfallOrbitalWave
var _fire_aura: EmberfallPersistentAura
var _perpetual_winter: EmberfallFrostZone
var _familiars: Array[EmberfallSpectralFamiliar] = []
var aegis_charges := 0
var _aegis_bubble: EmberfallAegisBubble
var _aegis_clock := 0.0
var _solar_heal_clock := 0.0
var _cataclysm_clock := 0.0
## Set by _apply_damage so callers (Guadaña del Vacío) know if the hit crit.
var _last_hit_crit := false

## Flat color per chapter: under the floor art, and the whole floor if a
## chapter's tile is missing.
const BIOME_TINTS := {
	1: Color("17232a"),
	2: Color("18302d"),
	3: Color("34231d"),
}

## Infinite map: the floor is one repeating sprite that follows the player,
## snapped to the tile so the pattern never slides. Decor is generated per
## chunk around the player (same chunk, same decor) and dropped behind.
## Cavernas is mirrored because its tile shows a seam at the edges.
const FLOOR_ART := {
	1: ["res://assets/suelo/cap1_criptas.png", false],
	2: ["res://assets/suelo/cap2_cavernas.png", true],
	3: ["res://assets/suelo/cap3_forja.png", false],
}
const FLOOR_TILE_WORLD := 420.0 # on-screen height of one tile
const FLOOR_VIEW_HALF := Vector2(700.0, 900.0) # covers a 390x844 screen plus shake and margin
const FLOOR_SHADE := Color(0.82, 0.82, 0.86)
const DECOR_NAMES := ["pilar", "calaveras", "cristal", "lapida", "brasero", "huesos", "roca", "circulo_runico"]
## Solid props block the player and enemies; the radius is a share of the
## drawn size, at the base of the prop. Flat ones (bones, rune circle) are
## walked over.
const DECOR_SOLID := {"pilar": 0.26, "calaveras": 0.3, "cristal": 0.3, "lapida": 0.28, "brasero": 0.28, "roca": 0.36}
## A chapter without its own props borrows these neutral ones from chapter 1.
const DECOR_FALLBACK := {2: ["roca", "cristal", "huesos", "circulo_runico"], 3: ["roca", "huesos", "calaveras", "circulo_runico"]}
const DECOR_CHUNK := 700.0
const DECOR_PER_CHUNK := 5
const DECOR_SIZE := 54.0
## Regular enemies left this far behind are moved back in front of the player.
const ENEMY_RECYCLE_DISTANCE := 950.0

var _floor_bg: ColorRect
var _floor_sprite: Sprite2D
var _floor_period := Vector2.ZERO
var _decor_textures: Array = [] # [name, Texture2D]
var _decor_chunks := {} # Vector2i -> Array[Sprite2D]
var _chapter := 1

func _build_biome_background() -> void:
	_chapter = int(GameState.current_stage_context.get("chapter", 1))
	_floor_bg = ColorRect.new()
	_floor_bg.color = BIOME_TINTS.get(_chapter, Color("101a2b"))
	_floor_bg.size = FLOOR_VIEW_HALF * 2.0
	_floor_bg.z_index = -100
	_floor_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_floor_bg)
	var art: Array = FLOOR_ART.get(_chapter, FLOOR_ART[1])
	if ResourceLoader.exists(str(art[0])):
		var tile := load(str(art[0])) as Texture2D
		var mirrored := bool(art[1])
		_floor_sprite = Sprite2D.new()
		_floor_sprite.texture = tile
		_floor_sprite.centered = false
		_floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR if mirrored else CanvasItem.TEXTURE_REPEAT_ENABLED
		_floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var k := FLOOR_TILE_WORLD / float(tile.get_height())
		_floor_sprite.scale = Vector2(k, k)
		# One full period of the pattern, in world units (mirroring doubles it).
		_floor_period = tile.get_size() * k * (2.0 if mirrored else 1.0)
		var cells := (FLOOR_VIEW_HALF * 2.0 / _floor_period).ceil() + Vector2.ONE
		_floor_sprite.region_enabled = true
		_floor_sprite.region_rect = Rect2(Vector2.ZERO, cells * _floor_period / k)
		_floor_sprite.modulate = FLOOR_SHADE
		_floor_sprite.z_index = -99
		add_child(_floor_sprite)
	_decor_textures = _load_decor_textures(_chapter)
	_follow_floor(Vector2.ZERO)

## Called every frame: keeps the floor under the camera and decor around it.
func _follow_floor(center: Vector2) -> void:
	if _floor_bg:
		_floor_bg.position = center - FLOOR_VIEW_HALF
	if _floor_sprite and _floor_period != Vector2.ZERO:
		var corner := center - FLOOR_VIEW_HALF
		_floor_sprite.position = (corner / _floor_period).floor() * _floor_period
	_update_decor_chunks(center)

func _load_decor_textures(chapter: int) -> Array:
	var found: Array = []
	for decor_name: String in DECOR_NAMES:
		var path := "res://assets/suelo/decorados/cap%d/%s.png" % [chapter, decor_name]
		if ResourceLoader.exists(path):
			found.append([decor_name, load(path)])
	if found.is_empty():
		for decor_name: String in DECOR_FALLBACK.get(chapter, []):
			var path := "res://assets/suelo/decorados/cap1/%s.png" % decor_name
			if ResourceLoader.exists(path):
				found.append([decor_name, load(path)])
	return found

func _update_decor_chunks(center: Vector2) -> void:
	if _decor_textures.is_empty():
		return
	var here := Vector2i((center / DECOR_CHUNK).floor())
	var wanted := {}
	for dx in range(-1, 2):
		for dy in range(-2, 3):
			wanted[here + Vector2i(dx, dy)] = true
	for chunk: Vector2i in _decor_chunks.keys():
		if not wanted.has(chunk):
			for prop: Node2D in _decor_chunks[chunk]:
				if is_instance_valid(prop):
					prop.queue_free()
			_decor_chunks.erase(chunk)
	for chunk: Vector2i in wanted.keys():
		if not _decor_chunks.has(chunk):
			_decor_chunks[chunk] = _spawn_decor_chunk(chunk)

## Same chunk always gets the same decor (seeded by chunk and chapter).
func _spawn_decor_chunk(chunk: Vector2i) -> Array[Node2D]:
	var made: Array[Node2D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(chunk.x, chunk.y, _chapter))
	for i in DECOR_PER_CHUNK:
		var at := (Vector2(chunk) + Vector2(rng.randf(), rng.randf())) * DECOR_CHUNK
		var pick: Array = _decor_textures[rng.randi() % _decor_textures.size()]
		var decor_name: String = pick[0]
		var tex: Texture2D = pick[1]
		if at.length() < 160.0:
			continue # keep the starting spot clear
		var decor := Sprite2D.new()
		decor.texture = tex
		decor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var k := DECOR_SIZE * rng.randf_range(0.8, 1.15) / float(maxi(tex.get_width(), tex.get_height()))
		decor.scale = Vector2(k * (-1.0 if rng.randf() < 0.5 else 1.0), k)
		decor.position = at
		decor.modulate = Color(0.78, 0.78, 0.84)
		decor.z_index = -98
		add_child(decor)
		made.append(decor)
		if DECOR_SOLID.has(decor_name):
			var drawn := tex.get_size() * absf(k)
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = maxf(drawn.x, drawn.y) * float(DECOR_SOLID[decor_name])
			shape.shape = circle
			body.add_child(shape)
			# At the base of the prop, where it meets the floor.
			body.position = at + Vector2(0, drawn.y * 0.5 - circle.radius * 0.8)
			add_child(body)
			made.append(body)
	return made

## Infinite map: regular enemies the player outran reappear ahead of them
## instead of trailing forever off-screen. Bosses, élites and the mini-boss
## stay put (the player is meant to deal with them).
func _recycle_far_enemies() -> void:
	var heading: Vector2 = player.velocity.normalized() if player.velocity.length() > 10.0 else Vector2.from_angle(randf() * TAU)
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead or enemy.is_boss or enemy.elite_tier > 0:
			continue
		if enemy.global_position.distance_to(player.global_position) > ENEMY_RECYCLE_DISTANCE:
			enemy.global_position = player.global_position + heading.rotated(randf_range(-0.9, 0.9)) * 540.0

func _ready() -> void:
	GameState.change_screen("playing")
	GameState.set_boss_encounter(false)
	_build_biome_background()
	player = EmberfallPlayer.new()
	player.position = Vector2.ZERO
	player.setup(self)
	player.died.connect(_on_player_died)
	add_child(player)
	sparks = EmberfallSparks.new()
	add_child(sparks)
	_setup_lighting()
	rerolls = 2 + _up("reroll")
	banishes = 2 + _up("banish")
	_revives_left = _up("revival")
	_gold_at_start = GameState.gold
	_grant_starting_power()
	for i in 4:
		spawn_enemy()

## Dim arena with a few warm lights (hero, élites, boss), so the
## violet/teal palette glows. Kept to a handful of lights: the Compatibility
## renderer pays an extra pass per light on everything it touches.
const LIGHTING_ENABLED := true
const AMBIENT := Color(0.5, 0.46, 0.66)
static var _light_texture: GradientTexture2D

func _setup_lighting() -> void:
	if not LIGHTING_ENABLED:
		return
	var ambient := CanvasModulate.new()
	ambient.color = AMBIENT
	add_child(ambient)
	player.add_child(make_light(330.0, Color(1.0, 0.92, 0.82), 0.9))

static func make_light(radius: float, color: Color, energy: float) -> PointLight2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 1))
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		_light_texture = GradientTexture2D.new()
		_light_texture.gradient = gradient
		_light_texture.fill = GradientTexture2D.FILL_RADIAL
		_light_texture.fill_from = Vector2(0.5, 0.5)
		_light_texture.fill_to = Vector2(1.0, 0.5)
		_light_texture.width = 256
		_light_texture.height = 256
	var light := PointLight2D.new()
	light.texture = _light_texture
	light.texture_scale = radius / 128.0
	light.color = color
	light.energy = energy
	light.blend_mode = Light2D.BLEND_MODE_ADD
	return light

## Each hero starts with the active that defines them (CharacterData's
## starting_power), so their element shows from the first second.
func _grant_starting_power() -> void:
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	var start := DEFAULT_STARTING_POWER
	if hero_data != null and AbilityCatalog.is_active(hero_data.starting_power):
		start = hero_data.starting_power
	skills[start] = 1
	_refresh_powers()

func _physics_process(delta: float) -> void:
	if GameState.screen != "playing":
		return
	elapsed += delta
	if not boss_spawned and elapsed >= _boss_time():
		spawn_boss()
	_tick_events()
	for pickup in pickups.duplicate():
		if not is_instance_valid(pickup):
			pickups.erase(pickup)
		elif pickup.tick(player, delta):
			_collect_pickup(pickup)
	spawn_clock += delta
	if spawn_clock >= spawn_interval * _stage_spawn_interval_mult():
		spawn_clock = 0.0
		spawn_enemy()
		if elapsed > 60.0:
			spawn_enemy()
		spawn_interval = maxf(0.55, spawn_interval * 0.995)
	for orb in orbs:
		if is_instance_valid(orb):
			orb.tick(player, pickup_radius(), delta)
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			projectiles.erase(projectile)
	update_powers(delta)
	_follow_floor(player.global_position)
	_recycle_far_enemies()

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
	if LIGHTING_ENABLED:
		boss.add_child(make_light(220.0, Color(0.55, 0.95, 0.95), 0.7))
	add_child(boss)
	enemies.append(boss)

# --- Active abilities --------------------------------------------------------

## Fires every owned active whose own clock is due. Persistent ones
## (Lunas, Aura, Familiar, Invierno Perpetuo) live as nodes that
## _refresh_powers() keeps in sync; only their periodic extras tick here.
func update_powers(delta: float) -> void:
	for id in skills:
		skill_timers[id] = float(skill_timers.get(id, 0.0)) + delta
	var cd := cooldown_multiplier()
	_update_powers_inner(delta, cd)
	damage_source = "basic"

func _update_powers_inner(delta: float, cd: float) -> void:
	if skills.has("daggers"):
		var interval := (0.3 if is_evolved("daggers") else 1.1) * attack_speed_multiplier()
		if _due("daggers", interval):
			_fire_daggers(skill_level("daggers"))
	if skills.has("fire") and _due("fire", FIRE_TICK_INTERVAL):
		_tick_fire_aura(skill_level("fire"), delta)
	if skills.has("chain") and _due("chain", (1.2 if is_evolved("chain") else 2.0) * cd):
		_fire_chain(skill_level("chain"))
	if skills.has("poison_bomb") and _due("poison_bomb", 4.0 * cd):
		for i in (2 if is_evolved("poison_bomb") else 1):
			_trigger_poison_bomb(skill_level("poison_bomb"))
	if skills.has("blizzard") and not is_evolved("blizzard") and _due("blizzard", 3.0 * cd):
		_trigger_blizzard(skill_level("blizzard"))
	if skills.has("boomerang") and _due("boomerang", 2.2 * cd):
		_fire_boomerang(skill_level("boomerang"))
	if skills.has("slash") and _due("slash", 1.5 * cd):
		_trigger_slash(skill_level("slash"))
	if skills.has("meteor"):
		if _due("meteor", 3.2 * cd):
			_trigger_meteors(skill_level("meteor"))
		if is_evolved("meteor"):
			_cataclysm_clock += delta
			if _cataclysm_clock >= 10.0 * cd:
				_cataclysm_clock = 0.0
				_spawn_meteor(_meteor_target(), METEOR_BASE_RADIUS * 2.8 * area_multiplier(), (28 + 10 * skill_level("meteor")) * 4, 1.1, true)
	if skills.has("shard") and _due("shard", 2.6 * cd):
		_fire_shards(skill_level("shard"))
	if skills.has("aegis"):
		_tick_aegis(delta)

## True (and resets the clock) once `id` has waited `interval` seconds.
func _due(id: String, interval: float) -> bool:
	if float(skill_timers.get(id, 0.0)) < interval:
		return false
	skill_timers[id] = 0.0
	return true

func skill_level(id: String) -> int:
	return int(skills.get(id, 0))

func is_evolved(id: String) -> bool:
	return evolved.has(id)

## Dagas Rúnicas: a fan toward where the player faces (not auto-aimed — the
## direction is the player's to choose, unlike every other active).
func _fire_daggers(lvl: int) -> void:
	var count := 1 + (lvl - 1) / 2 + amount_bonus() + (1 if is_evolved("daggers") else 0)
	var aim := player.facing_direction
	for i in count:
		var spread := deg_to_rad(9.0) * (float(i) - float(count - 1) / 2.0)
		var dagger := _make_skill_projectile(EmberfallSkillProjectile.Style.DAGGER, "daggers")
		dagger.direction = aim.rotated(spread)
		dagger.speed = 640.0 * proj_speed_multiplier()
		dagger.damage = 9 + 4 * lvl
		dagger.lifetime = 0.6
		dagger.pierce = -1 if is_evolved("daggers") else 0
		add_child(dagger)
	SfxPlayer.play("combat/basic_projectile.wav")

## Aura Ígnea: unlike the other actives this isn't a burst on a cooldown,
## it's meant to be *constant* — so its tick rate stays fixed instead of
## scaling with Enfriamiento. Corona Solar also heals while it's burning.
func _tick_fire_aura(lvl: int, _delta: float) -> void:
	damage_source = "fire"
	var radius := fire_aura_radius()
	var tick_damage := int(round((4.0 + lvl * 3.0) * 0.5 * (1.5 if is_evolved("fire") else 1.0)))
	var burned_any := false
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(player.global_position) < radius:
			enemy.apply_burn(2.0 * duration_multiplier(), 2 + lvl)
			_apply_damage(enemy, tick_damage)
			burned_any = true
	if is_evolved("fire"):
		_solar_heal_clock += FIRE_TICK_INTERVAL
		if burned_any and _solar_heal_clock >= 6.0:
			_solar_heal_clock = 0.0
			player.heal(1)

func fire_aura_radius() -> float:
	return (FIRE_AURA_BASE_RADIUS + 6.0 * skill_level("fire")) * area_multiplier() * (1.4 if is_evolved("fire") else 1.0)

## Cadena Eléctrica: capped per jump so the arc reads as lightning hopping
## between nearby enemies, not teleporting across the map. Every hit
## leaves the target electrocuted (next hit +25%).
func _fire_chain(lvl: int) -> void:
	damage_source = "chain"
	SfxPlayer.play("abilities/chain_lightning.wav")
	var remaining := enemies.duplicate()
	var origin := player.global_position
	var jumps := 20 if is_evolved("chain") else 2 + lvl + amount_bonus()
	var jump_range := CHAIN_JUMP_RANGE * area_multiplier()
	for i in mini(jumps, remaining.size()):
		var target: EmberfallEnemy = nearest_from(remaining, origin, jump_range)
		if not target:
			break
		_apply_damage(target, 20 + lvl * 8)
		if is_instance_valid(target):
			target.apply_shock(1.5 * duration_multiplier())
		_spawn_chain_fx(origin, target.global_position)
		origin = target.global_position
		remaining.erase(target)

## Ventisca: a lasting frost zone drops at a random spot near the player (not
## centered on them) and keeps chilling/damaging anything that stays inside
## it for its whole lifetime, instead of a single instant hit.
func _trigger_blizzard(lvl: int) -> void:
	var angle := randf_range(0.0, TAU)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(40.0, 150.0)
	SfxPlayer.play("abilities/blizzard_start.wav")
	var zone := preload("res://scripts/components/frost_zone.gd").new()
	zone.position = pos
	zone.radius = (70.0 + lvl * 6.0) * area_multiplier()
	zone.tick_damage = 6 + lvl * 2
	zone.freeze_duration = 0.6
	zone.lifetime = 7.0 * duration_multiplier()
	zone.game_ref = self
	add_child(zone)

## Frasco Tóxico: a flask visibly arcs from the player to a nearby point (see
## EmberfallPoisonBombProjectile), then on landing leaves a pool that keeps
## poisoning whatever stands in it until it dissipates.
func _trigger_poison_bomb(lvl: int) -> void:
	var angle := randf_range(0.0, TAU)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(60.0, 180.0)
	var thrown := preload("res://scripts/components/poison_bomb_projectile.gd").new()
	thrown.launch(player.global_position, pos)
	thrown.landed.connect(_spawn_poison_pool.bind(lvl))
	add_child(thrown)
	SfxPlayer.play("abilities/poison_bomb_throw.wav")

func _spawn_poison_pool(pos: Vector2, lvl: int) -> void:
	SfxPlayer.play("abilities/poison_bomb_impact.wav")
	var pool := preload("res://scripts/components/poison_pool.gd").new()
	pool.position = pos
	pool.radius = (55.0 + lvl * 4.0) * area_multiplier()
	pool.tick_damage = 3 + lvl * 2
	pool.lifetime = (4.0 + lvl * 0.5) * duration_multiplier()
	pool.chase_speed = 45.0 if is_evolved("poison_bomb") else 0.0
	pool.game_ref = self
	add_child(pool)

## Hacha Bumerán: thrown at the nearest enemy (or ahead, if none), flies out
## and comes back to the player, hitting on both legs. Torbellino de Acero
## swaps that for a widening spiral around the player.
func _fire_boomerang(lvl: int) -> void:
	var count := 1 + (1 if lvl >= 3 else 0) + (1 if lvl >= 5 else 0) + amount_bonus()
	var target: EmberfallEnemy = nearest_from(enemies, player.global_position, 400.0)
	var aim := player.global_position.direction_to(target.global_position) if target else player.facing_direction
	for i in count:
		var axe := _make_skill_projectile(EmberfallSkillProjectile.Style.AXE, "boomerang")
		axe.direction = aim.rotated(TAU * float(i) / float(count))
		axe.damage = 16 + 6 * lvl
		axe.pierce = -1
		axe.hit_radius = 20.0 * area_multiplier()
		axe.visual_scale = area_multiplier()
		if is_evolved("boomerang"):
			axe.mode = EmberfallSkillProjectile.Mode.SPIRAL
			axe.speed = 300.0 * proj_speed_multiplier()
			axe.lifetime = 2.6 * duration_multiplier()
			axe.rehit_interval = 0.5
		else:
			axe.mode = EmberfallSkillProjectile.Mode.BOOMERANG
			axe.speed = 380.0 * proj_speed_multiplier()
			axe.out_distance = 220.0 * area_multiplier()
			axe.return_target = player
			axe.lifetime = 4.0
		add_child(axe)

## Tajo Sombrío: one wide horizontal cut to both sides at once, so it
## covers the player's flanks no matter where they face.
func _trigger_slash(lvl: int) -> void:
	var half_width := (65.0 + 9.0 * lvl) * area_multiplier()
	var half_height := 24.0 * area_multiplier()
	var hit_damage := 14 + 6 * lvl
	damage_source = "slash"
	SfxPlayer.play("combat/basic_melee.wav")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var offset: Vector2 = enemy.global_position - player.global_position
		if absf(offset.x) > half_width or absf(offset.y) > half_height + 20.0:
			continue
		var hit_pos: Vector2 = enemy.global_position
		var killed := _apply_damage(enemy, hit_damage)
		# Guadaña del Vacío: critical kills burst into nearby enemies.
		if killed and _last_hit_crit and is_evolved("slash"):
			_void_burst(hit_pos, int(hit_damage * 0.6))
	var fx := EmberfallSlashFx.new()
	fx.half_width = half_width
	fx.half_height = half_height
	fx.color = AbilityCatalog.color("slash")
	fx.evolved = is_evolved("slash")
	fx.position = Vector2(0, -6)
	player.add_child(fx)

func _void_burst(at: Vector2, burst_damage: int) -> void:
	var radius := 60.0 * area_multiplier()
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(at) < radius:
			_apply_damage(enemy, burst_damage, false, false)
	_spawn_burst_fx(at, radius, AbilityCatalog.color("slash"))

const METEOR_BASE_RADIUS := 48.0

## Lluvia de Meteoros: lands on enemies near the player when there are any,
## otherwise anywhere close by, always with a visible marker first.
func _trigger_meteors(lvl: int) -> void:
	var count := 1 + (lvl - 1) / 2 + amount_bonus()
	for i in count:
		_spawn_meteor(_meteor_target(), (METEOR_BASE_RADIUS + 4.0 * lvl) * area_multiplier(), 28 + 10 * lvl, 0.7)

func _meteor_target() -> Vector2:
	var nearby := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e.global_position.distance_to(player.global_position) < 320.0)
	if not nearby.is_empty():
		return nearby.pick_random().global_position
	var angle := randf_range(0.0, TAU)
	return player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(60.0, 220.0)

func _spawn_meteor(at: Vector2, radius: float, meteor_damage: int, telegraph: float, cataclysm: bool = false) -> void:
	var meteor := EmberfallMeteorStrike.new()
	meteor.game_ref = self
	meteor.position = at
	meteor.radius = radius
	meteor.damage = meteor_damage
	meteor.telegraph = telegraph
	meteor.burn_duration = 2.0 * duration_multiplier()
	meteor.cataclysm = cataclysm
	add_child(meteor)

## Esquirla Errante: launched in a random direction, ricochets off the
## screen edges. Prisma Infinito splits off two short-lived shards per bounce.
func _fire_shards(lvl: int) -> void:
	for i in 1 + amount_bonus():
		var angle := randf_range(0.0, TAU)
		_spawn_shard(player.global_position, Vector2(cos(angle), sin(angle)), 12 + 5 * lvl, 1 + lvl, 3.5 * duration_multiplier(), true)

func _spawn_shard(at: Vector2, dir: Vector2, shard_damage: int, bounce_count: int, life: float, can_split: bool) -> void:
	var shard := _make_skill_projectile(EmberfallSkillProjectile.Style.SHARD, "shard")
	shard.global_position = at
	shard.mode = EmberfallSkillProjectile.Mode.BOUNCE
	shard.direction = dir
	shard.speed = 420.0 * proj_speed_multiplier()
	shard.damage = shard_damage
	shard.bounces = bounce_count
	shard.lifetime = life
	shard.pierce = -1
	shard.rehit_interval = 0.4
	shard.visual_scale = 1.0 if can_split else 0.6
	if can_split and is_evolved("shard"):
		shard.bounced.connect(_split_shard.bind(shard_damage))
	add_child(shard)

func _split_shard(at: Vector2, dir: Vector2, parent_damage: int) -> void:
	for turn in [-0.6, 0.6]:
		_spawn_shard(at, dir.rotated(turn), parent_damage / 2, 0, 0.9, false)

## Égida Rúnica: recharges one charge at a time; player.damage() spends
## them through try_block() before any heart is lost.
func _tick_aegis(delta: float) -> void:
	var max_charges := 2 if is_evolved("aegis") else 1
	if aegis_charges >= max_charges:
		_aegis_clock = 0.0
		return
	_aegis_clock += delta
	if _aegis_clock >= maxf(4.0, 12.0 - 1.5 * skill_level("aegis")) * cooldown_multiplier():
		_aegis_clock = 0.0
		aegis_charges += 1
		player.queue_redraw()

## Called by player.damage(): Armadura's chance first, then an Égida charge.
## True means the hit is fully negated.
func try_block() -> bool:
	if randf() < armor_block_chance():
		return true
	if aegis_charges <= 0:
		return false
	aegis_charges -= 1
	player.queue_redraw()
	SfxPlayer.play("status/freeze_apply.wav", false)
	var shield_color := AbilityCatalog.color("aegis")
	spawn_ring(player.global_position + Vector2(0, -4), shield_color, 70.0, 0.3, 4.0)
	spawn_sparks(player.global_position + Vector2(0, -4), shield_color, 10, 220.0)
	# Bastión: the breaking shield pushes everything back with a nova.
	if is_evolved("aegis"):
		var radius := 110.0 * area_multiplier()
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(player.global_position) < radius:
				_apply_damage(enemy, 40 + 8 * skill_level("aegis"), true, true, "aegis")
				if is_instance_valid(enemy):
					enemy.knockback(player.global_position.direction_to(enemy.global_position) * 420.0)
		_spawn_burst_fx(player.global_position, radius, EmberfallFx.evolved_color(shield_color))
	return true

func _make_skill_projectile(style: int, id: String) -> EmberfallSkillProjectile:
	var projectile := EmberfallSkillProjectile.new()
	projectile.game_ref = self
	projectile.style = style
	projectile.color = AbilityCatalog.color(id)
	projectile.source_id = id
	projectile.evolved = is_evolved(id)
	projectile.global_position = player.projectile_origin.global_position if is_instance_valid(player.projectile_origin) else player.global_position
	return projectile

## Re-syncs every persistent ability node with the current levels, passives
## and evolutions. Called after any pick, since passives (Área, Amplitud…)
## change them too.
func _refresh_powers() -> void:
	if skills.has("orbital"):
		if not is_instance_valid(_orbital_wave):
			_orbital_wave = preload("res://scripts/components/orbital_wave.gd").new()
			_orbital_wave.game_ref = self
			_orbital_wave.player_node = player
			player.add_child(_orbital_wave)
			SfxPlayer.play("abilities/orbital.wav", false)
		var orbital_level := skill_level("orbital")
		_orbital_wave.moon_count = EmberfallOrbitalWave.MAX_MOONS if is_evolved("orbital") else orbital_level + 1 + amount_bonus()
		_orbital_wave.damage = int((6 + orbital_level * 3) * (1.5 if is_evolved("orbital") else 1.0))
		_orbital_wave.radius_scale = area_multiplier()
		_orbital_wave.knockback_force = 260.0 if is_evolved("orbital") else 0.0
		_orbital_wave.evolved = is_evolved("orbital")
	if skills.has("fire"):
		if not is_instance_valid(_fire_aura):
			_fire_aura = preload("res://scripts/components/persistent_aura.gd").new()
			player.add_child(_fire_aura)
			player.move_child(_fire_aura, 0)
			SfxPlayer.play("abilities/constant_fire_start.wav", false)
		# Re-run on every pick so Área / level / Corona Solar resize the visual.
		_fire_aura.setup(fire_aura_radius(), is_evolved("fire"))
	if skills.has("blizzard") and is_evolved("blizzard") and not is_instance_valid(_perpetual_winter):
		_perpetual_winter = preload("res://scripts/components/frost_zone.gd").new()
		_perpetual_winter.radius = (70.0 + 6.0 * skill_level("blizzard")) * 1.3 * area_multiplier()
		_perpetual_winter.tick_damage = 8 + 3 * skill_level("blizzard")
		_perpetual_winter.freeze_duration = 1.2
		_perpetual_winter.lifetime = INF
		_perpetual_winter.game_ref = self
		_perpetual_winter.evolved = true
		player.add_child(_perpetual_winter)
		player.move_child(_perpetual_winter, 0)
	if skills.has("aegis"):
		if not is_instance_valid(_aegis_bubble):
			_aegis_bubble = EmberfallAegisBubble.new()
			_aegis_bubble.game_ref = self
			player.add_child(_aegis_bubble)
		_aegis_bubble.evolved = is_evolved("aegis")
	if skills.has("familiar"):
		var familiar_level := skill_level("familiar")
		var wanted := 1 + (1 if familiar_level >= 3 else 0) + (1 if familiar_level >= 5 else 0) + (2 if is_evolved("familiar") else 0)
		while _familiars.size() < wanted:
			var familiar := EmberfallSpectralFamiliar.new()
			familiar.game_ref = self
			familiar.player_node = player
			familiar.global_position = player.global_position
			add_child(familiar)
			_familiars.append(familiar)
		for i in _familiars.size():
			_familiars[i].slot = i
			_familiars[i].slot_count = _familiars.size()
			_familiars[i].damage = 8 + 4 * familiar_level
			_familiars[i].evolved = is_evolved("familiar")
			_familiars[i].fire_interval = (0.6 if is_evolved("familiar") else 1.2) * attack_speed_multiplier()

# --- Shared combat helpers ---------------------------------------------------

## Fuego Constante's frame_01/02 are a near-solid disc (unlike frame_00's
## sparse ring); the base radius keeps the aura's footprint inside the
## Lunas' orbit so the two don't fight for the same screen space.
const FIRE_AURA_BASE_RADIUS := 44.0
const FIRE_TICK_INTERVAL := 0.25
## Cadena Eléctrica: bounded to a believable lightning hop.
const CHAIN_JUMP_RANGE := 220.0

## Area burst (bomb, evolution, revive, void burst, Bastión): a filled ring
## out to the hit radius plus sparks, drawn in code like the rest of §8.
func _spawn_burst_fx(pos: Vector2, radius: float, color: Color) -> void:
	spawn_ring(pos, color, radius, 0.4, 5.0, true)
	spawn_ring(pos, Color(1, 1, 1), radius * 0.55, 0.25, 3.0)
	spawn_sparks(pos, color, clampi(int(radius / 10.0), 8, 24), 240.0)

## Basic-attack impact: the shot packs only ship "fly" frames, so this is a
## tiny procedural burst instead — separate from damage (already applied by
## the caller) and separate from the projectile itself (which may keep going
## if it pierces).
func _spawn_impact_flash(pos: Vector2, color: Color) -> void:
	var flash := EmberfallImpactFlash.new()
	flash.position = pos
	flash.color = color
	add_child(flash)

## Cadena Eléctrica: a jagged bolt drawn between the two points.
func _spawn_chain_fx(from: Vector2, to: Vector2) -> void:
	var bolt := EmberfallLightning.new()
	bolt.from = from
	bolt.to = to
	var color := AbilityCatalog.color("chain")
	bolt.color = EmberfallFx.evolved_color(color) if is_evolved("chain") else color
	bolt.thick = 1.3 if is_evolved("chain") else 1.0
	add_child(bolt)

## Hit sparks shared by every ability (one node draws them all).
var sparks: EmberfallSparks

func spawn_sparks(at: Vector2, color: Color, count: int, speed: float = 150.0) -> void:
	if is_instance_valid(sparks):
		sparks.burst(at, color, count, speed)

func spawn_ring(at: Vector2, color: Color, radius: float, lifetime: float = 0.35, width: float = 5.0, fill: bool = false) -> void:
	var ring := EmberfallFxRing.new()
	ring.position = at
	ring.color = color
	ring.radius = radius
	ring.lifetime = lifetime
	ring.width = width
	ring.fill = fill
	add_child(ring)

## Sparks per hit for each ability; the constant ones (aura, pools, orbit)
## hit often, so they spark less.
const HIT_SPARKS := {
	"fire": 1, "orbital": 2, "poison_bomb": 1, "blizzard": 1,
}

## Applies damage to an enemy (rolling crit, consuming Electrocutado) and,
## if it dies, grants kills/loot consistently across every damage source.
## Returns true when this hit killed it.
func _apply_damage(enemy: EmberfallEnemy, amount: int, apply_multiplier: bool = true, can_crit: bool = true, source: String = "") -> bool:
	_last_hit_crit = false
	if not is_instance_valid(enemy) or enemy.dead:
		return false
	var final_amount := float(amount)
	if apply_multiplier:
		final_amount *= damage_multiplier()
	if enemy.is_boss or enemy.elite_tier > 0:
		final_amount *= boss_damage_multiplier()
	final_amount *= enemy.consume_shock()
	if can_crit and randf() < crit_chance():
		_last_hit_crit = true
		final_amount *= crit_multiplier()
	var dealt := int(round(final_amount))
	record_damage(source if source != "" else damage_source, mini(dealt, enemy.hp))
	spawn_damage_number(enemy.global_position, dealt, _last_hit_crit)
	var spark_source := source if source != "" else damage_source
	if AbilityCatalog.is_active(spark_source):
		var spark_color := AbilityCatalog.color(spark_source)
		if is_evolved(spark_source):
			spark_color = EmberfallFx.evolved_color(spark_color)
		spawn_sparks(enemy.global_position, spark_color, int(HIT_SPARKS.get(spark_source, 3)) + (2 if _last_hit_crit else 0))
	SfxPlayer.play_enemy_hit()
	if _last_hit_crit:
		SfxPlayer.play("combat/critical_hit.wav")
	if _last_hit_crit or enemy.is_boss:
		hit_stop(0.035 if enemy.is_boss else 0.03)
	# Small push away from the hero so every hit is felt; heavy foes budge less.
	var push := HIT_PUSH * (0.35 if enemy.elite_tier > 0 or enemy.archetype == EmberfallEnemy.Archetype.TANK else 1.0)
	enemy.knockback(player.global_position.direction_to(enemy.global_position) * push)
	if enemy.damage(dealt):
		_on_enemy_killed(enemy)
		return true
	return false

## Damage per source for the result screen's ranking. `damage_source` is
## the fallback for hits dealt synchronously inside an ability's trigger.
var damage_by_source := {}
var damage_source := "basic"
var _gold_at_start := 0

func gold_this_run() -> int:
	return maxi(0, GameState.gold - _gold_at_start)

func record_damage(source: String, amount: int) -> void:
	if amount > 0:
		damage_by_source[source] = int(damage_by_source.get(source, 0)) + amount

const HIT_PUSH := 150.0
const HIT_STOP_COOLDOWN := 0.25
var _hit_stop_ready_at := 0

## Freezes the game for a few milliseconds (crits, boss hits) so heavy hits
## land with weight. Throttled so a crit-heavy build doesn't stutter.
func hit_stop(duration: float) -> void:
	var now := Time.get_ticks_msec()
	if GameState.reduce_motion or now < _hit_stop_ready_at or Engine.time_scale < 1.0:
		return
	_hit_stop_ready_at = now + int(HIT_STOP_COOLDOWN * 1000.0)
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

## Public so enemy.gd can show numbers for its own poison/burn ticks too,
## keeping every damage source visually consistent.
## Late-game swarms can produce hundreds of hits a second; past this many
## numbers on screen only crits still spawn one.
const DAMAGE_NUMBER_CAP := 45
var _damage_numbers_alive := 0

func spawn_damage_number(pos: Vector2, amount: int, is_crit: bool) -> void:
	if _damage_numbers_alive >= DAMAGE_NUMBER_CAP and not is_crit:
		return
	_damage_numbers_alive += 1
	var number := preload("res://scripts/components/damage_number.gd").new()
	number.tree_exiting.connect(func(): _damage_numbers_alive -= 1)
	number.position = pos + Vector2(randf_range(-10.0, 10.0), -10.0)
	number.amount = amount
	number.is_crit = is_crit
	add_child(number)

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

# --- Enemies and stages -------------------------------------------------------

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
	var angle := randf_range(0.0, TAU)
	_spawn_enemy_at(player.position + Vector2(cos(angle), sin(angle)) * 540.0, _pick_archetype())

func _spawn_enemy_at(at: Vector2, archetype: int, elite_tier: int = 0) -> EmberfallEnemy:
	var enemy := EmberfallEnemy.new()
	enemy.position = at
	enemy.setup(player, (1.0 + elapsed / 90.0) * _difficulty_multiplier(), false, archetype)
	if elite_tier > 0:
		enemy.make_elite(elite_tier)
		if LIGHTING_ENABLED:
			enemy.add_child(make_light(150.0, Color("e8b84a") if elite_tier == 1 else Color("b07cff"), 0.6))
	enemy.game_ref = self
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	add_child(enemy)
	enemies.append(enemy)
	return enemy

# --- Élites, wave events and special drops -------------------------------------

func _tick_events() -> void:
	if boss_spawned:
		return
	if elapsed >= _next_elite_time:
		_next_elite_time = elapsed + randf_range(ELITE_INTERVAL_MIN, ELITE_INTERVAL_MAX)
		spawn_elite(1)
	for i in WAVE_EVENTS.size():
		if i in _events_fired or elapsed < float(WAVE_EVENTS[i]["time"]):
			continue
		_events_fired.append(i)
		run_wave_event(str(WAVE_EVENTS[i]["type"]))

func spawn_elite(tier: int) -> void:
	var angle := randf_range(0.0, TAU)
	var archetype: int = EmberfallEnemy.Archetype.TANK if tier >= 2 else _pick_archetype()
	_spawn_enemy_at(player.position + Vector2.from_angle(angle) * 520.0, archetype, tier)
	if tier >= 2:
		announced.emit("¡Se acerca un mini-jefe!", VIOLET)
		SfxPlayer.play("boss/boss_spawn.wav", false)
	else:
		announced.emit("¡Apareció un élite!", GOLD)

func run_wave_event(kind: String) -> void:
	var chapter := int(GameState.current_stage_context.get("chapter", 1))
	match kind:
		"ring":
			announced.emit("¡Horda!", DANGER)
			var count := 14 + chapter * 2
			var offset := randf() * TAU
			for i in count:
				var at := player.position + Vector2.from_angle(offset + TAU * i / count) * 380.0
				_spawn_enemy_at(at, EmberfallEnemy.Archetype.CHASER)
		"swarm":
			announced.emit("¡Enjambre!", DANGER)
			var from := Vector2.from_angle(randf() * TAU)
			var across := from.orthogonal()
			for i in 10 + chapter * 2:
				var at := player.position + from * 480.0 + across * (i - 5) * 38.0
				_spawn_enemy_at(at, EmberfallEnemy.Archetype.FAST)
		"miniboss":
			spawn_elite(2)

func spawn_pickup(at: Vector2, kind: int) -> void:
	var pickup := EmberfallPickup.new()
	pickup.position = at
	pickup.setup(kind)
	add_child(pickup)
	pickups.append(pickup)

func _roll_small_drop(at: Vector2) -> void:
	var roll := randf() / luck_multiplier()
	if roll < DROP_POTION:
		spawn_pickup(at, EmberfallPickup.Kind.POTION)
	elif roll < DROP_POTION + DROP_MAGNET:
		spawn_pickup(at, EmberfallPickup.Kind.MAGNET)
	elif roll < DROP_POTION + DROP_MAGNET + DROP_BOMB:
		spawn_pickup(at, EmberfallPickup.Kind.BOMB)

func _collect_pickup(pickup: EmberfallPickup) -> void:
	pickups.erase(pickup)
	var at := pickup.global_position
	match pickup.kind:
		EmberfallPickup.Kind.CHEST:
			_open_chest(false)
		EmberfallPickup.Kind.EPIC_CHEST:
			_open_chest(true)
		EmberfallPickup.Kind.POTION:
			player.heal(POTION_HEAL)
			SfxPlayer.play("progression/power_selected.wav", false)
		EmberfallPickup.Kind.MAGNET:
			for orb in orbs:
				if is_instance_valid(orb):
					orb.magnetized = true
			SfxPlayer.play("economy/pickup_xp.wav", false)
		EmberfallPickup.Kind.BOMB:
			_detonate_bomb(at)
	pickup.queue_free()

## Chest: a ready evolution if there is one (common chest stops there), then
## 1-2 upgrades (common) or 2-3 (epic) picked like the level-up cards, plus gold.
func _open_chest(epic: bool) -> void:
	SfxPlayer.play("economy/chest_open.wav", false)
	var gained: Array[String] = []
	for id in skills.keys():
		if can_evolve(id):
			_apply_evolution(id)
			gained.append(AbilityCatalog.display_name(id, true))
			break
	var count := randi_range(2, 3) if epic else (0 if not gained.is_empty() else randi_range(1, 2))
	for i in count:
		var candidates := _upgrade_candidates()
		if candidates.is_empty():
			break
		var pick := _weighted_pick(candidates)
		_apply_upgrade(pick)
		gained.append("%s Nv.%d" % [AbilityCatalog.display_name(pick), ability_level(pick)])
	_refresh_powers()
	var gold := int(round((30 if epic else 15) * gold_multiplier()))
	GameState.add_gold(gold)
	_chests_opened += 1
	var text := "Cofre: " + (", ".join(PackedStringArray(gained)) if not gained.is_empty() else "+%d de oro" % gold)
	announced.emit(text, VIOLET if epic else GOLD)

## Bomba: clears regular enemies on screen; élites and the boss take a chunk.
func _detonate_bomb(at: Vector2) -> void:
	SfxPlayer.play("abilities/area_explosion.wav", false)
	_spawn_burst_fx(at, 260.0, Color("ff9a4a"))
	var half := get_viewport_rect().size * 0.5
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var offset: Vector2 = enemy.global_position - player.global_position
		if absf(offset.x) > half.x or absf(offset.y) > half.y:
			continue
		if enemy.is_boss:
			_apply_damage(enemy, 120, false, false, "bomb")
		elif enemy.elite_tier > 0:
			_apply_damage(enemy, 250, false, false, "bomb")
		else:
			_apply_damage(enemy, enemy.hp, false, false, "bomb")

## Debug-build testing aid, used by the HUD's debug buttons.
func debug_action(action: String) -> void:
	if not OS.is_debug_build():
		return
	match action:
		"boss":
			if not boss_spawned:
				spawn_boss()
		"elite":
			spawn_elite(1)
		"miniboss":
			spawn_elite(2)
		"horde":
			run_wave_event("ring" if randf() < 0.5 else "swarm")
		"drops":
			for i in 3:
				spawn_pickup(player.position + Vector2.from_angle(TAU * i / 3.0) * 90.0, [EmberfallPickup.Kind.POTION, EmberfallPickup.Kind.MAGNET, EmberfallPickup.Kind.BOMB][i])
		"ability_next":
			_debug_show_ability(1)
		"ability_up":
			_debug_level_up_ability()

## Debug: the active being previewed by HAB / NV+.
var _debug_ability_index := -1

## Swaps every active for the next one in the catalog at level 1, so each
## ability can be looked at alone.
func _debug_show_ability(step: int) -> void:
	var ids: Array = AbilityCatalog.ACTIVES.keys()
	_debug_ability_index = posmod(_debug_ability_index + step, ids.size())
	_debug_clear_actives()
	var id := str(ids[_debug_ability_index])
	skills[id] = 1
	_refresh_powers()
	announced.emit("PRUEBA: %s NV. 1" % AbilityCatalog.display_name(id), GOLD)

## Debug: +1 level to the previewed active; past the max it evolves.
func _debug_level_up_ability() -> void:
	if _debug_ability_index < 0:
		_debug_show_ability(1)
		return
	var id := str(AbilityCatalog.ACTIVES.keys()[_debug_ability_index])
	if not skills.has(id):
		return
	if skill_level(id) < AbilityCatalog.MAX_LEVEL:
		skills[id] = skill_level(id) + 1
		announced.emit("PRUEBA: %s NV. %d" % [AbilityCatalog.display_name(id), skill_level(id)], GOLD)
	elif not is_evolved(id):
		_apply_evolution(id)
	_refresh_powers()

func _debug_clear_actives() -> void:
	for id in skills.keys():
		skill_timers.erase(id)
	skills.clear()
	evolved.clear()
	aegis_charges = 0
	for node: Node in [_orbital_wave, _fire_aura, _perpetual_winter, _aegis_bubble]:
		if is_instance_valid(node):
			node.queue_free()
	# queue_free is deferred: drop the references now so _refresh_powers
	# builds fresh nodes this same frame.
	_orbital_wave = null
	_fire_aura = null
	_perpetual_winter = null
	_aegis_bubble = null
	for familiar in _familiars:
		if is_instance_valid(familiar):
			familiar.queue_free()
	_familiars.clear()

# --- Hero basic attack --------------------------------------------------------

const PROJECTILE_SPEED := 520.0
## Tuned so the default (ranged) reach lands past melee/mid-range without
## covering the whole arena — enemies spawn 540px out, so a shot needs to let
## some of them close in first instead of sniping everything on spawn.
const PROJECTILE_BASE_LIFETIME := 1.0
const BASIC_ATTACK_BASE_DAMAGE := 20

## Effective reach of the current hero's basic attack — same speed/lifetime
## math spawn_projectile uses, exposed for the temporary debug range overlay.
func player_attack_range() -> float:
	var hero_data := GameState.get_character_data(GameState.selected_character_id)
	var range_scale := hero_data.attack_range_scale if hero_data != null else 1.0
	return PROJECTILE_SPEED * PROJECTILE_BASE_LIFETIME * range_scale

## The hero's own attack is no longer an ability slot: it grows only with
## passives (Fuerza, Celeridad, Amplitud, Velocidad de proyectil, Crítico)
## and permanent upgrades/equipment.
func spawn_projectile(_from: EmberfallPlayer) -> void:
	# Gate candidates by the real attack range instead of just picking the
	# globally nearest, which read as infinite range.
	var attack_range := player_attack_range()
	var living_enemies := enemies.filter(func(e): return is_instance_valid(e) and not e.dead and e.global_position.distance_to(player.global_position) <= attack_range)
	if living_enemies.is_empty():
		return
	living_enemies.sort_custom(func(a, b):
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position)
	)
	var bonus_damage := GameState.permanent_damage + GameState.get_equipped_bonus("damage")
	var base_damage := BASIC_ATTACK_BASE_DAMAGE + bonus_damage * 2
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
	var shot_count := 1 + amount_bonus()
	var shot_color := hero_data.attack_color if hero_data != null else Color(0.2, 0.95, 0.85)
	var shot_sprite_folder := hero_data.attack_sprite_folder if hero_data != null else ""
	var shot_frame_names := _shot_frame_names(hero_data)
	var origin_pos := player.projectile_origin.global_position if is_instance_valid(player.projectile_origin) else player.position
	for i in mini(shot_count, living_enemies.size()):
		var target: EmberfallEnemy = living_enemies[i]
		var projectile := EmberfallProjectile.new()
		projectile.position = origin_pos
		projectile.setup(target.position, final_damage, shot_color, shot_sprite_folder, shot_range_scale, shot_frame_names)
		projectile.speed = PROJECTILE_SPEED * proj_speed_multiplier()
		projectile.set_meta("hit_enemies", [])
		projectile.set_meta("max_pierces", 0)
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
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.global_position.distance_to(player.global_position) < radius:
			if not _apply_damage(enemy, hit_damage, false):
				_apply_hero_guaranteed_status(enemy)
	var fx := EmberfallProjectile.new()
	fx.position = player.position
	fx.setup(player.position, 0, hero_data.attack_color, hero_data.attack_sprite_folder, 0.4, hero_data.attack_aoe_frame_names, 0.5)
	add_child(fx)

func _process(_delta: float) -> void:
	if GameState.screen != "playing":
		return
	for projectile in projectiles:
		if not is_instance_valid(projectile):
			continue
		var hit_enemies: Array = projectile.get_meta("hit_enemies", [])
		var max_pierces: int = projectile.get_meta("max_pierces", 0)
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.dead and not hit_enemies.has(enemy) and projectile.global_position.distance_to(enemy.global_position) < 34.0:
				hit_enemies.append(enemy)
				projectile.set_meta("hit_enemies", hit_enemies)
				var hit_pos: Vector2 = enemy.global_position
				if not _apply_damage(enemy, projectile.damage_amount, false):
					_apply_hero_guaranteed_status(enemy)
				_spawn_impact_flash(hit_pos, projectile.color)
				if hit_enemies.size() > max_pierces:
					projectile.queue_free()
				break

## HERO-01: ties each mage's element to their own identity instead of luck
## (AUD-05) — Vaelor's fire always burns, Azyren's ice always briefly
## freezes, Orven's poison always poisons.
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
	var bestiary_key := BestiaryCatalog.key_for(enemy)
	_kills_by_type[bestiary_key] = int(_kills_by_type.get(bestiary_key, 0)) + 1
	_spawn_death_fx(enemy)
	if enemy.elite_tier > 0:
		var chest: int = EmberfallPickup.Kind.EPIC_CHEST if enemy.elite_tier >= 2 else EmberfallPickup.Kind.CHEST
		spawn_pickup(enemy.global_position, chest)
		spawn_xp(enemy.global_position + Vector2(24, 0), enemy.xp_value)
		spawn_gold(enemy.global_position + Vector2(-24, 0), enemy.gold_value)
	elif randf() < 0.15:
		spawn_gold(enemy.global_position, enemy.gold_value)
	else:
		spawn_xp(enemy.global_position, enemy.xp_value)
	if enemy.elite_tier == 0 and not enemy.is_boss:
		_roll_small_drop(enemy.global_position)
	if enemy == boss:
		SfxPlayer.play("boss/boss_defeated.wav", false)
		end_run(true)
	else:
		SfxPlayer.play("combat/enemy_death.wav")

## Bosses draw their own art, so their death is a plain big ember burst.
func _spawn_death_fx(enemy: EmberfallEnemy) -> void:
	var fx := EmberfallDeathFx.new()
	fx.position = enemy.global_position
	if enemy.is_boss:
		fx.size = 150.0
		fx.ember = Color("2de1d0")
	else:
		fx.size = enemy.visual_size()
		fx.tint = Color.WHITE if enemy.uses_own_art() else enemy.visual_tint()
		fx.texture = enemy.death_texture()
		fx.flip = enemy.faces_left()
	add_child(fx)

## Past this many orbs on the field, new drops merge into the nearest orb of
## the same kind instead of adding nodes (keeps late game fast and readable).
const ORB_CAP := 120

func spawn_xp(at: Vector2, amount: int) -> void:
	_spawn_orb(at, amount, false)

func spawn_gold(at: Vector2, amount: int) -> void:
	_spawn_orb(at, amount, true)

func _spawn_orb(at: Vector2, amount: int, gold: bool) -> void:
	if orbs.size() >= ORB_CAP and _merge_orb(at, amount, gold):
		return
	var orb := EmberfallXPOrb.new()
	orb.position = at
	orb.setup(amount, gold)
	orb.tree_exiting.connect(_on_orb_removed.bind(orb))
	add_child(orb)
	orbs.append(orb)

func _merge_orb(at: Vector2, amount: int, gold: bool) -> bool:
	var best: EmberfallXPOrb
	var best_distance := INF
	for orb in orbs:
		if not is_instance_valid(orb) or orb.collected or orb.is_gold != gold:
			continue
		var distance: float = orb.global_position.distance_squared_to(at)
		if distance < best_distance:
			best_distance = distance
			best = orb
	if best == null:
		return false
	best.absorb(amount)
	return true

# --- Passive stats --------------------------------------------------------------

func passive_level(id: String) -> int:
	return int(passives.get(id, 0))

## Permanent upgrade level (UpgradeCatalog), bought between runs.
func _up(id: String) -> int:
	return GameState.get_upgrade_level(id)

func pickup_radius() -> float:
	return 80.0 + passive_level("magnet") * 35.0 + _up("magnet") * 20.0 + (60.0 if is_evolved("familiar") else 0.0)

func damage_multiplier() -> float:
	return 1.0 + passive_level("might") * 0.10 + _up("damage") * 0.03

func boss_damage_multiplier() -> float:
	return 1.0 + _up("boss_damage") * 0.10

func xp_multiplier() -> float:
	return 1.0 + _up("growth") * 0.04

func gold_multiplier() -> float:
	return 1.0 + _up("greed") * 0.10

func luck_multiplier() -> float:
	return 1.0 + _up("luck") * 0.25

## Extra seconds of invulnerability after taking a hit (player.gd).
func invuln_bonus() -> float:
	return _up("invuln") * 0.15

## Movement speed is no longer an in-run pick (it moved to permanent
## upgrades); kept so player.gd's movement code needs no special case.
func speed_multiplier() -> float:
	return 1.0

## Half-hearts per second.
func regen_per_second() -> float:
	return passive_level("regen") * 0.1 + _up("regen") * (1.0 / 30.0)

func armor_block_chance() -> float:
	return passive_level("armor") * 0.08 + _up("armor") * 0.03

func crit_chance() -> float:
	return passive_level("crit") * 0.08 + _up("crit") * 0.03

func crit_multiplier() -> float:
	return 1.5 + passive_level("crit") * 0.2

func attack_speed_multiplier() -> float:
	return maxf(0.5, 1.0 - passive_level("haste") * 0.08 - _up("haste") * 0.04)

func cooldown_multiplier() -> float:
	return maxf(0.4, 1.0 - passive_level("cooldown") * 0.08 - _up("cooldown") * 0.03)

func area_multiplier() -> float:
	return 1.0 + passive_level("area") * 0.10 + _up("area") * 0.05

func duration_multiplier() -> float:
	return 1.0 + passive_level("duration") * 0.15 + _up("duration") * 0.08

func amount_bonus() -> int:
	return passive_level("amount") + _up("amount")

func proj_speed_multiplier() -> float:
	return 1.0 + passive_level("proj_speed") * 0.15 + _up("proj_speed") * 0.08

# --- Level-up -------------------------------------------------------------------

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		xp_needed = int(xp_needed * 1.35)
		level += 1
		pending_levels += 1
	if pending_levels > 0 and GameState.screen != "level_up":
		_present_level_up()

## AUD-07: once every slot is full and maxed there may be nothing left to
## offer — showing that screen would leave the player stuck looking at zero
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

## Level shown on a card: the current level of an owned ability, 0 if new.
func ability_level(id: String) -> int:
	return passive_level(id) if AbilityCatalog.is_passive(id) else skill_level(id)

func can_evolve(active_id: String) -> bool:
	if skill_level(active_id) < MAX_ABILITY_LEVEL or is_evolved(active_id):
		return false
	var paired := str(AbilityCatalog.ACTIVES[active_id]["evolution"]["passive"])
	return passive_level(paired) > 0

## Every non-evolution option that could be picked right now, with its
## weight: upgrades of what you already own are 3× as likely as something
## new, so builds come together instead of spreading thin.
func _upgrade_candidates(exclude: Array[String] = []) -> Dictionary:
	var result := {}
	for id in AbilityCatalog.ACTIVES:
		if id in banished or id in exclude:
			continue
		if not skills.has(id) and not GameState.is_ability_unlocked(id):
			continue
		if skills.has(id):
			if skill_level(id) < MAX_ABILITY_LEVEL:
				result[id] = 3.0
		elif skills.size() < AbilityCatalog.ACTIVE_SLOTS:
			result[id] = 1.0
	for id in AbilityCatalog.PASSIVES:
		if id in banished or id in exclude:
			continue
		if passives.has(id):
			if passive_level(id) < MAX_ABILITY_LEVEL:
				result[id] = 3.0
		elif passives.size() < AbilityCatalog.PASSIVE_SLOTS:
			result[id] = 1.0
	return result

## Up to 3 cards: any ready evolution first (golden card), then a weighted
## mix of actives and passives.
func _roll_level_up_options(exclude: Array[String] = []) -> Array[String]:
	var options: Array[String] = []
	for id in skills:
		if can_evolve(id) and options.size() < 3:
			options.append(AbilityCatalog.evolution_option(id))
	var candidates := _upgrade_candidates(exclude)
	while options.size() < 3 and not candidates.is_empty():
		var pick := _weighted_pick(candidates)
		options.append(pick)
		candidates.erase(pick)
	return options

func _weighted_pick(weights: Dictionary) -> String:
	var total := 0.0
	for w in weights.values():
		total += float(w)
	var roll := randf() * total
	for id in weights:
		roll -= float(weights[id])
		if roll <= 0.0:
			return id
	return weights.keys().back()

## The level-up panel's queue_free() is deferred (still alive/clickable for
## the rest of the frame it was freed on), so a fast double-tap on the same
## button can fire this twice before the panel is actually gone. `_choice_locked`
## closes that window; the deferred unlock only re-opens it once this frame
## has fully finished, well before the rebuilt panel could be tapped again.
var _choice_locked := false

func choose_power(option_id: String) -> void:
	if _choice_locked or GameState.screen != "level_up" or option_id not in current_level_up_options:
		return
	_choice_locked = true
	call_deferred("_unlock_choice")
	if AbilityCatalog.is_evolution(option_id):
		_apply_evolution(AbilityCatalog.evolution_source(option_id))
	else:
		SfxPlayer.play("progression/power_selected.wav", false)
		_apply_upgrade(option_id)
	_refresh_powers()
	_finish_level_choice()

## Shared by the level-up cards and the chests. Callers run _refresh_powers().
func _apply_upgrade(id: String) -> void:
	if AbilityCatalog.is_active(id):
		skills[id] = skill_level(id) + 1
	else:
		passives[id] = passive_level(id) + 1
		if id == "vitality":
			player.max_hp += VITALITY_HP
			player.heal(VITALITY_HP)

func _apply_evolution(source: String) -> void:
	evolved.append(source)
	_evolutions_done += 1
	announced.emit("¡Evolución: %s!" % AbilityCatalog.display_name(source, true), GOLD)
	_spawn_burst_fx(player.global_position, 170.0, EmberfallFx.GOLD)
	SfxPlayer.play("progression/fusion_unlocked.wav", false)

const VITALITY_HP := 2 # 1 full heart per pick
const SKIP_HEAL := 1
const SKIP_GOLD := 5

## Saltar: no pick this level, a small heal and some gold instead.
func skip_level_up() -> void:
	if _choice_locked or GameState.screen != "level_up":
		return
	_choice_locked = true
	call_deferred("_unlock_choice")
	player.heal(SKIP_HEAL)
	GameState.add_gold(SKIP_GOLD)
	_finish_level_choice()

func _finish_level_choice() -> void:
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
	current_level_up_options = _roll_level_up_options()
	return true

## Descartar: that option never comes back this run; its card is replaced
## by a fresh one (evolutions can't be banished).
func banish_option(option_id: String) -> bool:
	if banishes <= 0 or GameState.screen != "level_up" or AbilityCatalog.is_evolution(option_id) or option_id not in current_level_up_options:
		return false
	banishes -= 1
	banished.append(option_id)
	var index := current_level_up_options.find(option_id)
	var replacement := _upgrade_candidates(current_level_up_options)
	if replacement.is_empty():
		current_level_up_options.remove_at(index)
	else:
		current_level_up_options[index] = _weighted_pick(replacement)
	if current_level_up_options.is_empty():
		skip_level_up()
	return true

func _on_player_died() -> void:
	if _revives_left > 0:
		_revive()
		return
	end_run(false)

## Revivir (permanent upgrade): back with half health, a short grace window
## and a shockwave that clears some room.
func _revive() -> void:
	_revives_left -= 1
	player.hp = maxi(1, player.max_hp / 2)
	player.invulnerable = 2.5
	player.queue_redraw()
	announced.emit("¡Reviviste!", GOLD)
	SfxPlayer.play("progression/fusion_unlocked.wav", false)
	_spawn_burst_fx(player.global_position, 200.0, EmberfallFx.GOLD)
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var offset: Vector2 = enemy.global_position - player.global_position
		if offset.length() < 200.0:
			enemy.knockback(offset.normalized() * 600.0)

## Every way a run can end goes through here, so lifetime stats (and the
## ability unlocks they drive) are recorded exactly once.
func end_run(victory: bool) -> void:
	if not _run_reported:
		_run_reported = true
		var newly := GameState.record_run({
			"victory": victory, "kills": kills, "level": level, "time": int(elapsed),
			"chests": _chests_opened, "evolutions": _evolutions_done,
			"abilities": skills.keys() + passives.keys(), "evolved": evolved.duplicate(),
			"kills_by_type": _kills_by_type,
		})
		for id in newly:
			announced.emit("¡Nueva habilidad: %s!" % AbilityCatalog.display_name(id), GOLD)
		GameState.last_run_summary = {
			"victory": victory, "kills": kills, "level": level, "time": int(elapsed),
			"chests": _chests_opened, "evolutions": _evolutions_done,
			"gold_collected": maxi(0, GameState.gold - _gold_at_start),
			"damage": damage_by_source.duplicate(),
			"skills": skills.duplicate(), "evolved": evolved.duplicate(),
			"unlocked": newly,
		}
	GameState.finish_run(victory, kills)

func _on_enemy_removed(enemy: EmberfallEnemy) -> void:
	enemies.erase(enemy)

func _on_orb_removed(orb: EmberfallXPOrb) -> void:
	if orb.collected:
		if orb.is_gold:
			GameState.add_gold(int(round(orb.value * gold_multiplier())))
		else:
			add_xp(int(round(orb.value * xp_multiplier())))
	orbs.erase(orb)

func _on_projectile_removed(projectile: EmberfallProjectile) -> void:
	projectiles.erase(projectile)
