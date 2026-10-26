class_name NavigationFooter
extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal navigation_requested(index: int, id: StringName)

@export var entries: Array[Dictionary] = [
	{"id": &"shop", "tooltip": "Tienda"},
	{"id": &"character", "tooltip": "Personaje y equipo"},
	{"id": &"home", "tooltip": "Inicio"},
	{"id": &"inventory", "tooltip": "Inventario"},
	{"id": &"dungeons", "tooltip": "Mazmorras"},
]
@export var icons: Array = []
@export var selected_index := 2

var _buttons: Array[Button] = []

const KIT_DIR := "res://assets/ui/pixel_simple_v1/"
const SELECTED_NAV_TEXTURE := preload("res://assets/ui/pixel_simple_v1/frames/selection.png")
const FOOTER_FRAME_TEXTURE := preload("res://assets/ui/pixel_simple_v1/frames/footer_frame.png")
func _kit_ready() -> bool:
	return ResourceLoader.exists(KIT_DIR + "frames/footer_frame.png")

func _uses_kit_frame() -> bool:
	return _kit_ready() and entries.size() == 5

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var safe_bottom := _safe_area_bottom_inset()
	var height := 92.0 if _kit_ready() else 82.0
	offset_top = -height - safe_bottom
	custom_minimum_size.y = height + safe_bottom
	add_theme_stylebox_override("panel", StyleBoxEmpty.new() if _uses_kit_frame() else _panel_style())
	_build(safe_bottom)

func _build(safe_bottom: float = 0.0) -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()

	# The supplied footer art has five cells. With four destinations, use the
	# flexible four-button layout instead of leaving an empty framed cell.
	var use_kit := _uses_kit_frame()
	if use_kit:
		# Frame art: five equal cells, one per option.
		var frame := TextureRect.new()
		# The art has empty margins above/below the bar: crop to the artwork so it
		# reaches the bottom edge of the screen.
		frame.texture = FOOTER_FRAME_TEXTURE
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(frame)

	# Each button covers an equal-width share of the screen. Icon positions
	# below are centred against the resolved button rect, not its top-left.
	var row: Control = Control.new() if use_kit else HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -int(safe_bottom)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if row is HBoxContainer:
		(row as HBoxContainer).add_theme_constant_override("separation", 6)
		(row as HBoxContainer).add_theme_constant_override("margin_left", 10)
		(row as HBoxContainer).add_theme_constant_override("margin_right", 10)
	add_child(row)

	for index in range(entries.size()):
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = str(entries[index].get("tooltip", ""))
		button.accessibility_name = button.tooltip_text
		if use_kit:
			button.anchor_left = float(index) / float(entries.size())
			button.anchor_right = float(index + 1) / float(entries.size())
			button.anchor_top = 0.08
			button.anchor_bottom = 0.92
			for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				button.set_offset(side, 0.0)
		else:
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(0, 82)
		button.tooltip_text = ""
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = null
		var selection := TextureRect.new()
		selection.name = "SelectionEffect"
		selection.texture = SELECTED_NAV_TEXTURE
		selection.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		selection.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		selection.stretch_mode = TextureRect.STRETCH_SCALE
		selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		selection.set_anchor(SIDE_TOP, 0.0)
		selection.set_anchor(SIDE_BOTTOM, 1.0)
		selection.offset_top = 0.0
		selection.offset_bottom = 0.0
		selection.modulate = Color(1.0, 1.0, 1.0, 0.5)
		selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(selection)
		if index < icons.size() and icons[index] != null:
			var icon := TextureRect.new()
			icon.name = "NavIcon"
			icon.texture = icons[index]
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_preset(Control.PRESET_TOP_LEFT)
			var icon_size := 48.0 if use_kit else 52.0
			icon.size = Vector2(icon_size, icon_size)
			icon.position = (button.size - icon.size) * 0.5
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
		_apply_button_styles(button, index == selected_index)
		button.pressed.connect(_select.bind(index))
		row.add_child(button)
		button.resized.connect(_center_button_icon.bind(button))
		_center_button_icon(button)
		_buttons.append(button)

func _center_button_icon(button: Button) -> void:
	var icon := button.get_node_or_null("NavIcon") as TextureRect
	if icon == null:
		return
	var optical_offset_x := 0.0
	if _uses_kit_frame():
		var button_index := button.get_index()
		optical_offset_x = 12.0 if button_index == 0 else (8.0 if button_index == 1 else (-12.0 if button_index == entries.size() - 1 else (-8.0 if button_index == entries.size() - 2 else 0.0)))
	icon.position = (button.size - icon.size) * 0.5 + Vector2(optical_offset_x, 0.0)

func _select(index: int) -> void:
	if index < 0 or index >= _buttons.size() or _buttons[index].disabled:
		return
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

func set_destination_enabled(id: StringName, enabled: bool) -> void:
	for i in entries.size():
		if StringName(entries[i].get("id", &"")) == id and i < _buttons.size():
			_buttons[i].disabled = not enabled
			_apply_button_styles(_buttons[i], i == selected_index)
			return

func _apply_button_styles(button: Button, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _slot_style(selected))
	button.add_theme_stylebox_override("hover", _slot_style(selected))
	button.add_theme_stylebox_override("pressed", _slot_style(selected))
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new() if _uses_kit_frame() else UiTheme.button_disabled())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.modulate = Color(0.48, 0.48, 0.56) if button.disabled else (Color.WHITE if selected else Color(0.95, 0.92, 1.0))
	var selection := button.get_node_or_null("SelectionEffect") as TextureRect
	if selection:
		selection.visible = selected and not button.disabled and _uses_kit_frame()
	for child in button.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", UiTheme.ACCENT if selected else UiTheme.TEXT_MUTED)

func _safe_area_bottom_inset() -> float:
	# Desktop: the window never overlaps the taskbar, so screen-vs-usable-rect
	# is not a real inset there. Only phones/tablets have cutouts/gesture bars.
	if not OS.has_feature("mobile"):
		return 0.0
	var screen_index := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen_index)
	var usable := DisplayServer.screen_get_usable_rect(screen_index)
	return maxf(0.0, float(screen_size.y - (usable.position.y + usable.size.y)))

func _panel_style() -> StyleBoxFlat:
	var style := UiTheme.panel(UiTheme.BORDER, UiTheme.CORNER, 4)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_top = 2
	return style

func _slot_style(selected: bool) -> StyleBox:
	if _uses_kit_frame():
		if not selected:
			return StyleBoxEmpty.new()
		# Selected cell: only a light turquoise shadow, no border or fill.
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(0, 0, 0, 0)
		glow.set_corner_radius_all(8)
		glow.shadow_color = Color(UiTheme.ACCENT, 0.45)
		glow.shadow_size = 5
		return glow
	var normal := UiTheme.slot(selected, 10)
	normal.border_color = UiTheme.ACCENT if selected else Color("3a2b52")
	return normal
