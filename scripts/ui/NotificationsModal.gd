extends PanelContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal closed

const WIDTH := 340.0
const UNLOCK_PREFIX := "Habilidad desbloqueada: "

var _list: VBoxContainer
## Unread state when the modal opened: Inicio marks everything read right
## after opening, but the new ones should still stand out this time.
var _unread_at_open := {}

func _ready() -> void:
	theme = UiTheme.make_theme()
	anchor_left = 0.5; anchor_right = 0.5; anchor_top = 0.5; anchor_bottom = 0.5
	offset_left = -WIDTH / 2.0; offset_right = WIDTH / 2.0; offset_top = -230; offset_bottom = 230
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.BORDER, 6, 4)))
	for entry in GameState.notifications:
		if not bool(entry.get("read", false)):
			_unread_at_open[int(entry.get("timestamp", 0))] = true
	_build()
	_refresh()
	GameState.notifications_changed.connect(func(_unread): _refresh())

func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	box.add_child(UiTheme.modal_header("AVISOS", func(): closed.emit()))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	if GameState.notifications.is_empty():
		_list.add_child(_empty_state())
		return
	for entry in GameState.notifications:
		_list.add_child(_entry_row(entry))

func _empty_state() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	var icon := UiTheme.icon_rect("notificacion.png", 56.0)
	icon.modulate = Color(1, 1, 1, 0.45)
	box.add_child(icon)
	var label := Label.new()
	label.text = "No hay avisos nuevos."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	box.add_child(label)
	return box

## Icon tile, title + detail, relative time and an unread dot.
func _entry_row(entry: Dictionary) -> Control:
	var text := str(entry.get("text", ""))
	var unread := not bool(entry.get("read", false)) or _unread_at_open.has(int(entry.get("timestamp", 0)))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _entry_style(unread))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(46, 46)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Color("120c1e")
	tile_style.border_color = Color(UiTheme.GOLD, 0.45)
	tile_style.set_border_width_all(1)
	tile_style.set_corner_radius_all(8)
	tile_style.set_content_margin_all(4)
	tile.add_theme_stylebox_override("panel", tile_style)
	var icon := TextureRect.new()
	icon.texture = _icon_for(text)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tile.add_child(icon)
	row.add_child(tile)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 0)
	row.add_child(labels)
	var title := Label.new()
	var detail := Label.new()
	if text.begins_with(UNLOCK_PREFIX):
		title.text = "Habilidad desbloqueada"
		detail.text = text.substr(UNLOCK_PREFIX.length()).capitalize()
	else:
		title.text = text
		detail.visible = false
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UiTheme.GOLD if unread else UiTheme.TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(title)
	detail.add_theme_font_size_override("font_size", 15)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(detail)
	var when := Label.new()
	when.text = _relative_time(int(entry.get("timestamp", 0)))
	when.add_theme_font_size_override("font_size", 12)
	when.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	when.visible = when.text != ""
	labels.add_child(when)

	if unread:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(9, 9)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = UiTheme.EMBER
		dot_style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", dot_style)
		row.add_child(dot)
	return card

## Ability icon when the text names an unlocked ability; mail otherwise.
func _icon_for(text: String) -> Texture2D:
	if text.begins_with(UNLOCK_PREFIX):
		var name := text.substr(UNLOCK_PREFIX.length())
		for id in AbilityCatalog.UNLOCKS.keys():
			if AbilityCatalog.display_name(id) == name:
				var tex := AbilityCatalog.icon(id)
				if tex != null:
					return tex
	return UiTheme.icon("notificacion.png")

func _relative_time(timestamp: int) -> String:
	if timestamp <= 0:
		return ""
	var seconds := int(Time.get_unix_time_from_system()) - timestamp
	if seconds < 60:
		return "Recién"
	if seconds < 3600:
		return "Hace %d min" % (seconds / 60)
	if seconds < 86400:
		return "Hace %d h" % (seconds / 3600)
	var days := seconds / 86400
	return "Hace %d día%s" % [days, "" if days == 1 else "s"]

func _entry_style(unread: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.08, 0.18, 0.95) if unread else Color(0.08, 0.06, 0.13, 0.9)
	style.border_color = Color(UiTheme.GOLD, 0.5) if unread else Color(UiTheme.BORDER_SOFT, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
