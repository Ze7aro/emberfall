extends Node2D

const BOSS_TIME := 720.0
const POWER_IDS: Array[String] = ["directed", "orbital", "area", "chain", "fire", "piercing"]
const BOOST_IDS: Array[String] = ["boost_damage", "boost_health", "boost_speed", "boost_regen", "magnetism", "poison_chance", "burn_chance", "freeze_chance", "extra_projectile", "crit_chance", "crit_damage", "attack_speed", "cooldown_reduction", "ability_duration"]
const BOOST_HEALTH_AMOUNT := 20
const MAX_ABILITY_LEVEL := 6

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
var skills: Dictionary = {"directed": 1}
var boosts: Dictionary = {
	"boost_damage": 0, "boost_health": 0, "boost_speed": 0, "boost_regen": 0, "magnetism": 0,
	"poison_chance": 0, "burn_chance": 0, "freeze_chance": 0, "extra_projectile": 0, "crit_chance": 0, "crit_damage": 0,
	"attack_speed": 0, "cooldown_reduction": 0, "ability_duration": 0,
}
var pending_levels := 0
var overlay: Control
var rerolls := 2
var fusions: Array[String] = []
var skill_timers := {"orbital": 0.0, "area": 0.0, "chain": 0.0, "fire": 0.0}
var boss: EmberfallEnemy
var boss_spawned := false
## Alternates the level-up screen between offering powers or boosts, one at a time.
var current_options_are_boosts := false
var current_level_up_options: Array[String] = []

func _ready() -> void:
	GameState.change_screen("playing")
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
	if not boss_spawned and elapsed >= BOSS_TIME:
		spawn_boss()
	spawn_clock += delta
	if spawn_clock >= spawn_interval:
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
	boss = EmberfallEnemy.new()
	var angle := randf_range(0.0, TAU)
	boss.position = player.position + Vector2(cos(angle), sin(angle)) * 460.0
	boss.setup(player, 1.0 + elapsed / 90.0, true)
	boss.game_ref = self
	boss.tree_exiting.connect(_on_enemy_removed.bind(boss))
	add_child(boss)
	enemies.append(boss)

func update_powers(delta: float) -> void:
	for key in skill_timers:
		skill_timers[key] = float(skill_timers[key]) + delta
	var cooldown := cooldown_multiplier()
	if int(skills.get("orbital", 0)) > 0 and skill_timers["orbital"] >= 0.35 * cooldown:
		skill_timers["orbital"] = 0.0
		var orbit_radius := 82.0
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < orbit_radius:
				_apply_damage(enemy, 10 + int(skills["orbital"]) * 5)
	if int(skills.get("area", 0)) > 0 and skill_timers["area"] >= 2.4 * cooldown:
		skill_timers["area"] = 0.0
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < 120.0:
				_apply_damage(enemy, 16 + int(skills["area"]) * 8)
	if int(skills.get("chain", 0)) > 0 and skill_timers["chain"] >= 2.0 * cooldown:
		skill_timers["chain"] = 0.0
		var remaining := enemies.duplicate()
		var origin := player.global_position
		for i in mini(2 + int(skills["chain"]), remaining.size()):
			var target: EmberfallEnemy = nearest_from(remaining, origin)
			if not target:
				break
			_apply_damage(target, 20 + int(skills["chain"]) * 8)
			origin = target.global_position
			remaining.erase(target)
	if int(skills.get("fire", 0)) > 0 and skill_timers["fire"] >= 0.5 * cooldown:
		skill_timers["fire"] = 0.0
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < 105.0:
				_apply_damage(enemy, 4 + int(skills["fire"]) * 3)

## Applies damage to an enemy (rolling crit + status effects) and, if it
## dies, grants kills/loot consistently across every damage source
## (projectiles and ability ticks alike).
func _apply_damage(enemy: EmberfallEnemy, amount: int, apply_multiplier: bool = true) -> void:
	if not is_instance_valid(enemy):
		return
	var final_amount := amount
	if apply_multiplier:
		final_amount = int(round(final_amount * damage_multiplier()))
	if randf() < crit_chance():
		final_amount = int(round(final_amount * crit_multiplier()))
	if enemy.damage(final_amount):
		_on_enemy_killed(enemy)
		return
	_maybe_apply_status(enemy)

func _maybe_apply_status(enemy: EmberfallEnemy) -> void:
	var duration := duration_multiplier()
	if randf() < poison_chance():
		enemy.apply_poison(3.0 * duration, 4 + int(boosts.get("poison_chance", 0)))
	if randf() < burn_chance():
		enemy.apply_burn(3.0 * duration, 4 + int(boosts.get("burn_chance", 0)))
	if randf() < freeze_chance():
		enemy.apply_freeze(1.5 * duration)

