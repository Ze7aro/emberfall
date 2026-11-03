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
	{"id": &"void_crypts", "name": "CRIPTAS DEL VACÍO", "chapter": 1, "level": 1, "rewards": "Oro · Gema · Cofre", "preview": "res://assets/ui/escenarios/game_bg.png", "required": 0},
	{"id": &"verdant_ruins", "name": "RUINAS VERDANTES", "chapter": 1, "level": 2, "rewards": "Oro · Cofre · Reliquia", "preview": "res://assets/ui/escenarios/world_map.png", "required": 1},
	{"id": &"ember_forge", "name": "FORJA DE EMBER", "chapter": 2, "level": 1, "rewards": "Oro · Gema · Núcleo", "preview": "res://assets/ui/escenarios/game_bg.png", "required": 3}
]
var _map_index := 0
var _start_button: Button
var _header_holder: VBoxContainer
var start_label := "INICIAR"
## Optional second line under the start label (Inicio: "Explora, lucha, progresa").
var start_subtitle := ""
## Inicio hides the rewards line; Mazmorras keeps it (its rewards are real data).
var show_rewards := true
var _start_title: Label
var _info_panel: PanelContainer
var _start_sub: Label
## Inicio stands the selected hero on the stage card; Mazmorras doesn't.
var show_hero := false
## Energy a start costs; shown on the right of the start button when > 0.
var energy_cost := 0
var _hero_sprite: Control
var _art: Control
var _dots: HBoxContainer
var _cost_box: HBoxContainer

func _ready() -> void:
	_build()
	set_map(_maps[_map_index])

func _build() -> void:
	theme = UiTheme.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_constant_override("margin_left", 18)
	add_theme_constant_override("margin_right", 18)
	add_theme_constant_override("margin_top", int(UiTheme.CONTENT_TOP))
	add_theme_constant_override("margin_bottom", 140)

	var column := VBoxContainer.new()
	column.name = "MapColumn"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(column)

	_header_holder = VBoxContainer.new()
	column.add_child(_header_holder)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTheme.style_title(_title, 25)
	column.add_child(_title)
	column.add_child(UiTheme.ornament(200.0))

	_chapter = Label.new()
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter.add_theme_font_size_override("font_size", 15)
	_chapter.add_theme_color_override("font_color", UiTheme.ACCENT)
	column.add_child(_chapter)

	var card := Control.new()
	card.custom_minimum_size = Vector2(0, 270)
	column.add_child(card)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _preview_style())
	panel.clip_contents = true
	card.add_child(panel)
	var art := Control.new()
	art.clip_contents = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(art)
	_preview = TextureRect.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(_preview)
	# Darkened edges so the art reads as a lit stage, not a flat tile.
	var shade := TextureRect.new()
	shade.texture = _vignette_texture()
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(shade)

	_art = art
	if show_hero:
		_build_hero(art)

	_lock_overlay = ColorRect.new()
	_lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_overlay.color = Color(0.02, 0.01, 0.05, 0.7)
	_lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay.visible = false
	art.add_child(_lock_overlay)
	_lock_icon = TextureRect.new()
	_lock_icon.texture = load("res://assets/ui/icons/lock.png")
	_lock_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lock_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock_icon.set_anchors_preset(Control.PRESET_CENTER)
	_lock_icon.offset_left = -32
	_lock_icon.offset_right = 32
	_lock_icon.offset_top = -32
	_lock_icon.offset_bottom = 32
	_lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_icon.visible = false
	art.add_child(_lock_icon)

	card.add_child(_arrow_button("arrow_left.png", true, func(): previous_map_requested.emit()))
	card.add_child(_arrow_button("arrow.png", false, func(): next_map_requested.emit()))

	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 6)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_dots)

	_info_panel = PanelContainer.new()
	var info_panel := _info_panel
	info_panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_default", UiTheme.slot(false, 10)))
	column.add_child(info_panel)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	info_panel.add_child(info_box)

	_rewards = Label.new()
	_rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rewards.add_theme_font_size_override("font_size", 14)
	_rewards.add_theme_color_override("font_color", UiTheme.PURPLE)
	info_box.add_child(_rewards)

	_modifier = Label.new()
	_modifier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modifier.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modifier.add_theme_font_size_override("font_size", 12)
	_modifier.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	info_box.add_child(_modifier)

	_start_button = Button.new()
	_start_button.name = "StartMapButton"
	_start_button.custom_minimum_size = Vector2(0, 58)
	_start_button.size_flags_horizontal = Control.SIZE_FILL
	UiTheme.apply_primary(_start_button, 16.0)
	_build_start_content()
	_start_button.pressed.connect(func():
		if not _start_button.disabled:
			start_map_requested.emit(_map_data)
	)
	column.add_child(_start_button)

