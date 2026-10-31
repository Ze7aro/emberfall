extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

func _ready() -> void:
	theme = UiTheme.make_theme()
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -165; offset_right = 165; offset_top = -240; offset_bottom = 240
	custom_minimum_size = Vector2(330, 480)
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	box.add_child(UiTheme.header("CONFIGURACIÓN", "AJUSTA TU EXPERIENCIA", 26))
	box.add_child(UiTheme.section_title("AUDIO"))

	var music := CheckButton.new()
	music.text = "MÚSICA"
	music.button_pressed = GameState.music_enabled
	music.toggled.connect(GameState.set_music_enabled)
	box.add_child(music)

	var effects := CheckButton.new()
	effects.text = "EFECTOS DE SONIDO"
	effects.button_pressed = GameState.effects_enabled
	effects.toggled.connect(GameState.set_effects_enabled)
	box.add_child(effects)

	box.add_child(UiTheme.section_title("JUEGO"))

	var vibration := CheckButton.new()
	vibration.text = "VIBRACIÓN"
	vibration.button_pressed = GameState.vibration_enabled
	vibration.toggled.connect(GameState.set_vibration_enabled)
	box.add_child(vibration)

	var motion := CheckButton.new()
	motion.text = "REDUCIR TEMBLOR Y DESTELLOS"
	motion.button_pressed = GameState.reduce_motion
	motion.toggled.connect(GameState.set_reduce_motion)
	box.add_child(motion)

	var joystick_row := HBoxContainer.new()
	joystick_row.add_theme_constant_override("separation", 10)
	var joystick_label := Label.new()
	joystick_label.text = "JOYSTICK"
	joystick_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	joystick_row.add_child(joystick_label)
	var joystick := OptionButton.new()
	for option in ["CHICO", "NORMAL", "GRANDE"]:
		joystick.add_item(option)
	joystick.select(GameState.joystick_size)
	joystick.custom_minimum_size = Vector2(120, 40)
	joystick.item_selected.connect(GameState.set_joystick_size)
	joystick_row.add_child(joystick)
	box.add_child(joystick_row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var close := Button.new()
	close.text = "CERRAR"
	close.icon = load("res://assets/ui/pixel_simple_v1/icons/close.png") as Texture2D
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)
