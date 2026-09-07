class_name NavigationFooter
extends PanelContainer

signal navigation_requested(index: int, id: StringName)

@export var entries: Array[Dictionary] = [
	{"id": &"shop", "tooltip": "Tienda"},
	{"id": &"upgrades", "tooltip": "Mejoras permanentes"},
	{"id": &"world", "tooltip": "Mundo"},
	{"id": &"heroes", "tooltip": "Personajes"},
	{"id": &"dungeons", "tooltip": "Mazmorras"},
]
@export var icons: Array = []
@export var selected_index := 0

var _buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -112.0
	custom_minimum_size.y = 112.0
	add_theme_stylebox_override("panel", _panel_style())
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	for index in range(entries.size()):
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 88)
		button.tooltip_text = str(entries[index].get("tooltip", ""))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = null
		if index < icons.size() and icons[index] != null:
			var icon := TextureRect.new()
			icon.texture = icons[index]
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_preset(Control.PRESET_CENTER)
			icon.position = Vector2(-28, -34)
			icon.size = Vector2(56, 56)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
		_apply_button_styles(button, index == selected_index)
		button.pressed.connect(_select.bind(index))
		row.add_child(button)
		_buttons.append(button)

func _select(index: int) -> void:
	selected_index = index
	for i in range(_buttons.size()):
		_apply_button_styles(_buttons[i], i == selected_index)
	navigation_requested.emit(index, StringName(entries[index].get("id", &"")))

func select_by_id(id: StringName) -> void:
	for i in entries.size():
		if StringName(entries[i].get("id", &"")) == id:
			selected_index = i
			for j in _buttons.size(): _apply_button_styles(_buttons[j], j == i)
			return

func _apply_button_styles(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _slot_style(selected))
	button.add_theme_stylebox_override("hover", _slot_style(true))
	button.add_theme_stylebox_override("pressed", _slot_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.modulate = Color.WHITE if selected else Color(0.82, 0.78, 0.9)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("120d1d")
	style.border_color = Color("4e3a68")
	style.set_border_width_all(4)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 8
	return style

func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21182d") if not selected else Color("302040")
	style.border_color = Color("5b4771") if not selected else Color("20e6bd")
	style.set_border_width_all(3)
	style.set_corner_radius_all(9)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
