extends CanvasLayer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

const POWER_NAMES := {
	"directed": "DISPARO DIRIGIDO",
	"orbital": "ONDA ORBITAL",
	"area": "EXPLOSIÓN DE ÁREA",
	"chain": "CADENA ELÉCTRICA",
	"fire": "FUEGO CONSTANTE",
	"blizzard": "VENTISCA",
	"poison_bomb": "BOMBA VENENOSA",
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
	"blizzard": "Lluvia de escarcha en un punto al azar cerca tuyo: daña y congela",
	"poison_bomb": "Lanza una bomba cerca tuyo que deja un charco venenoso",
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
var hearts: HeartsRow
var boss_label: Label
var boss_bar: ProgressBar
var panel: PanelContainer
var pause_button: Button
var pause_panel: PanelContainer
var _confirm_exit := false

## First-run guidance (PLAY-01): a non-blocking hint that states the goal and
## the control scheme, gone as soon as the player actually moves, plus one
## line on the first level-up screen. Never shown again once GameState marks
## it complete — no modal, no forced reading, just gets out of the way.
var _tutorial_active := false
var _tutorial_hint: Label

func setup(owner: Node) -> void:
	world = owner
	_tutorial_active = not GameState.tutorial_completed
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
	hearts = HeartsRow.new()
	hearts.heart_size = 16.0
	top.add_child(hearts)
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
	boss_label.add_theme_color_override("font_color", UiTheme.DANGER)
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
	joystick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick.direction_changed.connect(_on_joystick)
	add_child(joystick)

	pause_button = Button.new()
	pause_button.text = "⏸"
	pause_button.anchor_left = 1.0; pause_button.anchor_right = 1.0
	pause_button.offset_left = -56; pause_button.offset_right = -16
	pause_button.offset_top = 16; pause_button.offset_bottom = 60
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.theme = UiTheme.make_theme()
	pause_button.pressed.connect(_toggle_pause)
	add_child(pause_button)

	if _tutorial_active:
		_build_tutorial_hint()

func _build_tutorial_hint() -> void:
	_tutorial_hint = Label.new()
	_tutorial_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_hint.anchor_left = 0.5; _tutorial_hint.anchor_right = 0.5
	_tutorial_hint.offset_left = -160; _tutorial_hint.offset_right = 160
	_tutorial_hint.anchor_top = 1.0; _tutorial_hint.anchor_bottom = 1.0
	_tutorial_hint.offset_top = -160; _tutorial_hint.offset_bottom = -100
	_tutorial_hint.add_theme_font_size_override("font_size", 15)
	_tutorial_hint.add_theme_color_override("font_color", UiTheme.TEXT)
	_tutorial_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_tutorial_hint.add_theme_constant_override("shadow_offset_x", 1)
	_tutorial_hint.add_theme_constant_override("shadow_offset_y", 1)
	_tutorial_hint.text = "Sobreviví y derrotá al jefe.\nTocá y arrastrá en cualquier parte de la pantalla para moverte."
	add_child(_tutorial_hint)

func _toggle_pause() -> void:
	if GameState.screen == "playing":
		SfxPlayer.play_ui("ui/pause.wav")
		GameState.change_screen("paused")
	elif GameState.screen == "paused":
		SfxPlayer.play_ui("ui/resume.wav")
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
		_confirm_exit = false
	if GameState.screen not in ["playing", "level_up"]:
		return
	if is_instance_valid(_tutorial_hint) and is_instance_valid(world.player) and world.player.velocity.length_squared() > 400.0:
		_tutorial_hint.queue_free()
		_tutorial_hint = null
	level_label.text = "NV. %d  ·  ELIMINADOS %d" % [world.level, world.kills]
	xp_bar.value = float(world.xp) / float(world.xp_needed) * 100.0
	hearts.set_hearts(world.player.hp, world.player.max_hp)
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

## Full-screen dimmer that also swallows touches, so the joystick underneath
## can't react while a modal panel (level-up / pause) is open. Lives and dies
## with the panel it backs.
func _add_blocker_for(target: Control) -> void:
	var blocker := ColorRect.new()
	blocker.color = Color(0.03, 0.02, 0.07, 0.72)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)
	target.tree_exited.connect(blocker.queue_free)

