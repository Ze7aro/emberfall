extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## Unified hero + equipment screen. Two states live in the same scene
## (EQUIPMENT / HERO_SELECTION); switching between them is a Tween, never a
## scene change. Equipment is a single global loadout shared by every hero.

signal change_hero_mode_requested
signal hero_focused(hero_id: StringName)
signal hero_selection_requested(hero_id: StringName)
signal locked_hero_pressed(hero_id: StringName)
signal equipment_slot_pressed(slot_type: String)
signal inventory_item_pressed(item_id: String)
signal equip_item_requested(item_id: String)
signal selection_cancelled

@export_enum("inventory", "character") var initial_section: String = "inventory"

const ARC_RADIUS_X := 150.0
const ARC_RADIUS_Y := 46.0
const TRANSITION_TIME := 0.3

var _characters: Array = []
var _type_icons: Dictionary = {}
var _equipment_slots: Dictionary = {}
var _cards: Array[HeroCarouselCard] = []
var _mode := "EQUIPMENT"
var _transitioning := false
var _focused_index := 0
var _drag_active := false
var _drag_start_x := 0.0
var _drag_accum := 0.0

var _equipment_state: Control
var _selection_state: Control
var _left_slots: VBoxContainer
var _right_slots: VBoxContainer
var _hero_sprite: AnimatedSprite2D
var _hero_attack_label: Label
## Selection mode: the focused hero's weapon and its challenge.
var _weapon_icon: TextureRect
var _weapon_name: Label
var _weapon_goal: Label
var _change_hero_button: Button
var _forge_button: Button
var _forge: ForgePanel
var _basic_stats: HBoxContainer
## Equipment stats other than attack and health, in one short line.
var _equip_summary: Label
var _summary_toggle: Button
static var _summary_open := false
var _inventory_panel: Control
var _inventory_grid: GridContainer
var _essence_label: Label
var _sort_button: Button
var _detail: EquipmentDetailPanel
## Backpack order; kept while the game is open.
const SORT_MODES := ["rarity", "type", "level"]
const SORT_LABELS := {"rarity": "RAREZA", "type": "CASILLERO", "level": "NIVEL"}
static var _sort_mode := "rarity"
var _carousel_area: Control
var _carousel_indicators: HBoxContainer
var _selected_hero_name: Label
var _hero_name_label: Label
var _select_button: Button
var _back_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	_load_type_icons()
	_characters = _load_characters()

	_equipment_state = _build_equipment_state()
	add_child(_equipment_state)
	_selection_state = _build_selection_state()
	add_child(_selection_state)
	_build_carousel_cards()

	_refresh_hero_area()
	if initial_section == "character":
		_show_character_section_immediately()

	GameState.gold_changed.connect(func(_v): _refresh_basic_stats(); _refresh_inventory())
	GameState.gems_changed.connect(func(_v): _refresh_inventory())
	GameState.essence_changed.connect(func(_v): _refresh_inventory())
	GameState.inventory_changed.connect(func(): _refresh_equipment_slots(); _refresh_inventory())
	GameState.progress_changed.connect(_refresh_cards)

func _show_character_section_immediately() -> void:
	_mode = "HERO_SELECTION"
	_focused_index = _index_of_id(GameState.selected_character_id)
	_update_selection_info()
	_equipment_state.visible = false
	_selection_state.visible = true
	_selection_state.modulate.a = 1.0
	_layout_carousel(false)

## -- Data loading --

func _load_type_icons() -> void:
	for t in GameState.EQUIPMENT_TYPES:
		var path := "res://assets/ui/equipment/%s.png" % str(t)
		if not ResourceLoader.exists(path):
			path = "res://assets/ui/equipment/armor.png"
		_type_icons[t] = load(path) as Texture2D

func _icon_for_type(t: String) -> Texture2D:
	return _type_icons.get(t)

## The item's own icon (assets/ui/equipment/items/<id>.png, see
## docs/PROMPTS_EQUIPAMIENTO.md) or its slot's generic one while it's missing.
func _icon_for_item(item: Dictionary) -> Texture2D:
	var path := "res://assets/ui/equipment/items/%s.png" % str(item.get("id", ""))
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return _icon_for_type(str(item.get("equipment_type", "")))

## Heroes live as CharacterData .tres resources (see CharacterCatalog for the
## explicit roster) so adding/rebalancing one doesn't require touching this
## script beyond registering its path in the catalog.
func _load_characters() -> Array:
	var result: Array = []
	for data in CharacterCatalog.load_all():
		result.append({
			"id": data.id, "name": data.display_name, "weapon": data.weapon,
			"texture": data.texture_path, "sprite_folder": data.sprite_folder,
			"cost": data.cost, "currency": data.currency, "requirement": data.requirement,
			"attack_name": data.attack_name, "attack_color": data.attack_color,
			"hp_modifier": data.hp_modifier, "damage_modifier": data.damage_modifier,
		})
	return result

