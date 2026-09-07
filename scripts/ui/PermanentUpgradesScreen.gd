extends Control

const UPGRADES := [["damage", "DAÑO"], ["health", "VIDA"], ["speed", "VELOCIDAD"]]

var _gold_label: Label
var _rows := {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 0.5; box.anchor_bottom = 0.5
	box.offset_left = -160; box.offset_right = 160; box.offset_top = -180; box.offset_bottom = 180
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := Label.new()
	title.text = "MEJORAS PERMANENTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
	box.add_child(title)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_gold_label)

	for entry in UPGRADES:
		var kind: String = entry[0]
		var label: String = entry[1]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(_buy_upgrade.bind(kind))
		box.add_child(button)
		_rows[kind] = button

	_refresh()

func _buy_upgrade(kind: String) -> void:
	GameState.buy_upgrade(kind)
	_refresh()

func _refresh() -> void:
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
