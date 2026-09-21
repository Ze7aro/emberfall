class_name NavigationFooter
extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal navigation_requested(index: int, id: StringName)

@export var entries: Array[Dictionary] = [
	{"id": &"shop", "tooltip": "Tienda"},
	{"id": &"missions", "tooltip": "Misiones"},
	{"id": &"home", "tooltip": "Inicio"},
	{"id": &"upgrades", "tooltip": "Progreso"},
	{"id": &"dungeons", "tooltip": "Mazmorras"},
]
@export var icons: Array = []
@export var selected_index := 0

var _buttons: Array[Button] = []
var _missions_badge: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var safe_bottom := _safe_area_bottom_inset()
	offset_top = -112.0 - safe_bottom
	custom_minimum_size.y = 112.0 + safe_bottom
	add_theme_stylebox_override("panel", _panel_style())
	_build(safe_bottom)
	# PROMPT_MISIONES_EMBERFALL.md: "Si se completa una misión fuera de esta
	# pantalla, mostrar un indicador en el icono de Misiones del footer."
	GameState.missions_changed.connect(_refresh_missions_badge)
	_refresh_missions_badge()

func _build(safe_bottom: float = 0.0) -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10 + int(safe_bottom))
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
		if StringName(entries[index].get("id", &"")) == &"missions":
			_missions_badge = ColorRect.new()
			_missions_badge.color = UiTheme.DANGER
			_missions_badge.custom_minimum_size = Vector2(14, 14)
			_missions_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_missions_badge.position = Vector2(-18, 6)
			_missions_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_missions_badge.visible = false
			button.add_child(_missions_badge)
		_apply_button_styles(button, index == selected_index)
		button.pressed.connect(_select.bind(index))
		row.add_child(button)
		_buttons.append(button)
	_refresh_missions_badge()

func _refresh_missions_badge() -> void:
	if is_instance_valid(_missions_badge):
		_missions_badge.visible = GameState.has_claimable_missions()

func _select(index: int) -> void:
	if index != selected_index:
		SfxPlayer.play_ui("ui/ui_select.wav")
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

func _safe_area_bottom_inset() -> float:
	var screen_index := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var usable := DisplayServer.screen_get_usable_rect(screen_index)
	return maxf(0.0, float(screen_size.y - (usable.position.y + usable.size.y)))

func _panel_style() -> StyleBoxFlat:
	var style := UiTheme.panel(UiTheme.BORDER, UiTheme.CORNER, 4)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_top = 4
	return style

func _slot_style(selected: bool) -> StyleBoxFlat:
	var style := UiTheme.slot(selected, 10)
	if not selected:
		style.border_color = Color("3a2b52")
	return style
