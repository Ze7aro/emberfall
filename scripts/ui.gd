extends CanvasLayer

var world: Node
var xp_bar: ProgressBar
var level_label: Label
var timer_label: Label
var hp_bar: ProgressBar
var panel: PanelContainer

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
	var joystick := load("res://scripts/components/virtual_joystick.gd").new()
	joystick.position = Vector2(12, 650)
	joystick.size = Vector2(170, 170)
	joystick.direction_changed.connect(_on_joystick)
	add_child(joystick)

func _process(_delta: float) -> void:
	if not is_instance_valid(world) or GameState.screen not in ["playing", "level_up"]:
		return
	level_label.text = "NV. %d  ·  ELIMINADOS %d" % [world.level, world.kills]
	xp_bar.value = float(world.xp) / float(world.xp_needed) * 100.0
	hp_bar.value = float(world.player.hp) / float(world.player.max_hp) * 100.0
	timer_label.text = "%02d:%02d" % [int(world.elapsed) / 60, int(world.elapsed) % 60]
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
	title.text = "¡SUBIR DE NIVEL!  (REROLLS: %d)" % world.rerolls
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	box.add_child(title)
	for power in ["directed", "orbital", "area", "chain", "fire", "piercing", "magnetism"]:
		var button := Button.new()
		button.text = power.to_upper()
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_choose.bind(power))
		box.add_child(button)
	var reroll := Button.new()
	reroll.text = "CAMBIAR OPCIONES"
	reroll.disabled = world.rerolls <= 0
	reroll.pressed.connect(_reroll)
	box.add_child(reroll)
	add_child(panel)

func _choose(power: String) -> void:
	world.choose_power(power)

func _on_joystick(value: Vector2) -> void:
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.touch_direction = value

func _reroll() -> void:
	if world.reroll_power_choices():
		panel.queue_free()
		panel = null