func nearest_from(pool: Array, origin: Vector2) -> EmberfallEnemy:
	var result: EmberfallEnemy
	var best := INF
	for enemy in pool:
		if is_instance_valid(enemy) and not enemy.dead:
			var distance := origin.distance_squared_to(enemy.global_position)
			if distance < best:
				best = distance
				result = enemy
	return result

func spawn_enemy() -> void:
	var enemy := EmberfallEnemy.new()
	var angle := randf_range(0.0, TAU)
	enemy.position = player.position + Vector2(cos(angle), sin(angle)) * 540.0
	enemy.setup(player, 1.0 + elapsed / 90.0)
	enemy.game_ref = self
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	add_child(enemy)
	enemies.append(enemy)

func spawn_projectile(_from: EmberfallPlayer) -> void:
	var living_enemies := enemies.filter(func(e): return is_instance_valid(e) and not e.dead)
	if living_enemies.is_empty():
		return
	living_enemies.sort_custom(func(a, b):
		return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position)
	)
	var directed_level := int(skills.get("directed", 1))
	var bonus_damage := GameState.permanent_damage + GameState.get_equipped_bonus("damage")
	var base_damage := 20 + bonus_damage * 2 + (directed_level - 1) * 6
	var final_damage := int(round(base_damage * damage_multiplier()))
	var shot_count := 1 + int(boosts.get("extra_projectile", 0))
	for i in mini(shot_count, living_enemies.size()):
		var target: EmberfallEnemy = living_enemies[i]
		var projectile := EmberfallProjectile.new()
		projectile.position = player.position
		projectile.setup(target.position, final_damage)
		projectile.set_meta("hit_enemies", [])
		projectile.set_meta("max_pierces", int(skills.get("piercing", 0)))
		projectile.tree_exiting.connect(_on_projectile_removed.bind(projectile))
		add_child(projectile)
		projectiles.append(projectile)

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
				if hit_enemies.size() > max_pierces:
					projectile.queue_free()
				break

## Grants the kill, drops gold OR xp (never both), and ends the run in
## victory once the stage boss falls.
func _on_enemy_killed(enemy: EmberfallEnemy) -> void:
	kills += 1
	if randf() < 0.5:
		spawn_gold(enemy.global_position, enemy.gold_value)
	else:
		spawn_xp(enemy.global_position, enemy.xp_value)
	if enemy == boss:
		GameState.finish_run(true, kills)

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

func nearest_enemy() -> EmberfallEnemy:
	var result: EmberfallEnemy
	var best := INF
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead:
			var distance := player.global_position.distance_squared_to(enemy.global_position)
			if distance < best:
				best = distance
				result = enemy
	return result

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
		current_level_up_options = _roll_level_up_options()
		GameState.change_screen("level_up")

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

func choose_power(power_id: String) -> void:
	if ability_level(power_id) >= MAX_ABILITY_LEVEL:
		return
	if power_id in BOOST_IDS:
		boosts[power_id] = int(boosts.get(power_id, 0)) + 1
		if power_id == "boost_health":
			player.max_hp += BOOST_HEALTH_AMOUNT
			player.hp += BOOST_HEALTH_AMOUNT
	else:
		skills[power_id] = int(skills.get(power_id, 0)) + 1
		check_fusions()
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels == 0:
		GameState.change_screen("playing")
	else:
		current_level_up_options = _roll_level_up_options()

func reroll_power_choices() -> bool:
	if rerolls <= 0 or GameState.screen != "level_up":
		return false
	rerolls -= 1
	# Reroll within the same kind currently on offer, not a fresh flip.
	current_level_up_options = _roll_level_up_options(false)
	return true

func check_fusions() -> void:
	var candidates := {
		"Tormenta de Ceniza": ["area", "fire"],
		"Corona del Trueno": ["orbital", "chain"],
		"Lanza del Eclipse": ["directed", "piercing"],
		"Horizonte Magnético": ["area", "piercing"],
		"Tempestad Ígnea": ["chain", "fire"]
	}
	for name in candidates:
		var pair: Array = candidates[name]
		if int(skills.get(pair[0], 0)) >= 5 and int(skills.get(pair[1], 0)) >= 5 and not fusions.has(name):
			fusions.append(name)

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
	draw_rect(Rect2(-900, -900, 1800, 1800), Color("101a2b"))
	for x in range(-800, 801, 80):
		draw_line(Vector2(x, -800), Vector2(x, 800), Color(0.12, 0.30, 0.34, 0.14), 1.0)
	for y in range(-800, 801, 80):
		draw_line(Vector2(-800, y), Vector2(800, y), Color(0.12, 0.30, 0.34, 0.14), 1.0)