func _current_hero() -> Dictionary:
	for c in _characters:
		if StringName(str(c.get("id", ""))) == GameState.selected_character_id:
			return c
	return _characters[0] if not _characters.is_empty() else {}

## Keeps `child`'s rect matching `wrap`'s (a plain, non-Container parent
## doesn't do this on its own). `child` keeps its own free-standing
## `position`, which is exactly what the Tween-driven slide needs.
func _bind_child_size(wrap: Control, child: Control) -> void:
	child.size = wrap.size
	wrap.resized.connect(func(): child.size = wrap.size)

## -- EQUIPMENT state --

func _build_equipment_state() -> Control:
	var state := Control.new()
	state.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = UiTheme.CONTENT_TOP
	scroll.offset_bottom = -124
	state.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)
	col.add_child(UiTheme.header("EQUIPAMIENTO", "", 20))

	# Each column sits inside a plain (non-Container) wrapper so its own
	# `position` is free for the Tween to animate — a direct child of
	# HBoxContainer/VBoxContainer gets its position reset by the container's
	# own layout pass, which is what was corrupting the slide animation.
	var hero_row := HBoxContainer.new()
	hero_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_row.add_theme_constant_override("separation", 10)
	col.add_child(hero_row)

	var left_wrap := Control.new()
	left_wrap.custom_minimum_size = Vector2(SLOT_COLUMN_WIDTH, 244)
	left_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_row.add_child(left_wrap)
	_left_slots = _build_slot_column(["weapon", "armor", "helmet"])
	left_wrap.add_child(_left_slots)
	_bind_child_size(left_wrap, _left_slots)

	var hero_wrap := Control.new()
	hero_wrap.custom_minimum_size = Vector2(150, 262)
	hero_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hero_preview := _build_hero_preview()
	hero_preview.position = Vector2(0, 45) # 18px lower within the equipment row.
	hero_preview.size = Vector2(150, 190)
	hero_wrap.add_child(hero_preview)
	hero_row.add_child(hero_wrap)
	# Name above the hero, basic attack under the feet.
	_hero_name_label = Label.new()
	_hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_name_label.position = Vector2(-20, 36)
	_hero_name_label.size = Vector2(190, 30)
	_hero_name_label.clip_text = true
	UiTheme.style_title(_hero_name_label, 20, UiTheme.GOLD)
	_hero_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_wrap.add_child(_hero_name_label)

	var right_wrap := Control.new()
	right_wrap.custom_minimum_size = Vector2(SLOT_COLUMN_WIDTH, 244)
	right_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_row.add_child(right_wrap)
	_right_slots = _build_slot_column(["amulet", "ring", "boots"])
	right_wrap.add_child(_right_slots)
	_bind_child_size(right_wrap, _right_slots)

	_hero_attack_label = Label.new()
	_hero_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hero_attack_label.position = Vector2(-20, 240)
	_hero_attack_label.size = Vector2(190, 24)
	_hero_attack_label.add_theme_font_override("font", UiTheme.bold_font())
	_hero_attack_label.add_theme_font_size_override("font_size", 15)
	_hero_attack_label.add_theme_color_override("font_outline_color", Color("07060d"))
	_hero_attack_label.add_theme_constant_override("outline_size", 4)
	_hero_attack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_wrap.add_child(_hero_attack_label)

	var hero_buttons := HBoxContainer.new()
	hero_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_buttons.add_theme_constant_override("separation", 10)
	col.add_child(hero_buttons)
	_change_hero_button = Button.new()
	_change_hero_button.text = "CAMBIAR HÉROE"
	UiTheme.apply_primary(_change_hero_button)
	_change_hero_button.custom_minimum_size = Vector2(200, 52)
	_change_hero_button.pressed.connect(_on_change_hero_pressed)
	hero_buttons.add_child(_change_hero_button)
	_forge_button = Button.new()
	_forge_button.text = "FORJA"
	UiTheme.apply_secondary(_forge_button)
	_forge_button.add_theme_color_override("font_color", UiTheme.EMBER)
	_forge_button.custom_minimum_size = Vector2(110, 52)
	_forge_button.pressed.connect(func(): open_forge(""))
	hero_buttons.add_child(_forge_button)

	_basic_stats = HBoxContainer.new()
	_basic_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	_basic_stats.add_theme_constant_override("separation", 24)
	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", UiTheme.kit("panel_default", UiTheme.slot(false, 8)))
	stats_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 2)
	stats_box.add_child(_basic_stats)
	_equip_summary = Label.new()
	_equip_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_equip_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equip_summary.custom_minimum_size = Vector2(300, 0)
	_equip_summary.add_theme_font_size_override("font_size", 12)
	_equip_summary.add_theme_color_override("font_color", UiTheme.ACCENT)
	stats_box.add_child(_equip_summary)
	_summary_toggle = Button.new()
	_summary_toggle.flat = true
	_summary_toggle.focus_mode = Control.FOCUS_NONE
	_summary_toggle.custom_minimum_size = Vector2(0, 22)
	_summary_toggle.add_theme_font_size_override("font_size", 11)
	_summary_toggle.add_theme_color_override("font_color", UiTheme.ACCENT)
	_summary_toggle.add_theme_color_override("font_hover_color", UiTheme.TEXT)
	_summary_toggle.pressed.connect(func():
		_summary_open = not _summary_open
		_refresh_basic_stats())
	stats_box.add_child(_summary_toggle)
	stats_panel.add_child(stats_box)
	col.add_child(stats_panel)

	var inventory_wrap := Control.new()
	inventory_wrap.custom_minimum_size = Vector2(0, 270)
	inventory_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(inventory_wrap)
	var inventory_frame := Panel.new()
	inventory_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_frame.add_theme_stylebox_override("panel", UiTheme.kit("panel_main", UiTheme.panel(UiTheme.BORDER, UiTheme.CORNER, 4)))
	inventory_wrap.add_child(inventory_frame)
	_inventory_panel = _build_inventory_panel()
	inventory_wrap.add_child(_inventory_panel)
	# Inset so the mochila content sits inside its frame.
	_inventory_panel.position = Vector2(10, 8)
	_inventory_panel.size = inventory_wrap.size - Vector2(20, 16)
	inventory_wrap.resized.connect(func(): _inventory_panel.size = inventory_wrap.size - Vector2(20, 16))
	return state

