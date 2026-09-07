extends MarginContainer

signal previous_map_requested
signal next_map_requested
signal start_map_requested(map_id: StringName)

var _map_id: StringName = &"void_crypts"
var _title: Label
var _chapter: Label
var _preview: TextureRect
var _rewards: Label
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
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("margin_left", 18)
	add_theme_constant_override("margin_right", 18)
	add_theme_constant_override("margin_top", 8)
	add_theme_constant_override("margin_bottom", 8)

	var column := VBoxContainer.new()
	column.name = "MapColumn"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	_title.add_theme_color_override("font_color", Color("f1e8ff"))
	column.add_child(_title)

	_chapter = Label.new()
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter.add_theme_font_size_override("font_size", 13)
	_chapter.add_theme_color_override("font_color", Color("20e6bd"))
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

	_start_button = Button.new()
	_start_button.name = "StartMapButton"
	_start_button.text = "INICIAR"
	_start_button.custom_minimum_size = Vector2(0, 64)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_button.add_theme_font_size_override("font_size", 22)
	_start_button.add_theme_stylebox_override("normal", _button_style(Color("20e6bd"), Color("171027")))
	_start_button.add_theme_stylebox_override("hover", _button_style(Color("8affdf"), Color("171027")))
	_start_button.add_theme_stylebox_override("pressed", _button_style(Color("13a98b"), Color("171027")))
	_start_button.pressed.connect(func():
		if not _start_button.disabled:
			start_map_requested.emit(_map_id)
	)
	column.add_child(_start_button)

func set_map(data: Dictionary) -> void:
	_map_id = StringName(data.get("id", "void_crypts"))
	if not is_instance_valid(_title):
		return
	_title.text = str(data.get("name", "MAPA"))
	_chapter.text = "Capítulo %s · Nivel %s" % [str(data.get("chapter", 1)), str(data.get("level", 1))]
	_rewards.text = "Recompensas posibles\n%s" % str(data.get("rewards", "Oro · Gema · Cofre"))
	var texture = load(str(data.get("preview", "res://assets/environment/game_bg.png")))
	if texture is Texture2D:
		_preview.texture = texture
	var unlocked := int(data.get("required", 0)) <= GameState.high_score
	_start_button.disabled = not unlocked
	_start_button.text = "INICIAR" if unlocked else "BLOQUEADO · %d" % int(data.get("required", 0))

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
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171027")
	style.border_color = Color("20e6bd")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	return style

func _button_style(border: Color, text_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("39244e")
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 44
	style.content_margin_right = 44
	return style
