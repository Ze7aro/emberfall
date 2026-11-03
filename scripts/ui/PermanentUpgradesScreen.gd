extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## Progreso: a grid of permanent upgrades bought with gold (UpgradeCatalog)
## and the list of abilities with their unlock goals (AbilityCatalog.UNLOCKS).
## Tapping any tile shows it in the detail panel at the bottom, where the
## purchase happens, so a stray tap while scrolling never spends gold.

const GOLD := Color("e8b84a")
const COLUMNS := 4
const TILE_SIZE := Vector2(82, 104)

var _gold_label: Label
var _upgrade_grid: GridContainer
var _ability_grid: GridContainer
var _ability_note: Label
var _detail_icon: Control
var _detail_title: Label
var _detail_desc: Label
var _detail_button: Button
## "up:<id>" or "ab:<id>".
var _selected := "up:damage"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var bg := ColorRect.new(); bg.color = UiTheme.BG_DEEP; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var art := UiTheme.background("bg_mejoras.png", 0.6)
	if art != null:
		add_child(art)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 15; root.offset_right = -15; root.offset_top = UiTheme.CONTENT_TOP; root.offset_bottom = -124
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	root.add_child(UiTheme.header("PROGRESO", "CRECE. EVOLUCIONA. SOBREVIVE.", 30, "mejoras_header.png"))

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	_gold_label = Label.new()
	_gold_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold_label.add_theme_color_override("font_color", GOLD)
	top_row.add_child(_gold_label)
	var codex := Button.new()
	codex.text = "CÓDEX ›"
	codex.custom_minimum_size = Vector2(100, 36)
	codex.add_theme_font_size_override("font_size", 12)
	codex.pressed.connect(_open_codex)
	top_row.add_child(codex)
	root.add_child(top_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	column.add_child(UiTheme.section_title("MEJORAS", "se aplican en todas las partidas"))
	_upgrade_grid = _make_grid()
	column.add_child(_upgrade_grid)
	var ability_header := UiTheme.section_title("HABILIDADES")
	_ability_note = Label.new()
	_ability_note.add_theme_font_size_override("font_size", 10)
	_ability_note.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	ability_header.add_child(_ability_note)
	column.add_child(ability_header)
	_ability_grid = _make_grid()
	column.add_child(_ability_grid)

	root.add_child(_build_detail_panel())

	GameState.gold_changed.connect(func(_v): _refresh())
	_refresh()

func _open_codex() -> void:
	var node := get_parent()
	while node:
		if node.has_method("navigate_to"):
			node.navigate_to(&"codex")
			return
		node = node.get_parent()

func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return grid

func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 118)
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
	_detail_button = Button.new()
	_detail_button.custom_minimum_size = Vector2(0, 34)
	_detail_button.add_theme_font_size_override("font_size", 12)
	UiTheme.apply_primary_flat(_detail_button)
	_detail_button.pressed.connect(_on_buy_pressed)
	text.add_child(_detail_button)
	return panel

func _refresh() -> void:
	_gold_label.text = "ORO DISPONIBLE: %d" % GameState.gold
	for child in _upgrade_grid.get_children():
		child.queue_free()
	for upgrade in UpgradeCatalog.UPGRADES:
		_upgrade_grid.add_child(_upgrade_tile(str(upgrade["id"])))
	for child in _ability_grid.get_children():
		child.queue_free()
	var unlocked := 0
	for id in AbilityCatalog.ACTIVES:
		if GameState.is_ability_unlocked(id):
			unlocked += 1
		_ability_grid.add_child(_ability_tile(id))
	_ability_note.text = "%d/%d" % [unlocked, AbilityCatalog.ACTIVES.size()]
	_refresh_detail()

func _upgrade_tile(id: String) -> Control:
	var entry := UpgradeCatalog.entry(id)
	var level := GameState.get_upgrade_level(id)
	var max_level := UpgradeCatalog.max_level(id)
	var maxed := level >= max_level
	var affordable := not maxed and GameState.gold >= UpgradeCatalog.cost(id, level)
	var border := GOLD if maxed else (UiTheme.ACCENT if affordable else Color("4a3f5c"))
	var footer := "MÁX" if maxed else "%d/%d" % [level, max_level]
	return _tile("up:" + id, UpgradeCatalog.icon(id), str(entry["name"]), footer, border, false)