const SLOT_COLUMN_WIDTH := 70.0

## Both columns (left: weapon/armor/helmet, right: amulet/ring/boots) go
## through this exact same builder so their slot sizing, spacing and label
## treatment can never drift apart between sides.
func _build_slot_column(types: Array) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	for t in types:
		var wrap := VBoxContainer.new()
		wrap.add_theme_constant_override("separation", 2)
		var label := Label.new()
		label.text = str(GameState.EQUIPMENT_TYPE_LABELS.get(t, t))
		label.custom_minimum_size = Vector2(SLOT_COLUMN_WIDTH, 0)
		label.clip_text = true
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		wrap.add_child(label)
		var slot_center := CenterContainer.new()
		slot_center.custom_minimum_size = Vector2(SLOT_COLUMN_WIDTH, 0)
		var slot := EquipmentSlot.new()
		slot.pressed.connect(_on_equipment_slot_pressed.bind(t))
		slot_center.add_child(slot)
		_equipment_slots[t] = slot
		wrap.add_child(slot_center)
		col.add_child(wrap)
	return col

func _build_hero_preview() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 190)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No frame: the hero stands on the rune circle, laid flat like a floor
	# seal and centred under the feet (sprite origin at 75, 165).
	var rune := RuneBackdrop.new()
	rune.position = Vector2(0, 90)
	rune.size = Vector2(150, 150)
	rune.pivot_offset = Vector2(75, 75)
	rune.scale = Vector2(1.0, 0.36)
	holder.add_child(rune)
	_hero_sprite = AnimatedSprite2D.new()
	_hero_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Origin near the feet (offset in texture pixels) so breathing grows
	# upward from the ground instead of from the middle of the body.
	_hero_sprite.offset = Vector2(0, -100)
	_hero_sprite.position = Vector2(75, 165)
	_hero_sprite.scale = Vector2(0.62, 0.62)
	holder.add_child(_hero_sprite)
	# Standing still, just breathing: a 1.5 % stretch of the chest, no float.
	var breath := create_tween()
	breath.set_loops()
	breath.tween_property(_hero_sprite, "scale", Vector2(0.62, 0.629), 1.6).set_trans(Tween.TRANS_SINE)
	breath.tween_property(_hero_sprite, "scale", Vector2(0.62, 0.62), 1.6).set_trans(Tween.TRANS_SINE)
	return holder

func _build_inventory_panel() -> Control:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 6)
	# Header: sort button, title and the Esencia the player has.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	panel.add_child(header)
	_sort_button = Button.new()
	_sort_button.custom_minimum_size = Vector2(104, 30)
	_sort_button.add_theme_font_size_override("font_size", 11)
	UiTheme.apply_secondary(_sort_button, 6.0)
	_sort_button.pressed.connect(_on_sort_pressed)
	header.add_child(_sort_button)
	var title := Label.new()
	title.text = "MOCHILA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	header.add_child(title)
	_essence_label = Label.new()
	_essence_label.custom_minimum_size = Vector2(104, 0)
	_essence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_essence_label.add_theme_font_override("font", UiTheme.bold_font())
	_essence_label.add_theme_font_size_override("font_size", 12)
	_essence_label.add_theme_color_override("font_color", EquipmentCatalog.RARITY_COLORS["epic"])
	header.add_child(_essence_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 214)
	panel.add_child(scroll)
	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 4
	_inventory_grid.add_theme_constant_override("h_separation", 8)
	_inventory_grid.add_theme_constant_override("v_separation", 8)
	_inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Centered horizontally so the 4 columns sit in the middle of the frame.
	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_center)
	grid_center.add_child(_inventory_grid)
	return panel

