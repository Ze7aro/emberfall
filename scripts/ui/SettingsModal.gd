extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

const WIDTH := 340.0

var _joystick_buttons: Array[Button] = []

func _ready() -> void:
	theme = UiTheme.make_theme()
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -WIDTH / 2.0; offset_right = WIDTH / 2.0; offset_top = -250; offset_bottom = 250
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	box.add_child(UiTheme.modal_header("CONFIGURACIÓN", func(): closed.emit()))

	box.add_child(UiTheme.section_title("AUDIO", "", UiTheme.GOLD))
	box.add_child(_toggle_row("Música", "Melodías del menú y de combate", GameState.music_enabled, GameState.set_music_enabled))
	box.add_child(_toggle_row("Efectos de sonido", "Golpes, habilidades y botones", GameState.effects_enabled, GameState.set_effects_enabled))

	box.add_child(UiTheme.section_title("JUEGO", "", UiTheme.GOLD))
	box.add_child(_toggle_row("Vibración", "Al recibir daño", GameState.vibration_enabled, GameState.set_vibration_enabled))
	box.add_child(_toggle_row("Menos movimiento", "Reduce temblores y destellos", GameState.reduce_motion, GameState.set_reduce_motion))
	box.add_child(_joystick_row())

	var version := Label.new()
	version.text = "Emberfall %s" % str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", Color(UiTheme.TEXT_MUTED, 0.6))
	version.visible = version.text.strip_edges() != "Emberfall"
	box.add_child(version)

## Card row: title + hint on the left, pill switch on the right. The whole
## row is the CheckButton, so any tap on it toggles.
func _toggle_row(title: String, hint: String, value: bool, on_toggle: Callable) -> Control:
	var toggle := CheckButton.new()
	toggle.button_pressed = value
	toggle.custom_minimum_size = Vector2(0, 54)
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.toggled.connect(on_toggle)
	var row_style := _row_style()
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		toggle.add_theme_stylebox_override(state, row_style)
	var labels := VBoxContainer.new()
	labels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	labels.offset_left = 14.0
	labels.offset_right = -64.0
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.add_theme_constant_override("separation", -2)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.add_child(labels)
	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_override("font", UiTheme.bold_font())
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(name_label)
	var hint_label := Label.new()
	hint_label.text = hint
	hint_label.clip_text = true
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(hint_label)
	return toggle

## Joystick size as three segment buttons instead of a dropdown.
func _joystick_row() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _row_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var label := Label.new()
	label.text = "Joystick"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", UiTheme.bold_font())
	label.add_theme_font_size_override("font_size", 17)
	row.add_child(label)
	var options := ["Chico", "Normal", "Grande"]
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		button.custom_minimum_size = Vector2(66, 38)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_select_joystick.bind(i))
		row.add_child(button)
		_joystick_buttons.append(button)
	_select_joystick(GameState.joystick_size, false)
	return panel

func _select_joystick(index: int, save: bool = true) -> void:
	if save:
		GameState.set_joystick_size(index)
	for i in _joystick_buttons.size():
		var button := _joystick_buttons[i]
		var active := i == index
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1b6f7a") if active else Color("1a1528")
		style.border_color = UiTheme.ACCENT if active else UiTheme.BORDER_SOFT
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, style)
		var color := UiTheme.PRIMARY_TEXT if active else UiTheme.TEXT_MUTED
		for key in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(key, color)

func _row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.15, 0.9)
	style.border_color = Color(UiTheme.BORDER_SOFT, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
