extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed
## Configuración now lives here (the HUD gear was removed).
signal settings_requested

var _xp_bar: ProgressBar
var _level_label: Label
var _xp_label: Label
var _gold_value: Label
var _gems_value: Label

func _ready() -> void:
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -150; offset_right = 150; offset_top = -235; offset_bottom = 235
	custom_minimum_size = Vector2(300, 470)
	theme = UiTheme.make_theme()
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
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

	box.add_child(UiTheme.header("PERFIL", "MÁS QUE UN GUERRERO, UNA HISTORIA", 26, "perfil_header.png"))
	var profile := _build_profile_tab()
	profile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(profile)

	var settings := Button.new()
	settings.text = "CONFIGURACIÓN"
	settings.icon = load("res://assets/ui/pixel_simple_v1/icons/settings.png") as Texture2D
	settings.custom_minimum_size = Vector2(0, 44)
	settings.pressed.connect(func(): settings_requested.emit())
	box.add_child(settings)

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
	UiTheme.style_bar(_xp_bar, 30.0, "fill_xp.png")
	_xp_bar.max_value = max(GameState.experience_to_next, 1)
	_xp_bar.value = GameState.experience
	tab.add_child(_xp_bar)
	_xp_label = Label.new()
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 11)
	_xp_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	_xp_label.text = "%d / %d" % [GameState.experience, GameState.experience_to_next]
	tab.add_child(_xp_label)

	var stats := GridContainer.new()
	stats.name = "GridContainer"
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 16)
	stats.add_theme_constant_override("v_separation", 8)
	tab.add_child(stats)
	_gold_value = _add_stat(stats, "ORO", str(GameState.gold))
	_gems_value = _add_stat(stats, "JOYAS", str(GameState.gems))
	_add_stat(stats, "RÉCORD", str(GameState.high_score))
	return tab

func _add_stat(parent: GridContainer, title: String, value: String) -> Label:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", UiTheme.kit("panel_card", UiTheme.slot(false, 8), 8.0))
	parent.add_child(tile)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(stack)
	var value_label := Label.new()
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	stack.add_child(value_label)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	stack.add_child(title_label)
	return value_label

func _on_level_changed(value: int) -> void:
	_level_label.text = "NIVEL %d" % value

func _on_experience_changed(current: int, needed: int) -> void:
	_xp_bar.max_value = max(needed, 1)
	_xp_bar.value = current
	_xp_label.text = "%d / %d" % [current, needed]

func _on_gold_changed(value: int) -> void:
	_gold_value.text = str(value)

func _on_gems_changed(value: int) -> void:
	_gems_value.text = str(value)