func _on_equipment_slot_pressed(equipment_type: String) -> void:
	equipment_slot_pressed.emit(equipment_type)
	var item := GameState.get_equipped_item_for_type(equipment_type)
	if not item.is_empty():
		open_item_detail(str(item.get("uid", "")))

func _on_inventory_item_pressed(uid: String) -> void:
	inventory_item_pressed.emit(uid)
	open_item_detail(uid)

## Detail card with compare, equip, upgrade and salvage (see
## EquipmentDetailPanel). Changes reach this screen via inventory_changed.
func open_item_detail(uid: String) -> void:
	if is_instance_valid(_detail):
		_detail.queue_free()
	var item := GameState.find_item(uid)
	if item.is_empty():
		return
	_detail = EquipmentDetailPanel.new()
	add_child(_detail)
	_detail.show_item(uid, _icon_for_item(item))
	_detail.forge_requested.connect(open_forge)
	_detail.closed.connect(func():
		_refresh_equipment_slots()
		_refresh_inventory()
		_refresh_basic_stats())

## The Forge, optionally with `uid`'s item already chosen.
func open_forge(uid: String) -> void:
	if is_instance_valid(_detail):
		_detail.queue_free()
	if is_instance_valid(_forge):
		_forge.queue_free()
	_forge = ForgePanel.new(_icon_for_item)
	_forge.select(uid)
	add_child(_forge)
	_forge.closed.connect(func():
		_refresh_equipment_slots()
		_refresh_inventory()
		_refresh_basic_stats())

func _on_sort_pressed() -> void:
	_sort_mode = SORT_MODES[(SORT_MODES.find(_sort_mode) + 1) % SORT_MODES.size()]
	_refresh_inventory()

func _sorted_inventory() -> Array:
	var items: Array = GameState.equipment_inventory.duplicate()
	var key := func(item: Dictionary) -> Array:
		var rarity := EquipmentCatalog.rarity_index(str(item.get("rarity", "common")))
		var slot := GameState.EQUIPMENT_TYPES.find(str(item.get("equipment_type", "")))
		var level := int(item.get("level", 1))
		match _sort_mode:
			"type": return [slot, -rarity, -level]
			"level": return [-level, -rarity, slot]
		return [-rarity, slot, -level]
	items.sort_custom(func(a, b):
		var ka: Array = key.call(a)
		var kb: Array = key.call(b)
		for i in ka.size():
			if ka[i] != kb[i]:
				return ka[i] < kb[i]
		return str(a.get("uid", "")) < str(b.get("uid", "")))
	return items

## True when `item` would raise the main stat of its slot.
func _is_upgrade_over_equipped(item: Dictionary) -> bool:
	var equipment_type := str(item.get("equipment_type", ""))
	var current := GameState.get_equipped_item_for_type(equipment_type)
	if str(current.get("uid", "")) == str(item.get("uid", "")):
		return false
	return current.is_empty() or EquipmentCatalog.main_value(item) > EquipmentCatalog.main_value(current) + 0.01

func _refresh_equipment_slots() -> void:
	for t in GameState.EQUIPMENT_TYPES:
		var slot: EquipmentSlot = _equipment_slots.get(t)
		if slot == null:
			continue
		var item := GameState.get_equipped_item_for_type(t)
		if item.is_empty():
			slot.set_empty()
		else:
			slot.set_item(_icon_for_item(item), str(item.get("rarity", "common")), EquipmentCatalog.main_short(item), true, false, int(item.get("level", 1)))

## Backpack always shows a full grid of square slots, not just the ones
## holding an item — an empty inventory otherwise reads as a blank panel
## instead of storage space, and a partially-filled row looked uneven.
const INVENTORY_MIN_SLOTS := 12

func _refresh_inventory() -> void:
	_sort_button.text = "ORDEN: %s" % SORT_LABELS[_sort_mode]
	_essence_label.text = "ESENCIA %d" % GameState.essence
	for child in _inventory_grid.get_children():
		child.queue_free()
	for item in _sorted_inventory():
		_inventory_grid.add_child(_build_inventory_slot(item))
	var slot_count := maxi(INVENTORY_MIN_SLOTS, GameState.equipment_inventory.size())
	var remainder := slot_count % _inventory_grid.columns
	if remainder != 0:
		slot_count += _inventory_grid.columns - remainder
	for _i in slot_count - GameState.equipment_inventory.size():
		_inventory_grid.add_child(EquipmentSlot.new())

