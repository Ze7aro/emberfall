extends CanvasLayer

const POWER_NAMES := {
	"directed": "DISPARO DIRIGIDO",
	"orbital": "ONDA ORBITAL",
	"area": "EXPLOSIÓN DE ÁREA",
	"chain": "CADENA ELÉCTRICA",
	"fire": "FUEGO CONSTANTE",
	"piercing": "PERFORACIÓN",
	"magnetism": "MAGNETISMO",
	"boost_damage": "MÁS DAÑO",
	"boost_health": "MÁS VIDA",
	"boost_speed": "MÁS VELOCIDAD",
	"boost_regen": "REGENERACIÓN",
	"poison_chance": "VENENO",
	"burn_chance": "QUEMADURA",
	"freeze_chance": "CONGELAMIENTO",
	"extra_projectile": "PROYECTIL EXTRA",
	"crit_chance": "PROBABILIDAD DE CRÍTICO",
	"crit_damage": "DAÑO CRÍTICO",
	"attack_speed": "VELOCIDAD DE ATAQUE",
	"cooldown_reduction": "REDUCCIÓN DE ENFRIAMIENTO",
	"ability_duration": "DURACIÓN",
}

const POWER_DESCRIPTIONS := {
	"directed": "Disparo automático: más daño y velocidad de ataque",
	"orbital": "Ondas de energía alrededor tuyo cada pocos segundos",
	"area": "Explosión que golpea a todo lo que esté cerca tuyo",
	"chain": "Rayo que salta entre varios enemigos cercanos",
	"fire": "Quema constantemente a los enemigos que tengas cerca",
	"piercing": "Tu disparo automático atraviesa más enemigos",
	"magnetism": "Aumenta la distancia a la que recogés oro y experiencia",
	"boost_damage": "Aumenta el daño de todos tus ataques",
	"boost_health": "Aumenta tu vida máxima y te cura esa cantidad",
	"boost_speed": "Aumenta tu velocidad de movimiento",
	"boost_regen": "Regenerás vida automáticamente cada segundo",
	"poison_chance": "Probabilidad de envenenar al golpear: daño por segundo",
	"burn_chance": "Probabilidad de quemar al golpear: daño por segundo",
	"freeze_chance": "Probabilidad de congelar al golpear: ralentiza al enemigo",
	"extra_projectile": "Tu disparo automático lanza un proyectil adicional",
	"crit_chance": "Aumenta la probabilidad de golpe crítico",
	"crit_damage": "Aumenta el daño extra de tus golpes críticos",
	"attack_speed": "Aumenta la velocidad de tu disparo automático",
	"cooldown_reduction": "Reduce el tiempo de reutilización de tus habilidades activas",
	"ability_duration": "Aumenta la duración de veneno, quemadura y congelamiento",
}

var world: Node
var xp_bar: ProgressBar
var level_label: Label
var timer_label: Label
var hp_bar: ProgressBar
var boss_label: Label
var boss_bar: ProgressBar
var panel: PanelContainer
var pause_button: Button
var pause_panel: PanelContainer

func setup(owner: Node) -> void:
	world = owner
	var top := VBoxContainer.new()
	top.position = Vector2(16, 16)
	top.size = Vector2(358, 88)
	add_child(top)
	level_label = Label.new()
	level_label.add_theme_font_size_override("font_size", 16)
	top.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 14)
	top.add_child(xp_bar)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 10)
	top.add_child(hp_bar)
	timer_label = Label.new()
	timer_label.position = Vector2(16, 118)
	timer_label.add_theme_font_size_override("font_size", 16)
	add_child(timer_label)
	boss_label = Label.new()
	boss_label.position = Vector2(0, 20)
	boss_label.anchor_left = 0.5; boss_label.anchor_right = 0.5
	boss_label.offset_left = -140; boss_label.offset_right = 140
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "¡JEFE!"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", Color("e65a5a"))
	boss_label.visible = false
	add_child(boss_label)
	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.5; boss_bar.anchor_right = 0.5
	boss_bar.offset_left = -140; boss_bar.offset_right = 140
	boss_bar.position.y = 48
	boss_bar.custom_minimum_size = Vector2(280, 14)
	boss_bar.visible = false
	add_child(boss_bar)
	var joystick: Control = load("res://scripts/components/virtual_joystick.gd").new()
	joystick.position = Vector2(12, 650)
	joystick.size = Vector2(170, 170)
	joystick.direction_changed.connect(_on_joystick)
	add_child(joystick)

	pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.anchor_left = 1.0; pause_button.anchor_right = 1.0
	pause_button.offset_left = -56; pause_button.offset_right = -16
	pause_button.offset_top = 16; pause_button.offset_bottom = 60
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.pressed.connect(_toggle_pause)
	add_child(pause_button)

