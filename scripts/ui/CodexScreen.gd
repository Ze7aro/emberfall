extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")
const DragScroll := preload("res://scripts/ui/DragScroll.gd")

## Códex: every ability and evolution the player has used, a guide with the
## recipe of each evolution already made at least once, and a bestiary of
## enemies with lifetime kill counts. Unseen entries show as "???".
## Opened from Progreso; tapping a tile shows it in the bottom panel.

signal back_requested

const GOLD := Color("e8b84a")
const COLUMNS := 4
const TILE_SIZE := Vector2(82, 96)
const LOCKED_TINT := Color(0.12, 0.10, 0.18)

## Shown for an evolution the player hasn't made yet: the recipe stays
## secret until then (it appears in the EVOLUCIONES guide afterwards).
const UNKNOWN_EVOLUTION := "Evolución: ??? (evoluciónala una vez para registrar su receta)"

var _detail_icon: CenterContainer
var _detail_title: Label
var _detail_desc: Label
var _drag: DragScroll

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var bg := ColorRect.new(); bg.color = UiTheme.BG_DEEP; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var art := UiTheme.background("bg_mejoras.png", 0.7)
	if art != null:
		add_child(art)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 15; root.offset_right = -15; root.offset_top = UiTheme.CONTENT_TOP; root.offset_bottom = -124
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	var back := Button.new()
	back.text = "‹ PROGRESO"
	back.custom_minimum_size = Vector2(110, 40)
	back.add_theme_font_size_override("font_size", 12)
	back.pressed.connect(func(): back_requested.emit())
	header_row.add_child(back)
	var title := Label.new()
	title.text = "CÓDEX"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTheme.style_title(title, 26)
	header_row.add_child(title)
	root.add_child(header_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_drag = DragScroll.new(scroll)
	add_child(_drag)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	var heroes := AbilityCatalog.WEAPON_CHALLENGES.keys()
	var unlocked_weapons := 0
	for hero_id in heroes:
		if GameState.is_weapon_unlocked(AbilityCatalog.weapon_id(StringName(hero_id))):
			unlocked_weapons += 1
	column.add_child(UiTheme.section_title("ARMAS", "%d/%d" % [unlocked_weapons, heroes.size()]))
	var weapon_grid := _make_grid()
	for hero_id in heroes:
		weapon_grid.add_child(_weapon_tile(str(hero_id)))
	column.add_child(weapon_grid)

	var actives := AbilityCatalog.ACTIVES.keys()
	column.add_child(UiTheme.section_title("ACTIVAS", "%d/%d" % [_count_seen(actives), actives.size()]))
	var active_grid := _make_grid()
	for id in actives:
		active_grid.add_child(_ability_tile(str(id)))
	column.add_child(active_grid)

	var passives := AbilityCatalog.PASSIVES.keys()
	column.add_child(UiTheme.section_title("PASIVAS", "%d/%d" % [_count_seen(passives), passives.size()]))
	var passive_grid := _make_grid()
	for id in passives:
		passive_grid.add_child(_ability_tile(str(id)))
	column.add_child(passive_grid)

	_build_evolution_guide(column)

	var seen_enemies := 0
	for entry in BestiaryCatalog.ENTRIES:
		if int(GameState.bestiary.get(entry["key"], 0)) > 0:
			seen_enemies += 1
	column.add_child(UiTheme.section_title("BESTIARIO", "%d/%d" % [seen_enemies, BestiaryCatalog.ENTRIES.size()]))
	var enemy_grid := _make_grid()
	for entry in BestiaryCatalog.ENTRIES:
		enemy_grid.add_child(_enemy_tile(entry))
	column.add_child(enemy_grid)

	root.add_child(_build_detail_panel())
	_show_detail(null, "CÓDEX", "Toca un arma, una habilidad, una evolución o un enemigo para ver su detalle. Lo que todavía no descubriste aparece como ???.", UiTheme.TEXT)

func _count_seen(ids: Array) -> int:
	var seen := 0
	for id in ids:
		if str(id) in GameState.discovered_abilities:
			seen += 1
	return seen

func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return grid

func _tile(border: Color, picture: Control, caption: String, caption_color: Color, on_press: Callable) -> Control:
	var tile := Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.focus_mode = Control.FOCUS_NONE
	var style := UiTheme.slot(false, 4)
	style.border_color = border
	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("hover", style)
	tile.add_theme_stylebox_override("pressed", style)
	_connect_tap(tile, on_press)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 6; box.offset_bottom = -4; box.offset_left = 3; box.offset_right = -3
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(box)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(picture)
	box.add_child(center)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", caption_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return tile

func _picture(texture: Texture2D, size: float, tint: Color, fallback_text: String = "?") -> Control:
	if texture == null:
		var label := Label.new()
		label.text = fallback_text
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.modulate = tint
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _ability_tile(id: String) -> Control:
	var seen := id in GameState.discovered_abilities
	var evolved_seen := id in GameState.discovered_evolutions
	if not seen:
		var unknown := _picture(AbilityCatalog.icon(id), 46.0, LOCKED_TINT)
		return _tile(UiTheme.BORDER_SOFT, unknown, "???", UiTheme.TEXT_MUTED, func():
			var hint := "Todavía no la usaste en ninguna partida."
			if AbilityCatalog.UNLOCKS.has(id) and not GameState.is_ability_unlocked(id):
				hint = "Bloqueada: %s." % str(AbilityCatalog.UNLOCKS[id]["text"])
			_show_detail(null, "???", hint, UiTheme.TEXT_MUTED))
	var picture := _picture(AbilityCatalog.icon(id, evolved_seen), 46.0, Color.WHITE, AbilityCatalog.display_name(id).left(1))
	var border: Color = GOLD if evolved_seen else UiTheme.ACCENT_DIM
	return _tile(border, picture, AbilityCatalog.display_name(id), UiTheme.TEXT, func():
		var text := AbilityCatalog.description(id)
		if AbilityCatalog.is_active(id):
			var evolution: Dictionary = AbilityCatalog.ACTIVES[id]["evolution"]
			var partner := AbilityCatalog.display_name(str(evolution["passive"]))
			if evolved_seen:
				text += "\n★ %s (nivel %d + %s): %s" % [str(evolution["name"]), AbilityCatalog.MAX_LEVEL, partner, str(evolution["desc"])]
			else:
				text += "\n" + UNKNOWN_EVOLUTION
		_show_detail(AbilityCatalog.icon(id, evolved_seen), AbilityCatalog.display_name(id, evolved_seen), text, GOLD if evolved_seen else UiTheme.TEXT))

## A hero's weapon: "???" until its challenge (played with that hero)
## unlocks it for every hero.
func _weapon_tile(hero_id: String) -> Control:
	var id := AbilityCatalog.weapon_id(StringName(hero_id))
	var hero := AbilityCatalog.weapon_hero(id)
	var hero_name := hero.display_name.capitalize() if hero != null else hero_id
	var challenge := AbilityCatalog.weapon_challenge(hero_id)
	var progress := GameState.weapon_challenge_progress(hero_id)
	var goal := "%s (%d/%d)" % [str(challenge.get("text", "")), mini(int(progress[0]), int(progress[1])), int(progress[1])]
	if not GameState.is_weapon_unlocked(id):
		var hint := "Arma de %s. Desafío jugando con %s: %s." % [hero_name, hero_name, goal]
		if not GameState.owns_character(StringName(hero_id)):
			hint = "Arma de %s. Primero desbloquea a %s; después: %s." % [hero_name, hero_name, str(challenge.get("text", ""))]
		return _tile(UiTheme.BORDER_SOFT, _picture(AbilityCatalog.icon(id), 46.0, LOCKED_TINT), "???", UiTheme.TEXT_MUTED, func():
			_show_detail(null, "???", hint, UiTheme.TEXT_MUTED))
	var color := AbilityCatalog.color(id)
	var evolved_seen := id in GameState.discovered_evolutions
	var evolution := AbilityCatalog.evolution_info(id)
	return _tile(GOLD if evolved_seen else color, _picture(AbilityCatalog.icon(id, evolved_seen), 46.0, Color.WHITE), AbilityCatalog.display_name(id), UiTheme.TEXT, func():
		var text := "Arma de %s. La pueden usar todos los héroes.
Niveles: %s." % [hero_name, ", ".join(PackedStringArray([2, 3, 4, 5].map(func(l): return AbilityCatalog.weapon_level_text(l).to_lower())))]
		if not evolution.is_empty():
			var partner := AbilityCatalog.display_name(str(evolution["passive"]))
			if evolved_seen:
				text += "
★ %s (nivel %d + %s): %s" % [str(evolution["name"]), AbilityCatalog.MAX_LEVEL, partner, str(evolution["desc"])]
			else:
				text += "
" + UNKNOWN_EVOLUTION
		_show_detail(AbilityCatalog.icon(id, evolved_seen), AbilityCatalog.display_name(id, evolved_seen), text, GOLD if evolved_seen else color))

## Every Códex button: PASS so a drag that starts on it still scrolls, and
## a finger lifted after scrolling isn't taken as a tap.
func _connect_tap(button: Button, on_press: Callable) -> void:
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.pressed.connect(func():
		if not _drag.blocks_tap():
			on_press.call())

# --- Evolution guide --------------------------------------------------------

## Recipe (ability/weapon + passive → evolution) of every evolution made at
## least once in a run; the rest stay hidden behind a count.
func _build_evolution_guide(column: VBoxContainer) -> void:
	var sources: Array[String] = []
	for id in AbilityCatalog.ACTIVES:
		if AbilityCatalog.has_evolution(str(id)):
			sources.append(str(id))
	for hero_id in AbilityCatalog.WEAPON_EVOLUTIONS:
		sources.append(AbilityCatalog.weapon_id(StringName(hero_id)))
	var found: Array[String] = []
	for id in sources:
		if id in GameState.discovered_evolutions:
			found.append(id)
	column.add_child(UiTheme.section_title("EVOLUCIONES", "%d/%d" % [found.size(), sources.size()]))
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	for id in found:
		list.add_child(_evolution_row(id))
	var missing := sources.size() - found.size()
	if missing > 0:
		var note := Label.new()
		note.text = ("Faltan %d por descubrir. " % missing) + ("Cada evolución que logres en una partida registra aquí su receta." if found.is_empty() else "Evoluciona otras habilidades o armas para completar la guía.")
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.add_theme_font_size_override("font_size", 11)
		note.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		list.add_child(note)
	column.add_child(list)

func _evolution_row(id: String) -> Control:
	var evolution := AbilityCatalog.evolution_info(id)
	var partner := str(evolution["passive"])
	var evo_name := str(evolution["name"])
	var recipe := "%s (nivel %d) + %s (nivel %d)" % [AbilityCatalog.display_name(id), AbilityCatalog.MAX_LEVEL, AbilityCatalog.display_name(partner), AbilityCatalog.MAX_LEVEL]
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 60)
	row.focus_mode = Control.FOCUS_NONE
	var style := UiTheme.slot(false, 4)
	style.border_color = Color(GOLD, 0.7)
	row.add_theme_stylebox_override("normal", style)
	row.add_theme_stylebox_override("hover", style)
	row.add_theme_stylebox_override("pressed", style)
	_connect_tap(row, func():
		_show_detail(AbilityCatalog.icon(id, true), evo_name, "%s\n%s" % [recipe, str(evolution["desc"])], GOLD))
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8; box.offset_right = -8
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	box.add_child(_picture(AbilityCatalog.icon(id), 34.0, Color.WHITE, AbilityCatalog.display_name(id).left(1)))
	box.add_child(_symbol("+"))
	box.add_child(_picture(AbilityCatalog.icon(partner), 34.0, Color.WHITE, AbilityCatalog.display_name(partner).left(1)))
	box.add_child(_symbol("→"))
	box.add_child(_picture(AbilityCatalog.icon(id, true), 42.0, Color.WHITE, "★"))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override("separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(text)
	var title := Label.new()
	title.text = evo_name
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", UiTheme.bold_font())
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", GOLD)
	text.add_child(title)
	var sub := Label.new()
	sub.text = "%s + %s" % [AbilityCatalog.display_name(id), AbilityCatalog.display_name(partner)]
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	text.add_child(sub)
	return row

func _symbol(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", GOLD)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _enemy_tile(entry: Dictionary) -> Control:
	var key := str(entry["key"])
	var kills := int(GameState.bestiary.get(key, 0))
	var texture := BestiaryCatalog.texture(entry)
	if kills <= 0:
		return _tile(UiTheme.BORDER_SOFT, _picture(texture, 54.0, LOCKED_TINT), "???", UiTheme.TEXT_MUTED, func():
			_show_detail(null, "???", "Todavía no derrotaste a este enemigo.", UiTheme.TEXT_MUTED))
	var is_boss := entry.has("boss_folder")
	var picture := _picture(texture, 54.0, BestiaryCatalog.tint(entry))
	var border: Color = UiTheme.PURPLE if is_boss else UiTheme.ACCENT_DIM
	return _tile(border, picture, "×%d" % kills, UiTheme.TEXT, func():
		_show_detail(texture, str(entry["name"]), "%s\nDerrotados: %d" % [str(entry["desc"]), kills], UiTheme.PURPLE if is_boss else UiTheme.TEXT, BestiaryCatalog.tint(entry)))

func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 112)
	panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_modal", UiTheme.panel(UiTheme.ACCENT, UiTheme.CORNER, 3)))
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	_detail_icon = CenterContainer.new()
	_detail_icon.custom_minimum_size = Vector2(56, 56)
	row.add_child(_detail_icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 3)
	row.add_child(text)
	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 14)
	text.add_child(_detail_title)
	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_font_size_override("font_size", 11)
	_detail_desc.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	text.add_child(_detail_desc)
	return panel

func _show_detail(texture: Texture2D, title: String, desc: String, color: Color, tint: Color = Color.WHITE) -> void:
	for child in _detail_icon.get_children():
		child.queue_free()
	if texture != null:
		_detail_icon.add_child(_picture(texture, 52.0, tint))
	_detail_title.text = title
	_detail_title.add_theme_color_override("font_color", color)
	_detail_desc.text = desc