func _build_inventory_slot(item: Dictionary) -> Control:
	var uid := str(item.get("uid", ""))
	var t := str(item.get("equipment_type", ""))
	var equipped := str(GameState.equipped_by_type.get(t, "")) == uid
	var slot := EquipmentSlot.new()
	slot.set_item(_icon_for_item(item), str(item.get("rarity", "common")), EquipmentCatalog.main_short(item), equipped, _is_upgrade_over_equipped(item), int(item.get("level", 1)))
	slot.pressed.connect(_on_inventory_item_pressed.bind(uid))
	return slot

func _refresh_basic_stats() -> void:
	for child in _basic_stats.get_children():
		child.queue_free()

	var hero := _current_hero()
	var damage_modifier := float(hero.get("damage_modifier", 1.0))
	var hp_modifier := int(hero.get("hp_modifier", 0))
	var attack := int(round((20 + (GameState.permanent_damage + GameState.get_equipped_bonus("damage")) * 2) * damage_modifier))
	if attack > 0:
		var sword_icon := UiTheme.icon_rect("icono_ataque.png", 22)
		if sword_icon.texture == null:
			sword_icon = TextureRect.new()
			sword_icon.texture = _icon_for_type("weapon")
			sword_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sword_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sword_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sword_icon.custom_minimum_size = Vector2(18, 18)
		_basic_stats.add_child(_stat_icon_row(sword_icon, "ATQ", str(attack)))
		_basic_stats.add_child(_stat_divider())

	var max_units := maxi(2, EmberfallPlayer.BASE_MAX_HP + GameState.permanent_health + GameState.get_equipped_bonus("health") + hp_modifier)
	if max_units > 0:
		var heart_icon := HeartsRow.new()
		heart_icon.heart_size = 16.0
		heart_icon.set_hearts(2, 2)
		_basic_stats.add_child(_stat_icon_row(heart_icon, "VIDA", str(max_units)))
	var totals := GameState.equipment_totals()
	var parts := PackedStringArray()
	for stat in EquipmentCatalog.STATS:
		if stat in ["damage", "health"] or float(totals.get(stat, 0.0)) <= 0.0:
			continue
		parts.append(EquipmentCatalog.stat_text(stat, float(totals[stat])))
	var pieces := GameState.equipped_set_pieces()
	for set_id in pieces:
		var count := int(pieces[set_id])
		if count >= EquipmentCatalog.SET_BONUS_PIECES:
			parts.append("Set %s %d/6%s" % [str(EquipmentCatalog.SETS[set_id]["name"]), count, " + efecto" if count >= EquipmentCatalog.SET_EFFECT_PIECES else ""])
	_equip_summary.text = "  ·  ".join(parts)
	_equip_summary.visible = _summary_open and not parts.is_empty()
	_summary_toggle.visible = not parts.is_empty()
	_summary_toggle.text = ("Ocultar stats del equipo ▲" if _summary_open else "Ver stats del equipo (%d) ▼" % parts.size())