## Screens embedding this component set their own heading and start label.
## Title, optional subtitle and a chevron laid over the (text-free) kit button.
func _build_start_content() -> void:
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_left = 44.0
	stack.offset_right = -44.0
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_button.add_child(stack)
	_start_title = Label.new()
	_start_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_title.add_theme_font_size_override("font_size", 18)
	_start_title.add_theme_color_override("font_color", Color("ffffff"))
	_start_title.add_theme_color_override("font_shadow_color", Color("101321"))
	_start_title.add_theme_constant_override("shadow_offset_x", 1)
	_start_title.add_theme_constant_override("shadow_offset_y", 1)
	_start_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_start_title)
	_start_sub = Label.new()
	_start_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_sub.add_theme_font_size_override("font_size", 11)
	_start_sub.add_theme_color_override("font_color", Color("ecedf4"))
	_start_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_start_sub)
	_start_title.add_theme_font_override("font", UiTheme.title_font())
	_start_title.add_theme_font_size_override("font_size", 22)
	_start_title.add_theme_color_override("font_outline_color", Color("06232a"))
	_start_title.add_theme_constant_override("outline_size", 5)
	_start_sub.add_theme_font_size_override("font_size", 13)
	_start_sub.add_theme_color_override("font_color", Color("bff4f6"))
	_cost_box = HBoxContainer.new()
	_cost_box.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_cost_box.offset_left = -76.0
	_cost_box.offset_right = -20.0
	_cost_box.offset_top = -15.0
	_cost_box.offset_bottom = 15.0
	_cost_box.alignment = BoxContainer.ALIGNMENT_END
	_cost_box.add_theme_constant_override("separation", 2)
	_cost_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_button.add_child(_cost_box)
	_cost_box.add_child(UiTheme.icon_rect("energia.png", 28.0))
	var cost := Label.new()
	cost.name = "Cost"
	cost.add_theme_font_override("font", UiTheme.bold_font())
	cost.add_theme_font_size_override("font_size", 20)
	cost.add_theme_color_override("font_color", UiTheme.PRIMARY_TEXT)
	cost.add_theme_color_override("font_outline_color", Color("06232a"))
	cost.add_theme_constant_override("outline_size", 4)
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_box.add_child(cost)

func _set_start_text(title: String) -> void:
	_start_title.text = title
	_start_sub.text = start_subtitle
	_start_sub.visible = start_subtitle != ""
	_cost_box.visible = energy_cost > 0 and not _start_button.disabled
	(_cost_box.get_node("Cost") as Label).text = str(energy_cost)

func set_header(title: String, subtitle: String, banner: String = "") -> void:
	for child in _header_holder.get_children():
		child.queue_free()
	_header_holder.add_child(UiTheme.header(title, subtitle, 34, banner))

func set_map(data: Dictionary) -> void:
	_map_id = StringName(data.get("id", "void_crypts"))
	_map_data = data
	if not is_instance_valid(_title):
		return
	_title.text = str(data.get("name", "MAPA"))
	_chapter.text = "Capítulo %s · Nivel %s" % [str(data.get("chapter", 1)), str(data.get("level", 1))]
	_rewards.visible = show_rewards
	_rewards.text = "Recompensas: %d oro · %d esmeraldas" % [int(data.get("gold_reward", 0)), int(data.get("gems_reward", 0))]
	var modifier_label := str(data.get("modifier_label", ""))
	_modifier.text = modifier_label
	_modifier.visible = modifier_label != ""
	_info_panel.visible = show_rewards or _modifier.visible
	var texture = load(str(data.get("preview", "res://assets/ui/escenarios/game_bg.png")))
	if texture is Texture2D:
		_preview.texture = texture
	var unlocked: bool = unlock_check.call(data)
	_start_button.disabled = not unlocked
	_set_start_text(start_label if unlocked else "BLOQUEADO")
	_lock_overlay.visible = not unlocked
	_lock_icon.visible = not unlocked
	if is_instance_valid(_hero_sprite):
		_hero_sprite.visible = unlocked
	_refresh_dots()

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

