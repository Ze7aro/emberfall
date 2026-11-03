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
	var art := UiTheme.background("bg_tienda.png", 0.6)
	if art != null:
		add_child(art)
	var scroll := ScrollContainer.new(); scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); scroll.offset_top = UiTheme.CONTENT_TOP; scroll.offset_bottom = -120; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	var frame := MarginContainer.new(); frame.add_theme_constant_override("margin_left", 12); frame.add_theme_constant_override("margin_right", 12); frame.add_theme_constant_override("margin_top", 6); frame.add_theme_constant_override("margin_bottom", 18); frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(frame)
	content = VBoxContainer.new(); content.custom_minimum_size = Vector2(0, 1180); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation", 10); frame.add_child(content)
	var header := HBoxContainer.new(); header.custom_minimum_size = Vector2(0, 72); content.add_child(header)
	var title := UiTheme.header("TIENDA", "LA OSCURIDAD TAMBIÉN TIENE SUS RECURSOS", 34, "tienda_header.png"); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	_add_section("MONEDAS")
	var coins := GridContainer.new(); coins.columns = 3; coins.size_flags_horizontal = Control.SIZE_EXPAND_FILL; coins.add_theme_constant_override("h_separation", 5); coins.add_theme_constant_override("v_separation", 6); content.add_child(coins)
	for i in GameState.COIN_OFFERS.size(): coins.add_child(_product_card(GameState.COIN_OFFERS[i], "MONEDAS", i))
	_add_section("ENERGÍA")
	var energy := HBoxContainer.new(); energy.add_theme_constant_override("separation", 5); content.add_child(energy)
	for i in GameState.ENERGY_OFFERS.size(): energy.add_child(_product_card(GameState.ENERGY_OFFERS[i], "ENERGÍA", i))
	_add_section("BAÚLES")
	var chests := HBoxContainer.new(); chests.add_theme_constant_override("separation", 5); content.add_child(chests)
	for i in GameState.CHEST_TIERS.size(): chests.add_child(_chest_card(GameState.CHEST_TIERS[i], i))

const SECTION_NOTES := {"MONEDAS": "Recursos para un guerrero sin límites", "ENERGÍA": "Sigue explorando", "BAÚLES": "Equipo, mejoras y más"}

func _add_section(text_value: String) -> void:
	var row := UiTheme.section_title(text_value, str(SECTION_NOTES.get(text_value, "")), GOLD)
	row.custom_minimum_size = Vector2(0, 38)
	content.add_child(row)

const ART_DIR := "res://assets/ui/"
## Stable offer ids select art independently from catalogue order.
## Exact amounts and prices remain dynamic text from GameState.
const OFFER_ART := {
	"recarga_oro_gratis": "shop/gold_coins.png",
	"recarga_oro_baja": "shop/gold_stack.png",
	"recarga_oro_media": "shop/gold_pile.png",
	"bolsa_oro_media": "shop/gold_bag.png",
	"cofre_oro_medio": "shop/gold_chest.png",
	"cofre_oro_grande": "shop/gold_chest.png",
	"recarga_energia_gratuita": "icons/energy.png",
	"recarga_energia_media": "shop/energy_bottle.png",
	"recarga_energia_grande": "shop/energy_bottles.png",
	"baul_comun": "shop/chest_common.png",
	"baul_epico": "shop/chest_epic.png",
}

