class_name TopHud
extends PanelContainer

signal profile_pressed
signal notifications_pressed
signal settings_pressed

var _level_label: Label
var _xp_bar: ProgressBar
var _energy_bar: ProgressBar
var _energy_label: Label
var _gold_label: Label
var _gems_label: Label
var _notification_badge: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size.y = 88.0
	add_theme_stylebox_override("panel", _panel_style())
	_build()

func set_level(value: int) -> void:
	_level_label.text = str(value)

func set_experience(current: int, needed: int) -> void:
	_xp_bar.max_value = max(needed, 1)
	_xp_bar.value = clamp(current, 0, needed)

func set_energy(current: int, maximum: int) -> void:
	_energy_bar.max_value = max(maximum, 1)
	_energy_bar.value = clamp(current, 0, maximum)
	_energy_label.text = "%d/%d" % [current, maximum]

func set_gold(value: int) -> void:
	_gold_label.text = _compact_number(value)

func set_gems(value: int) -> void:
	_gems_label.text = _compact_number(value)

func set_notifications(unread: int) -> void:
	_notification_badge.visible = unread > 0
	_notification_badge.text = str(min(unread, 99)) if unread < 100 else "99+"

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)

	_build_profile_button(row)

	var energy_panel := PanelContainer.new()
	energy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_panel.size_flags_stretch_ratio = 1.4
	energy_panel.add_theme_stylebox_override("panel", _slot_style())
	row.add_child(energy_panel)
	var energy_stack := VBoxContainer.new()
	energy_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_panel.add_child(energy_stack)
	var energy_title := Label.new()
	energy_title.text = "ENERGÍA"
	energy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_title.add_theme_color_override("font_color", Color("9b8eaa"))
	energy_stack.add_child(energy_title)
	_energy_bar = ProgressBar.new()
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size.y = 16
	_energy_bar.add_theme_stylebox_override("background", _bar_style(Color("100b18")))
	_energy_bar.add_theme_stylebox_override("fill", _bar_style(Color("20e6bd")))
	energy_stack.add_child(_energy_bar)
	_energy_label = Label.new()
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_stack.add_child(_energy_label)

	_gold_label = _add_value_panel(row, "ORO", "0", 0.85)
	_gems_label = _add_value_panel(row, "JOYAS", "0", 0.85)

	_build_icon_button(row, "✉", 0.6, func(): notifications_pressed.emit())
	_notification_badge = Label.new()
	_notification_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_notification_badge.offset_left = -22
	_notification_badge.offset_bottom = 18
	_notification_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_badge.add_theme_font_size_override("font_size", 12)
	_notification_badge.add_theme_color_override("font_color", Color("120d1d"))
	_notification_badge.add_theme_color_override("font_outline_color", Color("20e6bd"))
	_notification_badge.add_theme_constant_override("outline_size", 6)
	_notification_badge.visible = false
	row.get_child(row.get_child_count() - 1).add_child(_notification_badge)

	_build_icon_button(row, "⚙", 0.6, func(): settings_pressed.emit())

	set_level(1)
	set_experience(0, 100)
	set_energy(0, 1)
	set_gold(0)
	set_gems(0)
	set_notifications(0)

func _build_profile_button(parent: Container) -> void:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = 0.75
	button.text = ""
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _slot_style())
	button.add_theme_stylebox_override("hover", _slot_style())
	button.add_theme_stylebox_override("pressed", _slot_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func(): profile_pressed.emit())
	parent.add_child(button)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(stack)
	var title := Label.new()
	title.text = "NV."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_color", Color("9b8eaa"))
	stack.add_child(title)
	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_label.add_theme_font_size_override("font_size", 22)
	stack.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size.y = 5
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.add_theme_stylebox_override("background", _bar_style(Color("100b18")))
	_xp_bar.add_theme_stylebox_override("fill", _bar_style(Color("c86bff")))
	stack.add_child(_xp_bar)

func _build_icon_button(parent: Container, icon_text: String, ratio: float, on_press: Callable) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = ratio
	panel.add_theme_stylebox_override("panel", _slot_style())
	parent.add_child(panel)
	var button := Button.new()
	button.text = icon_text
	button.flat = true
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(on_press)
	panel.add_child(button)

func _add_value_panel(parent: Container, title: String, initial: String, ratio: float) -> Label:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = ratio
	panel.add_theme_stylebox_override("panel", _slot_style())
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(stack)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color("9b8eaa"))
	stack.add_child(title_label)
	var value_label := Label.new()
	value_label.text = initial
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	stack.add_child(value_label)
	return value_label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d1d")
	style.border_color = Color("4e3a68")
	style.set_border_width_all(4)
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21182d")
	style.border_color = Color("5b4771")
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

func _compact_number(value: int) -> String:
	if value >= 1_000_000:
		return "%.1fM" % (value / 1_000_000.0)
	if value >= 1_000:
		return "%.1fK" % (value / 1_000.0)
	return str(value)
