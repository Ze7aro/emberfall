class_name EquipmentDetailPanel
extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## Item detail over the equipment screen: stats at the current level, the
## comparison with what is equipped in the same slot, and the Equip / Upgrade
## / Salvage actions. Tapping outside the card closes it.

signal closed

const CARD_WIDTH := 350.0
const UP_COLOR := Color("6fe08a")
const DOWN_COLOR := Color("e86a6a")

var _uid := ""
var _icon: Texture2D
var _confirm_salvage := false
var _card: PanelContainer
var _body: VBoxContainer

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	center.add_child(_card)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_card.add_child(_body)

func show_item(uid: String, icon: Texture2D) -> void:
	_uid = uid
	_icon = icon
	_confirm_salvage = false
	_rebuild()

func close() -> void:
	closed.emit()
	queue_free()

func _rebuild() -> void:
	for child in _body.get_children():
		child.queue_free()
	var item := GameState.find_item(_uid)
	if item.is_empty():
		close()
		return
	var rarity := str(item.get("rarity", "common"))
	var rarity_color: Color = EquipmentCatalog.RARITY_COLORS.get(rarity, UiTheme.TEXT)
	var style := UiTheme.panel(rarity_color, UiTheme.CORNER, 3)
	style.bg_color = UiTheme.BG_PANEL
	style.set_content_margin_all(14)
	_card.add_theme_stylebox_override("panel", style)

	var equipment_type := str(item.get("equipment_type", ""))
	var equipped := str(GameState.equipped_by_type.get(equipment_type, "")) == _uid
	var level := int(item.get("level", 1))
	_body.add_child(UiTheme.modal_header(str(item.get("name", "")), close, 20))

	# Icon + rarity, slot and level.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	_body.add_child(top)
	var slot := EquipmentSlot.new()
	slot.custom_minimum_size = Vector2(64, 64)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.set_item(_icon, rarity, "", equipped, false, 0)
	top.add_child(slot)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(info)
	info.add_child(_label("%s · %s" % [EquipmentCatalog.RARITY_LABELS.get(rarity, rarity), EquipmentCatalog.TYPE_LABELS.get(equipment_type, equipment_type)], 14, rarity_color, true))
	info.add_child(_label("Nivel %d/%d" % [level, EquipmentCatalog.MAX_LEVEL], 14, UiTheme.TEXT))
	if equipped:
		info.add_child(_label("EQUIPADO", 12, UiTheme.GOLD, true))

	# Stats, compared with the item equipped in the same slot.
	var other := GameState.get_equipped_item_for_type(equipment_type)
	var comparing := not other.is_empty() and str(other.get("uid", "")) != _uid
	if comparing:
		_body.add_child(_label("Comparado con %s (Nv %d)" % [str(other.get("name", "")), int(other.get("level", 1))], 12, UiTheme.TEXT_MUTED))
	elif not equipped:
		_body.add_child(_label("No tenés nada equipado en este casillero", 12, UiTheme.TEXT_MUTED))
	_body.add_child(_stats_grid(item, other if comparing else {}))

	var cost := EquipmentCatalog.upgrade_cost(item)
	if not cost.is_empty():
		var next := item.duplicate(true)
		next["level"] = level + 1
		var gains := PackedStringArray()
		var now_stats := EquipmentCatalog.item_stats(item)
		var next_stats := EquipmentCatalog.item_stats(next)
		for stat in next_stats:
			var gain := float(next_stats[stat]) - float(now_stats.get(stat, 0.0))
			if gain > 0.0:
				gains.append("%s %s" % [EquipmentCatalog.stat_label(stat), EquipmentCatalog.delta_text(stat, gain)])
		var gains_label := _label("Al mejorar: " + ", ".join(gains), 12, UiTheme.ACCENT)
		gains_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(gains_label)

	var unique := str(item.get("unique", ""))
	if unique != "":
		var unique_label := _label("Efecto único: %s (se activa más adelante)" % EquipmentCatalog.UNIQUES.get(unique, unique), 12, EquipmentCatalog.RARITY_COLORS["legendary"])
		unique_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(unique_label)

	_body.add_child(_buttons(item, equipped, cost))
	_body.add_child(_label("Tenés %d de oro y %d de Esencia" % [GameState.gold, GameState.essence], 12, UiTheme.TEXT_MUTED))

