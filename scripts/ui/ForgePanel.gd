class_name ForgePanel
extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## The Forge: 3 identical items (same item and rarity) fuse into one of the
## next rarity; Épico+ needs 2 to become Legendario. The copy with the
## highest level is kept. The rules live in GameState.merge_*.

signal closed

const COLUMNS := 5

var _icon_for_item: Callable
var _selected_uid := ""
var _input_row: HBoxContainer
var _result_slot: EquipmentSlot
var _result_text: Label
var _status: Label
var _merge_button: Button
var _merge_all_button: Button
var _grid: GridContainer

func _init(icon_for_item: Callable) -> void:
	_icon_for_item = icon_for_item
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 10
	card.offset_right = -10
	card.offset_top = UiTheme.CONTENT_TOP - 8
	card.offset_bottom = -116
	var style := UiTheme.panel(UiTheme.EMBER, UiTheme.CORNER, 3)
	style.bg_color = UiTheme.BG_PANEL
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	card.add_child(body)
	body.add_child(UiTheme.modal_header("FORJA", close, 24))

	var hint := Label.new()
	hint.text = "Juntá 3 objetos iguales de la misma rareza para subirla. De Épico+ a Legendario alcanzan 2. Se queda el de nivel más alto."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	body.add_child(hint)

	# Inputs -> result.
	var fusion := HBoxContainer.new()
	fusion.alignment = BoxContainer.ALIGNMENT_CENTER
	fusion.add_theme_constant_override("separation", 6)
	body.add_child(fusion)
	_input_row = HBoxContainer.new()
	_input_row.add_theme_constant_override("separation", 6)
	fusion.add_child(_input_row)
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 26)
	arrow.add_theme_color_override("font_color", UiTheme.EMBER)
	fusion.add_child(arrow)
	_result_slot = EquipmentSlot.new()
	_result_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fusion.add_child(_result_slot)

	_result_text = Label.new()
	_result_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_text.add_theme_font_override("font", UiTheme.bold_font())
	_result_text.add_theme_font_size_override("font_size", 13)
	body.add_child(_result_text)
	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
	body.add_child(_status)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	body.add_child(buttons)
	_merge_button = Button.new()
	_merge_button.text = "FUSIONAR"
	_merge_button.custom_minimum_size = Vector2(0, 48)
	_merge_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTheme.apply_primary(_merge_button)
	_merge_button.pressed.connect(_on_merge_pressed)
	buttons.add_child(_merge_button)
	_merge_all_button = Button.new()
	_merge_all_button.text = "FUSIONAR TODO"
	_merge_all_button.custom_minimum_size = Vector2(0, 48)
	_merge_all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTheme.apply_secondary(_merge_all_button, 6.0)
	_merge_all_button.pressed.connect(_on_merge_all_pressed)
	buttons.add_child(_merge_all_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	center.add_child(_grid)

func _ready() -> void:
	_refresh()

func close() -> void:
	closed.emit()
	queue_free()

## Opens with `uid`'s item already chosen.
func select(uid: String) -> void:
	_selected_uid = uid
	if is_inside_tree():
		_refresh()

func _icon(item: Dictionary) -> Texture2D:
	return _icon_for_item.call(item)

func _refresh() -> void:
	if GameState.find_item(_selected_uid).is_empty():
		_selected_uid = ""
	_refresh_fusion()
	_refresh_groups()

func _refresh_fusion() -> void:
	for child in _input_row.get_children():
		child.queue_free()
	_result_slot.set_empty()
	_merge_button.disabled = true
	_merge_all_button.disabled = not _any_merge_possible()
	var copies := GameState.merge_copies(_selected_uid)
	if copies.is_empty():
		for _i in 3:
			_input_row.add_child(EquipmentSlot.new())
		_result_text.text = ""
		_status.text = "Elegí un objeto de la lista."
		return
	var item: Dictionary = copies[0]
	var rarity := str(item.get("rarity", "common"))
	var need := EquipmentCatalog.merge_count(rarity)
	if need <= 0:
		_input_row.add_child(_slot_for(item))
		_result_text.text = str(item.get("name", ""))
		_result_text.add_theme_color_override("font_color", EquipmentCatalog.RARITY_COLORS[rarity])
		_status.text = "Ya es Legendario: no se puede fusionar más."
		return
	var selection := GameState.merge_selection(_selected_uid)
	var shown: Array = selection if not selection.is_empty() else copies
	for i in need:
		_input_row.add_child(_slot_for(shown[i]) if i < shown.size() else EquipmentSlot.new())
	var preview: Dictionary = item.duplicate(true)
	EquipmentCatalog.raise_rarity(preview)
	var next := str(preview.get("rarity", rarity))
	_result_slot.set_item(_icon(preview), next, EquipmentCatalog.main_short(preview), false, false, int(preview.get("level", 1)))
	_result_text.text = "%s · %s · Nv %d/%d" % [str(item.get("name", "")), EquipmentCatalog.RARITY_LABELS[next], int(preview.get("level", 1)), EquipmentCatalog.max_level(next)]
	_result_text.add_theme_color_override("font_color", EquipmentCatalog.RARITY_COLORS[next])
	if selection.is_empty():
		var missing := need - copies.size()
		_status.text = "Tenés %d de %d. Te %s %d más igual%s." % [copies.size(), need, "falta" if missing == 1 else "faltan", missing, "" if missing == 1 else "es"]
		return
	var main_stat := str(item.get("main", {}).get("stat", ""))
	var gains := "%s %s → %s" % [EquipmentCatalog.stat_label(main_stat), EquipmentCatalog.value_text(main_stat, EquipmentCatalog.main_value(item)), EquipmentCatalog.value_text(main_stat, EquipmentCatalog.main_value(preview))]
	var refund := 0
	for material in selection.slice(1):
		refund += EquipmentCatalog.essence_spent(material)
	var subs_added := (preview.get("subs", []) as Array).size() - (item.get("subs", []) as Array).size()
	var parts := PackedStringArray([gains])
	if subs_added > 0:
		parts.append("+%d stat secundaria%s" % [subs_added, "" if subs_added == 1 else "s"])
	if next == "legendary":
		parts.append("efecto único")
	if refund > 0:
		parts.append("te devuelve %d de Esencia" % refund)
	_status.text = " · ".join(parts)
	_merge_button.disabled = false

func _slot_for(item: Dictionary) -> EquipmentSlot:
	var slot := EquipmentSlot.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.set_item(_icon(item), str(item.get("rarity", "common")), EquipmentCatalog.main_short(item), GameState._is_equipped(item), false, int(item.get("level", 1)))
	return slot

## One tile per item and rarity, with how many copies there are.
func _refresh_groups() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var groups := {}
	for item in GameState.equipment_inventory:
		var key := "%s|%s" % [item.get("id", ""), item.get("rarity", "")]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(item)
	var keys: Array = groups.keys()
	var info := func(key: String) -> Array:
		var first: Dictionary = groups[key][0]
		var rarity := str(first.get("rarity", "common"))
		var need := EquipmentCatalog.merge_count(rarity)
		var ready := need > 0 and (groups[key] as Array).size() >= need
		return [0 if ready else 1, -EquipmentCatalog.rarity_index(rarity), GameState.EQUIPMENT_TYPES.find(str(first.get("equipment_type", ""))), str(first.get("id", ""))]
	keys.sort_custom(func(a, b):
		var ia: Array = info.call(a)
		var ib: Array = info.call(b)
		for i in ia.size():
			if ia[i] != ib[i]:
				return ia[i] < ib[i]
		return false)
	for key in keys:
		var copies: Array = groups[key]
		var first: Dictionary = copies[0]
		var rarity := str(first.get("rarity", "common"))
		var need := EquipmentCatalog.merge_count(rarity)
		var best := 0
		for c in copies:
			best = maxi(best, int(c.get("level", 1)))
		var slot := EquipmentSlot.new()
		var count_text := "%d/%d" % [copies.size(), need] if need > 0 else "x%d" % copies.size()
		var ready := need > 0 and copies.size() >= need
		slot.set_item(_icon(first), rarity, count_text, str(first.get("uid", "")) == _selected_uid or _group_has(copies, _selected_uid), ready, best)
		if not ready:
			slot.modulate = Color(1, 1, 1, 0.7)
		slot.pressed.connect(select.bind(str(first.get("uid", ""))))
		_grid.add_child(slot)
	if keys.is_empty():
		var empty := Label.new()
		empty.text = "Tu mochila está vacía."
		empty.add_theme_color_override("font_color", UiTheme.TEXT_MUTED)
		_grid.add_child(empty)

func _group_has(copies: Array, uid: String) -> bool:
	for c in copies:
		if str(c.get("uid", "")) == uid:
			return true
	return false

func _any_merge_possible() -> bool:
	for item in GameState.equipment_inventory:
		if not GameState.merge_selection(str(item.get("uid", ""))).is_empty():
			return true
	return false

func _on_merge_pressed() -> void:
	var result := GameState.merge_item(_selected_uid)
	if not result.is_empty():
		_selected_uid = str(result.get("uid", ""))
	_refresh()

func _on_merge_all_pressed() -> void:
	var count := GameState.merge_all()
	_refresh()
	if count > 0:
		_status.text = "Se hicieron %d fusion%s." % [count, "" if count == 1 else "es"]
