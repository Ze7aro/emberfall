extends MarginContainer

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

signal previous_map_requested
signal next_map_requested
signal start_map_requested(data: Dictionary)

## Returns true if the given map dictionary should be playable. Screens that
## embed this component override it (e.g. gate by stage/dungeon progress).
var unlock_check: Callable = func(_data: Dictionary) -> bool: return true

var _map_id: StringName = &"void_crypts"
var _map_data: Dictionary = {}
var _title: Label
var _chapter: Label
var _preview: TextureRect
var _lock_overlay: ColorRect
var _lock_icon: TextureRect
var _rewards: Label
var _modifier: Label
var _maps: Array[Dictionary] = [
	{"id": &"void_crypts", "name": "CRIPTAS DEL VACÍO", "chapter": 1, "level": 1, "rewards": "Oro · Gema · Cofre", "preview": "res://assets/environment/game_bg.png", "required": 0},
	{"id": &"verdant_ruins", "name": "RUINAS VERDANTES", "chapter": 1, "level": 2, "rewards": "Oro · Cofre · Reliquia", "preview": "res://assets/environment/world_map.png", "required": 1},
	{"id": &"ember_forge", "name": "FORJA DE EMBER", "chapter": 2, "level": 1, "rewards": "Oro · Gema · Núcleo", "preview": "res://assets/environment/game_bg.png", "required": 3}
]
var _map_index := 0
var _start_button: Button

func _ready() -> void:
	_build()
	set_map(_maps[_map_index])

func _build() -> void:
	theme = UiTheme.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("margin_left", 18)
	add_theme_constant_override("margin_right", 18)
	add_theme_constant_override("margin_top", 160)
	add_theme_constant_override("margin_bottom", 140)

	var column := VBoxContainer.new()
	column.name = "MapColumn"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", UiTheme.TEXT)
	column.add_child(_title)

	_chapter = Label.new()
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter.add_theme_font_size_override("font_size", 13)
	_chapter.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(_chapter)

	var preview_row := HBoxContainer.new()
	preview_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_row.add_theme_constant_override("separation", 8)
	preview_row.custom_minimum_size.y = 220
	column.add_child(preview_row)

	var previous := Button.new()
	previous.text = "‹"
	previous.custom_minimum_size = Vector2(44, 72)
	previous.add_theme_font_size_override("font_size", 38)
	previous.pressed.connect(func(): previous_map_requested.emit())
	preview_row.add_child(previous)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 210)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _preview_style())
	preview_row.add_child(panel)
	_preview = TextureRect.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.custom_minimum_size = Vector2(0, 190)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_preview)

	_lock_overlay = ColorRect.new()
	_lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_overlay.color = Color(0, 0, 0, 0.55)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.visible = false
	panel.add_child(_lock_overlay)
	_lock_icon = TextureRect.new()
	_lock_icon.texture = load("res://assets/iconos main/06_candado.png")
	_lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock_icon.size = Vector2(56, 56)
	_lock_icon.set_anchors_preset(Control.PRESET_CENTER)
	_lock_icon.position = Vector2(-28, -28)
	_lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_icon.visible = false
	panel.add_child(_lock_icon)

	var next := Button.new()
	next.text = "›"
	next.custom_minimum_size = Vector2(44, 72)
	next.add_theme_font_size_override("font_size", 38)
	next.pressed.connect(func(): next_map_requested.emit())
	preview_row.add_child(next)

	_rewards = Label.new()
	_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rewards.add_theme_font_size_override("font_size", 14)
	_rewards.add_theme_color_override("font_color", Color("d8c9ed"))
	column.add_child(_rewards)

	_modifier = Label.new()
	_modifier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modifier.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modifier.add_theme_font_size_override("font_size", 12)
	_modifier.add_theme_color_override("font_color", Color("ff9c4d"))
	column.add_child(_modifier)

	_start_button = Button.new()
	_start_button.name = "StartMapButton"
	_start_button.text = "INICIAR"
	_start_button.custom_minimum_size = Vector2(0, 64)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_button.add_theme_font_size_override("font_size", 22)
	UiTheme.apply_primary(_start_button)
	_start_button.pressed.connect(func():
		if not _start_button.disabled:
			start_map_requested.emit(_map_data)
	)
	column.add_child(_start_button)

func set_map(data: Dictionary) -> void:
	_map_id = StringName(data.get("id", "void_crypts"))
	_map_data = data
	if not is_instance_valid(_title):
		return
	_title.text = str(data.get("name", "MAPA"))
	_chapter.text = "Capítulo %s · Nivel %s" % [str(data.get("chapter", 1)), str(data.get("level", 1))]
	_rewards.text = "Recompensas: %d oro · %d esmeraldas" % [int(data.get("gold_reward", 0)), int(data.get("gems_reward", 0))]
	var modifier_label := str(data.get("modifier_label", ""))
	_modifier.text = modifier_label
	_modifier.visible = modifier_label != ""
	var texture = load(str(data.get("preview", "res://assets/environment/game_bg.png")))
	if texture is Texture2D:
		_preview.texture = texture
	var unlocked: bool = unlock_check.call(data)
	_start_button.disabled = not unlocked
	_start_button.text = "INICIAR" if unlocked else "BLOQUEADO"
	_lock_overlay.visible = not unlocked
	_lock_icon.visible = not unlocked

func set_maps(list: Array[Dictionary]) -> void:
	_maps = list
	_map_index = 0
	if not _maps.is_empty():
		set_map(_maps[0])

func show_previous_map() -> void:
	_map_index = posmod(_map_index - 1, _maps.size())
	set_map(_maps[_map_index])

func show_next_map() -> void:
	_map_index = posmod(_map_index + 1, _maps.size())
	set_map(_maps[_map_index])

func _preview_style() -> StyleBoxFlat:
	var style := UiTheme.slot(true, 4)
	style.bg_color = UiTheme.BG_PANEL
	return style
