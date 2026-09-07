extends Control

const OFFERS := [
	{"amount": 10, "cost": 30, "label": "10 ENERGÍA"},
	{"amount": 25, "cost": 65, "label": "25 ENERGÍA"},
	{"amount": 50, "cost": 110, "label": "ENERGÍA COMPLETA"},
]

var _gold_label: Label
var _rows: Array[Button] = []
var _chest_button: Button
var _chest_result_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Color("101a2b"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 0.5; box.anchor_bottom = 0.5
	box.offset_left = -160; box.offset_right = 160; box.offset_top = -260; box.offset_bottom = 260
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := Label.new()
	title.text = "TIENDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("20e6bd"))
	box.add_child(title)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_gold_label)

	for offer in OFFERS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.pressed.connect(_buy_energy.bind(offer))
		box.add_child(button)
		_rows.append(button)

	var chest_title := Label.new()
	chest_title.text = "COFRES DE EQUIPAMIENTO"
	chest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chest_title.add_theme_font_size_override("font_size", 16)
	chest_title.add_theme_color_override("font_color", Color("20e6bd"))
	box.add_child(chest_title)

	_chest_button = Button.new()
	_chest_button.custom_minimum_size = Vector2(0, 56)
	_chest_button.pressed.connect(_buy_chest)
	box.add_child(_chest_button)

	_chest_result_label = Label.new()
	_chest_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chest_result_label.add_theme_color_override("font_color", Color("d8c9ed"))
	box.add_child(_chest_result_label)

	GameState.gold_changed.connect(func(_v): _refresh())
	GameState.energy_changed.connect(func(_v): _refresh())
	_refresh()

func _buy_energy(offer: Dictionary) -> void:
	GameState.buy_energy_refill(int(offer.amount), int(offer.cost))
	_refresh()

func _buy_chest() -> void:
	var item := GameState.open_chest()
	if item.is_empty():
		return
	_chest_result_label.text = "¡Obtuviste %s!" % str(item.get("name", ""))
	_refresh()

func _refresh() -> void:
	_gold_label.text = "ORO DISPONIBLE: %d  ·  ENERGÍA: %d/%d" % [GameState.gold, GameState.energy, GameState.MAX_ENERGY]
	for i in OFFERS.size():
		var offer: Dictionary = OFFERS[i]
		var button := _rows[i]
		var full := GameState.energy >= GameState.MAX_ENERGY
		button.text = "%s  ·  %d ORO" % [str(offer.label), int(offer.cost)]
		button.disabled = full or GameState.gold < int(offer.cost)
	_chest_button.text = "ABRIR COFRE  ·  %d ORO" % GameState.CHEST_COST
	_chest_button.disabled = GameState.gold < GameState.CHEST_COST
