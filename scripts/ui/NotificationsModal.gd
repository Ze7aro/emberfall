extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

var _list: VBoxContainer

func _ready() -> void:
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -160; offset_right = 160; offset_top = -190; offset_bottom = 190
	custom_minimum_size = Vector2(320, 380)
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", _panel_style()))
	_build()
	_refresh()
	GameState.notifications_changed.connect(func(_unread): _refresh())

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "NOTIFICACIONES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 240)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var close := Button.new()
	close.text = "CERRAR"
	close.icon = load("res://assets/ui/pixel_simple_v1/icons/close.png") as Texture2D
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	if GameState.notifications.is_empty():
		var empty := Label.new()
		empty.text = "Sin notificaciones."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("9b8eaa"))
		_list.add_child(empty)
		return
	for entry in GameState.notifications:
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _entry_style())
		_list.add_child(row)
		var label := Label.new()
		label.text = str(entry.get("text", ""))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)

func _entry_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21182d")
	style.border_color = Color("5b4771")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d1d")
	style.border_color = Color("4e3a68")
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	return style