func _stat_icon_row(icon: Control, label_text: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(icon)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", UiTheme.TEXT)
	row.add_child(value_label)
	return row

func _stat_divider() -> Label:
	var divider := Label.new()
	divider.text = "|"
	divider.add_theme_font_size_override("font_size", 18)
	divider.add_theme_color_override("font_color", Color("4a3f5c"))
	return divider

func _refresh_hero_area() -> void:
	var hero := _current_hero()
	if hero.is_empty():
		return
	var folder := str(hero.get("sprite_folder", ""))
	if folder != "" and is_instance_valid(_hero_sprite):
		_hero_sprite.sprite_frames = CharacterAnimations.build_sprite_frames(folder)
		_hero_sprite.play("idle_right")
	_hero_name_label.text = str(hero.get("name", ""))
	var attack_name := str(hero.get("attack_name", ""))
	_hero_attack_label.text = attack_name
	_hero_attack_label.visible = attack_name != ""
	if attack_name != "":
		_hero_attack_label.add_theme_color_override("font_color", hero.get("attack_color", UiTheme.ACCENT))
	_refresh_equipment_slots()
	_refresh_basic_stats()
	_refresh_inventory()

## -- HERO_SELECTION state --

func _build_selection_state() -> Control:
	var state := Control.new()
	state.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	state.visible = false

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = UiTheme.CONTENT_TOP
	col.offset_bottom = -124
	col.add_theme_constant_override("separation", 10)
	state.add_child(col)

	var title := Label.new()
	title.text = "SELECCIONAR HÉROE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", UiTheme.ACCENT)
	col.add_child(title)

	_carousel_area = Control.new()
	_carousel_area.custom_minimum_size = Vector2(0, 230)
	_carousel_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_carousel_area.clip_contents = true
	_carousel_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_carousel_area.gui_input.connect(_on_carousel_gui_input)
	col.add_child(_carousel_area)

	var prev_btn := Button.new()
	prev_btn.text = ""
	prev_btn.icon = UiTheme.icon("arrow_left.png")
	prev_btn.custom_minimum_size = Vector2(48, 60)
	prev_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	prev_btn.position += Vector2(4, -30)
	prev_btn.pressed.connect(_on_prev_pressed)
	_carousel_area.add_child(prev_btn)
	var next_btn := Button.new()
	next_btn.text = ""
	next_btn.icon = UiTheme.icon("arrow.png")
	next_btn.custom_minimum_size = Vector2(48, 60)
	next_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	next_btn.position += Vector2(-52, -30)
	next_btn.pressed.connect(_on_next_pressed)
	_carousel_area.add_child(next_btn)

	_carousel_indicators = HBoxContainer.new()
	_carousel_indicators.alignment = BoxContainer.ALIGNMENT_CENTER
	_carousel_indicators.add_theme_constant_override("separation", 6)
	col.add_child(_carousel_indicators)

	_selected_hero_name = Label.new()
	_selected_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_hero_name.add_theme_font_size_override("font_size", 16)
	col.add_child(_selected_hero_name)
	col.add_child(_build_weapon_info())

	var buttons_row := HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.add_theme_constant_override("separation", 12)
	col.add_child(buttons_row)
	_select_button = Button.new()
	_select_button.text = "SELECCIONAR"
	_select_button.custom_minimum_size = Vector2(140, 52)
	UiTheme.apply_primary(_select_button)
	_select_button.pressed.connect(_on_select_pressed)
	buttons_row.add_child(_select_button)
	_back_button = Button.new()
	_back_button.text = "VOLVER"
	_back_button.custom_minimum_size = Vector2(110, 52)
	_back_button.pressed.connect(_on_back_pressed)
	buttons_row.add_child(_back_button)

	return state

func _build_weapon_info() -> Control:
	var center := CenterContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	center.add_child(row)
	_weapon_icon = TextureRect.new()
	_weapon_icon.custom_minimum_size = Vector2(40, 40)
	_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_weapon_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_weapon_icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	_weapon_name = Label.new()
	_weapon_name.add_theme_font_override("font", UiTheme.bold_font())
	_weapon_name.add_theme_font_size_override("font_size", 15)
	text.add_child(_weapon_name)
	_weapon_goal = Label.new()
	_weapon_goal.add_theme_font_size_override("font_size", 13)
	_weapon_goal.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	_weapon_goal.custom_minimum_size = Vector2(230, 0)
	_weapon_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_weapon_goal)
	return center

func _refresh_weapon_info(hero_id: String) -> void:
	var weapon := AbilityCatalog.weapon_id(StringName(hero_id))
	_weapon_icon.texture = AbilityCatalog.icon(weapon)
	var hero := AbilityCatalog.weapon_hero(weapon)
	_weapon_name.text = "Arma: %s" % (hero.attack_name if hero != null else AbilityCatalog.display_name(weapon))
	_weapon_name.add_theme_color_override("font_color", AbilityCatalog.color(weapon))
	if GameState.is_weapon_unlocked(weapon):
		_weapon_goal.text = "✓ Desbloqueada para todos los héroes"
		_weapon_goal.add_theme_color_override("font_color", UiTheme.GOLD)
		return
	var challenge := AbilityCatalog.weapon_challenge(hero_id)
	var progress := GameState.weapon_challenge_progress(hero_id)
	_weapon_goal.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	_weapon_goal.text = "Para todos: %s · %d/%d" % [str(challenge.get("text", "")), mini(int(progress[0]), int(progress[1])), int(progress[1])]

func _build_carousel_cards() -> void:
	for hero in _characters:
		var card := HeroCarouselCard.new()
		var idx := _cards.size()
		_carousel_area.add_child(card)
		card.pressed.connect(_on_card_pressed.bind(idx))
		_cards.append(card)
	_refresh_cards()
	_carousel_area.resized.connect(func(): _layout_carousel(false))
	call_deferred("_layout_carousel", false)

func _refresh_cards() -> void:
	for i in _cards.size():
		var hero: Dictionary = _characters[i]
		var owned := GameState.owns_character(StringName(str(hero.get("id", ""))))
		_cards[i].setup(hero, owned, _card_condition_text(hero))

func _requirement_text(hero: Dictionary) -> String:
	var requirement := str(hero.get("requirement", ""))
	if requirement.begins_with("stage_"):
		return "Superar la pantalla %d" % int(requirement.trim_prefix("stage_"))
	if requirement.begins_with("dungeon_"):
		return "Superar %d mazmorra(s)" % int(requirement.trim_prefix("dungeon_"))
	return ""

func _requirement_met(hero: Dictionary) -> bool:
	return GameState.character_requirement_met(str(hero.get("requirement", "")))

