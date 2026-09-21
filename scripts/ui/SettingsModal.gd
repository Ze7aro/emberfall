extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

func _ready() -> void:
	theme = UiTheme.make_theme()
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -150; offset_right = 150; offset_top = -130; offset_bottom = 130
	custom_minimum_size = Vector2(300, 260)
	add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.BORDER, 6, 4))
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

	var title := Label.new()
	title.text = "CONFIGURACIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(title)

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

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var close := Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)
