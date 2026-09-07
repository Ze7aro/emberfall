extends Control

const UPGRADES := [["damage", "DAÑO"], ["health", "VIDA"], ["speed", "VELOCIDAD"]]

var _gold_label: Label
var _rows := {}
var _equipment_list: VBoxContainer
var _equipment_gold_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)

	var root := VBoxContainer.new()
	root.anchor_left = 0.5; root.anchor_right = 0.5; root.anchor_top = 0.5; root.anchor_bottom = 0.5
	root.offset_left = -180; root.offset_right = 180; root.offset_top = -220; root.offset_bottom = 220
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "MEJORAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
	root.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	tabs.add_child(_build_equipment_tab())
	tabs.add_child(_build_permanent_tab())

	GameState.gold_changed.connect(func(_v): _refresh_all())
	GameState.inventory_changed.connect(_refresh_equipment)
	_refresh_all()

func _refresh_all() -> void:
	_refresh_equipment()
	_refresh_permanent()

func _build_equipment_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "EQUIPAMIENTO"
	tab.add_theme_constant_override("separation", 8)

	_equipment_gold_label = Label.new()
	_equipment_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab.add_child(_equipment_gold_label)

	var hint := Label.new()
	hint.text = "Consigue equipamiento comprando cofres en la Tienda."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("9b8eaa"))
	tab.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)
	_equipment_list = VBoxContainer.new()
	_equipment_list.add_theme_constant_override("separation", 8)
	_equipment_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_equipment_list)
	return tab

func _build_permanent_tab() -> Control:
	var tab := VBoxContainer.new()
	tab.name = "PERMANENTES"
	tab.add_theme_constant_override("separation", 12)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab.add_child(_gold_label)

	for entry in UPGRADES:
		var kind: String = entry[0]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(_buy_upgrade.bind(kind))
		tab.add_child(button)
		_rows[kind] = button
	return tab

func _buy_upgrade(kind: String) -> void:
	GameState.buy_upgrade(kind)
	_refresh_permanent()

func _refresh_permanent() -> void:
	_gold_label.text = "ORO DISPONIBLE: %d" % GameState.gold
	for entry in UPGRADES:
		var kind: String = entry[0]
		var label: String = entry[1]
		var level := GameState.get_upgrade_level(kind)
		var button: Button = _rows[kind]
		if level >= 10:
			button.text = "%s  ·  NIVEL MÁXIMO" % label
			button.disabled = true
		else:
			var cost := 40 + level * 35
			button.text = "%s  NIVEL %d  ·  COSTE %d" % [label, level, cost]
			button.disabled = GameState.gold < cost

func _refresh_equipment() -> void:
	_equipment_gold_label.text = "OBJETOS: %d" % GameState.equipment_inventory.size()
	for child in _equipment_list.get_children():
		child.queue_free()
	if GameState.equipment_inventory.is_empty():
		var empty := Label.new()
		empty.text = "Todavía no tenés equipamiento."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("9b8eaa"))
		_equipment_list.add_child(empty)
		return
	for item in GameState.equipment_inventory:
		_equipment_list.add_child(_build_equipment_row(item))

func _build_equipment_row(item: Dictionary) -> Control:
	var uid := str(item.get("uid", ""))
	var equipped := GameState.equipped_equipment_id == uid
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _entry_style(equipped))
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	row.add_child(box)
	var label := Label.new()
	label.text = "%s  (+%d %s)" % [str(item.get("name", "")), int(item.get("value", 0)), str(item.get("stat", ""))]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	var button := Button.new()
	button.text = "EQUIPADO" if equipped else "EQUIPAR"
	button.disabled = equipped
	button.pressed.connect(func(): GameState.equip_item(uid))
	box.add_child(button)
	return row

func _entry_style(equipped: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("302040") if equipped else Color("21182d")
	style.border_color = Color("20e6bd") if equipped else Color("5b4771")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
