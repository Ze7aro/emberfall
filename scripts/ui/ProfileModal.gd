extends PanelContainer

signal closed

var _xp_bar: ProgressBar

func _ready() -> void:
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -150; offset_right = 150; offset_top = -180; offset_bottom = 180
	custom_minimum_size = Vector2(300, 360)
	add_theme_stylebox_override("panel", _panel_style())
	_build()
	GameState.level_changed.connect(_on_level_changed)
	GameState.experience_changed.connect(_on_experience_changed)
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.gems_changed.connect(_on_gems_changed)

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	tabs.add_child(_build_profile_tab())
	tabs.add_child(_build_settings_tab())

	var close := Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)

func _build_profile_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "PERFIL"
	tab.add_theme_constant_override("separation", 12)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "NIVEL %d" % GameState.level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	tab.add_child(level_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size.y = 14
	_xp_bar.max_value = max(GameState.experience_to_next, 1)
	_xp_bar.value = GameState.experience
	tab.add_child(_xp_bar)

	var stats := GridContainer.new()
	stats.name = "GridContainer"
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 16)
	stats.add_theme_constant_override("v_separation", 8)
	tab.add_child(stats)
	_add_stat(stats, "ORO", str(GameState.gold), "GoldValue")
	_add_stat(stats, "JOYAS", str(GameState.gems), "GemsValue")
	_add_stat(stats, "RÉCORD DE ELIMINACIONES", str(GameState.high_score), "")
	return tab

func _build_settings_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "AJUSTES"
	tab.add_theme_constant_override("separation", 14)

	var music := CheckButton.new()
	music.text = "MÚSICA"
	music.button_pressed = GameState.music_enabled
	music.toggled.connect(GameState.set_music_enabled)
	tab.add_child(music)

	var effects := CheckButton.new()
	effects.text = "EFECTOS DE SONIDO"
	effects.button_pressed = GameState.effects_enabled
	effects.toggled.connect(GameState.set_effects_enabled)
	tab.add_child(effects)
	return tab

func _add_stat(parent: GridContainer, title: String, value: String, value_node_name: String) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", Color("9b8eaa"))
	parent.add_child(title_label)
	var value_label := Label.new()
	value_label.text = value
	if value_node_name != "":
		value_label.name = value_node_name
	parent.add_child(value_label)

func _on_level_changed(value: int) -> void:
	$MarginContainer/VBoxContainer/TabContainer/PERFIL/LevelLabel.text = "NIVEL %d" % value

func _on_experience_changed(current: int, needed: int) -> void:
	_xp_bar.max_value = max(needed, 1)
	_xp_bar.value = current

func _on_gold_changed(value: int) -> void:
	$MarginContainer/VBoxContainer/TabContainer/PERFIL/GridContainer/GoldValue.text = str(value)

func _on_gems_changed(value: int) -> void:
	$MarginContainer/VBoxContainer/TabContainer/PERFIL/GridContainer/GemsValue.text = str(value)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d1d")
	style.border_color = Color("4e3a68")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	return style
