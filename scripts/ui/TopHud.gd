class_name TopHud
extends PanelContainer

signal notifications_pressed

var _level_label: Label
var _energy_bar: ProgressBar
var _energy_label: Label
var _gold_label: Label
var _gems_label: Label
var _notification_button: Button
var _notification_badge: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size.y = 88.0
	add_theme_stylebox_override("panel", _panel_style())
	_build()

func set_level(value: int) -> void:
	_level_label.text = str(value)

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
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	_level_label = _add_value_panel(row, "NV.", "1", 0.7)

	var energy_panel := PanelContainer.new()
	energy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_panel.size_flags_stretch_ratio = 1.5
	energy_panel.add_theme_stylebox_override("panel", _slot_style())
	row.add_child(energy_panel)
	var energy_stack := VBoxContainer.new()
	energy_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_panel.add_child(energy_stack)
	var energy_title := Label.new()
	energy_title.text = "ENERGÍA"
	energy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_stack.add_child(energy_title)
	_energy_bar = ProgressBar.new()
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size.y = 20
	_energy_bar.add_theme_stylebox_override("background", _bar_style(Color("100b18")))
	_energy_bar.add_theme_stylebox_override("fill", _bar_style(Color("20e6bd")))
	energy_stack.add_child(_energy_bar)
	_energy_label = Label.new()
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_stack.add_child(_energy_label)

	_gold_label = _add_value_panel(row, "ORO", "0", 1.0)
	_gems_label = _add_value_panel(row, "JOYAS", "0", 1.0)

	var notification_panel := PanelContainer.new()
	notification_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notification_panel.size_flags_stretch_ratio = 0.7
	notification_panel.add_theme_stylebox_override("panel", _slot_style())
	row.add_child(notification_panel)
	_notification_button = Button.new()
	_notification_button.text = "✉"
	_notification_button.flat = true
	_notification_button.add_theme_font_size_override("font_size", 28)
	_notification_button.pressed.connect(func(): notifications_pressed.emit())
	notification_panel.add_child(_notification_button)
	_notification_badge = Label.new()
	_notification_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_notification_badge.offset_left = -30
	_notification_badge.offset_bottom = 24
	_notification_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_badge.add_theme_color_override("font_color", Color("120d1d"))
	_notification_badge.add_theme_color_override("font_outline_color", Color("20e6bd"))
	_notification_badge.add_theme_constant_override("outline_size", 7)
	notification_panel.add_child(_notification_badge)

	set_level(2)
	set_energy(20, 35)
	set_gold(138)
	set_gems(110)
	set_notifications(1)

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
	value_label.add_theme_font_size_override("font_size", 22)
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
	style.content_margin_left = 8
	style.content_margin_right = 8
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