## One dot per map: the current one is a wide turquoise pill, unlocked ones
## are light, locked ones dim.
func _refresh_dots() -> void:
	if not is_instance_valid(_dots):
		return
	for child in _dots.get_children():
		child.queue_free()
	if _maps.size() < 2:
		return
	for i in _maps.size():
		var dot := Panel.new()
		var current := i == _map_index
		dot.custom_minimum_size = Vector2(18 if current else 7, 7)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		if current:
			style.bg_color = UiTheme.ACCENT
		elif unlock_check.call(_maps[i]):
			style.bg_color = Color(UiTheme.TEXT, 0.55)
		else:
			style.bg_color = Color(UiTheme.BORDER, 0.7)
		dot.add_theme_stylebox_override("panel", style)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dots.add_child(dot)

## Round dark button laid over the card edge, half outside it.
func _arrow_button(icon_file: String, left: bool, on_press: Callable) -> Button:
	var button := Button.new()
	button.icon = UiTheme.icon(icon_file)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 20)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.1, 0.82)
	style.border_color = Color(UiTheme.GOLD, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.set_content_margin_all(10)
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.set_anchors_preset(Control.PRESET_CENTER_LEFT if left else Control.PRESET_CENTER_RIGHT)
	button.offset_top = -22.0
	button.offset_bottom = 22.0
	button.offset_left = -14.0 if left else -30.0
	button.offset_right = 30.0 if left else 14.0
	button.pressed.connect(on_press)
	UiTheme.install_press_feedback(button)
	return button

## Turns the hero on after _ready (the embedding screen's _ready runs later).
func enable_hero() -> void:
	show_hero = true
	if is_instance_valid(_art) and not is_instance_valid(_hero_sprite):
		_build_hero(_art)
		# Keep the lock veil above the hero.
		_art.move_child(_hero_sprite, 2)

## The selected hero standing on a rune circle in the middle of the card,
## breathing slowly.
func _build_hero(parent: Control) -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	_hero_sprite = holder
	var rune := RuneBackdrop.new()
	rune.set_anchors_preset(Control.PRESET_CENTER)
	rune.offset_left = -80.0
	rune.offset_right = 80.0
	rune.offset_top = -50.0
	rune.offset_bottom = 110.0
	# Flattened so the circle lies on the floor under the hero's feet.
	rune.pivot_offset = Vector2(80.0, 80.0)
	rune.scale = Vector2(1.0, 0.38)
	holder.add_child(rune)
	var folder := str(GameState.selected_character_sprite_folder)
	if folder == "":
		folder = EmberfallPlayer.DEFAULT_SPRITE_FOLDER
	var frames := CharacterAnimations.build_sprite_frames(folder)
	if frames == null or not frames.has_animation("idle_right"):
		return
	var tex := frames.get_frame_texture("idle_right", 0)
	if tex == null:
		return
	var hero := TextureRect.new()
	hero.texture = tex
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.set_anchors_preset(Control.PRESET_CENTER)
	hero.offset_left = -95.0
	hero.offset_right = 95.0
	hero.offset_top = -130.0
	hero.offset_bottom = 60.0
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(hero)
	hero.pivot_offset = Vector2(95.0, 160.0)
	var tween := hero.create_tween().set_loops()
	tween.tween_property(hero, "scale", Vector2(1.0, 1.015), 1.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(hero, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)

static var _vignette: GradientTexture2D

static func _vignette_texture() -> GradientTexture2D:
	if _vignette != null:
		return _vignette
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0.02, 0.01, 0.05, 0.85))
	g.add_point(0.45, Color(0, 0, 0, 0.05))
	_vignette = GradientTexture2D.new()
	_vignette.gradient = g
	_vignette.fill = GradientTexture2D.FILL_RADIAL
	_vignette.fill_from = Vector2(0.5, 0.5)
	_vignette.fill_to = Vector2(1.0, 1.0)
	_vignette.width = 64
	_vignette.height = 64
	return _vignette

func _preview_style() -> StyleBox:
	var style := UiTheme.slot(true, 4)
	style.bg_color = UiTheme.BG_PANEL
	return UiTheme.kit("panel_default", style, 6.0)
