extends PanelContainer

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(300, 260)
	add_theme_stylebox_override("panel", _panel_style())
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
	title.text = "AJUSTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
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

	var close := Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d1d")
	style.border_color = Color("4e3a68")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	return style