func _ability_tile(id: String) -> Control:
	var open := GameState.is_ability_unlocked(id)
	var footer := "LISTA"
	if not open:
		var progress := GameState.unlock_progress(id)
		footer = "%d/%d" % [mini(int(progress[0]), int(progress[1])), int(progress[1])]
	var border: Color = AbilityCatalog.color(id) if open else Color("4a3f5c")
	return _tile("ab:" + id, AbilityCatalog.icon(id), AbilityCatalog.display_name(id), footer, border, not open)

func _tile(key: String, icon: Texture2D, title: String, footer: String, border: Color, locked: bool) -> Control:
	var button := Button.new()
	button.custom_minimum_size = TILE_SIZE
	button.focus_mode = Control.FOCUS_NONE
	var style := UiTheme.slot(key == _selected, 4)
	style.border_color = UiTheme.ACCENT if key == _selected else border
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.pressed.connect(_select.bind(key))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 6; box.offset_bottom = -4
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon_holder := CenterContainer.new()
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(_icon_node(icon, title, 42.0, locked))
	box.add_child(icon_holder)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(TILE_SIZE.x - 8, 0)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED if locked else UiTheme.TEXT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	var footer_label := Label.new()
	footer_label.text = footer
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 10)
	footer_label.add_theme_color_override("font_color", GOLD if footer == "MÁX" else UiTheme.ACCENT)
	footer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(footer_label)
	return button

## Icon, or a tile with the initial while the art doesn't exist yet. Locked
## abilities are shown dimmed with a padlock.
func _icon_node(icon: Texture2D, title: String, side: float, locked: bool) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(side, side)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon:
		var rect := TextureRect.new()
		rect.texture = icon
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked:
			rect.modulate = Color(0.35, 0.32, 0.42)
		holder.add_child(rect)
	else:
		var tile := Panel.new()
		tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.add_theme_stylebox_override("panel", UiTheme.slot(false, 0))
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(tile)
		var initial := Label.new()
		initial.text = title.substr(0, 1).to_upper()
		initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial.add_theme_font_size_override("font_size", int(side * 0.45))
		initial.add_theme_color_override("font_color", UiTheme.TEXT_MUTED if locked else UiTheme.ACCENT)
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(initial)
	if locked:
		var lock := TextureRect.new()
		lock.texture = load("res://assets/ui/icons/lock.png") as Texture2D
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.offset_left = -11; lock.offset_right = 11; lock.offset_top = -11; lock.offset_bottom = 11
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(lock)
	return holder

func _select(key: String) -> void:
	_selected = key
	SfxPlayer.play_ui("ui/ui_select.wav")
	_refresh()

func _refresh_detail() -> void:
	for child in _detail_icon.get_children():
		child.queue_free()
	var id := _selected.substr(3)
	if _selected.begins_with("up:"):
		var entry := UpgradeCatalog.entry(id)
		var level := GameState.get_upgrade_level(id)
		var max_level := UpgradeCatalog.max_level(id)
		_detail_icon.add_child(_icon_node(UpgradeCatalog.icon(id), str(entry["name"]), 52.0, false))
		_detail_title.text = "%s  ·  NV. %d/%d" % [str(entry["name"]).to_upper(), level, max_level]
		_detail_desc.text = str(entry["desc"])
		_detail_button.visible = true
		if level >= max_level:
			_detail_button.text = "NIVEL MÁXIMO"
			_detail_button.disabled = true
		else:
			var cost := UpgradeCatalog.cost(id, level)
			_detail_button.text = "MEJORAR  ·  %d ORO" % cost
			_detail_button.disabled = GameState.gold < cost
	else:
		var open := GameState.is_ability_unlocked(id)
		_detail_icon.add_child(_icon_node(AbilityCatalog.icon(id), AbilityCatalog.display_name(id), 52.0, not open))
		_detail_title.text = AbilityCatalog.display_name(id)
		var requirement: Dictionary = AbilityCatalog.UNLOCKS.get(id, {})
		if open:
			_detail_desc.text = AbilityCatalog.description(id)
		else:
			var progress := GameState.unlock_progress(id)
			_detail_desc.text = "%s\nPara desbloquear: %s (%d/%d)" % [AbilityCatalog.description(id), str(requirement.get("text", "")), mini(int(progress[0]), int(progress[1])), int(progress[1])]
		_detail_button.visible = false

func _on_buy_pressed() -> void:
	if not _selected.begins_with("up:"):
		return
	GameState.buy_upgrade(_selected.substr(3))
	_refresh()