func _toggle_pause() -> void:
	if GameState.screen == "playing":
		GameState.change_screen("paused")
	elif GameState.screen == "paused":
		GameState.change_screen("playing")

func _process(_delta: float) -> void:
	if not is_instance_valid(world):
		return
	pause_button.visible = GameState.screen == "playing"
	if GameState.screen == "paused" and not pause_panel:
		show_pause_panel()
	if GameState.screen != "paused" and pause_panel:
		pause_panel.queue_free()
		pause_panel = null
	if GameState.screen not in ["playing", "level_up"]:
		return
	level_label.text = "NV. %d  ·  ELIMINADOS %d" % [world.level, world.kills]
	xp_bar.value = float(world.xp) / float(world.xp_needed) * 100.0
	hp_bar.value = float(world.player.hp) / float(world.player.max_hp) * 100.0
	timer_label.text = "%02d:%02d" % [int(world.elapsed) / 60, int(world.elapsed) % 60]
	var boss_alive: bool = is_instance_valid(world.boss)
	boss_label.visible = boss_alive
	boss_bar.visible = boss_alive
	if boss_alive:
		boss_bar.value = float(world.boss.hp) / float(world.boss.max_hp) * 100.0
	if GameState.screen == "level_up" and not panel:
		show_level_up()
	if GameState.screen != "level_up" and panel:
		panel.queue_free()
		panel = null

func show_level_up() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(20, 190)
	panel.size = Vector2(350, 370)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "¡SUBIR DE NIVEL!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	box.add_child(title)
	var category := Label.new()
	category.text = "PASIVAS" if world.current_options_are_boosts else "ACTIVAS"
	category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category.add_theme_font_size_override("font_size", 14)
	category.add_theme_color_override("font_color", Color("20e6bd"))
	box.add_child(category)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for power in world.current_level_up_options:
		var button := Button.new()
		var level: int = world.ability_level(power)
		button.text = "%s  (NV. %d/%d)" % [str(POWER_NAMES.get(power, power)), level, world.MAX_ABILITY_LEVEL]
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_choose.bind(power))
		list.add_child(button)
		var desc := Label.new()
		desc.text = str(POWER_DESCRIPTIONS.get(power, ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color("9b8eaa"))
		list.add_child(desc)
	var reroll := Button.new()
	reroll.text = "CAMBIAR OPCIONES  (%d)" % world.rerolls
	reroll.disabled = world.rerolls <= 0
	reroll.pressed.connect(_reroll)
	box.add_child(reroll)
	add_child(panel)

func _choose(power: String) -> void:
	world.choose_power(power)
	if is_instance_valid(panel):
		panel.queue_free()
		panel = null

func _on_joystick(value: Vector2) -> void:
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.touch_direction = value

func _reroll() -> void:
	if world.reroll_power_choices():
		panel.queue_free()
		panel = null

func show_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.anchor_left = 0.5; pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5; pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -130; pause_panel.offset_right = 130
	pause_panel.offset_top = -100; pause_panel.offset_bottom = 100
	pause_panel.custom_minimum_size = Vector2(260, 200)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pause_panel.add_child(box)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var resume := Button.new()
	resume.text = "REANUDAR"
	resume.custom_minimum_size = Vector2(0, 52)
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)
	var exit := Button.new()
	exit.text = "SALIR"
	exit.custom_minimum_size = Vector2(0, 52)
	exit.pressed.connect(_exit_run)
	box.add_child(exit)
	add_child(pause_panel)

func _exit_run() -> void:
	if is_instance_valid(world):
		GameState.change_screen("playing")
		GameState.finish_run(false, world.kills)