func _cost_text(hero: Dictionary) -> String:
	var cost := int(hero.get("cost", 0))
	if cost <= 0:
		return ""
	var currency := str(hero.get("currency", "gold"))
	return "%d %s" % [cost, "ORO" if currency == "gold" else "ESMERALDAS"]

## What a locked card shows as its real unlock condition — progress gate
## takes priority over price, since paying doesn't help until it's met.
func _card_condition_text(hero: Dictionary) -> String:
	if GameState.owns_character(StringName(str(hero.get("id", "")))):
		return ""
	if not _requirement_met(hero):
		return _requirement_text(hero)
	return _cost_text(hero)

## Cards sit along a closed circular ring (angle step = 360° / card count) so
## going past the last card wraps back to the first and vice versa — the ring
## has no seam, so character 1 is reached both by going all the way forward
## and all the way back.
func _layout_carousel(animate: bool) -> void:
	if _cards.is_empty() or _carousel_area.size.x <= 0.0:
		return
	var count := _cards.size()
	var half := count / 2
	var angle_step_deg := 360.0 / count
	var center_x := _carousel_area.size.x / 2.0
	var center_y := _carousel_area.size.y / 2.0 - 8.0
	for i in count:
		var card: HeroCarouselCard = _cards[i]
		var offset := wrapi(i - _focused_index, -half, count - half)
		var is_center := offset == 0
		var angle := deg_to_rad(offset * angle_step_deg)
		var target_x := center_x + sin(angle) * ARC_RADIUS_X - HeroCarouselCard.CARD_SIZE.x / 2.0
		var target_y := center_y + (1.0 - cos(angle)) * ARC_RADIUS_Y - HeroCarouselCard.CARD_SIZE.y / 2.0
		var abs_offset := absi(offset)
		var target_scale := clampf(1.0 - abs_offset * 0.11, 0.32, 1.0)
		var target_alpha := clampf(1.0 - abs_offset * 0.08, 0.35, 1.0)
		card.visible = true
		card.z_index = 100 - abs_offset
		card.set_focus_state(is_center)
		if animate:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "position", Vector2(target_x, target_y), 0.28).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "scale", Vector2(target_scale, target_scale), 0.28)
			tween.tween_property(card, "modulate:a", target_alpha, 0.28)
		else:
			card.position = Vector2(target_x, target_y)
			card.scale = Vector2(target_scale, target_scale)
			card.modulate.a = target_alpha

func _update_indicators() -> void:
	for child in _carousel_indicators.get_children():
		child.queue_free()
	for i in _characters.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(7, 7)
		dot.color = UiTheme.ACCENT if i == _focused_index else Color("4a3f5c")
		_carousel_indicators.add_child(dot)

func _update_selection_info() -> void:
	if _characters.is_empty():
		return
	var hero: Dictionary = _characters[_focused_index]
	var id := StringName(str(hero.get("id", "")))
	var owned := GameState.owns_character(id)
	_selected_hero_name.text = str(hero.get("name", ""))
	_refresh_weapon_info(str(id))
	if owned:
		_select_button.text = "SELECCIONAR"
		_select_button.disabled = false
	elif not _requirement_met(hero):
		_select_button.text = "BLOQUEADO"
		_select_button.disabled = true
	else:
		var cost_text := _cost_text(hero)
		_select_button.text = "COMPRAR · %s" % cost_text if cost_text != "" else "COMPRAR"
		var currency := str(hero.get("currency", "gold"))
		var have := GameState.gold if currency == "gold" else GameState.gems
		_select_button.disabled = have < int(hero.get("cost", 0))
	_update_indicators()

func _move_focus(delta: int) -> void:
	if _transitioning or _cards.is_empty():
		return
	var new_index := wrapi(_focused_index + delta, 0, _cards.size())
	if new_index == _focused_index:
		return
	_focused_index = new_index
	_layout_carousel(true)
	_update_selection_info()
	hero_focused.emit(StringName(str(_characters[_focused_index].get("id", ""))))

func _on_prev_pressed() -> void:
	_move_focus(-1)

func _on_next_pressed() -> void:
	_move_focus(1)

func _on_carousel_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_drag_active = true; _drag_start_x = event.position.x; _drag_accum = 0.0
		elif _drag_active:
			_drag_active = false
			_resolve_swipe()
	elif event is InputEventScreenDrag and _drag_active:
		_drag_accum = event.position.x - _drag_start_x
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_active = true; _drag_start_x = event.position.x; _drag_accum = 0.0
		elif _drag_active:
			_drag_active = false
			_resolve_swipe()
	elif event is InputEventMouseMotion and _drag_active:
		_drag_accum = event.position.x - _drag_start_x