## Kit art for an offer; keeps the old text label if the file is missing.
## The art is small pixel art (~55 px): scaled up with nearest filtering.
func _art_node(offer_id: String, fallback: Label, height: float) -> Control:
	var path := ART_DIR + str(OFFER_ART.get(offer_id, ""))
	if path == "" or not ResourceLoader.exists(path):
		return fallback
	var rect := TextureRect.new()
	rect.texture = load(path) as Texture2D
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(0, height)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _card_base(min_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new(); card.custom_minimum_size = min_size
	var style := StyleBoxFlat.new(); style.bg_color = PANEL; style.border_color = BORDER; style.set_border_width_all(3); style.set_corner_radius_all(UiTheme.CORNER); style.content_margin_left = 5; style.content_margin_right = 5; style.content_margin_top = 5; style.content_margin_bottom = 5; card.add_theme_stylebox_override("panel", UiTheme.kit("panel_card", style, 10.0)); return card

func _product_card(offer: Dictionary, kind: String, index: int) -> Control:
	var card := _card_base(Vector2(0, 155)); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 6); card.add_child(box)
	if int(offer.cost) == 0:
		var tag := Label.new(); tag.text = "GRATIS"; tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tag.add_theme_font_size_override("font_size", 11); tag.add_theme_color_override("font_color", UiTheme.ACCENT); box.add_child(tag)
	var art := Label.new(); art.text = str(offer.art); art.custom_minimum_size = Vector2(0, 62); art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; art.add_theme_font_size_override("font_size", 14); art.add_theme_color_override("font_color", TURQ if kind == "ENERGÍA" else GOLD); box.add_child(_art_node(str(offer.get("id", "")), art, 62))
	var amount := Label.new(); amount.text = "%s %s" % [str(offer.amount), kind]; amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; amount.clip_text = true; amount.add_theme_font_size_override("font_size", 12); box.add_child(amount)
	var is_usd := offer.has("usd")
	var is_free := not is_usd and int(offer.cost) == 0
	var already_claimed := is_free and GameState.claimed_free_offers.has("%s_%d" % ["coin" if kind == "MONEDAS" else "energy", index])
	var buy := Button.new(); buy.name = "Buy"
	buy.text = "RECLAMADO" if already_claimed else ("GRATIS" if is_free else "%d ◇" % int(offer.cost))
	if is_usd:
		# First purchase through a rewarded ad (when the offer has one), then USD.
		var ad_pending: bool = bool(offer.get("ad_first", false)) and not GameState.claimed_free_offers.has("ad_%s_%d" % ["coin" if kind == "MONEDAS" else "energy", index])
		buy.text = "VER ANUNCIO" if ad_pending else "USD %s" % str(offer.usd)
	buy.disabled = already_claimed
	buy.custom_minimum_size = Vector2(0, 36)
	if already_claimed:
		buy.add_theme_stylebox_override("disabled", UiTheme.slot(false, 6)); buy.add_theme_font_size_override("font_size", 11)
	if not already_claimed: UiTheme.apply_primary(buy, 6.0)
	buy.clip_text = true
	buy.add_theme_font_size_override("font_size", 11)
	if is_usd:
		buy.pressed.connect(_show_store_soon)
	else:
		buy.pressed.connect(_buy_product.bind(kind, index))
	box.add_child(buy)
	return card

func _chest_card(chest: Dictionary, index: int) -> Control:
	var card := _card_base(Vector2(0, 260)); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 7); card.add_child(box)
	var title := Label.new(); title.text = chest.title; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_color_override("font_color", GOLD); title.add_theme_font_size_override("font_size", 17); box.add_child(title)
	var art := Label.new(); art.text = str(chest.art); art.custom_minimum_size = Vector2(0, 105); art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; art.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; art.add_theme_font_size_override("font_size", 23); art.add_theme_color_override("font_color", TURQ if chest.art == "EPIC" else Color("a87955")); box.add_child(_art_node(str(chest.get("id", "")), art, 105))
	var rarity := Label.new(); rarity.text = " · ".join(chest.rarities); rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; rarity.add_theme_font_size_override("font_size", 11); box.add_child(rarity)
	var buy := Button.new(); buy.name = "Buy"; buy.text = "%d  ◇" % int(chest.cost); buy.custom_minimum_size = Vector2(0, 48); UiTheme.apply_primary(buy); buy.pressed.connect(_buy_chest.bind(index)); box.add_child(buy)
	return card

## No payment / rewarded-ads SDK is connected yet: tapping only explains that.
## Nothing is granted. Hook the real purchase flow in here.
func _show_store_soon() -> void:
	var toast := Label.new()
	toast.text = "Próximamente"
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_outline_color", Color("0a0612"))
	toast.add_theme_constant_override("outline_size", 8)
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.offset_left = -100.0; toast.offset_right = 100.0
	toast.offset_top = -190.0; toast.offset_bottom = -150.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast)
	SfxPlayer.play("economy/purchase_failed.wav", false)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(toast.queue_free)

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
