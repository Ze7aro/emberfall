extends Node2D

const SESSION_TIME := 180.0
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
var pending_levels := 0
var overlay: Control
var rerolls := 2
var fusions: Array[String] = []
var skill_timers := {"orbital": 0.0, "area": 0.0, "chain": 0.0, "fire": 0.0}

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
	if elapsed >= SESSION_TIME:
		GameState.finish_run(true, kills)
		return
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

func update_powers(delta: float) -> void:
	for key in skill_timers:
		skill_timers[key] = float(skill_timers[key]) + delta
	if int(skills.get("orbital", 0)) > 0 and skill_timers["orbital"] >= 0.35:
		skill_timers["orbital"] = 0.0
		var orbit_radius := 82.0
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < orbit_radius:
				enemy.damage(10 + int(skills["orbital"]) * 5)
	if int(skills.get("area", 0)) > 0 and skill_timers["area"] >= 2.4:
		skill_timers["area"] = 0.0
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < 120.0:
				enemy.damage(16 + int(skills["area"]) * 8)
	if int(skills.get("chain", 0)) > 0 and skill_timers["chain"] >= 2.0:
		skill_timers["chain"] = 0.0
		var remaining := enemies.duplicate()
		var origin := player.global_position
		for i in mini(2 + int(skills["chain"]), remaining.size()):
			var target: EmberfallEnemy = nearest_from(remaining, origin)
			if not target:
				break
			target.damage(20 + int(skills["chain"]) * 8)
			origin = target.global_position
			remaining.erase(target)
	if int(skills.get("fire", 0)) > 0 and skill_timers["fire"] >= 0.5:
		skill_timers["fire"] = 0.0
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < 105.0:
				enemy.damage(4 + int(skills["fire"]) * 3)

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
	enemy.tree_exiting.connect(_on_enemy_removed.bind(enemy))
	add_child(enemy)
	enemies.append(enemy)

func spawn_projectile(_from: EmberfallPlayer) -> void:
	var target: EmberfallEnemy = nearest_enemy()
	if not target:
		return
	var projectile := EmberfallProjectile.new()
	projectile.position = player.position
	projectile.setup(target.position, 20 + GameState.permanent_damage * 2)
	projectile.tree_exiting.connect(_on_projectile_removed.bind(projectile))
	add_child(projectile)
	projectiles.append(projectile)
	# Simple reusable directed shot collision check.
	projectile.set_meta("target", target)
	projectile.set_meta("game", self)

func _process(_delta: float) -> void:
	if GameState.screen != "playing":
		return
	for projectile in projectiles.duplicate():
		if not is_instance_valid(projectile):
			continue
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and not enemy.dead and projectile.global_position.distance_to(enemy.global_position) < 34.0:
				if enemy.damage(projectile.damage_amount):
					kills += 1
					spawn_xp(enemy.global_position, enemy.xp_value)
				projectile.queue_free()
				break

func spawn_xp(at: Vector2, amount: int) -> void:
	var orb := EmberfallXPOrb.new()
	orb.position = at
	orb.setup(amount)
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
	return 80.0 + skills.get("magnetism", 0) * 35.0

func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		xp_needed = int(xp_needed * 1.35)
		level += 1
		pending_levels += 1
	if pending_levels > 0:
		GameState.change_screen("level_up")

func choose_power(power_id: String) -> void:
	skills[power_id] = int(skills.get(power_id, 0)) + 1
	check_fusions()
	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels == 0:
		GameState.change_screen("playing")

func reroll_power_choices() -> bool:
	if rerolls <= 0 or GameState.screen != "level_up":
		return false
	rerolls -= 1
	return true

func check_fusions() -> void:
	var candidates := {
		"Tormenta de Ceniza": ["area", "fire"],
		"Corona del Trueno": ["orbital", "chain"],
		"Lanza del Eclipse": ["directed", "piercing"],
		"Horizonte Magnético": ["area", "magnetism"],
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