func _resolve_swipe() -> void:
	if absf(_drag_accum) > 40.0:
		_move_focus(-1 if _drag_accum > 0 else 1)
	_drag_accum = 0.0

func _index_of_id(id: StringName) -> int:
	for i in _characters.size():
		if StringName(str(_characters[i].get("id", ""))) == id:
			return i
	return 0

func _on_card_pressed(index: int) -> void:
	var hero: Dictionary = _characters[index]
	var id := StringName(str(hero.get("id", "")))
	if not GameState.owns_character(id):
		locked_hero_pressed.emit(id)
	if index != _focused_index:
		_focused_index = index
		_layout_carousel(true)
	_update_selection_info()
	hero_focused.emit(id)

func _on_select_pressed() -> void:
	if _characters.is_empty():
		return
	var hero: Dictionary = _characters[_focused_index]
	var id := StringName(str(hero.get("id", "")))
	if not GameState.owns_character(id):
		if not _requirement_met(hero):
			return
		if not GameState.buy_character(id):
			return
		_refresh_cards()
	hero_selection_requested.emit(id)
	GameState.set_selected_character(id, str(hero.get("texture", "")), str(hero.get("sprite_folder", "")))
	_exit_selection_mode(true)

func _on_back_pressed() -> void:
	selection_cancelled.emit()
	_exit_selection_mode(false)

## -- State transition (Tween, same scene) --

func _on_change_hero_pressed() -> void:
	_enter_selection_mode()

func _enter_selection_mode() -> void:
	if _transitioning or _mode == "HERO_SELECTION":
		return
	_transitioning = true
	_mode = "HERO_SELECTION"
	change_hero_mode_requested.emit()
	_focused_index = _index_of_id(GameState.selected_character_id)
	_update_selection_info()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_left_slots, "position:x", -60.0, TRANSITION_TIME).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_left_slots, "modulate:a", 0.0, TRANSITION_TIME)
	tween.tween_property(_right_slots, "position:x", 60.0, TRANSITION_TIME).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_right_slots, "modulate:a", 0.0, TRANSITION_TIME)
	tween.tween_property(_inventory_panel, "position:y", 60.0, TRANSITION_TIME)
	tween.tween_property(_inventory_panel, "modulate:a", 0.0, TRANSITION_TIME)
	tween.tween_property(_change_hero_button, "modulate:a", 0.0, 0.2)
	tween.tween_property(_forge_button, "modulate:a", 0.0, 0.2)
	tween.tween_property(_basic_stats, "modulate:a", 0.0, 0.2)
	tween.tween_property(_hero_attack_label, "modulate:a", 0.0, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(_swap_to_selection_state)
	tween.tween_property(_selection_state, "modulate:a", 1.0, 0.22)
	tween.tween_callback(func(): _transitioning = false)

func _swap_to_selection_state() -> void:
	_equipment_state.visible = false
	_reset_equipment_transform()
	_selection_state.visible = true
	_selection_state.modulate.a = 0.0
	_layout_carousel(false)

func _exit_selection_mode(hero_changed: bool) -> void:
	if _transitioning or _mode == "EQUIPMENT":
		return
	_transitioning = true
	_mode = "EQUIPMENT"

	var tween := create_tween()
	tween.tween_property(_selection_state, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		_selection_state.visible = false
		_equipment_state.visible = true
		if hero_changed:
			_refresh_hero_area()
		else:
			_refresh_equipment_slots()
			_refresh_inventory()
			_refresh_basic_stats()
	)
	tween.set_parallel(true)
	tween.tween_property(_left_slots, "position:x", 0.0, TRANSITION_TIME).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_left_slots, "modulate:a", 1.0, TRANSITION_TIME)
	tween.tween_property(_right_slots, "position:x", 0.0, TRANSITION_TIME).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_right_slots, "modulate:a", 1.0, TRANSITION_TIME)
	tween.tween_property(_inventory_panel, "position:y", 0.0, TRANSITION_TIME)
	tween.tween_property(_inventory_panel, "modulate:a", 1.0, TRANSITION_TIME)
	tween.tween_property(_change_hero_button, "modulate:a", 1.0, 0.2)
	tween.tween_property(_forge_button, "modulate:a", 1.0, 0.2)
	tween.tween_property(_basic_stats, "modulate:a", 1.0, 0.2)
	tween.tween_property(_hero_attack_label, "modulate:a", 1.0, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(func(): _transitioning = false)

func _reset_equipment_transform() -> void:
	_left_slots.position.x = 0.0; _left_slots.modulate.a = 1.0
	_right_slots.position.x = 0.0; _right_slots.modulate.a = 1.0
	_inventory_panel.position.y = 0.0; _inventory_panel.modulate.a = 1.0
	_change_hero_button.modulate.a = 1.0
	_forge_button.modulate.a = 1.0
	_basic_stats.modulate.a = 1.0
	_hero_attack_label.modulate.a = 1.0
