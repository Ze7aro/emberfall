extends Control

const UiTheme := preload("res://scripts/ui/UiTheme.gd")

## AUD-08: amount/cost/rarities now live only in GameState (COIN_OFFERS/
## ENERGY_OFFERS/CHEST_TIERS) — this screen just displays them and buys by
## index, instead of being the source of truth GameState blindly trusted.
const BG := UiTheme.BG_DEEP
const PANEL := UiTheme.BG_SLOT
const BORDER := UiTheme.BORDER_SOFT
const TURQ := UiTheme.ACCENT
const GOLD := Color("f4bd4e")
var content: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.make_theme()
	var bg := ColorRect.new(); bg.color = BG; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var scroll := ScrollContainer.new(); scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); scroll.offset_top = 165; scroll.offset_bottom = -120; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	var frame := MarginContainer.new(); frame.add_theme_constant_override("margin_left", 12); frame.add_theme_constant_override("margin_right", 12); frame.add_theme_constant_override("margin_top", 6); frame.add_theme_constant_override("margin_bottom", 18); frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(frame)
	content = VBoxContainer.new(); content.custom_minimum_size = Vector2(0, 1180); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation", 10); frame.add_child(content)
	var header := HBoxContainer.new(); header.custom_minimum_size = Vector2(0, 72); content.add_child(header)
	var title := Label.new(); title.text = "TIENDA"; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 30); title.add_theme_color_override("font_color", TURQ); header.add_child(title)
	var close := Button.new(); close.text = "✕"; close.custom_minimum_size = Vector2(64, 64)
	close.pressed.connect(func():
		var main_layout := _find_main_layout()
		if main_layout:
			main_layout.navigate_to(&"home")
	)
	header.add_child(close)
	_add_section("MONEDAS")
	var coins := GridContainer.new(); coins.columns = 3; coins.size_flags_horizontal = Control.SIZE_EXPAND_FILL; coins.add_theme_constant_override("h_separation", 5); coins.add_theme_constant_override("v_separation", 6); content.add_child(coins)
	for i in GameState.COIN_OFFERS.size(): coins.add_child(_product_card(GameState.COIN_OFFERS[i], "MONEDAS", i))
	_add_section("ENERGÍA")
	var energy := HBoxContainer.new(); energy.add_theme_constant_override("separation", 5); content.add_child(energy)
	for i in GameState.ENERGY_OFFERS.size(): energy.add_child(_product_card(GameState.ENERGY_OFFERS[i], "ENERGÍA", i))
	_add_section("BAÚLES")
	var chests := HBoxContainer.new(); chests.add_theme_constant_override("separation", 5); content.add_child(chests)
	for i in GameState.CHEST_TIERS.size(): chests.add_child(_chest_card(GameState.CHEST_TIERS[i], i))

func _add_section(text_value: String) -> void:
	var label := Label.new(); label.text = "  ◈  %s  ◈" % text_value; label.custom_minimum_size = Vector2(0, 42); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 19); label.add_theme_color_override("font_color", GOLD); content.add_child(label)

func _card_base(min_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new(); card.custom_minimum_size = min_size
	var style := StyleBoxFlat.new(); style.bg_color = PANEL; style.border_color = BORDER; style.set_border_width_all(3); style.set_corner_radius_all(UiTheme.CORNER); style.content_margin_left = 5; style.content_margin_right = 5; style.content_margin_top = 5; style.content_margin_bottom = 5; card.add_theme_stylebox_override("panel", style); return card

func _product_card(offer: Dictionary, kind: String, index: int) -> Control:
	var card := _card_base(Vector2(0, 155)); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 6); card.add_child(box)
	var art := Label.new(); art.text = "✦\n%s" % str(offer.art); art.custom_minimum_size = Vector2(0, 62); art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; art.add_theme_font_size_override("font_size", 14); art.add_theme_color_override("font_color", TURQ if kind == "ENERGÍA" else GOLD); box.add_child(art)
	var amount := Label.new(); amount.text = "%s %s" % [str(offer.amount), kind]; amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; amount.clip_text = true; amount.add_theme_font_size_override("font_size", 12); box.add_child(amount)
	var is_free := int(offer.cost) == 0
	var already_claimed := is_free and GameState.claimed_free_offers.has("%s_%d" % ["coin" if kind == "MONEDAS" else "energy", index])
	var buy := Button.new(); buy.name = "Buy"
	buy.text = "RECLAMADO" if already_claimed else ("GRATIS" if is_free else "%d ◇" % int(offer.cost))
	buy.disabled = already_claimed
	buy.custom_minimum_size = Vector2(0, 36); buy.add_theme_font_size_override("font_size", 11)
	if not already_claimed: UiTheme.apply_primary(buy)
	buy.pressed.connect(_buy_product.bind(kind, index)); box.add_child(buy)
	return card

func _chest_card(chest: Dictionary, index: int) -> Control:
	var card := _card_base(Vector2(0, 260)); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 7); card.add_child(box)
	var title := Label.new(); title.text = chest.title; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_color_override("font_color", GOLD); title.add_theme_font_size_override("font_size", 17); box.add_child(title)
	var art := Label.new(); art.text = "✧\n%s\n✧" % chest.art; art.custom_minimum_size = Vector2(0, 105); art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; art.add_theme_font_size_override("font_size", 23); art.add_theme_color_override("font_color", TURQ if chest.art == "EPIC" else Color("a87955")); box.add_child(art)
	var rarity := Label.new(); rarity.text = " · ".join(chest.rarities); rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rarity.add_theme_font_size_override("font_size", 11); box.add_child(rarity)
	var buy := Button.new(); buy.name = "Buy"; buy.text = "%d  ◇" % int(chest.cost); buy.custom_minimum_size = Vector2(0, 48); UiTheme.apply_primary(buy); buy.pressed.connect(_buy_chest.bind(index)); box.add_child(buy)
	return card

func _buy_product(kind: String, index: int) -> void:
	if kind == "MONEDAS":
		GameState.buy_coin_offer(index)
	else:
		GameState.buy_energy_offer(index)

func _buy_chest(index: int) -> void:
	GameState.open_chest_with_gems(index)

func _find_main_layout() -> Node:
	var node := get_parent()
	while node:
		if node.has_method("navigate_to"):
			return node
		node = node.get_parent()
	return null
