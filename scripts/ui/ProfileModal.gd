extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

var _xp_bar: ProgressBar
var _level_label: Label
var _gold_value: Label
var _gems_value: Label

func _ready() -> void:
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -150; offset_right = 150; offset_top = -180; offset_bottom = 180
	custom_minimum_size = Vector2(300, 360)
	theme = UiTheme.make_theme()
	add_theme_stylebox_override("panel", UiTheme.panel(UiTheme.BORDER, 6, 4))
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

	var title := Label.new()
	title.text = "PERFIL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	box.add_child(title)
	var profile := _build_profile_tab()
	profile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(profile)

	var close := Button.new()
	close.text = "CERRAR"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)

func _build_profile_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "PERFIL"
	tab.add_theme_constant_override("separation", 12)

	_level_label = Label.new()
	var level_label := _level_label
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
	_gold_value = _add_stat(stats, "ORO", str(GameState.gold))
	_gems_value = _add_stat(stats, "JOYAS", str(GameState.gems))
	_add_stat(stats, "RÉCORD DE ELIMINACIONES", str(GameState.high_score))
	return tab

func _add_stat(parent: GridContainer, title: String, value: String) -> Label:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	parent.add_child(title_label)
	var value_label := Label.new()
	value_label.text = value
	parent.add_child(value_label)
	return value_label

func _on_level_changed(value: int) -> void:
	_level_label.text = "NIVEL %d" % value

func _on_experience_changed(current: int, needed: int) -> void:
	_xp_bar.max_value = max(needed, 1)
	_xp_bar.value = current

func _on_gold_changed(value: int) -> void:
	_gold_value.text = str(value)

func _on_gems_changed(value: int) -> void:
	_gems_value.text = str(value)