func _stats_grid(item: Dictionary, other: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)
	var mine := EquipmentCatalog.item_stats(item)
	var theirs := EquipmentCatalog.item_stats(other) if not other.is_empty() else {}
	var order: Array = mine.keys()
	for stat in theirs:
		if not order.has(stat):
			order.append(stat)
	for stat in order:
		var value := float(mine.get(stat, 0.0))
		var name_label := _label(EquipmentCatalog.stat_label(stat), 14, UiTheme.TEXT if mine.has(stat) else UiTheme.TEXT_MUTED)
		name_label.custom_minimum_size = Vector2(150, 0)
		grid.add_child(name_label)
		var value_text := EquipmentCatalog.value_text(stat, value) + ("/min" if stat == "regen" else "")
		var value_label := _label(value_text if mine.has(stat) else "—", 14, UiTheme.TEXT, true)
		value_label.custom_minimum_size = Vector2(70, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(value_label)
		var delta_label := _label("", 13, UiTheme.TEXT_MUTED, true)
		delta_label.custom_minimum_size = Vector2(80, 0)
		if not other.is_empty():
			var delta := value - float(theirs.get(stat, 0.0))
			var shown := snappedf(delta, 0.1) if stat == "regen" else roundf(delta)
			if is_zero_approx(shown):
				delta_label.text = "="
			else:
				delta_label.text = ("▲ " if shown > 0.0 else "▼ ") + EquipmentCatalog.delta_text(stat, delta)
				delta_label.add_theme_color_override("font_color", UP_COLOR if shown > 0.0 else DOWN_COLOR)
		grid.add_child(delta_label)
	return grid

func _buttons(item: Dictionary, equipped: bool, cost: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var equip := Button.new()
	equip.text = "QUITAR" if equipped else "EQUIPAR"
	equip.custom_minimum_size = Vector2(0, 48)
	UiTheme.apply_primary(equip)
	equip.pressed.connect(func():
		if equipped:
			GameState.unequip_type(str(item.get("equipment_type", "")))
		else:
			GameState.equip_item(_uid)
		_confirm_salvage = false
		_rebuild())
	box.add_child(equip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var upgrade := Button.new()
	upgrade.custom_minimum_size = Vector2(0, 52)
	upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTheme.apply_secondary(upgrade, 6.0)
	upgrade.add_theme_font_size_override("font_size", 13)
	if cost.is_empty():
		upgrade.text = "NIVEL MÁXIMO"
		upgrade.disabled = true
	else:
		upgrade.text = "MEJORAR\n%d oro · %d Esencia" % [int(cost["gold"]), int(cost["essence"])]
		upgrade.disabled = not GameState.can_upgrade_item(_uid)
		upgrade.pressed.connect(func():
			GameState.upgrade_item(_uid)
			_confirm_salvage = false
			_rebuild())
	row.add_child(upgrade)

	var salvage := Button.new()
	salvage.custom_minimum_size = Vector2(0, 52)
	salvage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTheme.apply_secondary(salvage, 6.0)
	salvage.add_theme_font_size_override("font_size", 13)
	var gain := EquipmentCatalog.salvage_value(item)
	if _confirm_salvage:
		salvage.text = "¿SEGURO?\nTocá de nuevo"
		salvage.add_theme_color_override("font_color", UiTheme.DANGER)
	else:
		salvage.text = "DESARMAR\n+%d Esencia" % gain
	salvage.pressed.connect(func():
		if not _confirm_salvage:
			_confirm_salvage = true
			_rebuild()
			return
		GameState.salvage_item(_uid)
		close())
	row.add_child(salvage)
	return box

func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", UiTheme.bold_font())
	return label