func show_level_up() -> void:
	panel = PanelContainer.new()
	panel.theme = UiTheme.make_theme()
	panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PURPLE, UiTheme.CORNER, 4))
	_add_blocker_for(panel)
	panel.position = Vector2(20, 190)
	panel.size = Vector2(350, 370)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "¡SUBIR DE NIVEL!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", UiTheme.PURPLE)
	box.add_child(title)
	var category := Label.new()
	category.text = "PASIVAS" if world.current_options_are_boosts else "ACTIVAS"
	category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category.add_theme_font_size_override("font_size", 14)
	category.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(category)
	if _tutorial_active:
		var hint := Label.new()
		hint.text = "Elegí una para mejorar a tu personaje"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		box.add_child(hint)
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
		UiTheme.apply_primary(button)
		button.pressed.connect(_choose.bind(power))
		list.add_child(button)
		var desc := Label.new()
		desc.text = str(POWER_DESCRIPTIONS.get(power, ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		list.add_child(desc)
	var reroll := Button.new()
	reroll.text = "CAMBIAR OPCIONES  (%d)" % world.rerolls
	reroll.disabled = world.rerolls <= 0
	reroll.pressed.connect(_reroll)
	box.add_child(reroll)
	add_child(panel)

func _choose(power: String) -> void:
	world.choose_power(power)
	if _tutorial_active:
		_tutorial_active = false
		GameState.mark_tutorial_completed()
	if is_instance_valid(panel):
		panel.queue_free()
		panel = null

func _on_joystick(value: Vector2) -> void:
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.touch_direction = value

func _reroll() -> void:
	if world.reroll_power_choices():
		SfxPlayer.play_ui("ui/ui_select.wav")
		panel.queue_free()
		panel = null

func show_pause_panel() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.theme = UiTheme.make_theme()
	pause_panel.add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.PURPLE, UiTheme.CORNER, 4))
	_add_blocker_for(pause_panel)
	pause_panel.anchor_left = 0.5; pause_panel.anchor_right = 0.5
	pause_panel.anchor_top = 0.5; pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -140; pause_panel.offset_right = 140
	pause_panel.offset_top = -220; pause_panel.offset_bottom = 220
	pause_panel.custom_minimum_size = Vector2(280, 440)
	add_child(pause_panel)
	_build_pause_content()

func _build_pause_content() -> void:
	for child in pause_panel.get_children():
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pause_panel.add_child(box)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UiTheme.PURPLE)
	box.add_child(title)
	if _confirm_exit:
		title.text = "¿SALIR?"
		var warning := Label.new()
		warning.text = "Perdés el progreso de esta partida."
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		box.add_child(warning)
		var confirm := Button.new()
		confirm.text = "SÍ, SALIR"
		confirm.custom_minimum_size = Vector2(0, 52)
		confirm.add_theme_color_override("font_color", UiTheme.DANGER)
		confirm.pressed.connect(_exit_run)
		box.add_child(confirm)
		var cancel := Button.new()
		cancel.text = "CANCELAR"
		cancel.custom_minimum_size = Vector2(0, 52)
		cancel.pressed.connect(func():
			_confirm_exit = false
			_build_pause_content()
		)
		box.add_child(cancel)
	else:
		title.text = "PAUSA"
		var fusion_title := Label.new()
		fusion_title.text = "FUSIONES"
		fusion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fusion_title.add_theme_font_size_override("font_size", 14)
		fusion_title.add_theme_color_override("font_color", UiTheme.ACCENT)
		box.add_child(fusion_title)
		var fusion_scroll := ScrollContainer.new()
		fusion_scroll.custom_minimum_size = Vector2(0, 160)
		fusion_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(fusion_scroll)
		var fusion_list := VBoxContainer.new()
		fusion_list.add_theme_constant_override("separation", 8)
		fusion_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fusion_scroll.add_child(fusion_list)
		for fusion_name in world.FUSION_RECIPES:
			fusion_list.add_child(_build_fusion_row(fusion_name))
		var resume := Button.new()
		resume.text = "REANUDAR"
		resume.custom_minimum_size = Vector2(0, 52)
		UiTheme.apply_primary(resume)
		resume.pressed.connect(_toggle_pause)
		box.add_child(resume)
		var exit := Button.new()
		exit.text = "SALIR"
		exit.custom_minimum_size = Vector2(0, 52)
		exit.pressed.connect(func():
			_confirm_exit = true
			_build_pause_content()
		)
		box.add_child(exit)

func _build_fusion_row(fusion_name: String) -> Control:
	var unlocked: bool = world.fusions.has(fusion_name)
	var pair: Array = world.FUSION_RECIPES[fusion_name]
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = ("✓ " if unlocked else "🔒 ") + fusion_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UiTheme.ACCENT if unlocked else UiTheme.TEXT_MUTED)
	row.add_child(label)
	if not unlocked:
		var req := Label.new()
		var level_a: int = world.ability_level(pair[0])
		var level_b: int = world.ability_level(pair[1])
		req.text = "%s Nv.%d/%d  +  %s Nv.%d/%d" % [
			str(POWER_NAMES.get(pair[0], pair[0])), level_a, world.FUSION_LEVEL_REQUIRED,
			str(POWER_NAMES.get(pair[1], pair[1])), level_b, world.FUSION_LEVEL_REQUIRED,
		]
		req.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		req.add_theme_font_size_override("font_size", 9)
		req.add_theme_color_override("font_color", Color("8a7d9c"))
		row.add_child(req)
	return row

func _exit_run() -> void:
	if is_instance_valid(world):
		GameState.change_screen("playing")
		GameState.finish_run(false, world.kills)
